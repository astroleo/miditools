;; for the moment only interpolate in flux direction

function lp_undecorr, lam, flux, f_undecorr_rms=f_undecorr_rms
	restore, '$MIDITOOLS/local/obs/decorrelations.sav'
	ix = where(stat.onestat[3,7] ne -1)
	stat = stat[ix]
	;;
	;;
	
	if lam eq 8.5 then l=0 else $
		if lam eq 10.5 then l=1 else $
		if lam eq 11.0 then l=-1 else $
		if lam ge 12.0 and lam le 13.0 then l=2 else $
		stop
	
	nflux = n_elements(stat[0].onestat[0,*])
	nsample = n_elements(stat)
	fluxes = stat[0].fluxes
	
	if l ne -1 then begin
		out = reform(total(stat.onestat[3+l,*],3)/nsample)
		out_rms = fltarr(nflux)
		for i=0, nflux-1 do out_rms[i] = stddev(stat.onestat[3+l,i])
	endif else begin
		out10 = reform(total(stat.onestat[3+1,*],3)/nsample)
		out12 = reform(total(stat.onestat[3+2,*],3)/nsample)
		out = 0.5*(out10+out12)
		
		out_rms10 = fltarr(nflux)
		out_rms12 = fltarr(nflux)
		for i=0, nflux-1 do out_rms10[i] = stddev(stat.onestat[3+1,i])
		for i=0, nflux-1 do out_rms12[i] = stddev(stat.onestat[3+2,i])
		out_rms = 0.5*(out_rms10 + out_rms12)
	endelse
	
	f_undecorr = 1 / interpol(out, fluxes, flux)
	f_undecorr_rms = interpol(out_rms, fluxes, flux)
	
	return, f_undecorr
	
;	cgplot, indgen(10), indgen(10), xr=[8,13], yr=[0,3], xtitle='Wavelength', ytitle='Correction factor',/nodata
	
;	for i=0, nwave-1 do begin
;		cgplots, 8.5, 1/out[0,i], psym=1
;		cgplots, 10.5, 1/out[1,i], psym=1
;		cgplots, 12.5, 1/out[2,i], psym=1
;	endfor
;	cgplot, [8,13], [1,1], linestyle=1, /over
end