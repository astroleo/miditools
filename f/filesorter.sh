#!/bin/bash
##
## Written by Leonard Burtscher (burtscher@mpia.de)
## 17 Nov 2009
##
## MODIFICATION RECORD
## 17 Nov 2009   initial version
## ...           minor modifications
## 06 Jul 2011   fixed bug that happened when obsdate should have been Dec 31 of
##                  any year
##
##
## PURPOSE
##
## 
## The purpose of this script is to sort MIDI data according to observation
## date. This script extracts the observing date from the the headers of all
## MIDI FITS files in sdir and moves them into subdirectories of the format
## YYYY-MM-DD under a specified archive directory (adir).
##
## For every file moved it will output one line to STDOUT; if a file already 
## exists at the target location, the file is not moved and a message is
## displayed
##
##
## TO DO
## merge common code with whighnight.sh
##
##
##
############ DEFINITIONS ############
##
## Absolute path to directory with files to be sorted
sdir=$MIDIDATAIN
##
## Absolute path to archive (with sorted files)
adir=$MIDIDATA
##
## Define beginning of night
## set night begin = 14:00 UT (= 11:00 / 9:00 local time)
nightbegin=14
######## END OF DEFINITIONS ########

currentdir=`pwd`
cd $sdir

filelist=`(find . -name MIDI.\*.fits)`
for i in $filelist; do
	##
	## check if file is a MIDI FITS file
	instrument=`dfits $i | grep INSTRUME | awk -F \' '{print $2}' | awk -F " " '{print $1}'`
	if [ ! $instrument = "MIDI" ]; then
		echo "File is not a MIDI FITS file. INSTRUME = $instrument"
	else
		##
		## extract part of DATE-OBS between ''
		dateobs=`dfits $i | grep DATE-OBS | awk -F \' '{print $2}'`
		##
		## get YYYY-MM-DD
		YYYYMMDD=`echo $dateobs | awk -F T '{print $1}'`
		year=`echo $YYYYMMDD | awk -F - '{print $1}'`
		month=`echo $YYYYMMDD | awk -F - '{print $2}'`
		day=`echo $YYYYMMDD | awk -F - '{print $3}'`
		##
		## get hh:mm:ss.sss; extract hour
		hhmmss=`echo $dateobs | awk -F T '{print $2}'`
		hour=`echo $hhmmss | awk -F : '{print $1}'`
		##
		## Strip leading 0 from $hour, $day and $month
		hour=`echo $hour | sed 's/^0//'`
		day=`echo $day | sed 's/^0//'`
		month=`echo $month | sed 's/^0//'`
		##
		## find out which night this file belongs to
		## check: are we at first day of month?
		if [ $hour -lt $nightbegin ] && [ ! $day -eq 1 ]; then
			day=$[day-1]
		elif [ $hour -lt $nightbegin ] && [ $day -eq 1 ] && [ $month -eq 1 ]; then
			 year=$[year-1] && month=12 && day=31
		elif [ $hour -lt $nightbegin ] && [ $day -eq 1 ]; then
			[ $month -eq 2 ] && month=1 && day=31
			##
			## leap year case
			if [ $month -eq 3 ] && [ $year -eq 2004 ] || [ $year -eq 2008 ]  || [ $year -eq 2012 ]  || [ $year -eq 2016 ]  || [ $year -eq 2020 ]; then
				month=2
				day=29
			elif [ $month -eq 3 ]; then
				month=2
				day=28
			fi
			##
			[ $month -eq 4 ] && month=3 && day=31
			[ $month -eq 5 ] && month=4 && day=30
			[ $month -eq 6 ] && month=5 && day=31
			[ $month -eq 7 ] && month=6 && day=30
			[ $month -eq 8 ] && month=7 && day=31
			[ $month -eq 9 ] && month=8 && day=31
			[ $month -eq 10 ] && month=9 && day=30
			[ $month -eq 11 ] && month=10 && day=31
			[ $month -eq 12 ] && month=11 && day=30
		fi
		##
		## add leading zero to day and month if less than 10
		[[ $day -lt 10 ]] && day=0$day
		[[ $month -lt 10 ]] && month=0$month
		##
		## construct directory structure for this file
		ddir=$year-$month-$day
		fdir=$adir/$ddir
		##
		## test if this directory structure exists, create it if it does not exist
		if [ ! -d "$fdir" ]; then
			mkdir -p $fdir
		fi
		##
		## get file name (without directory) to test if file exists
		filename=`echo $i | awk -F / '{print $NF}'`
		##
		## move raw file into appropriate directory
		## if directory exists and file does not exist
		if [ -d "$fdir" ]; then
			if [ -e "$fdir/$filename" ]; then
				echo "File $fdir/$filename exists. File not moved."
			else
				mv $i $fdir #for testing just comment out this line
				echo "Moved $i into $fdir"
			fi
		else
			echo "Error creating directory $fdir"
		fi
	fi
done

cd $currentdir