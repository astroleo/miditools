;;
;; FUNCTION MAN_GOOD_PHOT
;;
;; returns 1 if a photometry has manually been identified as good, 0 otherwise
;;
;; time is time of fringe track to which this photometry observation was associated
;;
function man_good_phot, night, time_track, verbose=verbose
	g = 0

	;; find out if manually included
	gooddata = read_text_var('$MIDITOOLS/local/obs/gooddata_phot_man.txt', sep='$')
	ix_good = where(gooddata.night eq night and gooddata.time eq time_track)
	if n_elements(ix_good) gt 1 then stop
	if ix_good ne -1 then begin
		if keyword_set(verbose) then $
			lprint, 'Manually included in data reduction: ' + night + ' / ' + time + '(' + gooddata.comment + ')'
		g = 1
	endif
	return, g
end