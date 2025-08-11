{%
add_pic = true
setvar("layout",theme .. ".html")
%}

# Emscripten
*Writing cross-platform code with Nim, C and Emscripten.*

I was working on a game engine called [Vectarine](http://vectarine.vanyle.netlib.re/) that I have not yet released.

This is a game engine designed to win game jams on [itch.io](https://itch.io), a website to host games, game jams and game assets.

There are a lot of games on itch. To stand out, you need to make your game pretty of course, but you also need to make it easy to play.
People don't want to download and unzip a game every time they want to play something, they want to try it in their browser (and maybe
download it later if it is very good and the desktop version has more features).

Thus, I needed to port my game engine, written in [Nim](https://nim-lang.org/) (a language that compiles to C) to the web.

I already knew about [Emscripten](https://emscripten.org/) which provides a standard C library and compiling toolchain that targets the web.

The engine has the following dependencies: GLFW (for managing windows), OpenGL (for drawing to the screen), Lua JIT for scripting, OpenAL
for audio and uses threads. Moreover, we read and write data from the filesystem to save progress. These are a bit low-level, but I wanted
to learn to use them instead of relying on higher level libraries like SDL which is also why I'm making an engine and not a game directly.

Let's see how much work there was to do:

## GLFW

GLFW is [already available](https://emscripten.org/docs/compiling/Contrib-Ports.html) with emscripten, I just needed to use a compilation flag `-sUSE_GLFW=3`


## OpenGL

OpenGL [is also available](https://emscripten.org/docs/porting/multimedia_and_graphics/OpenGL-support.html), but not all functions and GLSL shader construct are available.
I needed to add a preprocessor to my shader parser that emulates some shader constructs on the Web (and the `#version` directive)
I dropped support for geometry shaders as they are slow anyway.

## Audio and Sound

OpenAL [is available](https://emscripten.org/docs/porting/Audio.html)! Nothing do to, it worked out of the box! 

## Scripting

Scripting was harder. Vectarine uses the [Lua language](https://www.lua.org/) for scripting. For executing Lua, we use [LuaJIT](https://luajit.org/).
LuaJIT is a just-in-time compiler, it reads the code, compiles it on the fly to CPU instructions and executes them. These CPU instructions depend on the CPU
type used. On MacOSX, we can generate ARM instructions and on Windows, Intel instructions, but on the web, the instructions are wasm, a virtual instruction set
that is interpreted by the browser. LuaJIT does not support generating this kind of instructions.

So I decided to use regular Lua for the web. This is slower as the language is fully interpreted, but it's good enough. Because Nim supports arbitrary compile-time
execution, I wrote a tiny build-system in Nim that compiles Lua when the `emscripten` or the `noJit` flag is provided and links Lua against Nim.

Lua is small and only consist of about 30 files. So I store their path in an array and loop over it to compile everything.

Lua 5.1 and LuaJIT behave exactly the same in my tests, so I can write the same scripts and have the same behavior on the web and the desktop!

## Threads

I had a lot of issues with threading on the web. This is because I did not read [the documentation](https://emscripten.org/docs/porting/pthreads.html) properly.
To have threads, you need to compile with `-pthreads` and pass the right HTTP headers with serving the content. On itch.io, there is a toggle to
pass these headers with publishing your game.

Everything should thus work.

## Filesystem access

On the web, there is no real filesystem. [Emscripten tries to emulate it](https://emscripten.org/docs/porting/files/file_systems_overview.html) in a weird way that is a sync/async mess.

Functions like `fopen` and `fread` and `fwrite` will work but I want to persist changes between page reloads, so I cannot use the default filesystem backend (MemFS).
I decided to use the IDBFS backend which is the only one currently available to persist data in the browser.

However, I need to call `FS.syncfs()` from JavaScript to sync my changes after any edits, so I added a C/JavaScript bridge to do just that and I call `syncfs` after every write.

This allowed me to save and load data but I could not use this for assets. What I did is use the `slurp` function of Nim to read files at compile-time and include them directly inside the executable. This is enabled with the `-d:v3dEmbed` flag.
This allows vectarine to provide only one file when distributing the game for the desktop and to easily have access to all the assets the game needs on the Web.

## Other concerns

There were a few other smaller issues I encountered that were easily fixed.

First, opening links. When a player clicks on the credits, I want to open a tab in his browser to show them a page about me. In C, I can call `ShellExecuteA` or `xdg-open` depending on the platform. On the web, I wrote a JavaScript bridge and once in JavaScript, opening a tab is trivial.

Second, getting an accurate time. For simulating physics accurately, I need to get the time with as much precision as possible. Thankfully emscripten already provides a function for that, `emscripten_get_now`, so I used it.

Finally, I was ready to compile!

I used the following command for reference (excerpt from a powershell script):

```bash
$shell = $PSScriptRoot + "/wasm_shell.html"
$output = $PSScriptRoot + "/../builds/index.html"
$outputDir = $PSScriptRoot + "/../builds"
$nimcache = $PSScriptRoot + "/tmp"

$releaseDependentOptions = ""

if($release){
    $releaseDependentOptions = "--opt:size -d:release -d:v3dNoDebug"
}

$passL = "-o " + $output
$passL = $passL + " --shell-file " + $shell
$passL = $passL + " -fsanitize=undefined -lidbfs.js -sALLOW_MEMORY_GROWTH -sUSE_WEBGL2=1 "
$passL = $passL + " -sMAX_WEBGL_VERSION=2 -sMIN_WEBGL_VERSION=2 -sPTHREAD_POOL_SIZE=4 -sPTHREAD_POOL_SIZE_STRICT=0 "
$passL = $passL + " -L. --js-library web_tools/vectarine_lib.js "

nim c --nimcache:$nimcache --os:linux --cc:clang `
    --clang.exe:emcc.bat --clang.linkerexe:emcc.bat --clang.cpp.exe:em++.bat --clang.cpp.linkerexe:em++.bat `
    --listCmd --exceptions:goto --define:noSignalHandler --define:useMalloc --threads:on -d:v3dEmbed `
    --cpu:wasm32 $releaseDependentOptions -d:emscripten `
    --passC="-fsanitize=undefined -pthread -fno-exceptions -sSHARED_MEMORY -sALLOW_MEMORY_GROWTH " `
    --passL=$passL `
    $args
```

And finally, I got a playable game with audio, assets and scripting working!

You can find it here, it is a pretty hard puzzle game about Wang tiles: [https://vanyle0.itch.io/domino-demon](https://vanyle0.itch.io/domino-demon)

I plan to release more games on itch now that the engine has all the features I'd expect!
Even though the TODO list is still growing as I'm getting more ideas of things to implement every day ^^
