;; PRO LPw
;;
;; PURPOSE:
;;    reduce and calibrate a correlated flux observation of a weak source, also reduce phot if available
;;    The routine does not require any data of DPR TYPE 'PHOTOMETRY'.
;;
;;    - search nearest calibrator, calculate fringe image, fit mask to that, use this mask for cal and phot (if available)
;;    - reduce that cal using faintvispipe
;;    - reduce fringe track of science object using mask centered on cal
;;    - calibrate
;;
;; REQUIRED INPUTS:
;;    night
;;    time of science observation
;;
;; OPTIONS:
;;   calonly    set this flag if you only want to reduce a calibrator observation (the time then has to refer to this calibrator observation)
;;   skipexcal  skip existing reduced calibrator files
;;   skipexsci  skip existing reduced target files
;;
;;
;; IMPORTANT NOTE:
;;    this routine always reduces the calibrator data together with the science data,
;;    even if it already exists. This is necessary because we do not store the exact
;;    data reduction parameters and an existing cal file could have been reduced
;;    with a different mask or different smooth settings.
;;
pro lpw, night, time, calonly=calonly, skipexcal=skipexcal, skipexsci=skipexsci
	cd, '$MIDIDATA/'+night, current=currentdir
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	ix_sci = where(db.day eq night and db.time eq time)
	if db[ix_sci].dpr ne 'FT' then begin
		lprint, night + ' / ' + time + ': Not a fringe track!'
	endif
	if not keyword_set(calonly) then begin
		if db[ix_sci].catg ne 'SCIENCE' then begin
			lprint, 'lpw: ' + night + ' / ' + time + ': ' + 'Not a science observation!'
			goto, endofprogram
		endif
		time_sci=time
		time_cal = closestcal(night, time_sci, /verbose, bestix=bestix)
		if time_cal[0] eq '-1' then begin
			lprint, 'lpw: ' + night + ' / ' + time + ': ' + 'No calibrator to reduce data with. Skipping this obs.'
			goto, endofprogram
		endif
		scitag = maketag(night, time_sci)
		scifiles = loadf(night, time_sci, /nophot)
	endif else begin
		if db[ix_sci].catg ne 'CALIB' then begin
			lprint, 'lpw: ' + night + ' / ' + time + ': ' + 'Not a calibrator observations! Skipping this obs.'
			goto, endofprogram
		endif
		time_cal=time
		time_sci=time
	endelse
	
	;;
	;; set data reduction parameters if not set
	;;
	sm = 0.18
	gsm = 0.36
	factor = 1.2
	
	ix = where(db.day eq night and db.time eq time_sci)

	caltag = maketag(night, time_cal)
	calfiles = loadf(night, time_cal, /nophot)

	mask = caltag + '.srcmask.fits'	
	;;
	;; test if cal files exist
	;;
	if keyword_set(skipexcal) then begin
		; flag and fringes files are required for quality checks
		types = ['.srcmask.fits','.corr.fits','.flag.fits','.fringes.fits']
		for i=0, n_elements(types)-1 do begin
			if not file_test(caltag + types[i]) then goto, reducecal
		endfor
		lprint, 'lpw: ' + night + ' / ' + time + ': ' + 'Skipping calibrator reduction: all required files exist'
		goto, reducesci
	endif

	;;
	;; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	;;     CALIBRATOR DATA REDUCTION
	;; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	;;
	reducecal: lprint, 'Reducing calibrator observation ' + night + ' ' + time_cal
	if obs_good(night, time_cal) eq 0 then begin
		lprint, 'Data not good: ' + night + ' / ' + time_cal
		goto, reducesci
	endif

	;; detect correct /dave setting (definition changed multiple times in midiUtilities; this reflect status of EWS 2.0-beta (2012Jan25))
	;;
	caltrack = midigetkeyword('DET NRTS MODE',calfiles[0])
	if caltrack eq 'OBS_FRINGE_TRACK_DISPERSED_OFF' or caltrack eq 'OBS_FRINGE_NOTRACK_DISPERSED' then begin
		ave=0
	endif else if caltrack eq 'OBS_FRINGE_TRACK_DISPERSED' then begin
		ave=-1
	endif else begin
		lprint, 'lpw: ' + night + ' / ' + time + ': ' + 'mode not recognized: ' + caltrack
		goto, endofprogram
	endelse
	
	;;
	;; generate mask
	;;
	if not file_test(caltag+'.srcmask.fits') then $
		midiMakeMask, caltag, calfiles, factor=factor
	;;
	;; reduce calibrator fringe data
	;;
	midivispipe, caltag, calfiles, mask=mask, smooth=sm, gsmooth=gsm, /two, ave=ave, minopd=minopd, ierr=ierr
	print, ierr
	if ierr ne 0 then lprint, 'lpw: ierr = ' + ierr
	if ierr eq 12 then begin
		corruptcorrfile = caltag + '.corr.fits'
		spawn, 'rm ' + corruptcorrfile
		lprint, 'lpw: Removed corrupt corr file ' + corruptcorrfile
	endif
	if ierr eq 0 and keyword_set(forcecalmask) then makefringeimage, night, time_sci

	


	;;
	;; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	;;     SCIENCE TARGET DATA REDUCTION
	;; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	;;
	reducesci: redsci=1
	if keyword_set(calonly) then goto, endofprogram
	if obs_good(night, time_sci) eq 0 then begin
		lprint, 'Data not reducible / not calibratable: ' + night + ' / ' + time_sci
		goto, endofprogram
	endif

	
	;;
	;; test if sci files exist
	;;
	if keyword_set(skipexsci) then begin
		; flag and fringes files are required for quality checks
		types = ['.calcorr.fits','.corr.fits','.flag.fits','.fringes.fits','.groupdelay.fits']
		for i=0, n_elements(types)-1 do begin
			if not file_test(scitag + types[i]) then goto, reducesci2
		endfor
		lprint, 'lpw: ' + night + ' / ' + time + ': ' + 'Skipping science reduction: all required files exist'
				
		goto, endofprogram
	endif
	reducesci2: lprint, 'Reducing science target observation ' + night + ' ' + time_sci

	;;
	;; reduce science fringe data
	;;
	; test if we need a shifted mask for the science data
	if not file_test(scitag+'.fringeimages.fits') then forcecalmask=1
	mask_select, night, time_sci, mask=mask, forcecalmask=forcecalmask

	midivispipe, scitag, scifiles, mask=mask, smooth=sm, gsmooth=gsm, /two, ave=ave, ierr=ierr
	if ierr ne 0 then lprint, 'lpw: ierr = ' + ierr
	if ierr eq 12 then begin
		corruptcorrfile = scitag + '.corr.fits'
		spawn, 'rm ' + corruptcorrfile
		lprint, 'lpw: Removed corrupt corr file ' + corruptcorrfile
	endif
	if ierr eq 0 and keyword_set(forcecalmask) then makefringeimage, night, time_sci

	;;
	;; CALIBRATE SCIENCE FRINGE TRACK
	;;
	db = vboekelbase()
	if file_test(scitag+'.corr.fits') and file_test(caltag+'.corr.fits') then begin
		print, scitag+'.corr.fits'
		print, file_test(scitag+'.corr.fits')
		print, caltag+'.corr.fits'
		print, file_test(caltag+'.corr.fits')
		midicalibrate, scitag, caltag, caldatabase=db, /nophot
	endif

	endofprogram: eop=1
	cd, currentdir
	
	if keyword_set(forcecalmask) then begin
		if file_test(scitag+'.fringeimages.fits') then $
			lpw, night, time, /skipexcal $
		else lprint, 'lpw: ' + night + ' / ' + time + ': Science fringe image could not be created. Calibrator mask has not been shifted on science fringe image.'
	endif
end