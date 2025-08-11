{%
add_pic = true
setvar("layout",theme .. ".html")
%}

# Rewriting in rust
*How to clone you way out of a problem*

As you might have noticed because of the *subtle* banner at the bottom of this page, I am using a custom static website generator for this website.

<br>

Why?

<br>

Just read the [ASG](http://github.com/vanyle/ASG) page to find out.

<br>

However, while I love this generator, I was facing some impossible to debug crashes linked to the live reload system. Sometime, while saving a file and sending a websocket message to the browser for refreshing, the ASG process would crash.

After weeks of debugging threading issues in Nim, I gave up. While I still love Nim, I believe that multithreading, especially for IO-bound tasks is its biggest shortcoming. Most ~All~ Nim threading libraries like [weave](https://github.com/mratsim/weave) or [malebolgia](https://github.com/Araq/malebolgia) are designed for going a lot of computations, not for waiting that a file is changed. Moreover, I had to write my own bindings to the OS APIs for watching files as there is no good cross platform library to watch for changes in Nim.

<br>

Some of it was my fault as I was trying to use as few libraries as possible, but in the end, you read the title, you know what I did.

<br>

And I must say, Rust was gotten pretty good, so let's to a quick review of the language, divided between the great, the good and the bad as there was nothing too ugly I found.

Every item is listed from what I enjoyed the most to what I enjoyed the least.

## The Great

### The tooling

Rust has one of the best tooling I've every seen, maybe just behind Typescript. Autocompletion is fast and good, error highlighting too and installing packages is as simple as going a `cargo add <package name>`

Writing tests is as simple as annotating as putting your tests function inside a block like:

{{ highlight("rs", [[
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        let result = add(2, 2);
        assert_eq!(result, 4);
    }
}
]])}}

And calling `cargo test`.

<br>

### Super high quality libraries

I was able to replace 300 lines of OS specific MacOS, Windows and inotify code with a simple call to `new_debouncer` from the `notify_debouncer_full` crate which also handled deduplicating events, something I did manually previously.

{{ highlight("rs",[[

let (debounce_event_sender, mut debounce_receiver) = broadcast::channel(16);

let mut debouncer = new_debouncer(
    Duration::from_millis(100),
    None,
    move |result: DebounceEventResult| match result {
        Ok(events) => events.iter().for_each(|event| {
            let _ = debounce_event_sender.send(event.clone());
        }),
        Err(errors) => errors.iter().for_each(|error| println!("{error:?}")),
    },
).unwrap();
let _ = debouncer.watch(input_directory, RecursiveMode::Recursive);

// I can clone debounce_receiver and pass it around to listen to file events.

]])}}

The Lua crate was very very good too and allowed me to switch from Lua JIT to Luau to be able to put type annotations in my code!

I can also highlight code at build time using `syntect` crate meaning I no longer need to ship a large `highlight.min.js` file to your browser!

As a post writer, I just to

{{
highlight("lua",[==[
highlight("language",[[
    // My code here
]])
]==])
}}

And I get syntax highlighted!

<br>

## The good

### The type system

Rust's type system is pretty good, on par with typescript.
There are some issues of course.
Sometimes,` collect` fails and you need to put an annotation.
Sometimes you get an inference error because of something you do a few lines later and the error message is a bit confusing.

I really love this syntax:

{{
highlight("rs",[==[
let Some(val) = may_fail() else{
    return;
};
]==])
}}

It is similar to now Go does things while forcing you to handle the error.

### You can let an LLMs write some basic code

Because of how easy units tests can be added and how typing is really strict, you can for a lot of things just use an AI Agent like the one inside cursor to write some boilerplate code.

There is a lot of Rust code online, so the LLMs know the functions well and can help you learn new functions of the standard library.

The LLM will fail as soon as it needs to do something non-trivial, for example when doing using a new crate in the project for the first time, but they can help for repetitive tasks, refactoring and finding issues like unnecessary clones and typos.

## The bad

### Violating the Convention on Human Rights and Biomedicine

Ah cloning. We all know it's bad for performance, but we all do it.
Why? Maybe because we like Star Wars too much? Or maybe it is because of Jurassic Park?

Anyway, The crab people love it too.

When you're too tired to wrap your type in a `Rc<RefCell<T>>`, you just clone it.

In Nim, pointers are reference counted (but you can opt out), with some smart analysis from the compiler to remove the reference counting if it can prove that there is no crazy borrowing (plus some cycle detection).

I think this makes naively written Nim code faster to naively written Rust code.
Of course, you can spend time in Rust to use the best type for the job and beat naive Nim, but you can also use raw pointers and write snippets of assembly in Nim to crush other languages.

Anyway, It is not a big issue, just an annoyance. The code still works and has similar performance to the Nim code. Optimizing it will be a goal for future me.

Also, the fact that `String` must hold UTF-8 is silly. In ASG, I regularly convert `PathBuf` to `String` and doing `to_string_lossy()` feels useless. `String` should just be an alias to `Vec<u8>` with a dedicated type for `UTF-8`.

A type named `String` will be used everywhere as devs are used to it from other languages, so it makes sense to have something close to `std::string` from C++, `string` from Nim.

When I write a string in quotes, I am defining a byte sequence.

Maybe you can provide a `StringUnicode` type for unicode specific problems?

Because of this, I had to have an unsafe block when writing the tokenizer for ASG to test for substrings. Could I have done it without unsafe? Sure but in that case, I would have needed to convert between `&[u8]` and `String`, do some copies and make the code longer and less clear.

<br>

### Unable to find 'musl-g++' on 'x86_64-unknown-linux-musl'

Oh boy, do I hate how linking works on Linux. When building ASG for linux, I realized that the glibc version used by the Github Action CI was different from the one on my computer, meaning that my linux build was not usable for a lot of people.

I wanted to have a static build of ASG. It should be as simple as using `x86_64-unknown-linux-musl` for my target. Right?

<br>

😡😡😡

<br>

I spend 3 hours going from blog post to Stack Overflow to Github Issues, trying to understand how to do a linux static build because for some reason `cargo` tried to use gcc instead of musl for compiling some dependencies.

I fixed the issue with a Docker image made for this exact use case, but it was a wild ride. If you are interested, here is an excerpt from the workflow file:

{{ highlight("yaml", [[
jobs:
  release_linux:
    name: Release - Linux
    runs-on: ubuntu-latest
    # The build cannot work without this image.
    container:
      image: messense/rust-musl-cross:x86_64-musl

    steps:
      - uses: actions/checkout@v4

      - uses: actions-rust-lang/setup-rust-toolchain@v1
        with:
          profile: stable
          target: x86_64-unknown-linux-musl

      - name: Build
        run: cargo build --target=x86_64-unknown-linux-musl --release

]])}}

# Conclusion

Rust is pretty good. Way better than last time I tried to use it in 2018. The IDE support is solid and you are very productive for something this low-level.

Because of the linter and all the compile-time checks, I believe that it is the perfect language for work in large teams where readability and stability are paramount.

Is it good for writing web services as a Go replacement? I don't know, I did try to interact with a database. But it'd say that if you are writing an app that will run an a client's computer, outside a browser, like a CLI tool or a desktop app, Rust is a great choice.

You can crash-free statically linked executables in a language with easy access to low-level OS APIs.

<br>

**final note**:

If you want to try ASG, install it in one command using:


**Windows:**

{{ highlight("sh", [[irm "https://raw.githubusercontent.com/vanyle/ASG/refs/heads/master/install/get_asg_win.ps1" | iex]]) }}

**MacOS**

{{ highlight("sh", [[curl -fsSL https://raw.githubusercontent.com/vanyle/ASG/refs/heads/master/install/get_asg_macos.sh | sh]]) }}


**Linux:**

{{ highlight("sh", [[curl -fsSL https://raw.githubusercontent.com/vanyle/ASG/refs/heads/master/install/get_asg_linux.sh | sh]])}}

<br>

and start blogging!