#!/usr/bin/env python3

import csv # treating the input file as a csv
import sys
satFile = str(sys.argv[1]) # need to have this an an arguement when executing the file

# satellitePass object, containing key information about each pass. 
class satellitePass: 
    def __init__(self, name, freq, outdate, startunix, timer, startutc, elev):
        self.name = name
        self.freq = freq
        self.outdate = outdate
        self.startunix = startunix
        self.timer = timer
        self.startutc = startutc
        self.elev = elev
        self.status = "not scheduled" # a satellite pass can be not scheduled, scheduled, or ignored   

## checkOverlap takes two passes and checks if they overlap in time. 
# returns True if they overlap; returns false if they do not.
# returns false if the satellites being compared are the same satellite
def checkOverlap(pass_pivot, pass_comp):
    # the first satellite in the comparison, dubbed p
    p_start = pass_pivot.startunix
    p_end = pass_pivot.startunix + pass_pivot.timer
    p_name = pass_pivot.name
    
    # the second satellite in the comparison, dubbed c
    c_start = pass_comp.startunix
    c_end = pass_comp.startunix + pass_comp.timer
    c_name = pass_comp.name
    if (c_name != p_name): # only compare satellites of different names. Satellites with the same name (e.g., NOAA 15 and NOAA 15) will never conflict; they're the same sat
        if ( (c_start <= p_end and c_start >= p_start ) or (p_start <= c_end and p_start >= c_start ) ): # if either pass starts during the other's pass
            # print("Overlap! The following two satellites conflict, around",pass_pivot.startutc,":", c_name, p_name)
            return True # they conflict!
        else: 
            return False
    else: 
        return False

# finding the number of passes and all passes into a list as a Pass object
numPasses = 0
passQueue = [] # holds all passes
with open(satFile, 'r') as satellite_queue:
    reader = csv.reader(satellite_queue, delimiter=',')
    for row in reader: # this reads each row as a string array
        if (numPasses > 0): # the first row is the header of the file, and should not be read
            name = row[0]  
            freq = row[1]
            outdate = row[2]
            startunix = int(row[3])
            timer = int(row[4])
            startutc = row[5]
            elev = int(row[6])
            passQueue.append( satellitePass(name, freq, outdate, startunix, timer, startutc, elev) )
        numPasses = numPasses+1        
numPasses = numPasses-1 # the first line is the header, and should not be counted in the number of passes
satellite_queue.close()

# seeing conflicts, resolving them, and putting all valid passes in passQueue to a final queue, used for scheduling
n = 1 
for obj1 in passQueue: # obj1 is the satellite we're looking at
    i = 1
    for obj2 in passQueue: 
        if (obj1.name == obj2.name and obj1.startunix == obj2.startunix and i != n and obj1.status == "not scheduled"): # cancel duplicate entries!
            obj2.status = "canceled" 
        i = i+1
    if (obj1.status == "not scheduled"): # only bother looking at satellites that have not been scheduled. if they have been scheduled, then they should have handled all their conflicts already
        if(obj1.name == "METEOR-M 2"): # logic for if obj1 is METEOR
            obj1.status = "scheduled" # schedule all meteor passes
            for obj2 in passQueue:
                overlap = checkOverlap(obj1, obj2)
                if(overlap == True):                    
                    obj2.status = "canceled" # cancel anything that intersects with a meteor pass.
        else: # logic for if obj1 is NOAA
            for obj2 in passQueue:
                if ( obj2.status == "not scheduled" and checkOverlap(obj1, obj2) == True): # if there's overlap with an unscheduled satellite
                    if(obj2.name == "METEOR-M 2"): # if it conflicts with a meteor pass, cancel obj1 and schedule the meteor
                        obj2.status = "scheduled"
                        obj1.status = "canceled"
                    elif(obj2.elev <= obj1.elev): # if the overlap eleveation is not greater, remove the overlap and schedule obj1
                        obj2.status = "canceled"
                    else: # if the obj2 overlaps and its elevation is greater, we must see if furhter objects overlap obj2 and if they have higher prority than obj2 
                        overlapFlag = 0
                        for obj3 in passQueue:                             
                            if(obj3.status == "not scheduled" and checkOverlap(obj2,obj3) and obj3 != obj1): # if an unscheduled object overlaps obj2 that is NOT obj1
                                overlapFlag = 1
                                if (obj3.elev > obj2.elev):     #if obj3's elevation is greater than obj2, cancel obj2
                                    obj2.status = "canceled"    
                                else:                           # if ojb3's elevation is less than obj2, obj2 wins out and all its overlaps are canceled
                                    obj1.status = "canceled"
                                    obj3.status = "canceled"
                        if overlapFlag == 0: # if there's no further conflicts other than obj2 (which has a higher elevation than obj1), cancel obj1
                            obj1.status = "canceled"
            if(obj1.status != "canceled"):
                obj1.status = "scheduled" # if there's no conflicts, or if there was a conflict and obj1 didn't get canceled, schedule it!
    n=n+1
                    
# re-writing the satellite_queue.txt to contain all scheduled passes flagged in passQueue
with open(satFile, 'w') as satellite_queue: # replace directory path with satFile
    satelliteQueue_writer = csv.writer(satellite_queue, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
    satelliteQueue_writer.writerow(["[NAME]", "[CENTER FREQ]", "[OUTDATE (fmt: Ymd-HMs)]", "[Start time (fmt: unix)]", "[TIMER] (fmt: sec)", "[START TIME (fmt: UTC)]", "[ELEVATION]"])
    for obj in passQueue:
        if(obj.status == "scheduled"):
            rowStr = [obj.name, obj.freq, obj.outdate, obj.startunix, obj.timer, obj.startutc, obj.elev]
            satelliteQueue_writer.writerow(rowStr)
satellite_queue.close()
