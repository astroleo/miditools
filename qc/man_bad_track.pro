;;
;; FUNCTION MAN_BAD_TRACK
;;
;; returns 1 if a fringe track observation is reducible and has 
;; a non-zero chance of giving useful results, i.e. something has been tracked
;;
function man_bad_track, night, time, verbose=verbose
	g = 1
	
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	ix = where(db.day eq night and db.time eq time)
	
	if db[ix].dpr ne 'FT' then stop
	
	if db[ix].chopfrq ne 0. then begin
		if keyword_set(verbose) then $
			lprint, night + ' / ' + time + ': Chopped fringe track: Uncalibratable!'
		g = 0
	endif
	
	;; find out if manually excluded
	baddata = read_text_var('$MIDITOOLS/local/obs/baddata_track_man.txt', sep='$')
	ix_bad = where(baddata.night eq night and baddata.time eq time)
	if n_elements(ix_bad) gt 1 then stop
	if ix_bad ne -1 then begin
		if keyword_set(verbose) then $
			lprint, 'Manually excluded from data reduction: ' + night + ' / ' + time + '(' + baddata.comment + ')'
		g = 0
	endif
	return, g
end