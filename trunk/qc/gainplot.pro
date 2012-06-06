@$IDLTOOLS/plot/lplot
@$MIDITOOLS/dr/tools
@$MIDITOOLS/qc/gain
@$MIDITOOLS/qc/read_dimm
@$MIDITOOLS/qc/obs_good

; purpose: compute statistics for gains of one night
pro gainstat_old, night, gainfile=gainfile, stat=stat
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


; currently only for correlated fluxes

pro gainplot, gainfile=gainfile, night, outdir=outdir
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
	
		filename=night
		
		startplot, dirname=dirname, filename=filename, landscape='p', xsize=18, ysize=25, xoffset=1., yoffset=1.
			!p.multi = [0,1,4]
			corrsym = 4
			badcorrsym = 7
	
			dimm = read_dimm(night)
			; get smoothed values
			tau0 = ambismooth(dimm.t_UT, dimm.tau0, 10)
			seeing = ambismooth(dimm.t_UT, dimm.seeing, 10)
			flux_rms = ambismooth(dimm.t_UT, dimm.flux_rms, 10)
	
			; (1) gains + tau_0
			maxgain = 3000
			maxtau0 = 10
			gain_tau0_factor = maxgain/maxtau0
	
			plot, indgen(100), indgen(100), xr=[-2,12], yr=[0,maxgain], xstyle=1, ystyle=9, xtitle='Hours since midnight UT', ytitle='Correlated flux gain [counts/(s Jy)]', /nodata, charsize=1.5
			yticklabels = [0, 2.5, 5, 7.5, 10]
			ytickv = yticklabels*gain_tau0_factor
			ytickname = ['0.0','2.5','5.0','7.5','10.0']
			axis, yaxis=3, ystyle=1, ytickv=ytickv, ytickname=ytickname, yticks=n_elements(ytickv), ytitle = 'DIMM tau_0 [ms]', charsize=1.5
	
			; plot gains for cals
			if ix_good[0] ne -1 then begin
				plots, gains[ix_good].hh, gains[ix_good].gain8_5_2, psym=corrsym, color=5
				plots, gains[ix_good].hh, gains[ix_good].gain10_5_2, psym=corrsym, color=4
				plots, gains[ix_good].hh, gains[ix_good].gain12_5_2, psym=corrsym, color=3
			endif
			if ix_bad[0] ne -1 then begin
				plots, gains[ix_bad].hh, gains[ix_bad].gain8_5_2, psym=badcorrsym, color=5
				plots, gains[ix_bad].hh, gains[ix_bad].gain10_5_2, psym=badcorrsym, color=4
				plots, gains[ix_bad].hh, gains[ix_bad].gain12_5_2, psym=badcorrsym, color=3
			endif
	
			oplot, tau0.t_UT, tau0.ambi * gain_tau0_factor, psym=3
;			xyouts, gains[ix_all].hh, 100+gains[ix_all].gain8_5_2, gains[ix_all].time, charsize=0.7, alignment=0.5, orientation=90
			xyouts, 5, 3500, night, alignment=0.5
			
			;; read in obs_good, overplot science observations
			ix_night = where(db.day eq night and db.catg eq 'SCIENCE' and db.dpr eq 'FT')
			if ix_night[0] ne -1 then begin
				for i=0, n_elements(ix_night)-1 do begin
					if i mod 2 eq 0 then offset = 0.03 else offset = -0.05
					hh = hhmmss(db[ix_night[i]].time)
					obs_good = obs_good(night, db[ix_night[i]].time)
					if obs_good eq 1 then plots, hh, maxgain*0.8, psym=corrsym, symsize=0.5 else $
						plots, hh, maxgain*0.8, psym=badcorrsym, symsize=0.5
;					xyouts, hh, maxgain*(0.8+offset), db[ix_night[i]].time, charsize=0.35, alignment=0.5, orientation=90
				endfor
			endif
			
			; oplot MACAO tau0
			ix_all_db = where(db.day eq night and db.dpr eq 'FT')
			ix_t01 = where(db[ix_all_db].COU_AO1_T0_MEAN gt 0)
			ix_t02 = where(db[ix_all_db].COU_AO2_T0_MEAN gt 0)
			if ix_t01[0] ne -1 then begin
				ix_t01 = ix_all_db[ix_t01]
				hh_01 = hhmmss(db[ix_t01].time)
				t0mean1_ms = db[ix_t01].COU_AO1_T0_MEAN
				plots, hh_01, gain_tau0_factor/10 * t0mean1_ms, psym=5, color=2
				plots, [-1.5, 2500], psym=6, color=2 & xyouts, -1.3, 2500, 'Telescope 1 MACAO tau0 / 10', charsize=0.7, color=2
			endif else xyouts, -1.3, 2500, 'Telescope 1 MACAO tau0 not available', charsize=0.7
			if ix_t02[0] ne -1 then begin
				ix_t02 = ix_all_db[ix_t02]
				hh_02 = hhmmss(db[ix_t02].time)
				t0mean2_ms = db[ix_t02].COU_AO2_T0_MEAN
				plots, hh_02, gain_tau0_factor/10 * t0mean2_ms, psym=6, color=2
				plots, [-1.5, 2800], psym=5, color=2 & xyouts, -1.3, 2800, 'Telescope 2 MACAO tau0 / 10', charsize=0.7, color=2
			endif else xyouts, -1.3, 2800, 'Telescope 2 MACAO tau0 not available', charsize=0.7

			
			; (2) clouds
			plot, flux_rms.t_UT, flux_rms.ambi, psym=3, xr=[-2, 12], yr=[0,0.05], xstyle=1, ystyle=9, ytitle='DIMM flux rms', charsize=1.5
			yticklabels = [0, 45, 90, 135, 180]
			cloud_dist_factor = 0.05/180
			ytickv = yticklabels*cloud_dist_factor
			ytickname = ['0','45','90','135','180']
			axis, yaxis=3, ystyle=1, ytickv=ytickv, ytickname=ytickname, yticks=n_elements(ytickv), ytitle = 'DIMM-VLTI pointing diff. [deg]', charsize=1.5

			;;
			;; print DIMM-VLTI pointing difference in degree for each observation
			for i=0, n_elements(ix_all)-1 do begin
				dv_diff=dimm_pointing_diff(night,gains[ix_all[i]].time)
				if dv_diff ne -1 then begin
					if n_elements(dimm_vlti_diff) eq 0 then begin
						dimm_vlti_diff = dv_diff
						t_ut = gains[ix_all[i]].hh
					endif else begin
						dimm_vlti_diff = [dimm_vlti_diff,dv_diff]
						t_ut = [t_ut, gains[ix_all[i]].hh]
					endelse
				endif
			endfor
			if n_elements(t_ut) eq 1 then plots, t_ut, dimm_vlti_diff*cloud_dist_factor else $
				oplot, t_ut, dimm_vlti_diff*cloud_dist_factor, psym=1
			
			
	;		plot, flux_rms.t_UT, flux_rms.ambi, psym=3, xr=[-2, 12], yr=[0,0.05], xstyle=1, ystyle=9, ytitle='DIMM flux rms', charsize=1.5
	;		plots, hhmmss(db[ix_all_db].time), 10*db[ix_all_db].INS_PRES1_MEAN, color=3, psym=7
	;		yticklabels = findgen(6)/1000.
	;		ytickv = yticklabels*10
	;		ytickname = strtrim(ytickv,2)
	;		axis, yaxis=3, ystyle=1, ytickv=ytickv, ytickname=ytickname, yticks=n_elements(ytickv), ytitle = '10 * INS PRES1 MEAN [Pa]', charsize=1.5
	;		plots, -1.3, 0.04, psym=7, color=3
	;		xyouts, -1, 0.04, 'pressure'
	
	
			; (3) seeing
			plot, seeing.t_ut, seeing.ambi, psym=3, xr=[-2, 12], yr=[0,3], xstyle=1, ytitle='DIMM seeing [arcsec]', charsize=1.5
	
			; oplot DIMM seeing from header
			ix_seeing = where(db[ix_all_db].seeing gt 0)
			if ix_seeing[0] ne -1 then begin
				ix_seeing = ix_all_db[ix_seeing]
				hh_seeing = hhmmss(db[ix_seeing].time)
				seeing = db[ix_seeing].seeing	
				plots, hh_seeing, seeing, psym=2, color=2
				plots, [-1.5, 2.7], psym=2, color=2 & xyouts, -1.3, 2.7, 'DIMM seeing (header)', charsize=0.7, color=2
			endif
			
	
			; (4) legend, statistical info
			multibl = 0
			bl = gains[ix_all[0]].baseline
	
			xyouts, -2, -1, 'time     cal name     bad?     BL'
			
			; add science obs here
			
			for i=0, n_elements(ix_all)-1 do begin
				xyouts, -2, -1.5-0.25*i, string(gains[ix_all[i]].time, gains[ix_all[i]].name, gains[ix_all[i]].obs_good, gains[ix_all[i]].baseline, format='(A8, A10, A2, A10)')
				if gains[ix_all[i]].baseline ne bl then multibl = 1
			endfor
			
			if ix_night[0] ne -1 then begin
				for j=0, n_elements(ix_night)-1 do begin
					if j le 19 then begin
						x=6
						y=-2.0-0.15*j
						endif else begin
						x=10
						y=-2.0-0.15*(j-20)
					endelse
					obs_good = obs_good(night, db[ix_night[j]].time)
					xyouts, x, y, string(db[ix_night[j]].time, db[ix_night[j]].mcc_name, db[ix_night[j]].telescope, format='(A8, A10, A10)'), charsize=0.5
				endfor
			endif
	
			
			if multibl ne 0 then xyouts, -3, 11.5, '(!) Multiple baselines', charsize=1.5, color=3
			
			; statistics
			if ix_good[0] ne -1 then begin
				gainstat_old, night, gainfile=gainfile, stat=stat
				xyouts, 6, -1, 'lambda        avg gain    gain rms   rms/avg'
				xyouts, 6, -1.25, string('8.5+/-0.2   ', stat.avg_8_5_2, stat.rms_8_5_2, 100*stat.rms_8_5_2/stat.avg_8_5_2, ' %', format = '(A13, f9.2, f9.2, f8.2, A2)'), color=5
				xyouts, 6, -1.5, string('10.5+/-0.2   ', stat.avg_10_5_2, stat.rms_10_5_2, 100*stat.rms_10_5_2/stat.avg_10_5_2, ' %', format = '(A13, f9.2, f9.2, f8.2, A2)'), color=4
				xyouts, 6, -1.75, string('12.5+/-0.2   ', stat.avg_12_5_2, stat.rms_12_5_2, 100*stat.rms_12_5_2/stat.avg_12_5_2, ' %', format = '(A13, f9.2, f9.2, f8.2, A2)'), color=3
			endif
	
			!p.multi = 0
		endplot, dirname=dirname, filename=filename
	endelse
end