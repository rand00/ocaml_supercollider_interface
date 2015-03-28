#! /bin/bash

echo "Starting compilation of Lambdatactician and dependencies"

INSTALLED=$(ocamlfind list)

echo "$INSTALLED" | grep -qe "^lwt "
if [[ $? -eq 0 ]]
then
    echo Dependency Lwt is installed
    echo ">> Continuing compilation"
else
    echo "Dependency Lwt is not installed.."
    echo "Solution: Install with 'opam install lwt' and then run this script again."
    echo "Exiting compilation process"
    exit 1
fi

#Check if osc is already installed - if yes, and not with lwt-support, then
#  ask user to uninstall the existing version and exit
#  -> else install Osc with lwt support

#Checking if Osc is compiled with Lwt support
echo "$INSTALLED" | grep -qie "^osc \|^ocaml-osc "
if [[ $? -eq 0 ]]
then
    echo "$INSTALLED" | grep -qie "^osc.lwt \|^ocaml-osc.lwt "
    if [[ $? -eq 0 ]]
    then
        echo Dependency Osc is already installed with Lwt support
        echo ">> Continuing compilation"
    else
        echo Osc is already installed, but not with Lwt support
        echo "Solution: Uninstall Osc and recompile with Lwt support"
        exit 1
    fi
else
    if [ "$(ls -A lib_osc 2>/dev/null)" ]
    then
        echo "Osc files are present in 'lib_osc'"
    else
        echo "The 'lib_osc' directory is empty or nonexistent"
        echo "You probably forgot to pass the '--recursive' argument to 'git clone'"
        echo "Will now try to fetch the Osc library from github"

        git submodule update --init lib_osc
        if [[ $? -eq 0 ]]
        then
            echo "Osc lib was succesfully fetched"
        else
            echo "Something wen't wrong in with the download of Osc"
            exit 1
        fi
    fi

    echo "Starting compilation of Osc with Lwt support"
    ./compile_lib_osc.sh
    if [[ $? -eq 0 ]]
    then
        echo "Dependency Osc was compiled correctly wiht Lwt support"
        echo ">> Continuing compilation"
    else
        echo "Dependency Osc dit not install correctly.."
        echo "Exiting compilation process"
        exit 1
    fi
fi

if [ "$(ls -A core_rand 2>/dev/null)" ]
then
    echo "Core_rand files are present in 'core_rand'"
    echo ">> Continuing compilation"
else
    echo "The 'core_rand' directory is empty or nonexistent"
    echo "You probably forgot to pass the '--recursive' argument to 'git clone'"
    echo "Will now try to fetch the Core_rand library from github"

    git submodule update --init core_rand
    if [[ $? -eq 0 ]]
    then
        echo "Core_rand lib was succesfully fetched"
    else
        echo "Something wen't wrong in with the download of Core_rand"
        exit 1
    fi
fi


echo "Compiling Lambdatactician"
./compile_lambtac_native.sh
if [[ $? -eq 0 ]]
then
    echo "Compilation of Lambdatactician ran succesfully"
else
    echo "Compilation of Lambdatactician failed"
    exit 1
fi

which scsynth 2>&1 1>/dev/null
if [[ $? -eq 0 ]]
then
    echo "SuperCollider seems to be installed - all set!"
else
    echo "The SuperCollider server 'scsynth' is not visible in PATH"
    echo "The sound of Lambdatactician will not work without"
fi

echo "Compile-script ran succesfully"

