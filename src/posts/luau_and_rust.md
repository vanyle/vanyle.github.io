{%
add_pic = true
setvar("layout",theme .. ".html")
page_title = "The unreasonable effictiveness of Luau"
%}

# The unreasonable effectiveness of Luau

*Seals and Moons go well together*

For the past ~years~ few months, I've been working on a game engine. After several iteration on the best technology stack, I've
stumbled upon a marvel: 

Writing the core of the project in Rust and adding bits of Luau for scripting.

[Luau](https://luau.org/) is a variant of Lua with types.

The 2 languages compliment each other very well and the library to embed Luau into Rust, [mlua](https://github.com/mlua-rs/mlua) is a joy to work with.

Let's see the characteristics of each language:

| Pros of Rust | Cons of Rust |
| ------------ | ------------ |
| Execution speed | Slow iteration speed |
| Rich library ecosystem | No easy hot-reloading |
| Cross-platform | Creepy crab mascot 🦀 |

| Pros of Luau | Cons of Luau |
|  ------------ | ------------ |
| Fast iteration speed | Slow execution speed |
| Easy hot-reloading | No library ecosystem outside Roblox |
| Needs embedding | Awesome seal mascot 🦭  |

Essentially, every flaw of one language is compensated by the other.
Moreover, both have strong type systems, and communication between the 2 is super simple:

```rust
// Let's define a function in Rust that will be called from luau:
// Let's assume we have a 'lua' variable of type mlua::Lua
lua.globals().set("rs_add", lua.create_function(move |_, (a,b): (i32, i32)|{
    Ok(a + b)
}).unwrap();
```

Now, inside Luau, we can call our rust code:

```rust
print(rs_add(1,2))
```

We can even define our own type, for example, I defined [a `Fastlist` type](https://github.com/vanyle/vectarine/blob/5f0a12a6833379d0b698541dd876cee57897ce23/runtime/src/lua_env/lua_fastlist.rs#L114) which works a bit like numpy arrays to make super fast operation on lists, but with all the methods that exists on Lua tables, like `#list` to get the length.

## Dealing with imports

One tricky thing are imports. With the current Luau extension for VSCode, I'd get an error like `rs_add` is not defined.

To work around it, I first created a `.luaurc` file with the following content:

```json
{
	"languageMode": "strict",
	"lintErrors": false,
	"lint": {
		"FunctionUnused": false
	},
	"aliases": {
		"vectarine": "luau-api"
	}
}
```

This does not register global variables, but it makes it so that the `require` function from Luau produces objects with the correct type:

```luau

-- myFile has the type of what is returned by ./luau-api/myFile.luau
-- However, this won't work by itself at runtime
local myFile = require("@vectarine/myFile")
myFile.rs_add(1,2) -- We can call functions defined in myFile
```

In the rust code, I call the `register_module` function so that it returns the proper object when called instead of the default Luau resolution to make everything work!

```rust
let lua_table = lua.create_table().unwrap();
lua_table.set("rs_add", lua.create_function(move |_, (a,b): (i32, i32)|{
    Ok(a + b)
}).unwrap()
lua.register_module("@vectarine/myFile", lua_table);
```

I also [overrided the `require` function](https://github.com/vanyle/vectarine/blob/5f0a12a6833379d0b698541dd876cee57897ce23/runtime/src/lua_env.rs#L156) to provide better error messages and custom module path resolution.

## Hot reloading

Hot reloading is the biggest benefit from Luau scripting: you change some code, save it and you see the result instantly.
Adding hot reloading to Luau is super simple with the [notify_debouncer_full](https://docs.rs/notify-debouncer-full/latest/notify_debouncer_full/) crate.

When you receive an event that a file was changed, you reexecute it. I usually do so with a channel to allow multithreading:

```rust
let (debounce_event_sender, mut debounce_receiver) = broadcast::channel(16);
let cloned_sender = debounce_event_sender.clone();

// The debouncer needs to stay alive for the whole program.
// When it gets dropped, you won't receive any events from the sender.
let mut debouncer = new_debouncer(
    Duration::from_millis(100),
    None,
    move |result: DebounceEventResult| {
        match result {
            Ok(events) => events.iter().for_each(|event| {
                let _ = debounce_event_sender.send(event.clone());
            }),
            Err(errors) => errors.iter().for_each(|error| println!("{error:?}")),
        }
    },
)
.unwrap();

debouncer.watch(PathBuf::from("./lua_scripts"), RecursiveMode::Recursive).unwrap();

let lua = Lua::new();
// Register custom lua functions from Rust here
// ...

// You can also run scripts on startup

// Now, the hot-reload loop:
// You can loop in another thread if you need to.
loop {
    let event = debounce_receiver.recv().await;
    let Ok(event) = event else {
        break;
    };
    for path in &event.paths {
        match event.kind {
            notify::EventKind::Create(_) | notify::EventKind::Modify(_) => {
                if path.exists() {
                    // You can add a check to only reload files with a certain extension
                    // For example: if path.extension() == Some("luau") {
                    let lua_chunk = lua.load(fs::read(path).unwrap());
                    let result = lua_chunk
                        .set_name("@".to_owned() + path.to_str().unwrap())
                        .exec();
                    println!("{:?}", result);
                }
            }
            _ => {}
        }
    }
}

```

## Conclusion

Luau and Rust go very well together and whenever I need to add scripting capabilities to a project, I reach for these two. They allow for super fast iteration speed while building robust software.
If you have a rust project laying around, consider adding Luau scripting to it, it is super fun.
