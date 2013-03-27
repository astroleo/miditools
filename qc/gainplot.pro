@$MIDITOOLS/var/lplot
@$MIDITOOLS/qc/o3
@$MIDITOOLS/dr/tools
@$MIDITOOLS/qc/gain
@$MIDITOOLS/qc/read_dimm
@$MIDITOOLS/qc/obs_good
@$MIDITOOLS/LP/lp_calibrate

; purpose: compute statistics for gains of one night
pro gainstat_old, night, gainfile=gainfile, stat=stat, ix=ix
	if not keyword_set(gainfile) then gainfile='$MIDITOOLS/local/obs/gains.sav'
	restore, gainfile
	ix = where(gains.night eq night and gains.obs_good)
	rms_8_5_2 = stddev(gains[ix].gain8_5_2)
	avg_8_5_2 = avg(gains[ix].gain8_5_2)
	rms_10_5_2 = stddev(gains[ix].gain10_5_2)
	avg_10_5_2 = avg(gains[ix].gain10_5_2)
	rms_12_5_2 = stddev(gains[ix].gain12_5_2)
	avg_12_5_2 = avg(gains[ix].gain12_5_2)

	stat = {rms_8_5_2:rms_8_5_2, avg_8_5_2:avg_8_5_2, rms_10_5_2:rms_10_5_2, avg_10_5_2:avg_10_5_2, rms_12_5_2:rms_12_5_2, avg_12_5_2:avg_12_5_2}
end


function datetime2ix, nights, times
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	if n_elements(nights) ne n_elements(times) then stop
	for i=0, n_elements(nights)-1 do begin
		ix1 = where(db.day eq nights[i] and db.time eq times[i])
		if n_elements(dbix) eq 0 then dbix = ix1 else dbix = [dbix, ix1]
	endfor
	return, dbix
end

; currently only for correlated fluxes
;;
;; ATs: set keyword if observing nights was with ATs
;;

pro gainplot, gainfile=gainfile, night, outdir=outdir, ATs=ATs
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	if not keyword_set(gainfile) then gainfile = '$MIDITOOLS/local/obs/gains.sav'
	restore, gainfile

	ix_good = where(gains.night eq night and gains.obs_good eq 1)
	ix_bad = where(gains.night eq night and gains.obs_good eq 0)
	ix_all = where(gains.night eq night)
	if ix_all[0] eq -1 then begin
		lprint, 'Nothing to plot for ' + night
	endif else begin
		if not keyword_set(outdir) then dirname='$MIDILOCAL/obs/gainplots' else dirname = outdir
		if not file_test(dirname) then spawn, 'mkdir ' + dirname
	
		ps_start, filename=dirname+'/'+night+'.ps'
			corrsym = 4
			badcorrsym = 7
	
			; (1) gains + tau_0
			if keyword_set(ATs) then maxgain = 180 else maxgain = 2000
	
			cgplot, indgen(100), indgen(100), xr=[0,12], yr=[0,maxgain], xstyle=1, ystyle=1, ytitle='Conversion factor [counts/(Jy s px)]', /nodata, charsize=1.5, xtitle='Hours since midnight UT'
			
			maxam = 2.5
			gain_am_factor = maxgain/maxam

;			yticklabels = [1.0, 1.25, 1.5, 1.75, 2.0, 2.25, 2.5]
;			airmoffset = 0.7
;			ytickv = (yticklabels - airmoffset) *gain_am_factor
;			ytickname = ['1.00','1.25','1.50','1.75','2.00','2.25', '2.50']
;			cgaxis, yaxis=3, ystyle=1, ytickv=ytickv, ytickname=ytickname, yticks=n_elements(ytickv), ytitle = 'Airmass', charsize=1.5


			; plot gains for cals
			cgplots, gains[ix_good].hh, gains[ix_good].gain8_5_2, psym=corrsym, color='blue', symsize=1.5
			cgplots, gains[ix_good].hh, gains[ix_good].gain10_5_2, psym=corrsym, color='green', symsize=1.5
			cgplots, gains[ix_good].hh, gains[ix_good].gain12_5_2, psym=corrsym, color='red', symsize=1.5
			
			; plot airmass
;			dbix = datetime2ix(gains[ix_good].night, gains[ix_good].time)
;			cgplots, gains[ix_good].hh, (db[dbix].airm-airmoffset) * gain_am_factor, psym=2
				
			;; read in obs_good, overplot science observations
			ix_night = where(db.day eq night and db.catg eq 'SCIENCE' and db.dpr eq 'FT')
			plotsym, 3
			if ix_night[0] ne -1 then begin
				for i=0, n_elements(ix_night)-1 do begin
					hh = hhmmss(db[ix_night[i]].time)
					obs_good = obs_good(night, db[ix_night[i]].time)
					cgplots, hh, maxgain*0.9, psym=8, symsize=1
				endfor
			endif
			
			cgtext, 11.5, 1.8/2 * maxgain, night, align=1., charsize=1.5
			
			; statistics
			if ix_good[0] ne -1 then begin
				gainstat_old, night, gainfile=gainfile, stat=stat, ix=ix
				;
				; get gainstat for first AGN obs of this night
				sourcesfile = '$MIDITOOLS/local/obs/sources_lp_paper_fit.txt'
				sources = read_text(sourcesfile)
				sources = reform(sources[0,*])
				time_sci='-1'
				for i=0, n_elements(sources)-1 do begin
					ix=where(db.day eq night and strmid(db.mode,0,16) eq 'OBS_FRINGE_TRACK' and db.mcc_name eq sources[i])
					if ix[0] ne -1 then begin
						time_sci=db[ix[0]].time
						break
					endif
				endfor
				if time_sci eq '-1' then stop
				
				gainstat=gainselect(night,time_sci)
				if gainstat.avg[0] ne -1 then begin
					; compute avg stat
					avg_8_5_2=midiavgflux(gainstat.avg, 8.5, 0.2)
					rms_8_5_2=midiavgflux(gainstat.rms, 8.5, 0.2)
					avg_10_5_2=midiavgflux(gainstat.avg, 10.5, 0.2)
					rms_10_5_2=midiavgflux(gainstat.rms, 10.5, 0.2)
					avg_12_5_2=midiavgflux(gainstat.avg, 12.5, 0.2)
					rms_12_5_2=midiavgflux(gainstat.rms, 12.5, 0.2)
					
					xyouts, 0, -500, 'lambda      avg gain    gain rms    rms/avg ', charsize=0.75
					cgtext, 0, -650, string(avg_8_5_2, rms_8_5_2, 100*rms_8_5_2/avg_8_5_2, format = '("8.5+/-0.2   ", f9.2, "   ", f9.2, "   ", f8.2, " %")'), color='blue', charsize=0.75
					cgtext, 0, -725, string('10.5+/-0.2   ', avg_10_5_2, rms_10_5_2, 100*rms_10_5_2/avg_10_5_2, ' %', format = '(A13, f9.2, f9.2, f8.2, A2)'), color='green', charsize=0.75
					cgtext, 0, -800, string('12.5+/-0.2   ', avg_12_5_2, rms_12_5_2, 100*rms_12_5_2/avg_12_5_2, ' %', format = '(A13, f9.2, f9.2, f8.2, A2)'), color='red', charsize=0.75
					cgtext, 0, -900, string(gainstat.ncals, format='("Number of calibrators used for this computation: ", I2)'), charsize=0.75
				endif
			endif

	
	ps_end
	endelse
end

; returns log10 of cf at airmass am
function cf_am, am, p
	r = p[0] - p[1] * (am - 1)
	return, r
end

function fit_cf_am, am, gains
	startp = [3.4, 0.1]
	gains_err = 0.05*gains
;	p = mpfitfun('cf_am', am, gains, startp, weights=replicate(1d,n_elements(gains)))
	p = mpfitfun('cf_am', am, gains, gains_err, startp, parinfo=parinfo, /quiet)
	return, p
end

pro amcorrection, night, cf_err_am=cf_err_am, cf_err_noam=cf_err_noam
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	gainfile = '$MIDITOOLS/local/obs/gains.sav'
	restore, gainfile
	ix_good = where(gains.night eq night and gains.obs_good eq 1)
	dbix = datetime2ix(gains[ix_good].night, gains[ix_good].time)
	
	p = fit_cf_am(db[dbix].airm, alog10(gains[ix_good].gain12_5_2))
	
;	cgplot, db[dbix].airm, alog10(gains[ix_good].gain12_5_2), /nodata, ystyle=1, xr=[1.0,3.0],yr=[1.,4.]
;	cgplots, db[dbix].airm, alog10(gains[ix_good].gain12_5_2), psym=1
	
	ampoints = 1+findgen(200)/100
;	cgplot, ampoints, cf_am(ampoints, p), /over
	
	cf_err_am = stddev(gains[ix_good].gain12_5_2)/avg(gains[ix_good].gain12_5_2) ; airmass dependency NOT removed
	cf_err_noam = stddev(gains[ix_good].gain12_5_2 - 10^(cf_am(db[dbix].airm,p)))/avg(gains[ix_good].gain12_5_2) ; no airmass dependency
	
;	print, cf_err_am, format='("Gain variation at 12.5 micron w/o airmass correction:  ", f6.4)'
;	print, cf_err_noam, format='("Gain variation at 12.5 micron with airmass correction:  ", f6.4)'
end

pro amcorr_many, cf_err=cf_err
	sourcesfile = '$MIDITOOLS/local/obs/sources_lp_paper.txt'
	sources = read_text(sourcesfile)
	sources = reform(sources[0,*])
	nights = sourcenights(sources)
	for i=0, n_elements(nights)-1 do begin
		amcorrection, nights[i], cf_err_am=cf_err_am, cf_err_noam=cf_err_noam
		one = {night:nights[i], cf_err_am:cf_err_am, cf_err_noam:cf_err_noam}
		if n_elements(cf_err) eq 0 then cf_err=one else cf_err=[cf_err,one]
	endfor
end