#!/bin/bash
##
## PURPOSE
## Get all missing DIMM ambient condition measurements
##

year_start=2003
month_start=1
day_start=1

year=$year_start
month=$month_start
day=$day_start

year_now=`date "+%Y"`
month_now=`date "+%m"`
day_now=`date "+%d"`

tmpfile="/tmp/DIMMtmp.txt"

while true
do
	echo "$year-$month-$day"
	
	dimmfile=$MIDILOCAL/obs/DIMM/${year}-${month}-${day}.txt
	
	if [[ ! -f $dimmfile ]]; then
		night1=`date -v${year}y -v${month}m -v${day}d "+%Y-%m-%d"`
		night2=`date -v${year}y -v${month}m -v${day}d -v+1d "+%Y-%m-%d"`
		curl -s --data "night=&stime=$night1&starttime=12&etime=$night2&endtime=12&tab_interval=on&interval=&tab_ra=on&ra=&tab_dec=on&dec=&tab_fwhm=on&fwhm=&tab_airmass=on&airmass=&tab_rfl=on&rfl=&tab_tau=on&tau=&tab_tet=on&tet=&order=-start_date&export=tab&max_rows_returned=100000000" http://archive.eso.org/wdb/wdb/eso/ambient_paranal/query > $tmpfile
		cat $tmpfile | grep \"METEO\" | awk -F " " '{print $1 " " $2 " " $4 " " $5 " " $6 " " $7 " " $8 " " $9 " " $10}' > $dimmfile
		echo "Downloaded and parsed DIMM measurements for $night1 and saved to $dimmfile"
	else
		echo "DIMM measurements file $dimmfile exists for $night1"
	fi

	iyear=`date -v${year}y -v${month}m -v${day}d -v+1d "+%Y"`
	imonth=`date -v${year}y -v${month}m -v${day}d -v+1d "+%m"`
	iday=`date -v${year}y -v${month}m -v${day}d -v+1d "+%d"`
	
	year=$iyear
	month=$imonth
	day=$iday
	
	if [ $year -eq $year_now ] && [ $month -eq $month_now ] && [ $day -eq $day_now ]; then break; fi
done