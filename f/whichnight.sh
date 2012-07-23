#!/bin/bash
##
## Written by Leonard Burtscher (burtscher@mpia.de)
## 18 Jan 2010, last modified 19 Sep 2011
##
## MODIFICATION RECORD
##
## 19 Sep 2011   relocated kernel of the function into whichnight_date.sh
##
##
## PURPOSE
##
## 
## Determine to which night a file belongs from its FITS headers
##
## Reads in 1 ESO/MIDI FITS file, returns night as YYYY-MM-DD
##
##
############ DEFINITIONS ############
## Define beginning of night
## set night begin = 14:00 UT (= 11:00 / 9:00 local time)
nightbegin=14
######## END OF DEFINITIONS ########

filename=$1
	##
	## check if file is a MIDI FITS file
	instrument=`dfits $filename | grep INSTRUME | awk -F \' '{print $2}' | awk -F " " '{print $1}'`
	if [ ! $instrument = "MIDI" ]; then
		echo "File is not a MIDI FITS file. INSTRUME = $instrument"
	else
		##
		## extract part of DATE-OBS between ''
		dateobs=`dfits $filename | grep DATE-OBS | awk -F \' '{print $2}'`
		##
		$MIDITOOLS/f/whichnight_date.sh $dateobs
	fi