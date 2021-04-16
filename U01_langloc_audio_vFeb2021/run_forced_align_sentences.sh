#!/bin/bash
TXT_LOCATION="/Users/eghbalhosseiniasl1/MyCodes/MIT_U01_experiments/U01_langloc_audio_vFeb2021/stimuli_txt/"
AUDIO_LOCATION="/Users/eghbalhosseiniasl1/MyCodes/MIT_U01_experiments/U01_langloc_audio_vFeb2021/stimuli/"
ALIGHTMENT_LOCATION="/Users/eghbalhosseiniasl1/MyCodes/MIT_U01_experiments/U01_langloc_audio_vFeb2021/stimuli_alginment/"
AUDIO_FILE_NAME=""
#
for item in $TXT_LOCATION/*
    
do
    #echo $item
    sent_number=$(basename -s .txt $item) # get the file name and save it to test
    #echo $sent_number
    #echo $AUDIO_LOCATION$AUDIO_FILE_NAME"$sent_number"".wav"
    audio_file=$AUDIO_LOCATION$AUDIO_FILE_NAME"$sent_number"".wav"
    echo $audio_file
    txt_file=$item
    jason_file=$ALIGHTMENT_LOCATION"$sent_number"".json"
    echo $jason_file
    #echo $jason_file >$jason_file
    #echo $sent_number > $ALIGHTMENT_LOCATION$sent_number.txt
    #echo $jason_file
    python /Users/eghbalhosseiniasl1/MyCodes/gentle/align.py -o $jason_file $audio_file $txt_file
done
