;;
;; PRO LPSOURCEW
;;
;; reduce all observations of a weak source
;;
;; required input: sourcename
;;
pro lpsourcew, sourcename, year=year, maxyear=maxyear, ix=ix, reduce=reduce, obstable=obstable
	;;
	;; POLITICAL data selection
	;;
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	if keyword_set(year) and keyword_set(maxyear) then stop
	if keyword_set(year) then $
		ix = where(db.mcc_name eq sourcename and db.dpr eq 'FT' and db.mode ne 'OBS_FRINGE_TRACK_FOURIER' and strmid(db.day,0,4) eq year) $
	else if keyword_set(maxyear) then $
		ix = where(db.mcc_name eq sourcename and db.dpr eq 'FT' and db.mode ne 'OBS_FRINGE_TRACK_FOURIER' and float(strmid(db.day,0,4)) le float(maxyear)) $
	else $
		ix = where(db.mcc_name eq sourcename and db.dpr eq 'FT' and db.mode ne 'OBS_FRINGE_TRACK_FOURIER')
	
	; sort by observing date
	ix = ix[sort(db[ix].mjd_start)]
	
	; for Circinus: all AT data + published UT data
	if sourcename eq 'Circinus' then ix=where(db.mcc_name eq 'Circinus' and db.dpr eq 'FT' and (float(strmid(db.day,0,4)) le 2006 or strmid(db.telescope,0,1) ne 'U'))


	if ix[0] eq -1 then begin
		lprint, 'No fringe track observations for ' + sourcename
		return
	endif
	
	if keyword_set(obstable) then obstable, sourcename

	if keyword_set(reduce) then begin
		for i=0, n_elements(ix)-1 do begin
			datadir = loadf(db[ix[i]].day, '', /dironly)
			if not file_test(datadir) then begin
				lprint, 'lpsourcew: Skipping data reduction for ' + db[ix[i]].day + '. Data directory ' + datadir + ' not found.'
				continue
			endif
			print, i, db[ix[i]].day, db[ix[i]].time, db[ix[i]].TELESCOPE, db[ix[i]].grism, db[ix[i]].beamcombiner, db[ix[i]].mode, $
				format='(I3, "   ", A10, "   ", A8, "   ", A4, "   ", A5, "   ", A9, "   ", A30)'
			if obs_good(db[ix[i]].day, db[ix[i]].time) ne 0 then begin
				lpw, db[ix[i]].day, db[ix[i]].time, /skipexcal, /skipexsci
				lpw_phot, db[ix[i]].day, db[ix[i]].time, /skipexcal, /skipexsci
			endif else print, 'Observation not reducible / not calibratable'
		endfor
	endif
	if keyword_set(reduce) then lprint, 'Finished reducing data for ' + sourcename
end