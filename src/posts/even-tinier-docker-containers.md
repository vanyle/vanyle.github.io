{%
    add_pic = true
    setvar("layout",theme .. ".html")
%}
<script defer src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.5.1/languages/dockerfile.min.js"></script>

# Even tinier and awesomer dockers images

*The quest to not fill up disk space continues*

Hey. This article is the third from the Docker series!
If you are interested in Docker, see:

- [Getting started with Docker](https://vanyle.github.io/posts/docker_basics.html), an introduction to Docker Compose
- [Tiny Docker Big Performance](https://vanyle.github.io/posts/tiny-dockers-big-performance.html), for ways to make images smaller and faster

<br>

If you have been building you own Docker images, you might have experienced Docker filling up your disk with garbage images.
While you can remove images using commands such as `docker system prune`, it would be nice to have smaller images in the first place.

<br>

In "Tiny Docker Big Performance", we've seen how to build a container for a fully featured backend application in 12Mb. While this is already
not too big, we can do even better! Remember that smaller apps are faster to deploy, and consume less disk space and bandwidth, which is
super neat in a kubernetes environment with frequent deployments.

We'll also see other important practices that you can implement to improve your images and build systems.

## UPX

You can take a file from an existing docker image and copy just this specific file into your image. This is super useful as Docker can act as a super package
manager from which you can fetch any executable, as long as it is static and has no dependencies.

Consider this example provided by `ux`, the python package manager

```Dockerfile
FROM python:3.12-slim-bookworm
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# The rest of the docker file ...
```

We can take any base image, even a tiny one like alpine, and run `uv` to install Python and our requirements super quickly while minimizing
other dependencies (as long as the `uv` binary we're fetching is linked statically using `muslc` for example).

There are many useful standalone tools one can find inside Docker images, but one i'd like to highlight is [UPX](https://upx.github.io/).
UPX is an executable packer. It takes an executable, zips it and generates an auto-unzipping self-contained executable. You get an executable with
the same features but a smaller size.

While some people might consider having a separate build stage to pack their executable with `upx`, you don't need to!

```dockerfile
# --- BUILD STAGE ---
FROM golang@1.24.2-alpine AS gobuilder

# Copy upx inside your image
COPY --from=gruebel/upx:latest /usr/bin/upx /usr/bin/upx

# Build your go code as usual
COPY go.mod go.sum .

RUN go mod download
RUN go mod verify

COPY main.go .
COPY ./internal ./internal

# Of course, you can add linker flags here to strip symbols and other things
# but I'm keeping this example simple
RUN go build -o /myprogram 

# This is where the magic comes in, we are compressing the executable in the same stage as the build.
RUN upx --lzma /myprogram
# --- RUN STAGE ---
FROM scratch
COPY --from=gobuilder /myprogram /
ENTRYPOINT ["/myprogram"]
```
This makes the image even smaller, as that it contains exactly the files it needs.

The possibilities are endless and turn Docker into a super powerful build system + package manager.

<br>

Let's say you want to compress an mp4 video before including it into your production image. Well, you can just grab the ffmpeg executable from an image like `jrottenberg/ffmpeg` and run it during the build stage and ship compressed videos.

## Pin dependencies to a specific hash

In many tutorials, including this one, we declare stages using tags.
For example, we say:
```dockerfile
FROM golang@1.24.2
```

Which means that we should take the golang image with version `1.24.2` as a base and build from there.

While this is super readable, we have no guarantee that this tag will forever refer to this specific image. This is because
Git tags can be moved around freely.

If you want to truly pin your images (which you should, for reproducability and to avoid unexpected breakage), you should pin
your images using a hash like so:

```dockerfile
# golang alpine 1.24.1
FROM golang@sha256:43c094ad24b6ac0546c62193baeb3e6e49ce14d3250845d166c77c25f64b0386 
```

In that case, don't forget to add a comment to help people identify the version used and maybe a link to the image.

## Do not forget some essentials

When building images from scratch, there are some things that we usually take for granted in an image that are missing.
A prime example are SSL certificates. If you try to build a service that perform HTTPS requests using the docker images
I presented so far, you might get errors like:

`certificate verify failed: unable to get local issuer certificate`

This is because the image does not contain anything, not even default certificates. You need to copy them like so:


```dockerfile
# --- BUILD STAGE ---
FROM some_alpine_image as builder
RUN apk --no-cache add ca-certificates


# --- RUN STAGE ---
FROM scratch
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
# The rest is the same. Make sure gobuilder has the certificates installed.
```

## Conclusion

When starting out docker, it is tempting to put everything in one image, python, node, a c++ compiler, etc...
While it is convenient to just add a `apt get install missing-thing` in a docker when your app complains about
a missing dependency, this can quickly spiral out of control and you end up with docker images bigger than
the ones provided by [jupyter](https://quay.io/repository/jupyter/tensorflow-notebook?tab=tags)

Taking some extra time to trim extra dependencies and having distinct build and run stages will make your builds
faster, more reliable and your hard drive will thank you for it!

Do need to delete those family photos to make room for docker images anymore 😁.
