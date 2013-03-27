;;
;; PRO OBSTABLE
;;
;; PURPOSE: produce an observing log for a source given a source's name
;;
;; OPTIONS
;;    tex   put output into a .tex file and run pdftex on it
;;
pro obstable, sourcename, tex=tex
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
		
	; get info about stacks (combined fringe tracks)
	lpsourcew_stack, sourcename, stacks=stacks, ix=ix
	if ix[0] eq -1 then begin
		lprint, 'No fringe track observations for ' + sourcename
		return
	endif

	; sort by observing date
	ix = ix[sort(db[ix].mjd_start)]
	
	o_total=0.
	o_total_good=0.
	o_ph_total=0.
	o_ph_good_total=0.

	istack = 0

	lprint, 'Found ' + string(n_elements(ix)) + ' observations for ' + sourcename
		;;	             Fringe track information                                                                            | FT Quality Control               | Photometry        | Photometry QC  | Calibration
	if keyword_set(tex) then begin
		outfiledir = '$MIDILOCAL/obs/sources'
		if not file_test(outfiledir) then spawn, 'mk ' + outfiledir
		outfilebase = sourcename
		outfilename = outfilebase + '.tex'
		cd, outfiledir, current=current
		openw, lun, outfilename, /get_lun
;			printf, lun,  '\documentclass[11pt,a4paper,landscape]{article}'
;			printf, lun,  '\usepackage[latin1]{inputenc}'
;			printf, lun,  '\usepackage{graphicx}'
;			printf, lun,  '\usepackage{amssymb}'
;			printf, lun,  '\usepackage{epstopdf}'
;			printf, lun,  '\usepackage{hyperref}'
;			printf, lun,  ''
;			printf, lun,  '\textwidth = 250 mm'
;			printf, lun,  '\textheight = 170 mm'
;			printf, lun,  '\oddsidemargin = 0.0 mm'
;			printf, lun,  '\evensidemargin = 0.0 mm'
;			printf, lun,  '\topmargin = 0.0 mm'
;			printf, lun,  '\headheight = 0.0 mm'
;			printf, lun,  '\headsep = 0.0 mm'
;			printf, lun,  '\parskip = 0.5 mm'
;			printf, lun,  '\parindent = 0.0in'
;			printf, lun,  ''
;			printf, lun,  '\begin{document}'
;			printf, lun,  ''
			printf, lun,  '\begin{table}'
			printf, lun,  '\caption{Log of observations: ' + sourcename + '}'
			printf, lun,  '\centering'
			printf, lun,  '\begin{tabular}{c c c c c c c c c c c c c c c c}'
			printf, lun,  '\hline\hline'
			printf, lun,  '\multicolumn{8}{c}{Fringe track} & \multicolumn{3}{c}{FT QC} & PH & PH QC & \multicolumn{2}{c}{Calibration} \\'
			printf, lun,  'time & s & NDIT & BL & PA & g & mode & am & see & O & NGOOD & o3 & A/B & O & caltime & $\Delta$ am \\'
			printf, lun,  '\hline'			
	endif
	print, '|---Fringe track information--------------------------|-FT QC-------------|-PH--|-PH QC-|-Calibration---|'
	print, 'TIME',     's',      'NDIT',         'BL',         'PA',         'g',       'mode',    'am',        'see',       'Good?',       'NGOOD',   'o3',     'A',     'B',       'O',       'caltime',      'dam', $
	format='(A8, "   ",   A2, "   ",  A5, "   ",      A3, "   ",    A3, "   ",    A1, "   ", A6, "   ", A3,   "   ", A3,   "   ", A5, "   ", A5, "   ", A5,   "  ", A1, "/", A1, "   ", A1, "   ", A8, "   ",      A4)'
	
	night=''
	telescope=''
	
	for i=0, n_elements(ix)-1 do begin
		if keyword_set(tex) then begin
			; if too many entries on one page, start new page
			if (i ne 0 and (i mod 50 eq 0)) then begin
				printf, lun,  '\hline'
				printf, lun,  '\end{tabular}'
				printf, lun,  '\end{table}'
				printf, lun, ''
				printf, lun,  '\clearpage'
				printf, lun, ''
				printf, lun,  '\begin{table}'
				printf, lun,  '\caption{Log of observations: ' + sourcename + ' (continued)}'
				printf, lun,  '\centering'
				printf, lun,  '\begin{tabular}{c c c c c c c c c c c c c c c c}'
				printf, lun,  '\hline\hline'
				printf, lun,  '\multicolumn{8}{c}{Fringe track} & \multicolumn{3}{c}{FT QC} & PH & PH QC & \multicolumn{2}{c}{Calibration} \\'
				printf, lun,  'time & s & NDIT & BL & PA & g & mode & am & see & Good? & NGOOD & o3 & A/B & O & caltime & $\Delta$ am \\'
				printf, lun,  '\hline'			
			endif
		endif
		
		if (night ne db[ix[i]].day) or (telescope ne db[ix[i]].telescope) then begin
			if keyword_set(tex) then begin
				printf, lun, '\hline'
				printf, lun, '\multicolumn{15}{l}{' + db[ix[i]].day + ': ' + db[ix[i]].telescope + '} \\'
			endif
			print, '--------------------------------------------------------------------------------------------------------------------------------------'
			print, '   ===   ' + db[ix[i]].day + ': ' + db[ix[i]].telescope + '   ===   '
			night = db[ix[i]].day
			telescope = db[ix[i]].telescope
		endif
		
		o = obs_good(db[ix[i]].day, db[ix[i]].time, o3=o3, ngood=ngood)
		o_ph = obs_good(db[ix[i]].day, db[ix[i]].time, /phot)
		
		;;
		;; find out if this entry is stacked with following
		stackedwithfollowing = -1
		if o eq 1 then begin
			if stacks[istack].time_sci eq db[ix[i]].time then begin
				stackedwithfollowing = 0
				istack++
			endif else begin
				times_stack = *stacks[istack].times
				ix_times_stack = where(times_stack eq db[ix[i]].time)
				if ix_times_stack[0] ne -1 then stackedwithfollowing = 1 else begin
					print, times_stack
					print, db[ix[i]].time
					print, stackedwithfollowing
					stop
				endelse
			endelse
		endif

		if db[ix[i]].grism eq 'PRISM' then gr='P' else if db[ix[i]].grism eq 'GRISM' then gr='G' else stop
		if db[ix[i]].beamcombiner eq 'HIGH_SENS' then bc='HS' else bc=db[ix[i]].beamcombiner
		if db[ix[i]].mode eq 'OBS_FRINGE_TRACK_DISPERSED_OFF' then m='FT_OFF' else m=db[ix[i]].mode
		
		if keyword_set(tex) then m=repstr(m,'_','\_')
	
		am=db[ix[i]].airm

		caltime=closestcal(db[ix[i]].day, db[ix[i]].time, bestix=calix, caltests=caltests)
		if caltime[0] ne '-1' then begin
			amdiff=am-db[calix].airm
			time_cal = db[calix].time
		endif else begin
			amdiff = -999
			time_cal = '-'
		endelse

		;; search for photometries
		ix_A = where(db.day eq db[ix[i]].day and db.id eq db[ix[i]].id and db.dpr eq 'PH' and db.shut eq 'A')
		if ix_A[0] eq -1 then N_APHOT=0 else N_APHOT=n_elements(ix_A)
		ix_B = where(db.day eq db[ix[i]].day and db.id eq db[ix[i]].id and db.dpr eq 'PH' and db.shut eq 'B')
		if ix_B[0] eq -1 then N_BPHOT=0 else N_BPHOT=n_elements(ix_B)
		
		o_total++
		if N_APHOT ge 1 and N_BPHOT ge 1 then o_ph_total++
		if o eq 1 then o_total_good++
		if o_ph eq 1 then o_ph_good_total++

				
		seeing=obs_get_seeing(db[ix[i]].day, db[ix[i]].time)

		;;           FRINGE TRACK INFORMATION                                                                            | FT QUALITY CONTROL               | PHOTOMETRY        | PH QUALITY CONTROL  | CALIBRATION
		if keyword_set(tex) then $
			printf, lun, db[ix[i]].time, stackedwithfollowing, db[ix[i]].ndit, db[ix[i]].BL, db[ix[i]].PA, gr,        m,         am,          seeing,      o,    ngood,     o3,      N_APHOT, N_BPHOT,   o_ph,            time_cal, amdiff, $
			format='(A8, " & ",    I2, " & ", I5, " & ",      I3, " & ",    I3, " & ",    A1, " & ", A6, " & ", f3.1, " & ", f3.1, " & ", I2, " & ", I5, " & ", f5.2, " & ", I1, "/", I1, " & ", I2, " & ",            A8, " & ",      f8.1, "\\")'
		
		print, db[ix[i]].time, stackedwithfollowing, db[ix[i]].ndit, db[ix[i]].BL, db[ix[i]].PA, gr,        m,         am,          seeing,               o,    ngood,     o3,      N_APHOT, N_BPHOT,   o_ph,            time_cal, amdiff, $
		format='(A8, "   ",    I2, "   ", I5, "   ",      I3, "   ",    I3, "   ",    A1, "   ", A6, "   ", f3.1, "   ", f3.1, "   ", "   ", I2, "   ", I5, "   ", f5.2, "   ", I1, "/", I1, "   ", I2, "   ",            A8, "   ",      f4.1)'	
	endfor
	if keyword_set(tex) then begin
		;;
		;; LaTeX footer
		printf, lun,  '\hline'
		printf, lun,  '\end{tabular}'
		printf, lun,  '\end{table}'
;		printf, lun,  '\end{document}'
		free_lun, lun
		; compile PDF (run LaTeX)
;		cmd = 'pdflatex ' + outfilename + ' >> /tmp/pdflatexlog'
;		spawn, cmd
;		delfiles = ['.aux','.log','.out']
;		for i=0, n_elements(delfiles)-1 do begin
;			cmd = 'rm ' + outfiledir + '/' + outfilebase + delfiles[i]
;			spawn, cmd
;		endfor
		cd, current
;		print, 'Compiled .tex file, removed intermediate files, output: ' + outfilename
	endif
	
	print, o_total, o_ph_total, format='("Total number of (photometry) observations", I3, "(", I3, ")")'
	print, o_total_good, o_ph_good_total, format='("Total number of good (photometry) observations", I3, "(", I3, ")")'
	print, o_total_good/o_total, o_ph_good_total/o_ph_total, format='("Fraction of good (photometry) observations", f5.2, "(", f5.2, ")")'
end