;;
;; given a night and an id, returns file names of respective photometry files, if A and B files exist, else '-1'
;;
function getphotfiles, night, time, ix_A=ix_A, ix_B=ix_B, exists=exists
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	f = ['','']
	exists=0

	; phots are grouped together with track files by 'id'
	ix = where(db.day eq night and db.time eq time)
	id = db[ix].id

	ix_A = where(db.day eq night and db.id eq id and db.dpr eq 'PH' and db.shut eq 'A')
	ix_B = where(db.day eq night and db.id eq id and db.dpr eq 'PH' and db.shut eq 'B')
	
	if ix_A[0] eq -1 or ix_B[0] eq -1 then return, f else begin
		exists = 1
		
		for i=0, n_elements(ix_A)-1 do begin
			f[0] += db[ix_A[i]].f
			if i ne n_elements(ix_A) - 1 then f[0] += ' '
		endfor
		for i=0, n_elements(ix_B)-1 do begin
			f[1] += db[ix_B[i]].f
			if i ne n_elements(ix_B) - 1 then f[1] += ' '
		endfor
		return, f
	endelse
end

;; lpw_phot
;;
;; PURPOSE: Reduce and calibrate the photometry files belonging to a science fringe track observation
;;          identified by night and time
;;
;;          Note: the identification of photometry files to a fringe track still works with id (for the time being)
;;
;; CAVEAT:  Potentially problems with calibration if the fringe could not be reduced (e.g. NGOOD = 0), then redcal cannot be created and photometries will not be calibrated.
;;

pro lpw_phot, night, time, skipexcal=skipexcal, skipexsci=skipexsci
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	f_sci = getphotfiles(night, time)
	;;
	;; photometry A and B exist?
	if f_sci[0] eq '' then begin
		lprint, 'lpw_phot: ' + night + ' / ' + time + ': ' + 'None or only one of A or B phot. Skipping'
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
				midiphotopipe, caltag, f_cal, mask=srcmask, skymask=skymask
				cmd = 'oirRedCal ' + caltag
				spawn, cmd
			endif else lprint, 'lpw_phot: ' + night + ' / ' + time + ': ' + 'Skipping calibrator photometry reduction. All required files exist'
	
			
			; corr.fits is needed because midicalibrate requires redcal.fits (instrumental visibility)
			; when calling without /nophot option, i.e. there is currently no mode to only calibrate 
			; photometries. redcal in turn requires .photometry.fits (tested above) and .corr.fits
			; since we are not interested in visibilities generated from photometries, I copy here a random .corr.fits and .redcal.fits so that midicalibrate works.
			if not file_test(caltag + '.corr.fits') then lpw, night, caltime, /skipexcal
			if not file_test(caltag + '.redcal.fits') then spawn, 'oirRedCal ' + caltag
	
			if keyword_set(skipexsci) and file_test(scitag+'.photometry.fits') then begin
				lprint, 'lpw_phot: ' + night + ' / ' + time + ': ' + 'Skipping science target photometry reduction. All required files exist'
				reducesci = 0
			endif else reducesci = 1
	
			if reducesci then midiphotopipe, scitag, f_sci, mask=srcmask, skymask=skymask

			if not file_test(scitag + '.corr.fits') then begin
				delete_corr_sci = 1
				spawn, 'cp $MIDITOOLS/dr/for_calphot/any.corr.fits ' + scitag + '.corr.fits'
			endif else delete_corr_sci = 0
			
			if not file_test(scitag + '.redcal.fits') then begin
				delete_redcal_sci = 1
				spawn, 'cp $MIDITOOLS/dr/for_calphot/any.redcal.fits ' + scitag + '.redcal.fits'
			endif else delete_redcal_sci = 0

			db = vboekelbase()
			midicalibrate, scitag, caltag, caldatabase=db
	
			;;
			;; re-produce calcorr.fits with direct calibration that has been overwritten by the above statement
			if file_test(caltag+'.corr.fits') and file_test(scitag+'.corr.fits') then $
				midicalibrate, scitag, caltag, caldatabase=db, /nophot
			cd, current

			if delete_corr_sci then spawn, 'rm ' + scitag + '.corr.fits'
			if delete_redcal_sci then spawn, 'rm ' + scitag + '.redcal.fits'

		endif else lprint, 'lpw_phot: ' + night + ' / ' + time + ': ' + 'No suitable calibrator found. Skipping this obs.'
	endelse
end