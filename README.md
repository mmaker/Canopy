# Canopy - A git-blogging unikernel 🌿  [![Build Status](https://travis-ci.org/Engil/Canopy.svg?branch=master)](https://travis-ci.org/Engil/Canopy)

Canopy is an attempt at writting a blog-engine based on Git using [MirageOS][mirage].

The goal is to provide a simple blog platform that only requires you to provide a Git remote URL and respecting some architecture rules within the said repository.

Canopy is written in OCaml using MirageOS and [Irmin][irmin], but it is currently only available on the Unix platform.

 [decompress]: <https://github.com/oklm-wsh/Decompress>
 [mirage]: <http://mirage.io/>
 [irmin]: <https://github.com/mirage/irmin>

### Compiling and running Canopy

You will need at least `OCaml 4.02.3`, `opam 1.2` and `mirage 2.7.0` before starting. To setup a mirage environment, please refer to the mirage website.
You'll also need `bower` and `less-css` if you want to compile and retrieve everything related to the blog-styling (not needed to just test things out).

Checkout Canopy repository, then go inside:

```sh
# You need syndic using ptime, thus first install ptime
opam install ptime
# Then pin syndic to the branch where ptime is used
opam pin add syndic https://github.com/Cumulus/syndic.git#ptime
# Get js/css dependencies and compile Less files
./style.sh
# Configure the mirage application
mirage configure --unix
# Compile Canopy
make
# Run it
./mir-canopy -r https://github.com/Engil/Canopy-documentation.git -i Welcome -p 8080
```

A server will be launched using the specified URL as the git remote, `Index` as the default page rendered on the blog (it must exist within the repository) and `8080` is the listening port.
You can see more options by running `./mir-canopy --help`.

### Compiling and running on Xen

If you want to build for xen, there's a couple of packages that need to be
installed from specific branches.

```sh
opam pin add dolog 'https://github.com/UnixJunkie/dolog.git#no_unix'
opam pin add bin_prot 'https://github.com/hannesm/bin_prot.git#113.33.00+xen'
opam pin add crc 'https://github.com/yomimono/ocaml-crc.git#xen_linkopts'
```

You can either build with support for DHCP or static ip, just specifying it in an
environment variable, for instance:

```sh
DHCP='no' mirage configure --xen
make
```

Make sure to have `br0` set up for this. For example, I did:

```
# provide ip forwarding
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
sysctl -p /etc/sysctl.conf
iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
# create a new bridge
brctl addbr br0
ip addr dev br0 add 10.0.0.1/24
ip link set br0 up
```

Finally you can run your unikernel!

```sh
xl create -c canopy.xl
```

### Git push hooks

To keep your Canopy content updated, you need to tell your instance that new content is available on the git remote, then it will just pull the changes and will serve the new content.

To do that, Canopy use a simple URL path that you can set into Canopy_config.ml (`hook_push_path`).

Using Github, setting up this hook is pretty simple: just add a push webhook targeting your URL + your hook path.
For example, by default this hook path is `push`, so the resulting URL is `http://yourdomain/push`.

If you are not using Github, you can just find a way (`post-commit-hooks`, for example) to run a HTTP request to this URL.

### How Canopy works

Canopy will require you to provide a Git remote uri. Once started, it will clone in-memory the repository content and serve the content in a more or less organized way.

Each file at the root of the repository is considered a standalone page, more like the usual « About » or « Contact » pages. They will have their own entries in the navigation menu.

Each directories will contains more pages, but that will be classified under a category decided by the name of the said directory.
For example, a `posts/hello-word.md` file will be a new blog post under the `Posts` category.
You can use it to emulate some sort of tag, like for example having an `OCaml` directory regrouping all you writing in everyone's favorite language. :-)

The file syntax is just plain markdown, everything should be supported out-the-box (depending on the `ocaml-cow` markdown implementation), with a little bit of extra informations absolutely needed at the top of each files.

```
---
title: A blog entry
author: Me
abstract: A simple line telling what this article is all about, will be displayed in listing pages. (optional)
---
article content
```

If you don't respect this syntax, then the article won't show up in the resulting website.

You can also put some MathJax inside articles, Mathjax is activated if you pass the --mathjax parameter at startup.