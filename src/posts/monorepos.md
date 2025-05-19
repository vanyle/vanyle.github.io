# Monorepos for frontend, are they worth it?
*Short answer, it depends, probably not*

Let's see how do pnpm workspaces work, how to use them and are they worth it.

## What are monorepos?

Using monorepo is having one big git repository that stores all your (related) frontend projects in one place.
So if you have an app that contains some webviews and a website, you put everything in the same repository.

There are different ways to do monorepo. You could also include your backend code (and your whole code base) into one
repository or do a frontend/backend split.

I'll mainly focus on frontend aspects of monorepos but what I'm saying is applicable no matter the scope of your repository.

## What are the benefits?

You can reuse code and components between your projects without the need for versioning as changes across projects are atomic git commits.

The build and testing process is centralized. Tooling is standardized across the teams.

You can easily switch between projects.

Starting a new project with all the right linting and typing rules is easier.

## What are the drawbacks?

Testing and building is more complex. You need more caching to have good CI performance

On **very** large teams, Git performance can degrade as repository size increases.

Monorepos can be tricky to setup at first.

## Making them work with other tooling

The JavaScript ecosystem, mainly `yarn` and `pnpm` already support workspaces which allow you to split your code into multiple packages (and multiple `package.json`).
The go-to tool for managing monorepos is `turbo` which is a utility to schedule tasks located in multiple `package.json` files in your repository

## So, how can I setup a monorepo?

I'll assume you have `pnpm` installed.

I'll present you with the monorepo template I use which has worked well for me.
You can customize it how you'd like as it is flexible and powerful.

This section is very dense and contains a lot of config. I won't go into detail for every package I use, but I might do individual articles going into more details for specific dependencies.

Your directory structure should to look like this:

```
|- node_modules
|- package.json
|- turbo.json
|- .node-version
|- .gitignore
|- pnpm-workspace.yaml
|- pnpm-lock.yaml
|- apps
    |- app1
        |- node_modules
        |- package.json
        |- tsconfig.json
        |- src
        |- dist
    |- app2
        |- node_modules
        |- src
        |- tsconfig.json
        |- package.json
        |- dist
|- packages
    |- tsconfig
        |- package.json
        |- tsconfig.base.json
    |- shared
        |- node_modules
        |- tsconfig.json
        |- lib
        |- dist
        |- package.json
        |- build.mts
    |- ui
        |- node_modules
        |- lib
        |- dist
        |- tsconfig.json
        |- package.json
        |- build.mts
```

The file listed are the minimum you'll need to have a nice monorepo working with a shared typescript configuration. You can also share `tailwind` and `eslint` configurations using the same concepts we'll see. 

Let's explain what each file does at its purpose.
Let's start with the files are probably already familiar with if you've worked on frontend projects before:

- `node_modules`. This is where the packages for your repo are installed. This folder is gitignored and should be excluded from linters.
- `.gitignore`: This is a list of patterns which lists files that should not we commited to Git. It includes `node_modules`, `dist`, `.turbo`
- `src`, `lib`: These are the folders where you write your code. In the `app1` and `app2` folder, you might also have an `index.html` file and a `public` folder which are static assets that your project needs.
- `.node-version`: A file containing the version of node used by your project. Its content can be simply `22.14.0` for example. If you use a good node version like [`fnm`](https://github.com/Schniz/fnm) or `nvm`, it will automatically switch to that version so that you get reproducible behavior between team members.

### `package.json` and `pnpm-lock.yaml`

The `package.json` file contains information about your projects, its dependencies and commands.
The one at the root will most likely look like this:

```json
{
    "name": "project-name",
    "version": "0.1.0",
    "description": "description or just left empty",
    "type": "module",
    "scripts": {
        "dev": "turbo watch dev --concurrency 20",
        "build": "turbo run build",
        "lint": "turbo run lint",
        "type-check": "turbo run type-check"
    },
    "dependencies": {
        /* Your code's run-time dependencies, I'm putting react and date-fns here as an example */
        "react": "catalog:",
        "react-dom": "catalog:",
        "date-fns": "catalog:",
    },
    "devDependencies": {
        /* Your code's build-time dependencies, linter and other tools */
        "turbo": "catalog:",
        "typescript": "catalog:",
        "vite": "catalog:",
        "esbuild": "catalog:"

        /* You'll probably want a lot more devDependencies like '@types/react' but I'm keeping it short for readability */
    },
    /* You can pin a pnpm version too! */
    "packageManager": "pnpm@10.10.0",
    "engines": {
        /* This is redundant with the .node-version file but it is an option if you want */
        "node": ">=18.19.1"
    }
}
```

The `pnpm-lock.yml` will get automatically generated by pnpm and ensures that the same versions of dependencies specified are in the `package.json` are installed in a team. For example, if you declare in your `package.json` that `"foobar": "^0.1.0"`, the version `"0.1.2"` or `"0.1.40"` could be installed.
You also need consistency for dependencies of dependencies.

Then, in every subpackage, you can define the individual `dev`, `build` and `lint` tasks for your project. 
For example, the `package.json` in `app1` might look like this:

```json
{
    "name": "app1",
    "version": "0.1.0",
    "scripts": {
        "dev": "vite",
        "build": "tsc && vite build",
        "lint": "eslint . --max-warnings 0",
        "type-check": "tsc --noEmit"
    },
    "dependencies": {
        /* Add only the dependencies this specific package needs */
        "react": "catalog:",
        "react-dom": "catalog:",

        /*
        "shared" is the value of the "name" field in the shared package.
        This name will be used in imports, so you can customize it to '@project_name/shared' if you want to add
        emphasis to the fact that this is a local package.
         */
        "shared": "workspace:"
    },
    "devDependencies": {
        "turbo": "catalog:",
        "typescript": "catalog:",
        "vite": "catalog:",
        "eslint": "catalog:",
        "esbuild": "catalog:",

        /* "tsconfig" is the value of the "name" field in the tsconfig package */
        "tsconfig": ":workspace"
    },
}
```


### `pnpm-workspace.yaml`

The `pnpm-workspace.yaml` is the file that contains the global configuration of the monorepo while the `package.json` hold the 
configuration of individual subpackages.

It looks like this:
```yaml
# List all the packages in your repo. You can use * for selection or pass the explicit folder name if you want to customize your package structure
packages:
- packages/*
- apps/*
# pnpm will add a onlyBuiltDependencies section automatically to store packages
# that need an additional build step. You don't have to worry about it.
onlyBuiltDependencies:
- esbuild 

# This is the most important part, the catalog.
# This is where you list the version of dependencies used in your project.
# When you write "catalog:" as the version, you are picking the version here.
# This allow consistent version use in all your packages (to avoid having 2 different react version installed for 2 different packages for example)
catalog:
  react: ^19.1.0
  react-dom: ^19.1.0
  eslint: ^9.26.0
  vite: ^6.3.5
  typescript: ^5.8.3
  esbuild: ^0.25.4

# In case you are using deprecated version of some dependencies, you can silence the warning with this section
# If you do, you should probably add a comment explaining why you are using these dependencies.
allowedDeprecatedVersions:
    - deprecatedPackageExample: "5" # We use this because xxx
    - deprecatedPackageExample2: "*"
```

### `tsconfig.json` and the typescript configuration

Having a consistent typescript across your project is important to avoid strange errors when copy-pasting code from one package
from another and not understanding why something that is allowed in a package is not allowed in another one.

In this monorepo template, the main `tsconfig.json` file (named `tsconfig.base.json`) is defined in the `tsconfig` package.

The content looks like this:
```json
{
  "$schema": "https://json.schemastore.org/tsconfig",
  "display": "Base",
  "compilerOptions": {
    "allowJs": true,
    "noEmit": true,
    "module": "esnext",
    "downlevelIteration": true,
    "isolatedModules": true,
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "moduleResolution": "node",
    "allowSyntheticDefaultImports": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "noImplicitReturns": true,
    "jsx": "react-jsx", // only needed if you use react/jsx, obviously
    "lib": ["DOM", "ESNext"]
  }
}
```

This post is not about configuring typescript. If you are interested in that, check out [this great article](https://www.totaltypescript.com/tsconfig-cheat-sheet) by Matt Pocock.

In the other `tsconfig.json` files, I'm importing this base and specifying only package specific config like include paths.
The `tsconfig.json` in `app1` looks like this:

```json
{
    "extends": "tsconfig/tsconfig.base",
    "compilerOptions": {
        "baseUrl": ".",
        "outDir": "dist",
    },
    /* Put "lib" for non-app packages */
    "include": ["src"]
}
```

If you want to have multiple configuration (like a strict and a non-strict one for migration purposes for example), you can have both in the `tsconfig` package and extend the one you'd like.

### `build.mts`

In this repo, I'm using `esbuild` for building the packages (and `vite` for dev preview)
I just copy paste the same `build.mts` file everywhere:

```ts
import fs from 'node:fs';
import { replaceTscAliasPaths } from 'tsc-alias';
import { resolve } from 'node:path';
import esbuild from 'esbuild';

/**
 * @type { import('esbuild').BuildOptions }
 */
const buildOptions = {
  entryPoints: ['./index.ts', './lib/**/*.ts', './lib/**/*.tsx'],
  tsconfig: './tsconfig.json',
  bundle: false,
  target: 'es6',
  outdir: './dist',
  sourcemap: true,
};

await esbuild.build(buildOptions);

/**
 * Post build paths resolve since ESBuild only natively
 * support paths resolution for bundling scenario
 * @url https://github.com/evanw/esbuild/issues/394#issuecomment-1537247216
 */
await replaceTscAliasPaths({
  configFile: 'tsconfig.json',
  watch: false,
  outDir: 'dist',
  declarationDir: 'dist',
});

fs.copyFileSync(resolve('lib', 'global.css'), resolve('dist', 'global.css'));
```

It will generate the content of the `dist` folder which is what gets imported.
In the `package.json` of dependencies, for the `dev` script, you'll need to run this build file with `node build.mts` assuming your node version can execute typescript files (or `node --experimental-strip-types build.mts`).

If your node version does not support typescript, you can stick to `mjs` files instead.

### `turbo.json`

The `turbo.json` file contains configuration for the `turbo` tool. You can use it to store dependencies between tasks, and enabling/disabling caching.

You can start with this one:

```json
{
    "$schema": "https://turbo.build/schema.json",
    "ui": "tui",
    "globalEnv": [],
    "tasks": {
        "dev": {
            "outputs": ["dist/**", "build/**", "i18n/locales/**"],
            "cache": false,
            "persistent": true
        },
        "build": {
            // if you have multiple tasks starting with "build", like "build:app"
            // the build task will run them all
            "dependsOn": ["^build"],
            "outputs": ["../../dist/**", "dist/**", "build/**"],
            "cache": false
        },
        "lint": {
            "cache": false
        },
        "type-check": {
            "cache": false
        },
        "clean": {
            "dependsOn": ["^clean"],
            "cache": false
        }
    }
}
```

## Conclusion

Monorepos can be challenging to setup, but they can improve work in middle-sized team (5 to 100 developers) by allowing better sharing of components and good practices.

If you are working alone, in a very big team, or on only very specific project, monorepos can be overkilled for your use-case.

I believe however that this is rarely the case. For example, if you are building a SaaS, you might want to share components between your product
without having a single workspace with big compile times.

