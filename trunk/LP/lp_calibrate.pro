@$MIDITOOLS/var/realsort
@$MIDITOOLS/LP/lp_undecorr
;;
;; This function returns the average flux at a given wavelength + interval
;; it also estimates the error of this flux by taking into account both
;; the statistical error measured within one observation (given by EWS) and the 
;; uncertainity in the calibration (gain variation)
;;
function lpavgflx, calcorr, calcorrerr, gain_rms_rel, lam, dlam
	c0 = l2c(lam+dlam)
	c1 = l2c(lam)
	c2 = l2c(lam-dlam)
	
	N = float(c2-c0+1)
	avgflx = total(calcorr[c0:c2]) / N
	avgerr = total(calcorrerr[c0:c2]) / N
	avggain_rms_rel = total(gain_rms_rel[c0:c2]) / N
	
	;;
	;; determine factor of decorrelation correction
	;; DEACTIVATED: In EWS 2.0 decorrelation losses are negligible for 12.5 mu fluxes >~ 150 mJy
	;;               -- but take into account for faint fluxes shortwards of 12 mu!
;	f_undecorr = lp_undecorr(lam, avgflx, f_undecorr_rms=f_undecorr_rms)
;	avgflx_undecorr = avgflx * f_undecorr
	;;
	;; calculate total error of averaged correlated flux
	;; error of decorrelation correction factor is assumed to be independent from gain error
	;; DEACTIVATED -- but take into account for faint fluxes shortwards of 12 mu!
;	avgflx_undecorr_err = sqrt(1/N * avgerr^2 + avgflx^2 * (f_undecorr_rms^2 + (f_undecorr * avggain_rms_rel)^2))
	avgflx_err = sqrt(1/N * avgerr^2 + avgflx^2 * avggain_rms_rel^2)

;	return, {avg:avgflx_undecorr, avg_rms:avgflx_undecorr_err}
	return, {avg:avgflx, avg_rms:avgflx_err}
end

function lpavgphase, calphi, calphierr, lam, dlam
	c0 = l2c(lam+dlam)
	c1 = l2c(lam)
	c2 = l2c(lam-dlam)
	
	N = float(c2-c0+1)
	avgphase = float(total(calphi[c0:c2]) / N)
	avgphaseerr = float(total(calphierr[c0:c2]) / N)

	return, {avg:avgphase, avg_rms:avgphaseerr}
end
;;
;; helper FUNCTION gainstat
;;    calculates statistics of gains of a given night (and times of cal observations)
;;
function gainstat, night, times=times
	restore, '$MIDITOOLS/local/obs/gains.sav'
	if keyword_set(times) then begin
		for i=0, n_elements(times)-1 do begin
			oneix = where(gains.night eq night and gains.time eq times[i])
			if n_elements(ix) eq 0 then ix = oneix else ix = [ix, oneix]
		endfor
	endif else ix = where(gains.night eq night and gains.obs_good eq 1)

	if ix[0] eq -1 then gainstat = {avg:-1} else begin
		gain_avg = fltarr(171)
		gain_rms = fltarr(171)

		if n_elements(uniq(realsort(gains[ix].baseline))) gt 1 then lprint, 'Warning: Observations on multiple baselines are used for gain statistics!'
		if n_elements(ix) lt 2 then lprint, 'Warning: Cannot determine gain statistics, only one observation available.'
		
		for i=0, 170 do begin
			gain_avg[i] = avg(gains[ix].gain.corrgain[i])
			gain_rms[i] = rms(gains[ix].gain.corrgain[i])
		endfor
	
		
		gainstat = {avg:gain_avg, rms:gain_rms, ncals:n_elements(ix)}
	endelse
	return, gainstat
end

;;
;; helper FUNCTION gainselect
;;    select the correct calibrators for each science observation, returns 
;;    gainstat to calibrate this observation with
;;
function gainselect, night, time_sci
	restore, '$MIDITOOLS/local/obs/gains.sav'
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	ix_sci = where(db.day eq night and db.time eq time_sci)
	ix_cal_all = where(db.day eq night and db.dpr eq 'FT' and db.catg eq 'CALIB')
	ix_cal     = where(db.day eq night and db.dpr eq 'FT' and db.catg eq 'CALIB' and db.telescope eq db[ix_sci].telescope and db.grism eq db[ix_sci].grism)

	if n_elements(ix_cal) ne n_elements(ix_cal_all) then lprint, 'Selecting ' + strtrim(n_elements(ix_cal),2) + ' out of ' + strtrim(n_elements(ix_cal_all),2) + ' calibrator observations for conversion factor variance determination.'
	
	caltimes = db[ix_cal].time
	
	cal_good = intarr(n_elements(caltimes))
	for i=0, n_elements(caltimes)-1 do begin
		cal_good[i] = obs_good(night,caltimes[i])
	endfor
	
	caltimes = caltimes(where(cal_good eq 1))
	
	return, gainstat(night, times=caltimes)
end

;;
;; PRO LP_CALIBRATE
;;
;; CALIBRATION procedure
;;    (1) calibrate each science observation using the closest calibrator (standard procedure)
;;    (2) estimate the calibration error as the rms of the gain of all cals of the night
;;
;; PURPOSE:
;;    calibrate a *fringe track* observation using a prepared gain.sav file
;;    takes into account both the statistical error (given in the EWS output corr.fits)
;;    and the variations of the gain (counts s^-1 Jy^-1) in the night
;;
;; OPTIONS:
;;    nogain   do not include gain variations in error
;;
;; (FIXME -- modify lp_undecorr to correct spectra, not only averaged fluxes)
;;   --- DEACTIVATED --- currently no decorrelation correction since it is not needed for 12.5 mu fluxes as low as 150 mJy with EWS 2.0 -- but take into account for lower fluxes or shorter wavelengths!
;;
pro lp_calibrate, night, time, tag_sci, source=source, nogain=nogain
	f_sci = tag_sci+'.calcorr.fits'
	if not file_test(f_sci) then stop
	c = oirgetvis(f_sci,w=w)
	calcorr = c.visamp
	calcorrerr = c.visamperr
	calphi = c.visphi
	calphierr = c.visphierr
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	gainfile = '$MIDITOOLS/local/obs/gains.sav'
	restore, gainfile
	; get statistics of gains applicable for this observation
	gainstat = gainselect(night, time)
	if gainstat.avg[0] eq -1 then source = {night:'-1'} else begin
		gain_rms_rel = gainstat.rms/gainstat.avg
			
		if not keyword_set(nogain) then calcorr_rms = sqrt(calcorrerr^2 + calcorr^2 * gain_rms_rel^2) $
			else begin
				calcorr_rms = calcorrerr
				gain_rms_rel = fltarr(n_elements(c.visamp))
			endelse
		
		;;
		;; define wavelengths and intervals for averaging
		;;
		define_lam, z=redshift_from_nighttime(night, time), lam=lam, dlam=dlam

		flx = fltarr(n_elements(lam))
		err = fltarr(n_elements(lam))
		phi = fltarr(n_elements(lam))
		phi_err = fltarr(n_elements(lam))
		for i=0, n_elements(lam)-1 do begin
			a = lpavgflx(calcorr,calcorrerr,gain_rms_rel,lam[i],dlam[i])
			flx[i] = a.avg
			;;
			;; since we expect systematic errors to be >= 5%, we require the relative error of the average to be >= 5%
			if a.avg_rms/a.avg lt 0.05 and not keyword_set(nogain) then begin
				err[i] = 0.05*a.avg
				print, 'formal relative uncertainty of averaged flux < 0.05, setting it to 0.05'
			endif else err[i] = a.avg_rms
			
			p = lpavgphase(calphi,calphierr,lam[i],dlam[i])
			phi[i] = p.avg
			phi_err[i] = p.avg_rms
		endfor
		
		avg = {lam:lam, dlam:dlam, flx:flx, err:err, phi:phi, phi_err:phi_err}
		
		; interpolate everything to PRISM resolution for the moment
		if n_elements(calcorr) ne 171 then begin
			if n_elements(calcorr) ne 261 then stop
			w_grism = w
			restore, '$MIDITOOLS/MIDI/w.sav'
			calcorr = interpol(calcorr,w_grism,w)
			calphi = interpol(calphi,w_grism,w)
			calphierr = interpol(calphierr,w_grism,w)
		endif
		
		ix = where(db.day eq night and db.time eq time)
		source = {night:night, time:db[ix].time, id:db[ix].id, corramp:calcorr, corramperr:calcorr_rms, calphi:calphi, calphierr:calphierr, gain_avg:gainstat.avg, gain_rms:gainstat.rms, avg:avg, bl:db[ix].bl, pa:db[ix].pa, ucoord:c.ucoord, vcoord:c.vcoord, telescope:db[ix].telescope}
	endelse
end