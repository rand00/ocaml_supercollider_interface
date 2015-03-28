#! /bin/bash

ocamlbuild -use-ocamlfind -cflag -bin-annot -Is src sC.cmx sC.cmo
