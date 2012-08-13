@$MIDITOOLS/dr/lpw_phot
;; lpw_phot_visibility
;;
;; PURPOSE: Reduce and calibrate the photometry files belonging to a science fringe track observation
;;          identified by night and time
;;
;;          Note: the identification of photometry files to a fringe track still works with id (for the time being)
;;
;;          DIFFERENCE to lpw_phot: returns calibrated visibilities (.calvis.fits) using photometry files instead of only calibrated correlated fluxes
;;
;;

pro lpw_phot_visibility, night, time, skipexcal=skipexcal, skipexsci=skipexsci
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	f_sci = getphotfiles(night, time)
	;;
	;; photometry A and B exist?
	if f_sci[0] eq '' then begin
		lprint, 'None or only one of A or B phot; skipping'
	endif else begin
		caltime = closestcal(night, time, /verbose, /withphot)
		if caltime ne '-1' then begin
			cd, '$MIDIDATA/'+night, current=current
			caltag = maketag(night, caltime)
			scitag = maketag(night, time)
			srcmask = caltag + '.srcmask.fits'
			skymask = caltag + '.skymask.fits'
			if not (file_test(srcmask) and file_test(skymask)) then lpw, night, caltime, /calonly
			
			if keyword_set(skipexcal) and file_test(caltag+'.photometry.fits') then $
				reducecal = 0 else reducecal = 1
			
			if reducecal then begin
				f_cal = getphotfiles(night, caltime)
				faintphotopipe, caltag, f_cal, mask=srcmask, skymask=skymask
				cmd = 'oirRedCal ' + caltag
				spawn, cmd
			endif else lprint, 'Skipping calibrator photometry reduction: all required files exist'
	
			
			; corr.fits is needed because midicalibrate requires redcal.fits (instrumental visibility)
			; when calling without /nophot option, i.e. there is currently no mode to only calibrate 
			; photometries. redcal in turn requires .photometry.fits (tested above) and .corr.fits
			; since we are not interested in visibilities generated from photometries, I copy here a random .corr.fits and .redcal.fits so that midicalibrate works.
			if not file_test(caltag + '.corr.fits') then lpw, night, caltime, /skipexcal
			if not file_test(caltag + '.redcal.fits') then spawn, 'oirRedCal ' + caltag
	
			if keyword_set(skipexsci) and file_test(scitag+'.photometry.fits') then begin
				lprint, 'Skipping science target photometry reduction: all required files exist'
				reducesci = 0
			endif else reducesci = 1
	
			if reducesci then faintphotopipe, scitag, f_sci, mask=srcmask, skymask=skymask

			if not file_test(scitag + '.corr.fits') then begin
				print, '.corr.fits is missing'
				stop
			endif
			
			if not file_test(scitag + '.redcal.fits') then begin
				spawn, 'oirRedCal scitag'
			endif

			db = vboekelbase()
			midicalibrate, scitag, caltag, caldatabase=db
	
		endif else lprint, 'No suitable calibrator found. Skipping this obs.'
	endelse
end