@$MIDITOOLS/dr/lpw_phot
;;
;; Quality Control plot for photometries
;;
;;
;; time_sci is time of science FRINGE TRACK!
;;
pro QC_phot, night, time_sci, dirname=dirname, overwrite=overwrite
	if not keyword_set(dirname) then dirname = '$MIDIREDDIR'
	scitag = maketag(night,time_sci)
	sci_a_file  = scitag + '.Aphotometry.fits'
	sci_b_file  = scitag + '.Bphotometry.fits'
	sci_phot_file = scitag + '.photometry.fits'	
	sci_cal_phot_file = scitag + '.calphot.fits'	

	time_cal = closestcal(night, time_sci, /withphot)
	if time_cal[0] eq -1 then return
	caltag = maketag(night,time_cal)
	cal_a_file  = caltag + '.Aphotometry.fits'
	cal_b_file  = caltag + '.Bphotometry.fits'
	cal_ab_file = caltag + '.corr.fits' ;; needed for easy wavelength calibration only
	skymask = caltag + '.skymask.fits'
	srcmask = caltag + '.srcmask.fits'
	
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	ix_sci = where(db.day eq night and db.time eq time_sci)

	; hard code maximum counts / flux per source
	if strmid(db[ix_sci[0]].telescope,0,1) eq 'U' then begin
		case db[ix_sci[0]].mcc_name of
			'Circinus': flux_max = 20.
			'NGC1068': flux_max = 30.
			'IC4329A': flux_max = 1.5
			'NGC5506': flux_max = 1.0
			'NGC1365': flux_max = 0.8
			'NGC5128': flux_max = 2.0
			'HD135344b': flux_max = 3.0
			else: flux_max = 1.0
		endcase
		counts_max = 1000. * flux_max
	endif else begin
		;; AT observations
		flux_max = 20.
		counts_max = 100. * flux_max
	endelse
	
	outfiledir='$MIDILOCAL/obs/QC/'+db[ix_sci[0]].mcc_name
	if not file_test(outfiledir) then spawn, 'mkdir ' + outfiledir
	outfilename=outfiledir+'/'+night+'_'+ repstr(time_sci,':','') + '.QC_phot.ps'
	outfilename_png=outfiledir+'/'+night+'_'+ repstr(time_sci,':','') + '.QC_phot.png'

	if file_test(outfilename_png) and not keyword_set(overwrite) then begin
		print, outfilename + ' exists. Returning...'
	endif else if not (file_test(sci_a_file) and file_test(sci_b_file) and file_test(cal_ab_file) and file_test(sci_phot_file) and file_test(sci_cal_phot_file) and file_test(cal_a_file) and file_test(cal_b_file) and file_test(skymask) and file_test(srcmask)) then begin
		print, file_test(sci_a_file), file_test(sci_b_file), file_test(cal_ab_file), file_test(sci_phot_file), file_test(sci_cal_phot_file), file_test(cal_a_file), file_test(cal_b_file), file_test(skymask), file_test(srcmask)
		;; fringe files are missing
		lprint, night + ' / ' + time_sci + ': Some files and / or masks are missing; not producing any output.'
	endif else begin
		id_sci = db[ix_sci].id
		ix_cal = where(db.day eq night and db.time eq time_cal)
		id_cal = db[ix_cal].id
		
		f_ph = getphotfiles(night, time_sci, ix_A=ix_A, ix_B=ix_B)
		
		;;
		;; DATA1 is shifted by 1 pixel w.r.t. DATA2
		srcmask = oirgetdata(srcmask)
		srcmask_fi = (srcmask.data1 + shift(srcmask.data2, [0,-1]))/2
		skymask = oirgetdata(skymask)
		skymask_fi = (skymask.data1 + shift(skymask.data2, [0,-1]))/2

		bla = oirgetvis(cal_ab_file,w=w) ; just to get wavelength calibration
		
		; raw and cal spectra
		raw_cts = oirgetdata(sci_phot_file)
		cal_spec = oirgetdata(sci_cal_phot_file,2) ; masked geometric mean of A&B
		
		; obs good
		cal_obsgood = obs_good(night, time_cal, /phot)
		sci_obsgood = obs_good(night, time_sci, /phot)
		if cal_obsgood eq 1 then cal_good='good' else if cal_obsgood eq 0 then cal_good='bad' else cal_good='unknown'
		if sci_obsgood eq 1 then sci_good='good' else if sci_obsgood eq 0 then sci_good='bad' else sci_good='unknown'
		
		sci_txt = db[ix_sci[0]].mcc_name + ' in the night of ' + db[ix_sci[0]].day + ' at ' + time_sci + ' (' + id_sci + ') -- quality is ' + sci_good
		cal_txt = db[ix_cal[0]].mcc_name + ' in the night of ' + db[ix_cal[0]].day + ' at ' + time_cal + ' (' + id_cal + ') -- quality is ' + cal_good

		sci_a_phot = oirgetdata(sci_a_file,1)
		sci_b_phot = oirgetdata(sci_b_file,1)
		cal_a_phot = oirgetdata(cal_a_file,1)
		cal_b_phot = oirgetdata(cal_b_file,1)

		f='$MIDILOCAL/obs/fringeimages/'+night+'_'+ id_cal + '_' + time_sci + '_' + db[ix_sci[0]].mcc_name + '.photQC'
		ps_start, filename=outfilename;, xoffset=-1., yoffset=1., xsize=6., ysize=10., font_size=12; pagetype='A4'
			!p.multi = [0,2,4,0,0]
			cgLoadCT, 3
			; science images
			cgimage, sci_a_phot.data1, /axes, multimargin = 3
			cgcontour, skymask_fi, color='blue', nlevels=2, /overplot, label=0
			cgcontour, srcmask_fi, color='green',  nlevels=2, /overplot, label=0
			cgtext, 0.25, 0.95, 'SCIENCE A PHOT / DATA1', /normal, alignment = 0.5
		
			cgimage, sci_b_phot.data1, /axes, multimargin = 3
			cgcontour, skymask_fi, color='blue', nlevels=2, /overplot, label=0
			cgcontour, srcmask_fi, color='green',  nlevels=2, /overplot, label=0
			cgtext, 0.75, 0.95, 'SCIENCE B PHOT / DATA1', /normal, alignment = 0.5
			
			text_a = 'A photometries: '
			text_b = 'B photometries: '
			for k=0, n_elements(ix_A)-1 do text_a += db[ix_A[k]].time + ' '
			for k=0, n_elements(ix_B)-1 do text_b += db[ix_B[k]].time + ' '
			cgtext, 0.05, 0.75, text_a, /normal, charsize=0.7, alignment=0
			cgtext, 0.95, 0.75, text_b, /normal, charsize=0.7, alignment=1.

			if db[ix_sci[0]].grism eq 'GRISM' then gr = 1 else gr = 0
			cts = ncounts_phot(night, time_sci)
			
			; raw counts A
			cgplot, w, raw_cts[3].data1, xr=[8,13], xtitle='lambda [mu]', ytitle='Raw cts', title='Masked counts A';, yr=[0,counts_max]
			o3=o3(scitag,wl=wl,y=y,/A,ncts=ncts)
			for i=0, n_elements(wl)-1 do begin
				cgplot, [wl[i],wl[i]],[0,raw_cts[3].data1[l2c(wl[i],grism=gr)]], color='red', /overplot
			endfor
			cgtext, 8.05, 1.1*y[l2c(10.,grism=gr)], textoidl('O_3') + ' depth: ' + string(o3,format='(f5.2)'), charsize=0.7
			cgplot, w, y, color='green', /overplot
			cgtext, 11., 100, 'Avg over band: ' + string(cts[0],format='(I6)'), charsize=0.7

			
			; raw counts B
			cgplot, w, raw_cts[4].data1, xr=[8,13], xtitle='lambda [mu]', ytitle='Raw cts', title='Masked counts B';, yr=[0,counts_max]
			o3=o3(scitag,wl=wl,y=y,/B)
			for i=0, n_elements(wl)-1 do begin
				cgplot, [wl[i],wl[i]],[0,raw_cts[4].data1[l2c(wl[i],grism=gr)]], color='red', /overplot
			endfor
			cgtext, 8.05, 1.1*y[l2c(10.,grism=gr)], textoidl('O_3') + ' depth: ' + string(o3,format='(f5.2)'), charsize=0.7
			cgplot, w, y, color='green', /overplot
			cgtext, 11., 100, 'Avg over band: ' + string(cts[1],format='(I6)'), charsize=0.7

			; raw counts
			cgplot, w, raw_cts[5].data1, xr=[8,13], xtitle='lambda [mu]', ytitle='Raw cts', title='Masked counts sqrt(A*B)';, yr=[0,counts_max]
			; o3 test
			o3=o3(scitag,wl=wl,y=y)
			for i=0, n_elements(wl)-1 do begin
				cgplot, [wl[i],wl[i]],[0,raw_cts[5].data1[l2c(wl[i],grism=gr)]], color='red', /overplot
			endfor
			cgtext, 8.05, 1.1*y[l2c(10.,grism=gr)], textoidl('O_3') + ' depth: ' + string(o3,format='(f5.2)'), charsize=0.7
			cgplot, w, y, color='green', /overplot
			cgtext, 11., 100, 'Avg over band: ' + string(cts[2],format='(I6)'), charsize=0.7
			
			; calibrated flux
			cgplot, w, cal_spec.data1, xr=[8,13], yr=[0,flux_max], xtitle='lambda [mu]', ytitle='Flux [Jy]'

			; calibrator images
			cgimage, cal_a_phot.data1, /axes, multimargin = 3
			cgcontour, skymask_fi, color='blue', nlevels=2, /overplot, label=0
			cgcontour, srcmask_fi, color='green',  nlevels=2, /overplot, label=0
			cgtext, 0.25, 0.2, 'CALIB A PHOT / DATA1', /normal, alignment = 0.5
		
			cgimage, cal_b_phot.data1, /axes, multimargin = 3
			cgcontour, skymask_fi, color='blue', nlevels=2, /overplot, label=0
			cgcontour, srcmask_fi, color='green',  nlevels=2, /overplot, label=0
			cgtext, 0.75, 0.2, 'CALIB B PHOT / DATA1', /normal, alignment = 0.5

			; caption
			cgtext, 0.5, 0.75, sci_txt, /normal, charsize=0.7, alignment = 0.5
			cgtext, 0.75, 0.01, cal_txt, /normal, charsize=0.7, alignment = 0.5
			!p.multi = 0
		ps_end, /png, resize=50
		spawn, 'rm ' + outfilename
	endelse
end