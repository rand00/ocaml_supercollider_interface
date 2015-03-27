#! /bin/bash

#important to use -Is instead of -I
ocamlbuild -use-ocamlfind -cflag -bin-annot \
    -Is src,core_rand \
    lambdatactician.native
