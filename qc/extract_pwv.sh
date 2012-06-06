#!/bin/bash
#
# searches all .txt files in $MIDILOCAL/obs/PWV for date - PWV lines, resolves date string into day of night begin, outputs all lines

filelist=`ls $MIDILOCAL/obs/PWV/*.txt`

for FILENAME in $filelist; do
	while read LINE
	do
	esodate=`echo $LINE | awk -F " " '{print $1}'`
	day=`$MIDITOOLS/f/whichnight_date.sh $esodate`
	pwv=`echo $LINE | awk -F " " '{print $2}'`
	dpwv=`echo $LINE | awk -F " " '{print $4}'`
	ins=`echo $LINE | awk -F " " '{print $6}'`
	echo $day " " $pwv " " $dpwv " " $ins >> pwv.dat
#	done < 2005.txt
	done < $FILENAME
	echo "Done with " $FILENAME
done