#!/bin/bash
# this code has been copied and pasted from the NOAA instructables by haslettj, modified by James Monaco and Isaac Savona

# $1 = satellite name
# $2 = satellite center frequency

PREDICTION_START=`/usr/bin/predict -t /home/pi/weather/predict/weather.tle -p "${1}" | head -1`
# the first line of the predict output, the beginning of the pass (all info) 

PREDICTION_END=`/usr/bin/predict -t /home/pi/weather/predict/weather.tle -p "${1}" | tail -1`
# the last line of the predict output, the end of the pass (all info)

# -t: a predict command that specifies the .tle file used
# -p: predict the next pass for a specifc satllite
# | head -1: pipe the first line of the string into this variable
# | tail -1: pipe the last line of the string into this variable

END_UNIX=`echo $PREDICTION_END | cut -d " " -f 1`
# var 2 is 'echo [TIME]' where TIME the end time in seconds in 1970 (the first series of characters in prediction end)

#END_LOCAL=`date --date="TZ=\"UTC\" @${END_UNIX}" +%H:%M:%S`
END_LOCAL=`date -d @${END_UNIX} +%H:%M:%S`


# -d specifies delimeter
# -f 1: get the first field deliniated by spaces (the first series of characters, seconds since 1970)

MAXELEV=`/usr/bin/predict -t /home/pi/weather/predict/weather.tle -p "${1}" | awk -v max=0 '{if($5>max){max=$5}}END{print max}'`

# awk -v [var=value]: pattern matching, intialize max to 0 and if the fifth entry of the prediction (ie the elevation) is greater than max, set max equal to the elevation.
# if the elevation is greater than 0, set MAXELEV equal to the elevation in the tle file (for a given line of the file)

while [[ `date -d @${END_UNIX} +%D` == `date +%D` ]]; do
#while [[ `date --date="TZ=\"UTC\" @${END_UNIX}" +%D` == `date +%D` ]]; do
# date: prints current date in standard format
# date --date=[OPTION]: Prints the specified date in a standard format
# ... +%D: add the day format (MM/DD/YYYY) 
# OVERALL: while the end date is equal to today, execute this loop

START_UTC=`echo $PREDICTION_START | cut -d " " -f 3-4`
# start time in UTC format (ex: "02Aug20 21:23:34")

START_UNIX=`echo $PREDICTION_START | cut -d " " -f 1`
# start time in unix format (seconds after 1970)

START_LOCAL=`date -d @${START_UNIX} +%H:%M:%S`
#START_LOCAL=`date --date="TZ=\"UTC\" @${START_UNIX}" +%H:%M:%S`

START_UTC_SEC=`echo $START_UTC | cut -d " " -f 2 | cut -d ":" -f 3`
# the seconds element of START_UTC

TIMER=`expr $END_UNIX - $START_UNIX + $START_UTC_SEC`
# [end time (unix time)]  - [start time (unix time)] + [seconds element of start time], to give the total time (in sec) of the pass plus START_UTC_SEC

OUTDATE=`date -d "${START_UTC}" +%Y%m%d-%H%M%S` # trying different outdates that won't throw errors 
#OUTDATE=`date --date="TZ=\"UTC\" ${START_UTC}" +%Y%m%d-%H%M%S` # trying different outdates that won't throw errors 

#OUTDATE=`date --date="TZ=\"UTC\" $START_UTC" +%Y%m%d-%H%M%S`
# OUTDATE is displaying the start of the pass in YYYYMMDD-HHmmss, used in file name scheme
#OUTDAY=`echo $OUTDATE | cut -d "-" -f 1` # day of OUTDATE, used for directories. SHOULD BE IN LOCAL TIME
OUTDAY=`date +%Y%m%d` # directory for current day


if [ $MAXELEV -gt 19 ] # THIS SETS THE MINIMUM PASS ELEVATION TO 19 DEGREES
# if MAXELEV is greater than 19 degrees, do a pass!
  then
    echo ${1//" "}${OUTDATE} $MAXELEV
    # print to command line: [SATELLITE NAME] [STARTPASS] [ELEVATION]
    # Using the replace all model ${FOO//from/to}, //"" " replaces the space with nothing (i.e. deletes it)
    echo "$1,$2,$OUTDATE,$START_UNIX,$TIMER,$START_UTC,$MAXELEV" >> /home/pi/weather/${OUTDAY}/satellite_queue.txt # WRITE to satellite_queue.txt all info needed to schedule a pass

    
    ## the following lines can be used if atq_elevation_prioritize.sh is not desired; all passes will be scheduled, reguardless of timing conflicts between satellites
    #echo "mkdir -p /home/pi/weather/${OUTDAY}/${1//" "}${OUTDATE}" | at `date --date="TZ=\"UTC\" $START_UTC" +"%H:%M %D"` # folder for this pass, within the day folder
    #if [ "$1" == "METEOR-M 2" ]
      #then
        #echo "/home/pi/weather/predict/receive_and_process_meteor.sh \"${1}\" $2 /home/pi/weather/${OUTDAY}/${1//" "}${OUTDATE}/${1//" "}${OUTDATE} /home/pi/weather/predict/weather.tle $START_UNIX $TIMER" | at `date --date="TZ=\"UTC\" $START_UTC" +"%H:%M %D"`
      #else
    #echo "/home/pi/weather/predict/receive_and_process_satellite.sh \"${1}\" $2 /home/pi/weather/${OUTDAY}/${1//" "}${OUTDATE}/${1//" "}${OUTDATE} /home/pi/weather/predict/weather.tle $START_UNIX $TIMER" | at `date --date="TZ=\"UTC\" $START_UTC" +"%H:%M %D"`
    ## execute the recieve_and_process.sh using [SATELLITE NAME] at [FREQ], writing to [SATELLITE NAME][DATE] using the .tle at [START TIME (unix)] running for [TIMER] length, and schedule the atq for that
    #fi
    ##echo "$1, $START_LOCAL, $END_LOCAL, $MAXELEV" >> /home/pi/weather/${OUTDAY}/satellite_queue.txt # OLD WRITING TO SAT QUEUE; this is now useless    
fi

nextpredict=`expr $END_UNIX + 60`

PREDICTION_START=`/usr/bin/predict -t /home/pi/weather/predict/weather.tle -p "${1}" $nextpredict | head -1`
PREDICTION_END=`/usr/bin/predict -t /home/pi/weather/predict/weather.tle -p "${1}"  $nextpredict | tail -1`

MAXELEV=`/usr/bin/predict -t /home/pi/weather/predict/weather.tle -p "${1}" $nextpredict | awk -v max=0 '{if($5>max){max=$5}}END{print max}'`

END_UNIX=`echo $PREDICTION_END | cut -d " " -f 1`
END_LOCAL=`date -d @${END_UNIX} +%H:%M:%S`
#END_LOCAL=`date --date="TZ=\"UTC\" @${END_UNIX}" +%H:%M:%S`


done
