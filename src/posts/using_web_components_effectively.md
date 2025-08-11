{%
add_pic = true
setvar("layout",theme .. ".html")
%}

# Using web components effectively

*And how I decided to build more frontend framework as there are not enough to go around recently*
<br><br>

You'll learn about:
- Web components, 😁 duh!
- JS Tagged templates
- JS Decorators
- Why React elements sometime need a `key` attribute.
- The main principles of declarative UI frameworks
<br>

[Web components](https://developer.mozilla.org/en-US/docs/Web/API/Web_components) are the native way to create reusable, composable components, just like what you are used to if you are using React, Vue or other frontend frameworks.

Their major drawback is that they are verbose to write.

I'm going to write a component containing button with a counter that increases when clicked, a [classic example](https://react.dev/learn#updating-the-screen).

In React, one can write the following:

```ts
function MyCounter({ startingCount }: { startingCount: number }){
    const [count, setCount] = useState(startingCount);
    return (
    <button onClick={() => {
        setCount(count + 1);
    } }>
        Clicked {count} times
    </button>
  );
```

> I'm using typescript throughout this article for readability, but this would work just as well in regular JavaScript.

## Web components from scratch

First, I need to create a class that extends the native `HTMLElement` of the browser.

```ts
class MyCounter extends HTMLElement {
    constructor(){
        super();
        // Setup component
    }
    connectedCallback(){
        // Called when the component is connected to the DOM.
    }
    attributeChangedCallback(){
        // Called when an HTML attribute (`getAttribute`) changes
    }
}
```

In the constructor, I define a "shadow DOM", which is used to isolate the style and content inside of the component from the outside.

```ts
class MyCounter extends HTMLElement {
    constructor(){
        super();
        this.attachShadow({ mode: "open" });
        // this.shadowRoot can now be used.
    }
    // ...
}
```

Then, I can render something inside this shadow DOM:

```ts
class MyCounter extends HTMLElement {
    constructor(){
        super();
        this.attachShadow({ mode: "open" });
    }

    connectedCallback(){
        this.renderHTML();
    }

    renderHTML(){
        this.shadowRoot.innerHTML = `<button>Clicked ${0} times</button>`;
        this.shadowRoot.querySelector("button").addEventListener("click", () => {
            // TODO
        });
    }
}
```

Then, I need to get the the state of the counter from the attribute and store it:

```ts

class MyCounter extends HTMLElement{
    
    constructor(){
        super();
        this.attachShadow({ mode: "open" });
    }

    // We use a getter/setter to keep the attributes and the inner HTML in sync with the counter. 
    private _counter: number = 0;
    get counter(){
        return this._counter;
    }
    set counter(newCounter: number){
        this._counter = newCounter;
        this.setAttribute("startingCount", String(this._counter));
        this.renderHTML();
    }

    connectedCallback(){
        this.renderHTML();
    }

    renderHTML(){
        this.shadowRoot.innerHTML = `<button>Clicked ${this.counter} times</button>`;
        this.shadowRoot.querySelector("button").addEventListener("click", () => {
            this.counter++;
        });
    }

    // We need to declare the list of attributes we are using so that `attributeChangedCallback` is called
    // when the attributes are updated.
    static observedAttributes = ["startingCount"];

    attributeChangedCallback(
            name: string,
            oldValue: string,
            newValue: string
    ) {
        if(name === "startingCount"){
            const parsedValue = parseInt(newValue);
            // We need to prevent infinite loops here.
            if(!isNaN(parsedValue) && parsedValue !== this.counter){
                this.counter = parsedValue;
            }
        }
    }
}
```

> That's quite a lot of boilerplate and error-prone state syncing! As HTML attributes are string, I also need to manually convert back and forth between `String` and `number`.

Using the component is easy. First, I need to add it to the list of known components:

```ts
customElements.define("my-counter", MyCounter);
```

and I can use it!

```html
<div>
    <my-counter startingCount="3"></my-counter>
</div>
```

The state syncing dance is exactly the issue we are trying to avoid when using frameworks like React or Vue! Can we do better while still
relying on native APIs?

## A library to make web components easier

That's exactly the issue I had at my current company. The frontend codebase is quite old and uses mainly JQuery with bits of Backbone and Marionette. The JS code is loaded using a mix of RequireJS and custom loading code in such a way that using external NPM libraries is not possible,
so React, Vue or even [Lit](https://lit.dev) were out of the question!

This is why I built [VUI](https://github.com/vanyle/vui). VUI is extremely similar to Lit, but can be added to a project with no build-steps.

> The next few paragraphs are just an ad for VUI. But come on, how can you not love this tiny vanillaesque bit of JS 😊

VUI provides 2 concepts that are orthogonal a.k.a you can use one without using the other.
<br><br>
### The `VUI.Component` class

VUI removes the boilerplate by managing the syncing between the HTML, your state and your attributes using decorators so you can focus on the actual logic.

```ts
@customElement("my-counter")
class MyCounter extends VUI.Component {
    @attribute({name: "startingCount", type: "number"})
    accessor count: number = 0;

    // ...
}
```

Here, VUI automatically registers the component using the `customElement` decorator, and sync the HTML attribute `"startingCount"` with the JavaScript value `this.count`.

To do so, VUI makes use of [decorators](https://www.proposals.es/proposals/Decorators), a JavaScript feature that is not yet available in browsers (in 2025), but are underway.
Using decorators is optional, but they make the syntax simpler.

A decorator is a JavaScript function. When used on a class, the decorator takes the class constructor and can perform operations on it, like registering it.
`customElement` is a function that takes a string and returns the actual decorator function. It could be implemented like this:

```ts
function customElement(elementName: string) {
    return function (
        constructor: typeof VUI.Component & CustomElementConstructor
    ) {
        if (!customElements.get(elementName)) {
            customElements.define(elementName, constructor);
        } else {
            console.warn(`Component ${elementName} is already registered.`);
        }
    };
}
```

If you don't want to use decorators, you'll need to call `customElements.define(elementName, constructor);` yourself.
<br><br>
The same is true of the [`@attribute` decorator](https://github.com/vanyle/vui/blob/746dff701e1e4c9662b0f7f8b75bca4f6177114b/src/vui.ts#L832-L858). If you are not using decorators, you'll manually need to create a getter and setter.
VUI implements `attributeChangedCallback` for you, but you'll need to declare the `observedAttributes` array yourself.

<br>

### The `html` function

But that's not all! Another thing that was annoying with the counter was binding the click event to the button.
In this simple example, as there is not much HTML, this is not an issue, but as pages get bigger, having a large `this.shadowRoot.innerHTML = ...` quickly gets unreadable.

Thankfully, a lesser know feature of JavaScript comes to the rescue, [Tagged templates](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Template_literals#tagged_templates).
<br><br>
Tagged templates are JavaScript functions that can be used to customize how string interpolation work. In this case, instead of having expressions like `` `Hello, my name is ${name}` `` return a string, you
can return a DocumentFragment by adding `html` at the start: ``html`Hello, my name is ${name}` ``
<br><br>
A *naive* definition of `html` could look like this:

```ts
export function html(
    raw: TemplateStringsArray,
    ...expressions: AllowedExpressions[]
): DocumentFragment {
    const baseArray = [];
    raw.forEach((raw_i, i) => {
        baseArray.push(raw_i);
        if (i < expressions.length) {
            // You can handle expressions how you'd like. In this example, I just stringify them.
            baseArray.push(String(expressions[i]));
        }
    });
    const template = document.createElement("template");
    template.innerHTML = "".join(baseArray);
    return template.content;
}
```
Of course, VUI does something more complicated to properly handle rerenders.
<br><br>
When used inside a component, the `html` tag function looks like this.

```ts
@customElement("my-counter")
class MyCounter extends VUI.Component {
    @attribute({name: "startingCount", type: "number"})
    accessor count: number = 0;

    render: () => html`
        <button @click=${() => {this.count ++;} }>Clicked ${this.count} times.</button>    
    `;
}
```

Notice that the `render()` function returns the HTML and does not call `innerHTML`. This is because, like React, we perform a diff between
the old DOM and the new DOM during rerenders so that focus and selections and preserved when rendering.

And because the syntax is similar to Lit, the VSCode extension for Lit can be used for VUI.

This allowed us to switch to a declarative way of writing UIs that is more productive, without having to refactor all our code to switch to a new import system.
<br><br>
### Should you use VUI?

As much as it pains me to say it, the answer is probably no, as VUI is a one-to-one rewrite of Lit with less features. There are a few cases where you might still consider using VUI, mainly concerning legacy javascript projects.

- You want to write JavaScript with no build-steps while still enjoying composable components.
- You cannot use existing libraries like Lit due to the way you load JavaScript in your project.
- You want really high performance with load times and are not willing to put a full React bundle into your project.

With that caveat out of the way, let's see what writing VUI taught me about declarative frontend frameworks in general.

## The importance of `key`s

In the process, I learned about how React computes the differences between two DOM trees and why the `key` attribute matters. In VUI,  this attribute is written as `data-key`. Let's see how to is used:
<br><br>
Imagine you are rendering the following component:

```ts
class SomeComponent extends VUI.Component{
    showA: boolean = false;
    showB: boolean = true;

    renderHTML(){
        return html`
            ${this.showA && html`<div><input type="text" placeholder="A"/></div>`}
            ${this.showB && html`<div><input type="text" placeholder="B"/></div>`}
        `;
    }
}
```

If we set `showA` to `true` and `showB` to `false`, should we keep the cursor focused on the input?

Should the resulting `input` element in the DOM be the same object, or should it we a new freshly created `input`?

Well, just like in React, the `data-key` attribute can help. If two elements have the same key (and tag name!) between rerenders, VUI considers them to be the same and reuses the element.

You might already know that having a `key` is a best practice when rendering lists in React as in that case, you have a lot of elements with the same tag name. You usually want to reorder these elements between rerenders instead of creating them all from scratch for performance and to preserve selections.

What you might not know is that even in situations like the previous one where you have a few `ifs` or ternaries, adding a `data—key` prop (for VUI) or a `key` prop (for React) can make rendering faster and more predictable.

## An escape hatch

When making a framework, you really need to add an escape hatch so that you can be interoperable with other libraries.

In React, for example, this is done using an empty `div` with a `ref`. The `ref` gives you a handle to the underlying HTMLElement. You just need to make sure that your component is not rerendered or otherwise, the content of the `div` that was set by an external library will be lost.

In VUI, there is the `data-stable` attribute. When it is set, it means that the content of the element will only be rendered once. This is especially useful when using `contenteditable`:

```ts
return html`
    <div data-stable="true">${Math.random()}</div>
    <other-component></other-component>
    ${this.someAttribute && html`attribute was truthy!`}
`;
```

In this example, the number inside the div will not change as long as the component is mounted, while `other-component` will get rerendered as needed.

# Conclusion

Web components are a really cool API that allow all frontend developers to access components without using complex frameworks.
They are really verbose by default, but are flexible. 
You should use them together with another library to enjoy declarative UI, like Lit.

Consider staring ⭐ [VUI](https://github.com/vanyle/vui), I would really appreciate it!

You can use VUI in production, it is tested, documented and has simple storybook examples to learn from.
