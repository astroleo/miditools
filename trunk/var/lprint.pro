;;
;; PRO lprint: prints messages that are seen among the plethora of EWS output
;;             writes log message to file
;;
pro lprint, txt
	print, '###'
	print, '### LPIPE MESSAGE: ' + txt
	print, '###'
	logfile = '$MIDILOCAL/lpipe.log'
	openu, lun, logfile, /get_lun, /append
	printf, lun, systime() + '   ' + string(txt)
	close, /all
end