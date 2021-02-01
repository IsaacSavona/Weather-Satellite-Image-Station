#!/bin/bash

# $1 = Satellite Name
# $2 = Frequency
# $3 = FileName base
# $4 = TLE File
# $5 = UNIX start time
# $6 = Time to capture

sudo timeout $6 rtl_fm -f ${2}M -s 60k -g 48 -p 55 -E wav -E deemp -F 9 - | sox -t wav - $3.wav rate 11025

PassStart=`expr $5 + 90` # Start time plus 1:30, 

FileDirectory=`echo $3 | cut -d "/" -f 5`

if [ -e $3.wav ]
  then
    cp $4 /home/pi/weather/$FileDirectory/${FileDirectory}-weather.tle # creating a weather.tle file with the pass's info
    
    cp /home/pi/wxtoimgrc /home/pi/weather/$FileDirectory/${FileDirectory}-PassLocation # creating a file to save ground station info

    echo $PassStart > /home/pi/weather/$FileDirectory/${FileDirectory}-PassStart.txt # creating file to save pass start, stop, total time?
      
    # creating map overlay files
    /usr/local/bin/wxmap -T "${1}" -H $4 -p 0 -l 0 -c C:0xe0b165 -c S:0xe0b165 -c g:0xd18378 -c L:0xe0b165 -o $PassStart ${3}-map-muted.png # MUTED MAP
    
    /usr/local/bin/wxmap -T "${1}" -H $4 -p 0 -l 0 -c C:0x000000 -c S:0x000000 -c g:0x000000 -c L:0x000000 -o $PassStart ${3}-map-black.png # BLACK MAP
    
    /usr/local/bin/wxmap -T "${1}" -H $4 -p 0 -l 0 -c C:0xcdaae0 -c S:0xcdaae0 -c g:0xcdaae0 -c L:0xcdaae0 -o $PassStart ${3}-map-lavender.png # Fucking lavender
    
    /usr/local/bin/wxmap -T "${1}" -H $4 -p 0 -l 0 -C 0 -S 0 -g 0.0 -c L:0x5f7952 -o $PassStart ${3}-map-bare.png # bare map (no boarders)
    
    # Creating pass pictures with different enhancements
    /usr/local/bin/wxtoimg -m ${3}-map-bare.png -e MSA $3.wav ${3}-MSA-bare.png
    
    /usr/local/bin/wxtoimg -m ${3}-map-muted.png -e MSA $3.wav ${3}-MSA-muted.png
    
    /usr/local/bin/wxtoimg -m ${3}-map-black.png -e MSA $3.wav ${3}-MSA-black.png
    
    /usr/local/bin/wxtoimg -m ${3}-map-black.png -e ZA $3.wav ${3}-ZA.png
    
    /usr/local/bin/wxtoimg -m ${3}-map-black.png -e MCIR $3.wav ${3}-MCIR.png
    
    /usr/local/bin/wxtoimg -m ${3}-map-black.png -e pristine $3.wav ${3}-PRISTINE.png
    
    /usr/local/bin/wxtoimg -m ${3}-map-black.png -e NO $3.wav ${3}-NO.png
    
    /usr/local/bin/wxtoimg -m ${3}-map-black.png -e therm $3.wav ${3}-THERM.png
    
    /usr/local/bin/wxtoimg -m ${3}-map-black.png -e sea $3.wav ${3}-SEA.png
    
    /usr/local/bin/wxtoimg -m ${3}-map-black.png -e contrast $3.wav ${3}-CONTRAST.png
fi
