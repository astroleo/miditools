;;
;; PRO lprint: prints messages that are seen among the plethora of EWS output
;;
pro lprint, txt
	print, '###'
	print, '### LPIPE MESSAGE: ' + txt
	print, '###'
end