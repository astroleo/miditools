@$MIDITOOLS/dr/lpw_phot
;;
;; FUNCTION OBS_GOOD + helper functions
;;
;; PURPOSE:
;;    examine the quality of an observation
;;
;;    Tests implemented:
;;    (1) Data Reduction "goodness" (can the data be reduced?, 'red_good')
;;    (2) Manual flagging ('man_good')
;;    (3) Ozone depth for both PRISM and GRISM data
;;        Idea: If the signal is from outside the atmosphere, it should show 
;;        a pronounced ozone feature ('o3' gives fraction of counts in 
;;        ozone feature compared to interpolated continuum)
;;    (4) Seeing ('seeing' is in arcsec)
;;    (5) Tau0 in ms ('tau0')
;;    (6) Number of good frames ('ngood', for correlated flux observations only)
;;        if the number of good frames is lower than a threshold number, the 
;;        observation is considered bad (basically a signal/noise limit)
;;    (7) Clouds ('dimm_rms' in a given time span)
;;    (8) pointing difference between DIMM and VLTI ('dimm_pointing_diff')
;;
;;    calibratability:
;;    (9) distance of closest calibrator in airmass ('cal_dairm') ; forced positive
;;   (10) distance of closest calibrator in degrees ('cal_dist') ; forced positive
;;   (11) distance of closest calibrator in hours ('cal_dt') ; forced positive
;;
;;
;;    The results from all tests are stored in the sav file.
;;
;;    There is a hierarchy in these selection criteria (see obs_good_from_file)
;;
;; OPTIONS:
;;    reason    contains the results of the tests
;;    overwrite   if set, will run tests on reduced files and store result in sav 
;;                 file; if not set, will try to read saved test from sav file
;;
;; RETURN VALUE:
;;    -1    data could not be tested
;;     0    observation is bad
;;     1    observation is good
;;
;;
;; FUNCTION obs_good_from_file
;;
;; runs obsgood tests on reduced files (instead of returning stored values from SAV file)
;;
function obs_good_from_file, night, time, reason=reason, tests=tests, phot=phot
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	ix = where(db.day eq night and db.time eq time)
	if db[ix].dpr ne 'FT' then stop
	;;
	;; initialize tests struct
	tests={red_good:0,man_good:0,o3:-1.,seeing:-1.,tau0:-1.,rmsopd:-1.,$
		ngood:-1,dimm_rms:-1.,dimm_pointing_diff:-1.,cal_dairm:-1.,$
		cal_dist:-1.,cal_dt:-1.}
	;;
	;; initialize phot struct
	;;
	;; red_good: at least one reducible pair
	;; man_good: FIXME
	;; o3: depth of ozone feature
	;;
	tests_ph={red_good:-1,man_good:-1,o3:-1.}
	phot={exists:0,id:'',tests:tests_ph,o:-1,reason:'X'}
	;;
	;;
	;; -------------------------------------------------------------------------
	;; ------------------    I) TESTS    ---------------------------------------
	;; -------------------------------------------------------------------------
	;; Fringe Track tests
	;;	
	;; FT reducible?
	tests.red_good = red_good(night, time)
	;;
	;; FT manually excluded? (read manual exclusion list)
;	baddata = read_text('$MIDITOOLS/local/obs/baddata.txt')
;	ix_bad = where(baddata[0,*] eq night and baddata[1,*] eq time)
;	if ix_bad eq -1 then tests.man_good = 1 else tests.man_good = 0
	tests.man_good=1 ; for the moment -- check if needed at all
	;;
	;; ozone
	tag = maketag(night,time)
	tests.o3 = o3(tag, /corr)
	;;
	;; seeing
	tests.seeing = obs_get_seeing(night, time)
	;;
	;; tau0
	tests.tau0 = obs_get_tau0(night, time)
	;;
	;; ngood, RMSOPD
	flagfile = tag + '.flag.fits'
	if file_test(flagfile) then begin
		cmd = "dfits " + flagfile + " | grep NGOOD | awk -F ' ' '{print $3}'"
		spawn, cmd, a
		tests.ngood = fix(a[0])

		cmd = "dfits " + flagfile + " | grep RMSOPD | awk -F ' ' '{print $3}'"
		spawn, cmd, a
		tests.rmsopd = 1.e6*float(a[0])
	endif
	;;
	;; clouds (within 0.5 hours of observation)
	tests.dimm_rms = obs_get_max_rms(night, time, 0.5)
	;;	
	;; dimm pointing diff
	tests.dimm_pointing_diff = dimm_pointing_diff(night, time)
	;;
	;; -------------------------------------------------------------------------
	;; Photometry tests
	;;	
	;; PH exists?
	ix_ph = where(db.day eq night and db.id eq db[ix].id and db.dpr eq 'PH')

	if n_elements(ix_ph) ge 2 then begin
		phot.exists=1
		phot.o=1
		phot.id = db[ix].id
		;;
		;; Is this photometry reducible? (Yes, if at least one A/B pair is red_good)
		ph=getphotfiles(night,phot.id,ix_A=ix_A,ix_B=ix_B)
		igood_A = 0
		igood_B = 0
		for i=0, n_elements(ix_A)-1 do begin
			if red_good(night,db[ix_A[i]].time) then igood_A += 1
		endfor
		for i=0, n_elements(ix_B)-1 do begin
			if red_good(night,db[ix_B[i]].time) then igood_B += 1
		endfor
		
		if igood_A ge 1 and igood_B ge 1 then phot.tests.red_good = 1 else phot.tests.red_good = 0
		


		phot.tests.o3 = o3(tag)
	
		;; any phot manually excluded?
;		mangood=1
;		for i=0, n_elements(ix_ph)-1 do begin
;			mangood *= red_good(night,db[ix_ph[i]].time) ; returns 0 if any one is bad
;		endfor
		phot.tests.man_good=1
	endif
	;;
	;; -------------------------------------------------------------------------
	;; Calibrator (depends on photometry existence)
	;;
	if phot.exists then cal=closestcal(night,time,/withphot,caltests=caltests) else cal=closestcal(night,time,caltests=caltests)
	tests.cal_dairm=caltests.cal_dairm
	tests.cal_dist=caltests.cal_dist
	tests.cal_dt=caltests.cal_dt

	
	
	;; -------------------------------------------------------------------------
	;; ------------------    II) REJECTION REASON    ---------------------------
	;; -------------------------------------------------------------------------

	;; parameters (for track and photometry)
;	o3_max = 0.75
;	ngood_min = 2000
;	seeing_max = 1.5
;	rms_max = 0.03 ; max rms for cloud check
	RMSOPD_max = 4.5
	
	reason='X'
	o=1


	;; -------------------- FRINGE TRACK ----------------------
	; check if all tests went through
	;	if tests.seeing eq -1 then o=-1 ;; not checking for seeing -- has no effect on data quality (apart from increasing jitter?)
	if tests.red_good ne 1 then begin
		o=0
		reason='R'
	endif
	if tests.man_good ne 1 then begin
		o=0
		reason='M'
	endif
	
	if tests.o3 eq -1 then o=-1
	
	if o ne -1 then begin
		if tests.rmsopd gt RMSOPD_max then begin
			reason='J'
			o=0
		endif
;		endif else if tests.o3 gt o3_max then begin
;			reason='O'
;			o=0
;		endif
	endif
	
	if o eq 1 then reason=''
	
	
	
	;; ----------------------- PHOTOMETRY ------------------------
	if phot.exists then begin
		if phot.tests.red_good ne 1 then begin
			phot.o=0
			phot.reason='R'
		endif
		if phot.tests.man_good ne 1 then begin
			phot.o=0
			phot.reason='M'
		endif
	endif
	
	if phot.tests.o3 gt o3_max then begin
		phot.reason='O'
		phot.o=0
	endif
	
	if phot.tests.o3 eq -1 then begin
		phot.reason='X'
		phot.o=-1
	endif

	if phot.o eq 1 then phot.reason=''

	return, o
end

;;
;; main obs_good function
;;
;; OPTIONS
;; reason    if flagged bad, returns a one-character abbreviation of the reason for being flagged as bad
;; tests     returns a struct with the values of the various tests that are run
;; overwrite   read obs_good information from raw files (not from pre-computed .sav file); replaces any existing information
;;
function obs_good, night, time, reason=reason, tests=tests, phot=phot, overwrite=overwrite
	ogfile='$MIDITOOLS/local/obs/obsgood.sav'
	if not file_test(ogfile) then begin
		o = obs_good_from_file(night,time,reason=reason,tests=tests,phot=phot)
		one = {night:night, time:time, o:o, reason:reason, tests:tests, phot:phot}
		obsgood = one
		save, obsgood, file=ogfile
		return, o
	endif else begin
		restore, ogfile
		ix = where(obsgood.night eq night and obsgood.time eq time)
		if ix ne -1 then begin
			if keyword_set(overwrite) then begin
				ix = where(obsgood.night ne night and obsgood.time ne time)
				obsgood = obsgood[ix]
				save, obsgood, file=ogfile
				return, obs_good(night, time, reason=reason, tests=tests, phot=phot)
			endif
			o = obsgood[ix].o
			reason = obsgood[ix].reason
			tests = obsgood[ix].tests
			phot = obsgood[ix].phot
			return, o
		endif else begin
			o = obs_good_from_file(night,time,reason=reason,tests=tests,phot=phot)
			one = {night:night, time:time, o:o, reason:reason, tests:tests, phot:phot}
			obsgood = [obsgood, one]
			save, obsgood, file=ogfile
			return, o
		endelse
	endelse
end
;;
;;
; create obsgood.sav file containing quality check information for all fringe track observations of all sources of interest
;; 
;; will read obsgood information from an obsgood.sav file if it exists, i.e.
;;    incrementing a large database by calling obsgood_all with all data only
;;    takes slightly longer than doing some more error-prone incremental addition
;;
pro obs_good_all, nights=nights, sourcesfile=sourcesfile, overwrite=overwrite
	if not keyword_set(nights) then begin
		if not keyword_set(sourcesfile) then stop
		sources = read_text(sourcesfile)
		nights = sourcenights(sources)
	endif

	obsgoodfile = '$MIDITOOLS/local/obs/obsgood.sav'
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	
	for i=0, n_elements(nights)-1 do begin
		ix = where(db.day eq nights[i] and db.dpr eq 'FT' and db.mode ne 'OBS_FRINGE_TRACK_FOURIER' and db.beamcombiner eq 'HIGH_SENS' and db.mcc_name ne 'no_match!')
		if ix[0] eq -1 then begin
			lprint, 'Nothing to analyze in ' + nights[i]
			continue
		endif
		for j=0, n_elements(ix)-1 do begin
			o = obs_good(db[ix[j]].day, db[ix[j]].time, tests=tests, reason=reason, phot=phot, overwrite=overwrite)
			print, db[ix[j]].mcc_name, db[ix[j]].day, db[ix[j]].time, db[ix[j]].id, o, reason, tests.ngood, tests.rmsopd, phot.exists, phot.reason, format='(A15, "   ", A10, "   ", A8, "   (", A3, ")   ", I2, "   ", A1, "   ", I5, "   ", f5.2, "      ", I1, "   ", A1)'
		endfor
	endfor
end