{%
setvar("layout",theme .. ".html")
%}


# Stop wasting my time
*Why I think a lot of open-source software is in a very bad state and what we can do about it.*

Like everybody else, I use a lot of open-source software. My phone uses an open-source operating system,
some apps are open-source, about half of the program I use on my laptop are open-source or at least built from
mostly open-source parts. And for the most part, I like the software I use. 

Issues start arising when I use software that was not started by a company or that is mostly community maintained.

Let's take a step back.

## The story

Yesterday, I was trying to make my raspberry pi control my lamp. I had it working a few years ago, the code was there,
I just needed to install an npm library called `node-bluetooth`. This library depends on Node v10, so I installed that version
no problem. Then, I ran into compilation issues:

The library uses C bindings to make node interact with the C world and sockets. However, the build system depends on python 2.
Why would python be involved in compiling and linking C code to JS? No idea.

My debian installation shipped with Python 3.11. So I search for how to install python 2 and found pyenv. I installed pyenv and tried to setup
a python 2 environment. While the command was running in the background, I decided to watch a Youtube video.

Youtube recommended me a video about some guy bragging about how this Linux setup was so much better than Windows. For some reason, I like to watch these
to realise how much of a bullet I dodged by having a sane operating system. 

After the 20 minutes, I checked back on the installation. I got stuck. Of course it got stuck, it tried to compile Python 2.7 using only a Gb of RAM, how
could it not get stuck... Pyenv does not provide binaries, everything gets compiled on your machine, this is so much sAfEr and move coNvEnIeNt.

In the end, I still managed to install Python 2.7 by adding a new repository to apt and installing the corresponding package using a bunch of googling. And I got the C code
to compile, the package to get installed and the lamp to work!

## The lesson

While the whole story has a happy ending, it illustrate one key point. Open-source software is not free. You pay with your free time. It took me hours to find a way to install and set the correct
python version on debian. Also, at first, I did not know that python 2.7 was required, I tried with python 3.7, than 3.5. All these installations and uninstallations took
a lot of time.

There are multiple kind of open-source software. The first kind is software started by corporation that want some free help for finding bugs and security research or large non-profit organizations. Examples include Chromium, Android, VSCode, Firefox, PostgreSQL. These are some of the best software I used.

The second kind is software started by hobbyists that got more popular overtime. These are some of the worst software I used. This includes every GNU utility except the linux kernel. Every single one has total disrespect for the user, with some of the most poorly written documentation I've every read that requires extensive amounts of googling for even the most basic tasks. Yes, all of them: bash, tar, grep, make, screen, everything! I do not want to use google for a task as basic as archiving a folder.
I should just be able to run `tar` and have a selectable list of options. That is possible, TUI exist!

- I do not want to type obscure incantations on a austere prompt with white on black text to perform basic operations like installing a program. I want to click on the install button and select the program from a list.

-  I do not want to hear about some variables being undefined on line 146 of your build script. I don't want to copy this error message to google to find a 7-year-old stackoverflow post telling me that it means that I need to install this unrelated apt package and run this magic command. I want you to install the dependencies you need without needing to disrupt my work.

- I don't want to see a `Permission Denied` error. I am a sudoer and the only user of this computer! Just escalate to root when needed and maybe show me a prompt asking me to confirm the operation, like the sane operating systems do.

- I don't want to have to install system-wide packages to be able to compile my program for this project. I don't want to see obscure linker error about undefined symbols where I need to google the name of the missing library. I want a per-project package manager dedicated to installing static and dynamic libraries. I don't want to compile the software I use myself to find that it requires me to reinstall the compiler I have because it uses this new C++ feature. And if the computer absolutely needs to compile the software, at least, I, as a user, should not have to think, care, or even be aware of it.

Of course, there are outliers. Some hobbyist care deeply about UX and value the time of other fellow programmers. Some flawed projects get improved with better usability over time. In this other direction, some open-source software made by companies is very very user-hostile, especially when they are trying to sell you support (kubernetes?)

## What is going on?

But this is not the reason I am so mad. Because yes, people will build poor software and this is fine, we all got to start somewhere and get better after time. Hobbyist projects are designed for the person that made them and are provided "AS-IS" with no warranty. They are already kind enough to provide their work for free, so I'm not complaining on this front.

Why I am mad is how much people praise this bad software (the youtube video I was mentionning earlier). And how much time they waste doing useless tasks like looking up how to install a specific version of Python. When watching video of linux users, they sometimes talk about a mistake they made that made them reinstall their operating system, or how the "reinstalled it last week" or that this feature is so neat because you keep your program and their configuration when you reinstall your OS (NixOS, I'm looking at you). You know how many times I reinstalled the OS of my Windows computer? That right, **never**. I **never** had to waste an hour flashing a USB, then going through the setup options, then reinstalled and reconfiguring anything. Because I'm using an OS that is respectful to my time and to me as a person.

Does the OS send my data to Microsoft by default? Yes, and I don't care, because toggling off a setting option to disable telemetry is immensely preferable to having a computer where the audio can fail at any point (I am speaking from experience, I have multiple linux computers and friends using linux.). And also because my DNS blocks telemetry and ads, but this is another story.

*Sidenote: I'm refering to Linux as a Desktop Operating System in this context. While running linux on a server is painful, it remains in my opinion the best option available.*

But why do so many people on the internet praise linux and say that they are quitting Windows when there is any news about AI integration inside Windows? The answer is simple. People on the internet are not normal. This includes me, but it also includes almost everything you read online. Think about it. Who would have enough free time in their life to not only spend hours reinstalling every program on their computer every month, but also bragging about how awesome this is on every tech forum?

That is not the behavior of any sane and reasonable person. Only somebody **crazy** would do that. And the internet is filled with crazy people. When these people are antivaxxers or flat earthers, it is easy to realize they are crazy. You can go fact check what they are saying. But for a technical field like software, with a lot of connections to less technical fields like UX, user behavior, psychology, etc.. detecting when a widely held belief is wrong within a community is a lot tougher.

And, like anti-vaxxers, these people are damaging the programming community. Of course, not to the extend of anti-vaxxers that are endangering people's life, but they are endangering people's time!

So, what can you do about this? First, do not repeat or trust facts about software that you see in online forums. The only thing you can trust is the documentation and your own experience with the software. Do they say it is blazing fast and prevent memory issues? Try it out yourself and you'll see that's actually going on. Think about the incentive structure behind the software. Is this company trying to show me the best it can offer so I grow dependent of its ecosystem? Or does it try to complicate things to sell support to me?

All in all, be mindful of your technical choices and remember that your time is valuable and finite!
