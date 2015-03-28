#! /bin/bash

#important to use -Is instead of -I
ocamlbuild -use-ocamlfind -cflag -bin-annot \
    -Is src,test \
    test_synth.native
