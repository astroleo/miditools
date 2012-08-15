;;
;; created 2010-07-09
;;
;; PRO STARTPLOT / ENDPLOT
;;
;; PURPOSE
;;    set up PS plotting device
;;    set up a color table
;;    produce a PDF with correct orientation (and correct for IDL's seascape "bug")
;;
;; REQUIREMENS
;;    David Fanning's fixps.pro must lie in a directory that is in IDL's path
;;
pro startplot, dirname=dirname, filename=filename, colortable=colortable, xsize=xsize, ysize=ysize, landscape=landscape, xoffset=xoffset, yoffset=yoffset
	;; tests
	if not keyword_set(dirname) then dirname='/tmp'
	if not keyword_set(filename) then filename='plot'
	if not keyword_set(colortable) then colortable = -1
	if not keyword_set(landscape) then landscape=1 else landscape=0
	if colortable gt 45 then stop
	if colortable lt -2 then stop
	;;
	fp = dirname + '/' + filename + '.ps'
	;;
	set_plot,'ps'
	device, file = fp,/color,landscape=landscape, xsize=xsize, ysize=ysize, xoffset=xoffset, yoffset=yoffset
	if colortable lt 0 then begin
		case colortable of
		-1: begin
			grey=165
			TVLCT, $
			   [0,255,grey,255,  0,  0,247,230,0,0,  0,  0,  0,  0,  0,160,220],$ ; red
			   [0,255,grey,0,  255,  0,231,234,0,0,  0,150,255,120,255,255,100],$ ; green
				[0,255,grey,0,0,255,230,247,  0,0,0,255,255,255,  0,  0,  0, 20]   ; blue
			;; 0 = black
			;; 1 = white
			;; 2 = grey
			;; 3 = red
			;; 4 = green
			;; 5 = blue
			;; 6 = light orange
			;; 7 = light blue
			;; 8-10: black
			;; 11: blue
			;; 12: light blue
			;; 13: very light blue
			;; 14: green
			;; 15: light green
			;; 16: very light green
			;; 17: dark orange
			end
		-2: begin
			grey = 165
			TVLCT, $
				[0,255,grey,255,255,255,255,128,  0],$ ; red
				[0,255,grey,  0, 70,140,210,255,255],$ ; green
				[0,255,grey,  0,  0,  0,  0,  0,  0]   ; blue
				;; 0  black
				;; 1  white
				;; 2  grey
				;; 3-7 shades of red/yellow/green
			end
		endcase
	endif else loadct, colortable, /silent
end

pro endplot, dirname=dirname, filename=filename, verbose=verbose
	;; tests
	if not keyword_set(dirname) then dirname='/tmp'
	if not keyword_set(filename) then filename='plot'
	fp = dirname + '/' + filename + '.ps'
	;;
	device, /close
	set_plot,'x'
	;;
	cd, dirname, current=cdir
	fixps, filename+'.ps'
	cmd = 'ps2pdf ' + filename + '.ps'
	cmd2 = 'rm ' + filename + '.ps'
	spawn, cmd
	spawn, cmd2
	cd, cdir
	if keyword_set(verbose) then print, 'Wrote ' + dirname + '/'+ filename + '.pdf'
end

pro justplot, xdata, ydata, dirname=dirname, filename=filename, xtitle=xtitle, ytitle=ytitle, title=title, xr=xr, yr=yr, psym=psym
	if not keyword_set(dirname) then dirname='/tmp'
	if not keyword_set(filename) then filename='idlplot'
	startplot, dirname, filename
		plot, xdata, ydata, xtitle=xtitle, ytitle=ytitle, title=title, xr=xr, yr=yr, psym=psym
	endplot, dirname, filename
end

pro plottest
	dirname = '/tmp'
	file = 'plottest1'
	startplot, dirname, file
		plot, indgen(10)
	endplot, dirname, file
end