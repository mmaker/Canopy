FROM ocaml/dev:release-debian-9_ocaml-4.02.3
MAINTAINER canopy
ENV OPAMYES 1
RUN sudo apt-get update
RUN opam pin add dolog https://github.com/UnixJunkie/dolog.git\#no_unix
RUN opam pin add decompress https://github.com/oklm-wsh/Decompress.git
RUN opam pin add bin_prot https://github.com/samoht/bin_prot.git\#112.35.00+xen
RUN opam pin add crc https://github.com/yomimono/ocaml-crc.git\#xen_linkopts
RUN opam pin add syndic https://github.com/Cumulus/Syndic.git\#ptime
COPY . /src
RUN sudo chown -R opam:opam /src
WORKDIR /src
RUN opam config exec -- mirage configure --unix
RUN opam config exec -- make
