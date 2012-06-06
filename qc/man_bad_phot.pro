;;
;; FUNCTION MAN_BAD_PHOT
;;
;; returns 0 if a photometry has manually been identified as bad, 1 otherwise
;;
;; time is time of fringe track to which this photometry observation was associated
;;
function man_bad_phot, night, time_track, verbose=verbose
	g = 1

	;; find out if manually excluded
	baddata = read_text_var('$MIDITOOLS/local/obs/baddata_phot_man.txt', sep='$')
	ix_bad = where(baddata.night eq night and baddata.time eq time_track)
	if n_elements(ix_bad) gt 1 then stop
	if ix_bad ne -1 then begin
		if keyword_set(verbose) then $
			lprint, 'Manually excluded from data reduction: ' + night + ' / ' + time + '(' + baddata.comment + ')'
		g = 0
	endif
	return, g
end