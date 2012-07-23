#!/bin/bash
##
## Written by Leonard Burtscher (burtscher@mpia.de)
## 18 Jan 2010 (whichnight.sh), fork from this, last modified 19 Sep 2011
##
## PURPOSE
## Determine to which night an ESO date string (YYYY-MM-DDTHH:MM:SS.SSSS) belongs
## assuming given date is an ESODAT
##
## returns day of night begin as YYYY-MM-DD
##
## LIMITATIONS
## uses Mac OS X version of date command, not identical to GNU date. The latter
## does not understand the -v option (but has -d instead).
## 
##
############ DEFINITIONS ############
## Define beginning of night
## set night begin = 14:00 UT (= 11:00 / 9:00 local time)
nightbegin=14
######## END OF DEFINITIONS ########

dateobs=$1
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
if [[ $hour -lt $nightbegin ]]
then
	date -v${year}y -v${month}m -v${day}d -v-1d "+%Y-%m-%d"
else
	printf "%4d-%02d-%02d\n" $year $month $day
fi