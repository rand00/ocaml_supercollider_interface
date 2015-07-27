#! /bin/bash

## This script is based off of the following guide;
## http://swiki.hfbk-hamburg.de/MusicTechnology/634 

SCSYNTH=$(which scsynth)
PORT=57110
export SC_SYNTHDEF_PATH="./test_synths" 
#< this get's loaded, but is not set as standard when writing synths

export SC_JACK_INPUTS=2
export SC_JACK_OUTPUTS=2

if [[ $SC_JACK_DEFAULT_INPUTS == "" ]]
then 
    #export SC_JACK_DEFAULT_INPUTS="alsa_pcm:capture_1,alsa_pcm:capture_2"
    export SC_JACK_DEFAULT_INPUTS="system"
fi

if [[ $SC_JACK_DEFAULT_OUTPUTS == "" ]]
then 
    #export SC_JACK_DEFAULT_OUTPUTS="alsa_pcm:playback_1,alsa_pcm:playback_2"
    export SC_JACK_DEFAULT_OUTPUTS="system"
fi

# like this it's not necessary to run this script as root < (because of being in build-dir?)
# and it shows you how the server is actually started
SCCMD="$SCSYNTH -i ${SC_JACK_INPUTS} -o ${SC_JACK_OUTPUTS} -u $PORT $@"
echo $SCCMD "$@"

$SCCMD 2>&1

#nice -n -10 $SCCMD || $SCCMD

