{%
setvar("layout",theme .. ".html")
%}

<script defer src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.5.1/languages/dockerfile.min.js"></script>

# Docker basics

_The sequel to the old man and the sea explained for programmers_

After writing my last article about docker, I realized that a lot of people don't know the basics of Docker, so I decided to write a follow-up article explaining things in a short and concise manner, especially as I find the [official documentation](https://docs.docker.com/) to not be very useful unless you already know what you're looking for.

## What is Docker's purpose?

Docker is a way to build, distribute and install software that is easy, cross-platform and customizable.

Let's say you want to install a [postgresql](https://www.postgresql.org/) database.
You want to be able to configure the following:

- The version used
- The username / password
- The port to which the database should listen

You want to easily we able to share this configuration with other people, especially if you are working on a project that requires a database with a specific configuration. You also want to be able to install this software on production servers and local computers.

To do, so you simply define a `docker-compose.yml` file which looks like this:

```yml
services:
  my_database_service:
    image: postgres:17.3
    restart: always
    environment:
      POSTGRES_PASSWORD: postgres
      POSTGRES_USERNAME: postgres
    ports:
      - 5432:5432
```

You can start the database using `docker-compose up` (or `docker compose up` depending on your installation) and stop it using `docker-compose down`.
You can run the database in the background using `docker-compose up -d` (`d` stands for "detach")

This docker compose file can specify multiple services that interact with one another and stores the configuration of every service in a one source of truth.

Now let's say that you want an web interface to browse your database. You can look one up online, like [adminer](https://www.adminer.org/) for example. Then, you simply add it to your docker compose file like so:

```yml
services:
  my_database_service:
    image: postgres:17.3
    restart: always
    environment:
      POSTGRES_PASSWORD: postgres
      POSTGRES_USERNAME: postgres
    ports:
      - 5432:5432
  adminer:
    image: adminer:latest
    restart: unless-stopped
    ports:
      - 8888:8080
```

When running this docker file, you get 2 services. Your database and the database browsing tool available at `http://localhost:8888`.

You can easily update your database version by changing what does after the `:` and rerunning `docker-compose up`. You can (and should) pin your version instead of using `latest` to avoid unexpected upgrades and errors.

To ensure that the same version is used, you should pin your version using its sha256 hash like so:
`debian@sha256:5724d31208341cef9af6ae2be86be9cda6a87271f362a03481a522c9c19d401b`.

The service is ran in an isolated environment called a **Docker container**. You can run multiple database from different projects on your computer without any conflicts.

`postgres:17.3` and `adminer:latest` are called images. They are what gets instanciated when the container is ran. The image contains all the executable code needed for the container to function. For `postgres`, this includes the database executable itself, but also, depending on the exact image version you choose, tools like `curl`, `git` or `bash` or even `apt` that can be useful to debug a container while it is running. In some ways, images can be take as much space on disk as a full OS then they contain all these added tools.

You can list all running Dockers using `docker ps` (ps stands for processes). This will show a table like this:

```
CONTAINER ID   IMAGE        COMMAND                 CREATED       STATUS       PORTS                    NAMES
177802672aec   postgresql   docker-entrypoint.s…"   3 hours ago   Up 3 hours   0.0.0.0:5432->5432/tcp   my_database_service-1
```

You can create, remove, start and stop dockers using similar commands and the ID of the corresponding container, see the official documentation for more info.

If bash is installed in your container, you can "go inside" the container to run commands like `ls` and `cat` to understand what is going on and troubleshoot issues. You do so using the following command:

`docker exec -it 36d912a741cf psql --help`

`i` stands for "interactive" and `t` for `tty`. Sometimes, a docker might do nothing when started but contain a lot of useful CLI tools that you can run using `docker exec`. For example, if you need a ¨PostgreSQL client, you can use the one inside the postgresql image (don't forget to put the right ID):

`docker exec -it 36d912a741cf psql --help`

## Communication with the outside

By default, a container is completly isolated. You cannot get any data in or out, which is not very useful. This is why we can share ports and volumes in the `docker-compose.yml` file. The syntax is always `- outside_resource:inside_resource` to create a correspondance.

For example, the adminer service above has its 8080 port on the inside mapped to the 8888 port. This means that the app listens to the 8080 port internally, but docker maps it to the 8888 port outside, so you can access it in your browser at `http://localhost:8888`.

You can also share folders using this syntax:

```yml
services:
  my_database_service:
    image: postgres:17.3
    restart: unless-stopped
    environment:
      POSTGRES_PASSWORD: postgres
      POSTGRES_USERNAME: postgres
    # We put the content of the database in a locally accessible folder for simpler debugging.
    volumes:
      - ./database_internals:/var/lib/postgresql/data/pgdata
    ports:
      - 5432:5432
```

## Creating custom images

Now that you know how to run docker containers, you might want to create your own images. A good docker image is as tiny as possible and starts quickly.

Docker images are define using `Dockerfile`, which are a list of instruction on how to create the image. The easiest way to get started is to take an existing image and build upon it.

Let's say that I want a database with some tables already initialized. My SQL commands that create the tables are located inside an `init.sql` file.

Next to that file, I make a `Dockerfile` with the following:

```Dockerfile
# I start from an existing image. I could also have started from "scratch".
FROM postgres:17.3

# Copy the init.sql file inside the docker-entrypoint-initdb.d of the image
# The PostgreSql image will automatically execute all SQL files inside on startup.
COPY init.sql /docker-entrypoint-initdb.d/
```

Inside `Dockerfile`, you can also execute commands, like `RUN apt-get install git`, set environment variables like `ENV POSTGRES_USER docker` or define
the ports you application uses using `EXPOSE 8080`.

Now, I can use that image in a docker compose:

```yml
services:
  my_custom_image:
    build:
      context: .
      dockerfile: ./Dockerfile
    environment:
      POSTGRES_PASSWORD: postgres
      POSTGRES_USERNAME: postgres
    # We put the content of the database in a locally accessible folder for simpler debugging.
    volumes:
      - ./database_internals:/var/lib/postgresql/data/pgdata
    ports:
      - 5432:5432
```

When running a custom image and making changes to it, run `docker-compose build` to rebuild your image before starting it or your changes won't be taking into account.

### General advice on making `Dockerfile`s.

Every line of a Dockerfile with an instruction like `COPY` or `RUN` will create a new build step. These steps are cached, so when developing, put steps that are often changing near the end of your file. To reduce the cache size and prevent Docker from eating all the space available on your disk, try to group steps together, so instead of:

```Dockerfile
RUN apt-get install -y git
RUN apt-get install -y curl
```

You can do:

```Dockerfile
RUN apt-get install -y git curl
```

When you are running low on space, do a `docker system prune` to remove unused images and volumes.

## Putting your image in a registry

You can share your images with other people using a container registry. You can use a public registry like ghcr.io or your own private one.
Usually, you can a CI in your repository that automatically builds and uploads you image as you make changes to it.

This is what [Aiguillage does](https://github.com/vanyle/aiguillage/blob/master/.github/workflows/docker.yml).

Once your image is in a registry, you can pull it from anywhere using its URL: `ghrc.io/path_to_my/image:version`

## Conclusion

Docker is a very handy too to package and distribute you application. However, packaging you application in a small and efficient way is an art.

You can read the [following article](https://vanyle.github.io/posts/tiny-dockers-big-performance.html) on some examples to write Dockerfile with a small footprints for a classic Backend + Frontend + Database app in Go.
