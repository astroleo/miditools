#!/bin/bash
##
## PURPOSE
## Get all missing DIMM ambient condition measurements
##

nights=`ls $MIDILOCAL/obs/HDR/ | grep "^20"`
tmpfile="/tmp/DIMMtmp.txt"
	
for night in $nights; do
	year=`echo $night | awk -F "-" '{print $1}'`
	month=`echo $night | awk -F "-" '{print $2}'`
	day=`echo $night | awk -F "-" '{print $3}'`
	
	dimmfile="$MIDILOCAL/obs/DIMM/$night.txt"
	
	if [[ ! -f $dimmfile ]]; then
		night1=`date -v${year}y -v${month}m -v${day}d -v+1d "+%Y-%m-%d"`
		curl -s --data "night=&stime=$night&starttime=12&etime=$night1&endtime=12&tab_interval=on&interval=&tab_ra=on&ra=&tab_dec=on&dec=&tab_fwhm=on&fwhm=&tab_airmass=on&airmass=&tab_rfl=on&rfl=&tab_tau=on&tau=&tab_tet=on&tet=&order=-start_date&export=tab&max_rows_returned=100000000" http://archive.eso.org/wdb/wdb/eso/ambient_paranal/query > $tmpfile
		cat $tmpfile | grep \"METEO\" | awk -F " " '{print $1 " " $2 " " $4 " " $5 " " $6 " " $7 " " $8 " " $9 " " $10}' > $dimmfile
		echo "Downloaded and parsed DIMM measurements for $night"
	else
		echo "DIMM measurements file exists for $night"
	fi
done