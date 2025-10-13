{%
setvar("layout",theme .. ".html")
add_pic = true
%}
# What's the deal with JavaScript Modules?
*What do AMD, CommonJS or ESM even mean?*

I think a lot of frontend devs have struggled with these kind of error at least once in their lives:

```
Uncaught SyntaxError: Cannot use import statement outside a module
```

Or maybe:

```
Uncaught ReferenceError: require is not defined
```

At least, I did! To understand these errors, one needs to understand JavaScript modules and their history.

If you want a quick way to fix these errors and don't care about the root cause, jump to the last section.

> ℹ️ I'll use JavaScript and ECMAScript interchangeable in this article, JavaScript rolls of the tongue nicely.


## What are modules and why do we need them?

Modules are ways to split JavaScript code into multiple files.

> ❓ Why would you want to split code into multiple files?

- It enables code reuse across projects
- Instead of having one big file to load with all your functionality, the browser can load scripts as needed, which ensures a smoother experience and faster page loads.
- Having multiple small files improve code readability and avoid the scrolling problem aka having to scroll for hundred and hundreds of lines to find a function

For a long time, browsers did not have a native way to load a script from another script. The canonical way was to create a `script` object, set its `src` attribute and wait for it to load like so:

```js
var s = document.createElement("script");
s.src = "./my-other-file.js";
s.onload = function(){
    // my other file is loaded, I can use it!
}
document.head.appendChild(s); // adding s to the DOM starts the loading of the script
```

This is the method recommended in [this 2009 answer on Stack Overflow](https://stackoverflow.com/a/950098/13755243). I'll call this *script loading*

You could also put all your scripts directly in your HTML file inside the `<head>` tag.
However, both these methods have multiple drawbacks:

1. They do not support other JS environments like NodeJS where `window` and `document` do not exist and there are no HTML files.
2. Importing JS from other JS files is a bit verbose.
3. It is hard to tell where a function was defined as every top-level function and variable is global, which makes readability and maintainability a nightmare.
4. Cyclic imports lead to infinite loops and the browser hangs.
5. Files pollute the global namespace and can override each other
6. This technique is incompatible with TypeScript, where is no way for the TypeScript compiler to know what function are available and what are their types. You could
still use TypeScript and load files this way but it would not be ergonomic and you'd lose a lot of the benefits of the type system

Modules are a way to automate the previous process using various tools in order to make large scale JavaScript/TypeScript project practical.

## An (incomplete) list of JS module types

*In chronological order*

<br>

### CommonJS

When NodeJS was created in 2009, there needed to be a way to load script file.

> ℹ️ [NodeJS](https://nodejs.org/) is a runtime which executes JavaScript outside of a browser

At the time, only script loading existed, which is very browser specific. NodeJS has no concept of HTML or Document Object Model (DOM).
To solve the issue, the *CommonJS* module system was invented, or *CJS* for short.

The idea is that every file has a `module.exports` object where exports are set. Files can use the `require` function to load another file and get the content of its `module.exports`.

```js
// file-a.js
function greet(name){
    return "Hello " + name;
}
module.exports.greet = greet;
// You could also use: exports.greet = greet;
// exports is an alias for module.exports
```

```js
// main.js
var fileA = require("file-a.js");
console.log(fileA.greet("John")); // prints Hello John
```

<br>

### AMD

Asynchronous module definition, or AMD was created in response to CommonJS.
While CommonJS is convenient and solves the issues highlighted above, it has one flaw which prevents its use in the browser: `require` is a synchronous function.
This means that when you call `var fileA = require("file-a.js")`, execution of `main.js` stops, `file-a.js` is read and executed. The result is put inside `fileA`.

<br>

This works fine on a server where you can quickly read a file. But on a browser, reading `file-a.js` is a network call and could take a very long time, especially on poor connections.
As JavaScript is single-threaded (excluding Web Workers!), this would freeze the UI during the call and look very bad.

To solve these issues, AMD was created. It uses the following syntax:

```js
// file-a.js
define([ /* optional dependencies of file-a.js can go here */ ], function() {
    function greet(name){
        return "Hello " + name;
    }
    return {
        greet: greet
    };
});
```

```js
// main.js
require(["fileA"], function(fileA){
    console.log(fileA.greet("John"));
});
```

`require` and `define` are not native JavaScript functions for a browser. You need a runtime library to define them. Such a library is called a "Module Loader".
The popular AMD loaders include [RequireJS](https://requirejs.org/) and [Dojo](https://dojotoolkit.org/).

Internally, these libraries use the same `script` trick from the beginning of the article, but using a more structured approach so that you can easily see where a function was defined and how modules depend on one another.

<br>

The RequireJS implementation is essentially the specification of AMD as it is the most used loader. It has a lot of extra features:

You can use comments to indicate dependencies:

When using TypeScript, this will be added to the array of the first argument of `define`
```ts
/// <amd-dependency path="./file-a.js" />
```

You can load non-JS files using [custom RequireJS plugins](https://requirejs.org/docs/plugins.html):

```js
require(["text!hello.html"], function(helloFile){
    console.log(helloFile);
});
```

These is used to load CSS or text dynamically.

<br>

### UMD

TL;DR, UMD = AMD + CommonJS

UMD stands for Universal Module Definition. As CommonJS and AMD are mutually incompatible, UMD aims to be a format which works both on the browser and in NodeJS.
It is mainly a way to export files, not to import them and is commonly used by old libraries that try to support both Node and the browser.

```js
// UMD libraries use this common header.
// We assume that this file has a dependency named 'b'.
(function (root, factory) {
    if (typeof define === 'function' && define.amd) {
        // We are in an AMD environment
        define(['b'], factory);
    } else if (typeof module === 'object' && module.exports) {
        // We are running inside NodeJS
        module.exports = factory(require('b'));
    } else {
        // We are in a browser, but there is no AMD loader.
        root.returnExports = factory(root.b);
    }
// We try to find the name of the global variable. In node, this is `global` and in the browser, it is called `window`.
// In most environment, `globalThis` and `this` is an aliases for the global object.
}(typeof globalThis !== 'undefined' ? globalThis : this, function (b) {
    // This is the 'factory' function, this is were the library specific code lives.
    function greet(name){
        return "Hello " + name;
    }
    return {
        greet: greet
    };
}));
```

While UMD works both in Node and Browser, the syntax for its header is very verbose. Usually, this header is generated a build system or bundler.

<br>

### ESM

As time went on, it became clear that JavaScript needed a native, cross-environment way to load code from other files.
This is where ESM comes in. ESM means ECMAScript Module and is meant to be the modern way to import code.

The syntax is simple and concise:

```js
// file-a.js
export function greet(name){
    return "Hello " + name;
}
```

```js
// main.js
import { greet } from "./file-a.js";

console.log(greet("John"));
```

As ESM appeared in 2015 there needed a way to be compatible with the old ways to perform imports. `export` and `import` became reserved keywords which can
break existing code.

To solve this, Javascript files can be interpreted in two ways. As a module or as an inline-script. To indicate to the browser that a file is a module, it needs to be loaded using:
`<script src="path-to-file.js" type="module"></script>`. Scripts imported from a module using `import` are assumed to be modules.

In NodeJS, to activate module modes, you can add `"type": "module"` in your package.json:

```json
{
    "name": "your-package-name",
    "type": "module",
    // ... other properties ...
    "dependencies": {
        // ...
    }
}
```

You can also rename your file from `.js` to `.mjs` to indicate to Node that this is a module, which is convenient for scripts that do not have an associated `package.json` file.

**Quick info:**

Sometimes, you want to import a file using an absolute path instead of a relative one. To do so, you need to specify the base of the imports. You can do so using an `importmap` script:

```html
<!-- The content of importmap needs to be valid JSON and cannot have comments -->
<script type="importmap">
{
    "app/": "https://url-to-my.app/folder/"
}
</script>
```

Then, you can do `import { someFunction } from "app/my-script.js"` !

## Modules, Bundlers and Minification

As we saw previously, there are a lot of ways to define modules in JavaScript projects. The JS library you want to use might not necessarily be compatible with your
module system. This is where bundlers come into the picture.

For the purpose of this article, a JavaScript bundler is a tool that takes multiple JavaScript source files (it can also consume CSS and other resources!) and modifies them, put them together or splits them to produce optimized code. This optimized output is generally what gets sent to browsers or is executed by Node.

As bundlers have many purposes, they can be split into smaller tools/plugins that each has a specific purpose:

- Converting between multiple module types
- Grouping files together
- Rewriting paths in import statements
- Obfuscating code
- Compressing PNGs and other assets
- ...

There are many bundlers and bundler plugins which have more or less features.

The interesting thing about them is their ability to turn some files from one module type to another one, allowing codebases using AMD and CommonJS to work together for example.

Some of the most popular ones include: [Browserify](https://browserify.org/), [Babel](https://babeljs.io/), [`r.js`](https://github.com/requirejs/r.js), 
[Webpack](https://webpack.js.org/), ‚[Rollup](https://rollupjs.org/) (and [Vite](https://vite.dev/)), [Rsbuild](https://rsbuild.rs/).

Let's see what each of these tools does!

### Browserify

Browserify (as its name implies 🧙) makes CommonJS code able to run in a browser.
It takes a many JS files as input with the CommonJS import style and bundles them into one large file.

This makes CommonJS import available synchronously because when everything is in the same file, there is no loading to do!

Its main drawbacks are that it generates large bundles which take a long time to load in browsers. Moreover, it does not support other module types.
It also lacks customization and has few settings. It is poorly maintained, and I would not recommend using it currently, but it is still used in some old projects.

### Babel

Babel is a JavaScript compiler. It can convert modern JavaScript code into older versions of JavaScript to support old browsers. It has a rich plugin ecosystem which
allows it to do a lot of things, including converting between module types. For example, the `@babel/plugin-transform-modules-amd` plugin converts ESM code into AMD.

Babel plugins are easy to write. Babel provides the JavaScript AST that you can freely modify. The [Babel Plugin Handbook](https://github.com/kentcdodds/babel-plugin-handbook) is a good
introduction to babel plugins.

The main drawbacks of Babel are that it is slow and does not perform bundling. You generally need to use it with another tool like Webpack or Rollup.

### r.js

r.js is the official RequireJS optimizer. It takes multiple AMD files and bundles them into one file. It is a very old tool and is not maintained anymore. I would not recommend using it.
It does not recognize recent JavaScript syntax and does not support other module types. You might be using it if you have an old project using RequireJS.

It was however an excellent tool for its time as it could both bundle and optimize code. It lacks customization, plugins and is not very flexible. It also requires you to have Java installed.

### Webpack

Webpack is a very popular bundler. It can take multiple files using different module types and bundle them into one or more files.
It has a rich plugin ecosystem and is very customizable. It is used by many large projects and companies. It is a fine choice for a new project, but builds can be a bit slow.
It has a lot of features and supports code splitting, tree shaking, loading non-JS assets and more. All-in-all, it is a solid, mature tool that will stand the test of time.

### Rollup and Vite

Rollup is a modern bundler. Like webpack, it supports all module types and has a rich plugin ecosystem.
It is generally faster than Webpack and produces smaller bundles.

You generally use Rollup together with Vite. Vite is a build tool which uses Rollup under the hood for production builds.
It is very fast and has a great developer experience. Vite is my recommended choice for new TypeScript and JavaScript projects.

The main drawback of Vite is that is needs ESM modules to work. If you are using old libraries which is CommonJS or AMD, you need a conversion step before using Vite.
Don't worry, there are many plugins for that!
For example, [`vite-plugin-commonjs`](https://github.com/vite-plugin/vite-plugin-commonjs) can convert CommonJS to ESM for you.
You can also [use Babel as a Vite plugin](https://github.com/owlsdepartment/vite-plugin-babel) to perform this conversion.

You can also use [Rollup plugins directly](https://github.com/piuccio/rollup-plugin-amd) to perform these conversions.

### Rsbuild

Rsbuild is a lesser known bundler. It is less mature than other tools, but is very fast and has a great developer experience. While I would not recommend it for
production currently (in 2025), it is worth keeping an eye on it as it is looks promising. It is Webpack compatible, so if you are using Webpack, you can try to switch
to Rsbuild and see if you see faster compilation times.

## Dynamic imports

An import is dynamic when the imported module is not known at compile time. For example:

```js
var moduleName = getModuleName();
var result = require(moduleName);
```

All module types support dynamic imports, but the syntax and semantics vary. For example, in ESM, the following syntax is used:

```js
let module = await import(moduleName);
```

Dynamic imports are a challenge for bundlers as they cannot know at compile time what module will be imported, so they cannot include it in the bundle.

To make the job of bundlers easier, it is recommended to use static imports as much as possible.
For example, instead of doing:

```js

function getModuleName(){
    if(someCondition){
        return "./module-a.js";
    } else {
        return "./module-b.js";
    }
}

let moduleName = getModuleName();
let module = await import(moduleName);
```

You can do:

```js
function getModuleLoader(){
    if(someCondition){
        return () => import("./module-a.js");
    } else {
        return () => import("./module-b.js");
    }
}
let moduleLoader = getModuleLoader();
let module = await moduleLoader();
```

## Summary table

<br>

<style>
    td{
        text-align: center;
    }
</style>

| Module Name      | Natively supported by NodeJS | Supported by the browser | Allows cycles | Allows dynamic imports | Compatible with Vite   | Can be async |
| ---------------- | -------------------          | ------------------------ | ------------- | ---------------------- | --------------------   | ------------ |
| AMD              | ❌                           | Needs require.js         | ❌            | ✅                     |  Needs a plugin        |     ✅       |
| UMD              | ✅                           | Needs require.js         | ❌            | ✅                     |  Needs a plugin        |     ✅       |
| CJS              | ✅                           | Requires browserify      | ✅            | Depends on environment |  Needs a plugin        |     ❌       |
| ESM              | Stable since v14.0.0.        | Yes, since ES2015.       | ✅            | Depends on your bundler|  ✅                    |     ✅       |

> ℹ️ As of writing this, in 2025, the [latest LTS (long-term support) NodeJS version](https://nodejs.org/en/about/previous-releases) is v24.
> The latest ECMAScript specification is [ES2024, or ES15](https://tc39.es/ecma262/2024/), but ES2026 is in the works.
> I consider that [every feature introduced in ES2020](https://caniuse.com/?feats=mdn-javascript_operators_optional_chaining%2Cmdn-javascript_operators_nullish_coalescing%2Cmdn-javascript_builtins_globalthis%2Ces6-module-dynamic-import%2Cbigint%2Cmdn-javascript_builtins_promise_allsettled%2Cmdn-javascript_builtins_string_matchall%2Cmdn-javascript_statements_export_namespace%2Cmdn-javascript_operators_import_meta) and before is very widely supported as most browser auto-update regularly.

TL;DR: Use ESM.

## Interaction with `node_modules` and external libraries

The goal of modules is not only to split your code into multiple files, but also to be able to use code written by other people.

There are 2 types of people, the ones that use a bundler and the ones that don't.

Libraries needs to support both types of users. Let's take JQuery as an example.

> ❓ Why JQuery?
>
> JQuery is an old library with a lot of users which all have very different needs.
> It is also very popular and well-known.

If you don't use a bundler you want to just load JQuery using a `<script>` tag and use it directly in your code:

```html
<script src="https://url.providing.jquery.com/path/to/jquery.min.js"></script>
<script>
    // $ is defined here
    $(document).ready(function(){
        // ...
    });
</script>
```

If you are using a bundler, you probably also want correct types for JQuery:

```ts
import $ from "jquery";
// $ is properly typed here
$(document).ready(function(){
    // ...    
});
```

What happens is that JQuery provides multiple builds of its library.

For people that don't use a bundler, JQuery bundles its own code into one file which defines global variables (Internally, The JQuery project seems to use rollup with [swc](https://swc.rs/)).

For people that use a bundler, JQuery can provide its source code as-is. This code is already in ESM format and can be imported directly.

It is considered a best practice for libraries to not bundle or minify their code directly and let end users do it. This way, users can choose their own bundler and minification settings.
It allows for more optimization as the bundler can perform tree-shaking and remove unused code.

When a library is installed with `npm install`, its source code is put inside the `node_modules` folder.

Most bundlers and tools know to look there to resolve imports.
For example, when you do `import $ from "jquery"`, the bundler will look for a `jquery` folder inside `node_modules` and look for the `main` or `module` field in its `package.json` file to find the entry point of the library.

## Recommendations and takeaways

When starting a new project, use ESM for everything. Use Vite as a bundler if you can. It is fast, modern, has a lot of users including large companies and a great developer experience.

<br>

Use `.cjs` or `.mjs` as a file extension for your scripts, configurations, and other JS files that are a bit *outside* of your project.
This is a hint for most tools to treat these files as CommonJS or ESM.

## Common errors caused by modules and how to fix them

### Cannot use import statement outside a module

This means that you are inside a non-ESM context but are trying to use the "import { ... } from ..." syntax.
There are multiple possible fixes depending on your situation:

- If your code is loaded by a `<script>` tag, add `<script type="module" src="..."></script>` to the tag to signal to the browser that
this is a module.
- If the error comes from VS Code, add `"type": "module"` at the top of your `package.json`
- If you don't want to use ESM modules in your project, but just in this specific file, rename it from `.js` to `.mjs` (or from `.ts` to `.mts`) to indicate
to VS Code or your runtime that this file is a module explicitly.

<br>

### Uncaught ReferenceError: `require` is not defined.

The error can also be `define` is not defined, which is a bit funny to read.

This means that the `require` or the `define` functions do not exist. Normally, these functions are provided by your module loader like `require.js`.
Once again, depending on your situation, the root cause can vary.

If you are working on a modern project with ES Modules, this means that you used an incorrect module target, check your `tsconfig.json` file, specifically, the "module" option.
It should be "nodenext" for server projects (which use NodeJS) and "esnext" for browser project, especially if you have a bundler. Your probably have it set to `"amd"` or `"commonjs"`.

It might also mean that a step in your build system failed or misbehaved and calls to `require` did not get properly converted to what they should look like.

If you are working on an older project which uses `AMD` or `UMD`, it means that `requirejs` was not loaded, or was loaded too late. Check your HTML and make sure that requirejs is the first script you are loading and that your initial script is loaded after `requirejs` is ready.

## Sources

- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules
- https://rslib.rs/guide/basic/output-format
- https://nodejs.org/api/modules.html
- https://nodejs.org/api/esm.html
- https://www.youtube.com/watch?v=W5CXzo4TZVU
- https://www.typescriptlang.org/docs/handbook/modules/theory.html#the-module-output-format
- https://requirejs.org/
