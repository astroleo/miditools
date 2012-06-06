;;
;; function CLOSESTCAL
;;
;; PURPOSE:
;;    return time of cal closest in time, airmass, distance on sky
;;    for a given science observation (identified by night and time)
;;    the cal must have the same OBS MODE (e.g. off-zero tracking) and INS GRISM setting (e.g. PRISM)
;;
;; REQUIRED INPUTS:
;;    night         day of night begin (string), e.g. '2011-04-20'
;;    time          time of science observation (string), e.g. '02:14:34'
;;
;; OPTIONS:
;;    verbose       prints penalty sorting table and additional information
;;    withphot      returns nearest cal that has photometry
;;    caltests      set to a named variable to retrieve the parameters of the closest cal (airmass difference, distance on sky, time difference; all with respect to science observation)
;;    bestix        set to a named variable to retrieve the database index of the closest cal
;;
;; RETURNS:
;;    time of calibrator with smallest penalty value
;;
;; REQUIREMENTS:
;;    observation database
;;
function closestcal, night, time, verbose=verbose, withphot=withphot, caltests=caltests, bestix=bestix
	caltests = {cal_dairm:-1.,cal_dist:-1.,cal_dt:-1.}
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	;;
	;; penalty parameters
	;;
	;; NOTE: the parameters settings below almost always pick the calibrator nearest in time
	;;
	;; see http://nexsci.caltech.edu/software/V2calib/wbCalib/index.html for Keck use of
	;;    temporal and sky proximity weighting
	;;
	baddt = 1.                  ;; penalty for 1 hour time difference (FIXED, other penalties are relative to that)
	baddt_days = baddt * 24.
	badam = 0.                  ;; penalty for airmass difference of unity
	baddist_deg = 0.067         ;; penalty for 1 degree angular difference

	s_ix = where(db.day eq night and db.time eq time)
	s_mjd = db[s_ix].mjd_start
	s_am = db[s_ix].airm
	s_ra = db[s_ix].ra
	s_dec = db[s_ix].dec
	s_mode = db[s_ix].mode
	s_grism = db[s_ix].grism
	s_baseline = db[s_ix].telescope
	
	c_ix = where(db.day eq night and db.id ne '-1' and db.dpr eq 'FT' and db.catg eq 'CALIB' and db.telescope eq s_baseline and db.mode eq s_mode and db.grism eq s_grism and db.mcc_name ne 'no_match!')

	if c_ix[0] eq -1 then begin
		if keyword_set(verbose) then print, 'No suitable calibrator observation found'
		return, '-1'
	endif else begin
		;;
		;; compute their airmass and angular distances from the science observation
		dt_days = db[c_ix].mjd_start - s_mjd
		dam = db[c_ix].airm - s_am
		dist_deg = sqrt(((db[c_ix].ra - s_ra) * cos(db[c_ix].dec * !pi/180.))^2 + (db[c_ix].dec - s_dec)^2)
		dist_deg = min([[dist_deg],[abs(dist_deg-360)]],dimension=2)
		;;
		;; compute penalty function
		penalty = abs(dt_days) * baddt_days + abs(dam) * badam + dist_deg * baddist_deg
		penalty_sort_ix = sort(penalty)
		ncals = n_elements(penalty_sort_ix)
		c_ix = c_ix[penalty_sort_ix]		; sort the list of cals by penalty
		penalty = penalty[penalty_sort_ix]
		; find out if any of these cal observations are flagged as 'bad'
		redgood = intarr(n_elements(c_ix))

		for i=0, n_elements(c_ix)-1 do begin
			o = obs_good(night, db[c_ix[i]].time)
			if o eq 0 then redgood[i] = 0 else redgood[i] = 1
		endfor
		; find out which of them have photometry
		havephot = intarr(n_elements(c_ix))
		for i=0, n_elements(c_ix)-1 do begin
			ix_a = where(db.day eq night and db.id eq db[c_ix[i]].id and db.dpr eq 'PH' and db.shut eq 'A')
			ix_b = where(db.day eq night and db.id eq db[c_ix[i]].id and db.dpr eq 'PH' and db.shut eq 'B')
			havephot[i] = (ix_a ne -1 and ix_b ne -1)
		endfor
		; add 1 to c_ix, otherwise some element is always 0, i.e. 'bad'
		if keyword_set(withphot) then ix0 = (1 + c_ix) * redgood * havephot $
			else ix0 = (1 + c_ix) * redgood
		ix0_good = where(ix0 ne 0)
		if ix0_good[0] eq -1 then begin
			if keyword_set(verbose) then lprint, 'No suitable good calibrator observation found'
			return, '-1'
		endif
		ix1 = ix0[ix0_good] - 1 ; = database index list of good / valid cal fringe tracks, sorted by penalty
		bestix = ix1[0]

		if bestix eq -1 then begin
			if keyword_set(verbose) then lprint, 'No suitable good calibrator observation found'
			return, '-1'
		endif

		; if the one that we're going to use is not the nearest one, print, warning
		if bestix ne c_ix[0] and keyword_set(verbose) then lprint, 'Not using nearest cal'
		besttime = db[bestix].time
		bestid = db[bestix].id
		bestname = db[bestix].mcc_name
		bestam_diff = s_am - db[bestix].airm

		if keyword_set(verbose) then begin
			;;
			;; print list of best cals
			print, 'For science source ' + db[s_ix].mcc_name + ' (' + db[s_ix].day + ' / ' + db[s_ix].id + ' / ' + db[s_ix].grism + ' / ' + db[s_ix].beamcombiner + ') at'
			print, '     RA = ' + strtrim(db[s_ix].RA,2)
			print, '    DEC = ' + strtrim(db[s_ix].DEC,2)
			print, 'airmass = ' + strtrim(db[s_ix].airm,2)
			print, 'the closest calibrators are:'
			print, '     name    id        time   dt/hours    dairm    dist/deg   penalty   phot?   reducible?'
			for i=0, n_elements(c_ix)-1 do begin
					ii = c_ix[i]
					print, db[ii].mcc_name, db[ii].id, db[ii].time, 24*dt_days[penalty_sort_ix[i]], dam[penalty_sort_ix[i]], $
					dist_deg[penalty_sort_ix[i]], penalty[i], havephot[i], redgood[i], $
					format = '(A9,"   ",A3,"   ",A8,"   ",F6.2,"      ",F6.2,"    ",F6.2,"    ",F5.2,"      ",I1,"       ",I1)'
			endfor
			print, ''
			print, 'Best cal is ' + bestid  + ' (' + bestname + ')'
		endif
		;;
		;; per default do not use calibrators with airmass difference larger than dam_max
		dam_max=0.3
		if keyword_set(verbose) and abs(bestam_diff) gt dam_max then begin
			lprint, 'Nearest useable calibrator has abs(airmass difference [sci-cal]) of '+ strtrim(abs(bestam_diff),2)+' (greater than max=' + strtrim(dam_max,2) + ').'
		endif
		
		; best calibrator parameters (should be simplified / unified with above some time...)
		dt_days = db[bestix].mjd_start - s_mjd
		dist_deg = sqrt(((db[bestix].ra - s_ra) * cos(db[bestix].dec * !pi/180.))^2 + (db[bestix].dec - s_dec)^2)
		dist_deg = min([[dist_deg],[abs(dist_deg-360)]],dimension=2)
		caltests = {cal_dairm:abs(bestam_diff),cal_dist:abs(dist_deg),cal_dt:abs(dt_days*24.)}
		
		return, besttime
	endelse
end