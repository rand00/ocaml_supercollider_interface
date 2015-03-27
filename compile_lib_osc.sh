#! /bin/bash

## Make sure Lwt is installed 

cd lib_osc
ocamlbuild -clean
ocaml setup.ml -configure --enable-tests --enable-lwt
ocaml setup.ml -build
ocaml setup.ml -install
cd ..

