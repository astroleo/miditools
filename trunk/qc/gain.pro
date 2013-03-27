@$MIDITOOLS/cal/mcc_match
@$MIDITOOLS/qc/obs_good
;;
;; FUNCTION GAIN
;;
;; PURPOSE:
;;    determine (raw) corr + phot gain of one calibrator star (NOT taking airmass fluctuations within the night into account)
;;
;; PARAMETERS:
;;    night    e.g. '2010-05-31'
;;    caltime   e.g. '01:02:03'
;;
;; OPTIONAL PARAMETERS:
;;    reddir    the directory where the reduced data are
;;    nophot    only determine correlated flux gain
;;
function gain, night, caltime, reddir=reddir, nophot=nophot
	;;
	;; check if reduced files exist
	ctag = maketag(night, caltime, reddir=reddir)
	cfile = ctag + '.corr.fits'
	if not keyword_set(nophot) then begin
		pfile = ctag + '.photometry.fits'
		photometry = oirgetdata(pfile)
		photometry = photometry[5].data1
	endif
	
	if file_test(cfile) then begin
		corr = oirgetvis(cfile,w=w)
		correrr = corr.visamperr
		corr = corr.visamp
		
		; interpolate gain to PRISM resolution
		if n_elements(corr) eq 261 then begin
			w_grism = w
			restore, '$MIDITOOLS/MIDI/w.sav'
			corr = interpol(corr,w_grism,w)
			correrr = interpol(correrr,w_grism,w)
		endif
		
		;;
		;; get true cal spec and size
		restore, '$MIDITOOLS/local/obs/obs_db.sav'
		ix_cal = where(db.day eq night and db.time eq caltime)
		ra = db[ix_cal].ra
		dec = db[ix_cal].dec
;		cd, '$MIDITOOLS/mcc_match', current=current
		p = match_with_mcc(ra,dec)
;		cd, current
		calspec = interpol(p.specfnu,p.speclam,w)
		;;
		;; correct for visibility of cal
		realvis = calibrator_visibility(w,p.theta,db[ix_cal].bl)
		corrgain = corr / (calspec * realvis)
		corrgainerr = correrr / (calspec * realvis)
		
		;;
		;; store photometry data and instrumental visibility
		if not keyword_set(nophot) then begin
			ivis = corr / photometry
			photgain = photometry / calspec
		endif
	endif else stop
		;;
		;; store all into struct
		if not keyword_set(nophot) then $
			return, {corrgain:corrgain, corrgainerr:corrgainerr, phot:photometry, photgain:photgain, ivis:ivis, realvis:realvis} $
		else return, {corrgain:corrgain, corrgainerr:corrgainerr, realvis:realvis}
end

;;
;; returns database index of all suitable (*) calibrator datasets for specified night
;; (*) see where statement...
;;
function getcalix, night
	dbfile = '$MIDITOOLS/local/obs/obs_db.sav'
	restore, dbfile
;	if night eq '2005-02-28' or night eq '2005-05-26' then begin
;		c_ix = where(db.day eq night and db.catg eq 'CALIB' and db.dpr eq 'FT' and db.beamcombiner eq 'HIGH_SENS' and db.grism eq 'PRISM' and db.mode eq 'OBS_FRINGE_TRACK_DISPERSED')
;		lprint, 'Only selecting calibrators with DET NRTS MODE = OBS_FRINGE_TRACK_DISPERSED'
;	endif else begin
		c_ix = where(db.day eq night and db.catg eq 'CALIB' and db.dpr eq 'FT' and db.beamcombiner eq 'HIGH_SENS' and db.mode ne 'OBS_FRINGE_TRACK_FOURIER'); and db.grism eq 'PRISM')
;		lprint, 'Only selecting calibrators with DET NRTS MODE = OBS_FRINGE_TRACK_DISPERSED_OFF'
;	endelse
	return, c_ix
end

pro gain_reduce, nights=nights, nightfile=nightfile
	dbfile = '$MIDITOOLS/local/obs/obs_db.sav'
	restore, dbfile
	
	if keyword_set(nightfile) then nights = readnightfile(nightfile)
	if n_elements(nights) eq 0 then stop

	for i=0, n_elements(nights) -1 do begin
		c_ix = getcalix(nights[i])
		if c_ix[0] eq -1 then continue
		for j=0, n_elements(c_ix) - 1 do begin
			if db[c_ix[j]].mcc_name ne 'no_match!' and obs_good(db[c_ix[j]].day, db[c_ix[j]].time) ne 0 then lpw, nights[i], db[c_ix[j]].time, /calonly, /skipexcal
		endfor
		print, 'done with ' + nights[i]
	endfor
end

;;
;; PRO gain_airm_fit
;;
;; PURPOSE:
;;    fit a linear function to a number of log(gain) vs. airmass values
;;
function line, airmass, params
	return, params[0] + params[1] * airmass
end

pro gain_airm_fit, gains, params=params, ps=ps
	params=mpfitfun('line', gains.airmass, alog10(gains.gain12_5_2), 1.+fltarr(n_elements(gains.airmass)), [3.,0.], /quiet)
	if keyword_set(ps) then ps_start, filename='$MIDILOCAL/obs/gain_airmass/'+gains[0].night+'.ps'
	cgplot, gains.airmass, alog10(gains.gain12_5_2), psym=1, xr=[1.0,3.0],yr=[0.,4.]
	ams=1+findgen(200)/100.
	cgplot, /over, ams, line(ams, params)
	cgtext, 1.5, 1.0, gains[0].night, charsize=2
	if keyword_set(ps) then ps_end
end

;;
;; PRO gainstruct
;;
;; PURPOSE:
;;    collect gains for all nights listed in nightfile
;;		determine if cal obs are good (obs_good)
;;		determine averaged gains in a number of wavelength bins
;;      fit linear function to log(gain) vs airmass and take this fit out
;;		store in gainfile
;;
;;

pro gainstruct, nophot=nophot, nights=nights
	if not keyword_set(nophot) then begin
		print, 'Do I really want to run without /nophot? (then remove this line)'
		return
	endif
	gainfile='$MIDITOOLS/local/obs/gains.sav'
	dbfile = '$MIDITOOLS/local/obs/obs_db.sav'
	restore, dbfile
	
	if not keyword_set(nights) then begin
		sourcesfile = '$MIDITOOLS/local/obs/sources_lp_paper_fit.txt'
		sources = read_text(sourcesfile)
		sources = reform(sources[0,*])
		nights = sourcenights(sources)
	endif
	;;
	k=0
	for i=0, n_elements(nights) -1 do begin
		;;
		;; removed gain entries of this night if they exist (to be replaced by new values)
		;;
		if file_test(gainfile) then begin
			restore, gainfile
			ix = where(gains.night eq nights[i])
			if ix[0] ne -1 then begin
				ix_other = where(gains.night ne nights[i])
				if ix_other[0] ne -1 then begin
					gains = gains[ix_other] ; select only those that are not of this night
					save, gains, filename=gainfile
					lprint, 'Removed ' + string(n_elements(ix)) + ' entries of ' + nights[i]
				endif else stop
			endif
		endif

		c_ix = getcalix(nights[i])
		if c_ix[0] eq -1 then begin
			lprint, 'Skipping ' + nights[i] + ' (no data)'
			continue
		endif
		for j=0, n_elements(c_ix) - 1 do begin
			ctag = maketag(nights[i], db[c_ix[j]].time)
			;
			cfile = ctag + '.corr.fits'
			pfile = ctag + '.photometry.fits'
			;
			if not keyword_set(nophot) then if not file_test(pfile) then stop
			if db[c_ix[j]].mcc_name ne 'no_match!' and file_test(cfile) then begin
				gain = gain(nights[i],db[c_ix[j]].time,nophot=nophot)
				
				g = obs_good(nights[i], db[c_ix[j]].time)

				hh = hhmmss(db[c_ix[j]].time)
				;;
				;; determine average gains for a number of wavelengths
				gain8_5_2 = midiavgflux(gain.corrgain, 8.5, 0.2)
				gain10_5_2 = midiavgflux(gain.corrgain, 10.5, 0.2)
				gain12_5_2 = midiavgflux(gain.corrgain, 12.5, 0.2)
		
				onegain = {night:nights[i], id:db[c_ix[j]].id, time:db[c_ix[j]].time, mjd_start:db[c_ix[j]].mjd_start, airmass:db[c_ix[j]].airm, hh:hh, name:db[c_ix[j]].mcc_name, baseline:db[c_ix[j]].telescope, gain:gain, gain8_5_2:gain8_5_2, gain10_5_2:gain10_5_2, gain12_5_2:gain12_5_2, dgain12_5_2:-1., obs_good:g}
				if n_elements(gains) eq 0 then gains = onegain else gains = [gains, onegain]
				print, 'done with ' + db[c_ix[j]].time + ' (goodness is ' + string(g) + ')'
			endif else begin
				print, 'Skipped ' + nights[i] + ' / ' + db[c_ix[j]].time
				k++
			endelse
		endfor
		print, 'done with ' + nights[i]
		ix_night=where(gains.night eq nights[i] and gains.obs_good eq 1)
		if n_elements(ix_night) ge 3 then begin
			;
			; determine gain(airmass) function as a function of wavelength
			gain_airm_fit, gains[ix_night], params=params, /ps
			;
			; for each gain of this night, calculate dgain = gain_raw - gain(airmass) and store in struct
			for j=0, n_elements(ix_night) - 1 do begin
				gains[ix_night[j]].dgain12_5_2 = gains[ix_night[j]].gain12_5_2 - line(gains[ix_night[j]].airmass, params)
			end
		endif
		;
		save, gains, filename=gainfile
	endfor
	wait, 1
	print, 'Skipped ' + strtrim(k,2) + ' calibs (no match in cal database or no corr or no phot measurement or data not reduced)'
end