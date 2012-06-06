;;
;; FUNCTION O3
;;
;; PURPOSE:
;;    Determine depth of ozone feature relative to interpolated "continuum"
;;
function o3, tag, pl=pl, corr=corr, wl=wl, y=y, A=A, B=B, ncts=ncts
	if keyword_set(corr) then begin
		ext = '.corr.fits'
		filename = tag + ext
		if not file_test(filename) then return, -1.
		d = oirgetvis(filename)
		data = d.visamp
	endif else begin
		ext = '.photometry.fits'
		filename = tag + ext
		if not file_test(filename) then return, -1.
		if keyword_set(A) then $
			d = oirgetdata(filename,4) $ ; Masked flux A
			else if keyword_set(B) then $
			d = oirgetdata(filename,5) $ ; Masked flux B
			else d = oirgetdata(filename,6) ; Masked flux, geometric mean
		data = d.data1
	endelse

	;;
	;; determine if PRISM or GRISM data
	gr=strtrim(midigetkeyword('INS GRIS ID',filename),2)
	;;
	;; define boundaries for fit
	wl=[8.8,9.2,9.55,9.75,10.1,10.5]
	if gr eq 'GRISM' then begin
		restore, '$MIDITOOLS/MIDI/w_grism.sav'
		grism=1
		;;
		;; define boundaries for fit
		wlc=[l2c(wl[0],/grism),l2c(wl[1],/grism),l2c(wl[2],/grism),l2c(wl[3],/grism),l2c(wl[4],/grism),l2c(wl[5],/grism)]
	endif else if gr eq 'PRISM' then begin
		restore, '$MIDITOOLS/MIDI/w.sav'
		grism=0
		;;
		;; define boundaries for fit -- PRISM: longer wavelength corresponds to lower pixel value
		wlc=[l2c(wl[1]),l2c(wl[0]),l2c(wl[3]),l2c(wl[2]),l2c(wl[5]),l2c(wl[4])]
	endif else begin
		lprint, 'Unknown beam combiner: ' + gr
		stop
	endelse
	;
	; do a linear fit between around 9.0 and 10.3 micron
	;
	weights=fltarr(n_elements(w))

	weights[wlc[0]:wlc[1]]=1.
	weights[wlc[4]:wlc[5]]=1.
	q = polyfitw(w, data, weights, 1, y)
	;
	; now take value around 9.65 micron as inside ozone feature
	;
	c_no_o3 = total(y[wlc[2]:wlc[3]])/5
	c_in_o3 = total(data[wlc[2]:wlc[3]])/5
	if keyword_set(pl) then begin
		plot, w, data/max(data), xr=[8,13]
		for i=0, n_elements(wl)-1 do begin
			oplot, [wl[i],wl[i]],[0,1], color=255
		endfor
		oplot, w, y/max(data), color=255*128
	endif
	return, c_in_o3/c_no_o3
end