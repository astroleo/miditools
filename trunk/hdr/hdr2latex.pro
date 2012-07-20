@$MIDITOOLS/hdr/readhdr
@$MIDITOOLS/dr/tools
@$MIDITOOLS/var/read_text
;
; reads in a list of files
; outputs LaTeX table with Night (the night when the obs started) and Time
;
;;
;;    OLD!!! use db2latex (below) instead!
;;
; ISSUES
; * the programme number that is output is not necessarily the correct one (just the first one?)
;
pro hdr2latex, f
   hdrs = readhdr(f)
   t = ''
   ;
   ; LaTeX header
   print, '\begin{table}'
   print, '\caption{Log of observations}'
	print, '\centering'
	print, '\begin{tabular}{c c c c c c c c c c c c}'
	print, '\hline\hline'
	print, 'Night and Time & Object  & id  & DIT & \multicolumn{2}{c}{NDIT} & Airmass & Seeing\footnote{At 0.5 $\mu$m from the seeing monitor (DIMM)} & BL  & PA           &Associated calib\\'
	print, "\textit{[UTC]}    &         &     & [s] & FT\footnote{fringe track} & phot.          &         &['']&[m]&[$^{\circ}$]&\\"
	print, '\hline'
	;
   for i=0, n_elements(hdrs)-1 do begin
      if hdrs[i].telescope ne t then begin
         print, hdrs[i].day, ': & ', hdrs[i].telescope, ' & \multicolumn{3}{c}{', hdrs[i].prog, '}\\'
         print, '\hline'
         t = hdrs[i].telescope
      endif
      if (hdrs[i].dpr eq 'FT') then $
         print, hdrs[i].time, ' & ', hdrs[i].objname, ' &  & ', hdrs[i].dit, ' & ', hdrs[i].ndit, ' & ---  &     ', hdrs[i].airm, ' & ', $
                hdrs[i].seeing, ' & ', hdrs[i].bl, ' & ', hdrs[i].pa, ' &  \\'$
      else if (hdrs[i].dpr eq 'PH') then $
         print, hdrs[i].time, ' & ', hdrs[i].objname, ' &  & ', hdrs[i].dit, ' &  --- & ', hdrs[i].ndit, ' (', hdrs[i].shut, ')' ,' & ', hdrs[i].airm, ' & ', $
                hdrs[i].seeing, ' & ', hdrs[i].bl, ' & ', hdrs[i].pa, ' &  \\'
	endfor
	;
	; LaTeX footer
	print, '\hline'
	print, '\end{tabular}'
	print, '\end{table}'

end
;;
;; PRO DB2LATEX
;;
;; PURPOSE:
;;    extract observing log of one night into LaTeX / PDF table
;;
pro db2latex, night, dbfile=dbfile, outfiledir=outfiledir
	if not keyword_set(dbfile) then dbfile='$MIDITOOLS/local/obs/obs_db.sav'
	restore, dbfile
	t = ''
	ix = where(db.day eq night and (db.dpr eq 'FT' or db.dpr eq 'PH'))
	; check if there are any observations
	if ix[0] eq -1 then print, 'No fringe track or photometry observations on ' + night else begin		
		if not keyword_set(outfiledir) then outfiledir = '$MIDILOCAL/obs/log'
		outfilebase = 'obslog_' + night
		outfilename = outfilebase + '.tex'
		; check if dir exists
		if not file_test(outfiledir) then spawn, 'mkdir ' + outfiledir
		cd, outfiledir, current=current
		; output file
		openw, lun, outfilename, /get_lun
			printf, lun,  '\documentclass[11pt,a4paper,landscape]{article}'
			printf, lun,  '\usepackage[latin1]{inputenc}'
			printf, lun,  '\usepackage{graphicx}'
			printf, lun,  '\usepackage{amssymb}'
			printf, lun,  '\usepackage{epstopdf}'
			printf, lun,  '\usepackage{hyperref}'
			printf, lun,  ''
			printf, lun,  '\textwidth = 250 mm'
			printf, lun,  '\textheight = 170 mm'
			printf, lun,  '\oddsidemargin = 0.0 mm'
			printf, lun,  '\evensidemargin = 0.0 mm'
			printf, lun,  '\topmargin = 0.0 mm'
			printf, lun,  '\headheight = 0.0 mm'
			printf, lun,  '\headsep = 0.0 mm'
			printf, lun,  '\parskip = 0.5 mm'
			printf, lun,  '\parindent = 0.0in'
			printf, lun,  ''
			printf, lun,  '\begin{document}'
			printf, lun,  ''
			printf, lun,  '\begin{table}'
			printf, lun,  '\caption{Log of observations}'
			printf, lun,  '\centering'
			printf, lun,  '\begin{tabular}{c c c c c c c c c c c c}'
			printf, lun,  '\hline\hline'
			printf, lun,  'Night and Time & Object  & id  & DIT & \multicolumn{2}{c}{NDIT} & Airmass & Seeing & BL  & PA           &Associated calib\\'
			printf, lun,  "\textit{[UTC]}    &         &     & [s] & Track & Phot          &         &['']&[m]&[$^{\circ}$]&\\"
			printf, lun,  '\hline'
	
			for i=0, n_elements(ix)-1 do begin
				; if too many entries on one page, start new page
				if (i ne 0 and (i mod 25 eq 0)) then begin
					printf, lun,  '\hline'
					printf, lun,  '\end{tabular}'
					printf, lun,  '\end{table}'
					printf, lun, ''
					printf, lun,  '\clearpage'
					printf, lun, ''
					printf, lun,  '\begin{table}'
					printf, lun,  '\caption{Log of observations}'
					printf, lun,  '\centering'
					printf, lun,  '\begin{tabular}{c c c c c c c c c c c c}'
					printf, lun,  '\hline\hline'
					printf, lun,  'Night and Time & Object  & id  & DIT & \multicolumn{2}{c}{NDIT} & Airmass & Seeing\footnote{At 0.5 $\mu$m from the seeing monitor (DIMM)} & BL  & PA           &Associated calib\\'
					printf, lun,  "\textit{[UTC]}    &         &     & [s] & FT\footnote{fringe track} & phot.          &         &['']&[m]&[$^{\circ}$]&\\"
					printf, lun,  '\hline'
				endif
				if db[ix[i]].telescope ne t then begin
					printf, lun,  db[ix[i]].day, ': & ', db[ix[i]].telescope, ' & \multicolumn{3}{c}{', db[ix[i]].prog, '}\\'
					printf, lun,  '\hline'
					t = db[ix[i]].telescope
				endif
				
				sourcename=repstr(db[ix[i]].mcc_name,'_','\_')
				
				if (db[ix[i]].dpr eq 'FT') then $
					printf, lun,  db[ix[i]].time, ' & ', sourcename, ' & ', db[ix[i]].id, ' & ', db[ix[i]].dit, ' & ', db[ix[i]].ndit, ' & ---  &     ', db[ix[i]].airm, ' & ', $
						db[ix[i]].seeing, ' & ', db[ix[i]].bl, ' & ', db[ix[i]].pa, ' &  \\'$
				else if (db[ix[i]].dpr eq 'PH') then $
					printf, lun,  db[ix[i]].time, ' & ', sourcename, ' & ', db[ix[i]].id, ' & ', db[ix[i]].dit, ' &  --- & ', db[ix[i]].ndit, ' (', db[ix[i]].shut, ')' ,' & ', db[ix[i]].airm, ' & ', $
						db[ix[i]].seeing, ' & ', db[ix[i]].bl, ' & ', db[ix[i]].pa, ' &  \\'
			endfor
			;;
			;; LaTeX footer
			printf, lun,  '\hline'
			printf, lun,  '\end{tabular}'
			printf, lun,  '\end{table}'
			printf, lun,  '\end{document}'
		free_lun, lun
		; compile PDF (run LaTeX)
		cmd = 'pdflatex ' + outfilename + ' >> /tmp/pdflatexlog'
		spawn, cmd
		delfiles = ['.aux','.log','.out','.tex']
		for i=0, n_elements(delfiles)-1 do begin
			cmd = 'rm ' + outfiledir + '/' + outfilebase + delfiles[i]
			spawn, cmd
		endfor
		cd, current
	endelse
end

pro mdb2latex
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	a=db.day
	a=a[sort(a)]
	nights=a[uniq(a)]
	for i = 0, n_elements(nights) - 1 do begin
		print, nights[i]
		db2latex, nights[i]
	endfor
end