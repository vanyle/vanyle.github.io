{%
add_pic = true
setvar("layout",theme .. ".html")
page_title = "Bypass the borrow checker in Rust"
%}

# Bypass the borrow checker in Rust

*With this one weird trick, resolve mutable borrowing errors. Rustaceans hate it!*

I want to show a "trick" I found that allows you to refactor your Rust involving structs containing non-clonable objects
with ease. I'm not claiming to solve every issue you might have with mutable borrows, but it is something handy to have in your toolbelt of Rust patterns.

## The problem

Imagine you have this struct where A does not implement copy.

```rust
struct MyStruct{
    field: RefCell<A>
}
```

You want to give a clean interface to your struct, without exposing the fact that you are using a `RefCell` internally and to avoid the need for your API users to call `borrow_mut` which can
be very verbose.

Ideally, you want to write this:

```rust
impl MyStruct{
    pub fn access_field(&self) -> &mut A {
        todo!("How can I implement this 🤔");
    }
}
```

Well, you can think for a long time dear thinking emoji, because there is no safe we do to it without copying or cloning A.

Your options:

## 👎 Using RefMut

First, if your function signature was:
```rust
pub fn access_field<'a>(&'a self) -> RefMut<'a, A>
```

You could just call `borrow_mut` and that would work, but you are exposing the internals of your struct (which means that changes to the internals of your library break the code of your users)

## 👎 Using mut self

You could also have:
```rust
pub fn access_field(&mut self) -> &mut A{
    self.field.get_mut()
}
```

But this defeats the point of having a RefCell.

## ✨ My solution

Instead of returning a `&mut`, you can provide a callback that gets the reference and is able to manipulate it:

```rust
impl MyStruct {
    pub fn access_field<F, R>(&self, f: F) -> R
    where
        F: FnOnce(&mut A) -> R,
    {
        f(&mut self.field.borrow_mut())
    }
}
```

How, you can call your `access_field` like so:

```rust
let result = my_struct.access_field(|&mut field|{
    compute_something(field)
});
```

This pattern allows you to build function that can "provide" types without returning them and is useful in a lot of cases.

Let's say your program is able to draw text with a "default font". This font is a large object that you want to be able to access from anywhere in your code.
You don't want to copy it to avoid the performance penalty.

You can thus use a function like the following:

```rust
pub fn use_default_font<F, R>(f: F) -> R
 where F: FnOnce(&mut FontRenderingData) -> R,
{
    lazy_static! {
        // You can use a "thread_local!" block to avoid the cost of the Mutex if you know your program is single-threaded.
        static ref DEFAULT_FONT: Mutex<Option<FontRenderingData>> = Mutex::new(None);
    }
    let mut default_font = DEFAULT_FONT
        .lock()
        .expect("Failed to acquire lock on the default font.");

    if let Some(default_font) = default_font.as_mut() {
        return f(default_font);
    }
    let mut font = make_font_using_expensive_operations();
    let result = f(&mut font);
    *default_font = Some(font);
    result
}
```

which you can use like this:

```rust
let size_of_text  = use_default_font(&gl, |font_data| {
    font_data.measure_text("Hello");
});
```

We didn't even need a `Rc` or another pointer type and our font is never copied. The lambda we are passing allows us to give a scope to the mutable reference and makes everything safe.

In general, whenever you need to write a function that takes `&self` and returns something with a lifetime somewhat unrelated to `&self`, you can use this technique, which is surprisingly often the case, especially with code containing `Mutex` or `Refcell`.

The other advantage of this pattern is that to exposes an `async` way to interact with your objects.

Consider:

```rust
fn read_file(path: &Path) -> &[u8]
```

First, there is no way to produce a reference to the file content using the lifetime of the `path`, but you don't necessarily want to give back ownership to the caller, especially if you
are working with a `C` API to read the file which might use a different allocator than the rest of your code.
Second, reading from a file can take time and you don't want to block the thread while doing so.

Now consider:

```rust
// Async
fn read_file<F>(path: &Path, f: F) where F: FnOnce(&[u8])

// Sync
fn read_file<F, R>(path: &Path, f: F): R where F: FnOnce(&[u8]) -> R {
    let file = setup_file_read();
    let result = f(&file.buffer);
    // This syntax gives us the flexibility to run cleanup code after `f`, 
    // to close our file for example, without needing a custom destructor type.
    cleanup_file_access(file);
    result
}
```

Now, `read_file` can be `async`, which is super useful if your program targets wasm. Moreover, the caller does not get ownership of the resulting slice, but is still free to copy it if needed or do something else
like computing the file size.
