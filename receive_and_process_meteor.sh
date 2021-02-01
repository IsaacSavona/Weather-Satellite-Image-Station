#!/bin/bash

# $1 = Satellite Name
# $2 = Frequency
# $3 = FileName base ex: /home/pi/weather/${OUTDAY}/${NAME//" "}${OUTDATE}/${NAME//" "}${OUTDATe}
# $4 = TLE File
# $5 = EPOC start time (unix time)
# $6 = Time to capture

cd /home/pi/weather/

timeout $6 rtl_fm -M raw -s 140000 -f 137.1M -E dc -g 65 -p 0.5 ${3}

#sudo timeout -s SIGINT $6 `sh /home/pi/weather/predict/receive_and_demod_meteor.sh ${3}`

#meteor_demod -o ${3}.s -s 140000 /tmp/meteor_iq & 
#sleep 3
#timeout -s SIGINT $6 rtl_fm -M raw -s 140000 -f 137.9M -E dc -g 65 -p 0.5 /tmp/meteor_iq & 
#wait
#sleep `expr $6 + 10`

#timeout "${6}" rtl_fm -M raw -f 137.9M -E dc -g 65 -p 0.5 | sox -t raw -r 288k -c 2 -b 16 -e s - -t wav ${3}.wav rate 96k
#timeout "${6}" rtl_fm "enable_bias_tee" -M raw -f 137.9M -s 288k -g 50 | sox -t raw -r 288k -c 2 -b 16 -e s - -t wav ${3}.wav rate 96k
#wait
#meteor_demod -B -o ${3}.s ${3}.wav 
#wait

#DEMOD_JOBID=`ps -aux | grep "meteor_demod -s" | sed -n '1p' | cut -d " " -f 9`

#kill -s SIGINT $RECORD_JOBID
#kill -s SIGINT $DEMOD_JOBID

#kill -9 RECORD_JOBID
#kill -9 DEMOD_JOBID

#cd /home/pi/weather/

#medet/medet_arm ${3}.s $3 -r 66 -g 65 -b 64 -cn -na

#if [ -f "${3}.bmp" ]; then
#        python3 meteor_rectify/rectify.py ${3}.bmp
#        rm $3.bm
#fi
