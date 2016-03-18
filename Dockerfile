FROM ocaml/dev:release-debian-9_ocaml-4.02.3
MAINTAINER canopy
ENV OPAMYES 1
RUN whoami
RUN sudo apt-get update
RUN eval `opam config env`; opam update
RUN eval `opam config env`; opam pin add dolog https://github.com/UnixJunkie/dolog.git\#no_unix
RUN eval `opam config env`; opam pin add decompress https://github.com/oklm-wsh/Decompress.git
RUN eval `opam config env`; opam pin add bin_prot https://github.com/samoht/bin_prot.git\#112.35.00+xen
RUN eval `opam config env`; opam pin add crc https://github.com/yomimono/ocaml-crc.git\#xen_linkopts
COPY . /src
RUN sudo chown -R opam:opam  /src
WORKDIR /src
RUN eval `opam config env`; mirage configure --unix
RUN eval `opam config env`; make
