@$MIDITOOLS/qc/obs_good
;;
;; PRO qc_track
;;
;; plot fringe images for sci + cal and photometries (if available) together with contours of used src/skymask
;;
;; limitation: if only some photometry files exist, will skip photometry plots alltogether.

pro qc_track, night, time_sci, dirname=dirname, gsmooth=gsmooth, overwrite=overwrite
	if not keyword_set(dirname) then dirname = '$MIDILOCAL/obs/fringeimages'
	if not keyword_set(gsmooth) then gsmooth=20
	scitag = maketag(night,time_sci)
	sci_corr_file = scitag + '.corr.fits'
	sci_calcorr_file = scitag + '.calcorr.fits'
	sci_ab_file = scitag + '.fringeimages.fits'
	sci_gd_file = scitag + '.groupdelay.fits'
	sci_fringe_file = scitag + '.fringes.fits'
	sci_flag_file = scitag + '.flag.fits'
	sci_pdelay_file = scitag + '.powerdelay.fits'

	time_cal = closestcal(night, time_sci)
	if time_cal[0] ne -1 then begin
		caltag = maketag(night,time_cal)
		cal_corr_file = caltag + '.corr.fits'
		cal_ab_file = caltag + '.fringeimages.fits'
		skymask = caltag + '.skymask.fits'
		srcmask = caltag + '.srcmask.fits'
		mask_select, night, time_sci, mask=srcmask_sci
		if srcmask_sci ne srcmask then mask_is_shifted = 1 else mask_is_shifted = 0
		
		restore, '$MIDITOOLS/local/obs/obs_db.sav'
		ix_sci = where(db.day eq night and db.time eq time_sci)

		outfiledir='$MIDILOCAL/obs/QC/'+db[ix_sci[0]].mcc_name
		if not file_test(outfiledir) then spawn, 'mkdir ' + outfiledir
		outfilename=outfiledir+'/'+night+'_'+ repstr(time_sci,':','') + '.QC_track.ps'
		outfilename_png=outfiledir+'/'+night+'_'+ repstr(time_sci,':','') + '.QC_track.png'
		if file_test(outfilename_png) and not keyword_set(overwrite) then begin
			print, outfilename_png + ' exists. Returning...'
		endif else if not (file_test(sci_corr_file) and file_test(sci_calcorr_file) and file_test(sci_ab_file) and file_test(sci_gd_file) and file_test(sci_fringe_file) and file_test(sci_flag_file) and file_test(sci_pdelay_file) and file_test(cal_corr_file) and file_test(cal_ab_file) and file_test(skymask) and file_test(srcmask) and file_test(srcmask_sci)) then begin
			print, file_test(sci_corr_file), file_test(sci_calcorr_file), file_test(sci_ab_file), file_test(sci_gd_file), file_test(sci_fringe_file), file_test(sci_flag_file), file_test(sci_pdelay_file), file_test(cal_corr_file), file_test(cal_ab_file), file_test(skymask), file_test(srcmask), file_test(srcmask_sci)
			;; fringe files are missing
			lprint, night + ' / ' + time_sci + ': Some files and / or masks are missing; not producing any output.'
		endif else begin
			ix_cal = where(db.day eq night and db.time eq time_cal)
			
			;;
			;; DATA1 is shifted by 1 pixel w.r.t. DATA2
			srcmask = oirgetdata(srcmask)
			srcmask_fi = (srcmask.data1 + shift(srcmask.data2, [0,-1]))/2

			if mask_is_shifted then begin
				srcmask_sci = oirgetdata(srcmask_sci)
				srcmask_fi_sci = (srcmask_sci.data1 + shift(srcmask_sci.data2, [0,-1]))/2
			endif else begin
				srcmask_sci = srcmask
				srcmask_fi_sci = srcmask_fi
			endelse
	
			sci_ab = oirgetdata(sci_ab_file)
			sci_d1 = transpose(pseudocomplex(sci_ab.data1))
			sci_d2 = transpose(pseudocomplex(sci_ab.data2))
			sci_fi = float(sci_d1-shift(sci_d2,[0,-1]))
	
			cal_ab = oirgetdata(cal_ab_file)
			cal_d1 = transpose(pseudocomplex(cal_ab.data1))
			cal_d2 = transpose(pseudocomplex(cal_ab.data2))
			cal_fi = float(cal_d1-shift(cal_d2,[0,-1]))
			
			gd1 = oirgetdata(sci_gd_file) ;; contains the direct Fourier transforms of each frame
			gd2 = pseudocomplex(gd1.data1)
			gd2s = csmooth2(gd2,20)
			nframes = n_elements(gd2s[*,0])
			
			; obs good
			cal_obsgood = obs_good(night, time_cal, ngood=ngood_cal)
			sci_obsgood = obs_good(night, time_sci, ngood=ngood_sci)
			if cal_obsgood eq 1 then cal_good='good' else if cal_obsgood eq 0 then cal_good='bad' else cal_good='unknown'
			if sci_obsgood eq 1 then sci_good='good' else if sci_obsgood eq 0 then sci_good='bad' else sci_good='unknown'
	
			; raw counts
			cc = oirgetvis(cal_corr_file,w=w)
			sc = oirgetvis(sci_corr_file)
			cal_cts8 = round(average_vis(cc.visamp, 8.5, 0.2))
			cal_cts12 = round(average_vis(cc.visamp, 12.5, 0.2))
			sci_cts8 = round(average_vis(sc.visamp, 8.5, 0.2))
			sci_cts12 = round(average_vis(sc.visamp, 12.5, 0.2))
			
			; hard code maximum counts / flux per source
			if strmid(db[ix_sci[0]].telescope,0,1) eq 'U' then begin
				case db[ix_sci[0]].mcc_name of
					'Circinus': flux_max = 10.
					'NGC1068': flux_max = 10.
					'IC4329A': flux_max = 1.5
					'NGC5506': flux_max = 1.0
					'NGC1365': flux_max = 0.8
					'NGC5128': flux_max = 1.5
					'HD135344b': flux_max = 2.0
					else: flux_max = 0.6
				endcase
				counts_max = 1000. * flux_max
			endif else begin
				;; AT observations
				flux_max = 10.
				counts_max = 100. * flux_max
			endelse
			
			if db[ix_sci[0]].grism eq 'GRISM' then counts_max = 50. * flux_max
			
			; calibrated spectrum
			calspec = oirgetvis(sci_calcorr_file)
			
			; obs params
			grism = strtrim(db[ix_sci[0]].grism,2)
			
			; shift of sci fringe image w.r.t. cal mask
			yshifts = shifttest(night,time_sci)
			
			sci_txt = db[ix_sci[0]].mcc_name + ' in the night of ' + db[ix_sci[0]].day + ' at ' + time_sci + ' -- quality is ' + sci_good + ' -- number of good frames is ' + string(ngood_sci,format=I6)
			cal_txt = db[ix_cal[0]].mcc_name + ' in the night of ' + db[ix_cal[0]].day + ' at ' + time_cal + ' -- quality is ' + cal_good + ' -- number of good frames is ' + string(ngood_cal,format=I6)
			
			ps_start, filename=outfilename, xoffset=-1., yoffset=1., xsize=6., ysize=10., font_size=12; pagetype='A4'
				;;	
				;!P.Multi(0)	Contains the number of plots remaining on the page. Start with this as 0 to clear the page.
				;!P.Multi(1)	The number of plot columns on the page.
				;!P.Multi(2)	The number of plot rows on the page.
				;!P.Multi(3)	The number of plots stacked in the Z direction.
				;!P.Multi(4)	If 0, plots are displayed from left to right and top to bottom, i.e., the plots are displayed in rows. If 1, plots are displayed from top to bottom and from left to right, (i.e., the plots are displayed in columns).
				;;
				!p.multi = [0,1,5,0,0]
				cgLoadCT, 0
				
				; .groupdelay image
				; multimargin=[bottom, left, top, right] 
				cgimage, abs(gd2s), /axes, multimargin=[4,4,4,6], minvalue=0, maxvalue=20000, xtitle='frames'
				
				; plot time axis after we know time and frame conversion (below)
;				cgtext, 0.05, 0.98, 'abs(tag.groupdelay.fits), gsmooth = ' + strtrim(gsmooth,2), /normal, alignment = 0., charsize=0.7
				cgtext, 0.99, 0.98, db[ix_sci[0]].mcc_name, alignment=1.0, charsize=1.2, /normal
				
				;;
				;; More plotting commands to overplot found groupdelay + tracking delay + ... (partly code from Walter's midiDelayPlot)
				;;
					twopass=1
					OPD0=1.e6*double(midigetkeyword('OPD0',sci_gd_file,extna='IMAGING_DATA'))
					OPD1=1.e6*double(midigetkeyword('OPD1',sci_gd_file,extna='IMAGING_DATA'))
					OPD2=1.e6*double(midigetkeyword('OPD2',sci_gd_file,extna='IMAGING_DATA'))
					minopd=OPD0-OPD1
					maxopd=OPD0+OPD1
					cgaxis, yaxis=1, yrange=[minopd/1000.,maxopd/1000.], title='delay [mm]', ystyle=1
					datatime = oirGetData(sci_fringe_file,col='time')
					datatime = REFORM(datatime.time) ; time of each frame in mjd 
					startTime= datatime[0]
					dtime    = 86400*(datatime-startTime) ; seconds from beginning
				
					delay     = oirGetDelay(sci_gd_file)
					delaytime = REFORM(delay.time)&
					delaytime = 86400*(delaytime-startTime) ; seconds relative to datastart 
					flagdata  = oirGetFlag(sci_flag_file)
					nFlag     = N_ELEMENTS(flagdata)
					flagdata.timerang = 86400*(flagdata.timerang-startTime)
				
					opd   = oirGetOpd(sci_fringe_file)
					delay = REFORM(delay.delay)
					delay = INTERPOL(delay, delaytime, dtime) ; delay at each frame
					if (TOTAL(opd EQ 0.) GT 0 ) then $
						delay(where(opd EQ 0.0)) = median(reform(delay)); bad points
					if (KEYWORD_SET(twopass)) then begin
						delay2 = oirgetdelay(sci_pdelay_file)
						delay2 = REFORM(delay2.delay)
						if (TOTAL(opd EQ 0.) GT 0 ) then begin
							delay2(where(opd EQ 0.0)) = median(delay2); bad points
						endif
					endif
					if (TOTAL(opd EQ 0.) GT 0 ) then $
						opd(where(opd EQ 0.0)) = median(opd)  ; bad points
					ndelay = N_ELEMENTS(opd)
					topd   = where(dtime gt 15.)
					maxopd = max(opd)
					minopd = min(opd[topd])
					if (KEYWORD_SET(twopass)) then begin
						maxopd = max(maxopd>delay2)
						minopd = min(minopd<delay2[topd])
					endif
				;   plot,dtime, opd,yrange=[minopd,maxopd]+200*[-1,1], $
				
					;;				
					;; plot time axis only here because only here we know time-frame conversion
					duration = 86400*(datatime[n_elements(datatime)-1] - datatime[0])
					cgaxis, xaxis=1, xrange=[0,duration], title='time [s]', xstyle=1
					
;					frametimes = findgen(n_elements(dtime)) * duration/n_elements(dtime)

					tscale=n_elements(dtime)/duration
					
					fscale=interpol(findgen(n_elements(dtime)),dtime,findgen(n_elements(dtime)))
					pxoffset=-40
				
					cgplot,findgen(n_elements(opd)), pxoffset+1/abs(opd2) * (-(opd-opd0)+opd1), /overplot, color="blue"
					if (KEYWORD_SET(twopass)) then begin
						cgplot,findgen(n_elements(opd)),pxoffset+1/abs(opd2) * (-(delay2-opd0)+opd1), color = "green", /overplot, thick=2
					endif
					cgplot,findgen(n_elements(opd)),pxoffset+1/abs(opd2) * (-(delay-opd0)+opd1), color='yellow', /overplot
					for i=0,nFlag-1 do cgplot, tscale*flagdata[i].timerang, 100*[1,1],col='red',thick=2,/overplot
				;;
				;; End of delay subplot
				;;
	
				; science images
				cgLoadCT, 3
				cgimage, sci_fi, /axes, multimargin=4
				cgcontour, srcmask_fi_sci, color='green',  nlevels=2, /overplot, label=0
				cgtext, 0.5, 0.78, 'SCIENCE A+B TRACK -- float(DATA1-DATA2)', /normal, alignment = 0.5, charsize=0.7
				cgtext, 0.5, 0.77, sci_txt, /normal, charsize=0.5, alignment = 0.5
				cgtext, 0.5, 0.6, 'Science spectrum is shifted against cal mask by (DATA1/DATA2) ' + string(yshifts[0],', ', yshifts[1],format='(f7.2,A2,f7.2)') + ' px', /normal, charsize=0.5, alignment=0.5
				if mask_is_shifted then cgtext, 0.5, 0.61, 'Using shifted calibrator fringeimage mask', /normal, alignment=0.5, charsize=0.8

				; calibrator images
				cgimage, cal_fi, /axes, multimargin=4
				cgcontour, srcmask_fi, color='green',  nlevels=2, /overplot, label=0
				cgtext, 0.5, 0.58, 'CALIB A+B TRACK -- float(DATA1-DATA2)', /normal, alignment = 0.5, charsize=0.7
				cgtext, 0.5, 0.57, cal_txt, /normal, charsize=0.5, alignment = 0.5
				
				cgtext, 0.1, 0.41, 'Science target airmass: ' + strtrim(db[ix_sci[0]].airm,2), charsize=0.7, /normal
				cgtext, 0.5, 0.41, 'Average DIMM seeing for science obs: ' + strtrim(obs_get_seeing(night, time_sci),2), charsize=0.7, /normal
	
				!p.multi = [4,2,5,0,0]
				; mask cut
				cgplot, srcmask_fi_sci[l2c(8.5),*], color='green'
				cgplot, sci_fi[l2c(8.5),*]/max(sci_fi[l2c(8.5),*]), /overplot
				cgplot, cal_fi[l2c(8.5),*]/max(cal_fi[l2c(8.5),*]), /overplot, color='gray'
				cgtext, 3, 0.8, 'Cut at 8.5 micron', charsize=0.5
	
				!p.multi = [3,2,5,0,0]
				; mask cut
				cgplot, srcmask_fi_sci[l2c(12.5),*], color='green'
				cgplot, sci_fi[l2c(12.5),*]/max(sci_fi[l2c(12.5),*]), /overplot
				cgplot, cal_fi[l2c(12.5),*]/max(cal_fi[l2c(12.5),*]), /overplot, color='gray'
				cgtext, 3, 0.8, 'Cut at 12.5 micron', charsize=0.5
				
				!p.multi = [2,2,5,0,0]			
				; raw count spectrum and ozone absorption feature depth
				cgplot, w, sc.visamp, xr=[8,13], yr=[0,counts_max], xtitle='Wavelength [micron]', ytitle='Counts/s'
				o3=o3(scitag,/corr,wl=wl,y=y)
				if grism eq 'GRISM' then gr = 1 else gr = 0
				for i=0, n_elements(wl)-1 do begin
					cgplot, [wl[i],wl[i]],[0,sc.visamp[l2c(wl[i],grism=gr)]], color='red', /overplot
				endfor
				cgtext, 8.05, 1.1*y[l2c(10.,grism=gr)], textoidl('O_3') + ' depth: ' + string(o3,format='(f5.2)'), charsize=0.7
				cgplot, w, y, color='green', /overplot
			
	
				
	
				!p.multi = [1,2,5,0,0]			
				; calibrated spectrum
				cgplot, w, calspec.visamp, xr=[8,13], yr=[0, flux_max], xtitle='Wavelength [micron]', ytitle='Flux [Jy]'
	
				!p.multi = 0
			ps_end, /png, resize=50
			spawn, 'rm ' + outfilename
		endelse
	endif else lprint, 'No suitable calibrator observation found.'
end