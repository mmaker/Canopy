FROM ocaml/dev:release-ubuntu-14.04_ocaml-4.02.3
MAINTAINER canopy
ENV OPAMYES 1
RUN sudo apt-get update
RUN cd /home/opam/opam-repository; git pull && opam update
RUN opam upgrade
RUN opam update
RUN opam install ptime
RUN opam pin add syndic https://github.com/Cumulus/Syndic.git\#ptime
COPY . /src
RUN sudo chown -R opam:opam /src
WORKDIR /src
RUN opam config exec -- mirage configure --unix
RUN opam config exec -- make