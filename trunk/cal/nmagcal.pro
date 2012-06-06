function RJflux, F10_jy, lam_mu
	return, F10_jy * 10^2 * lam_mu^(-2.)
end

;;
;; function NMAGCAL
;;
;; PURPOSE:
;;    return calibrator info
;;
;; INPUT:
;;    EITHER a calibrator name (e.g. 'HD119193') OR a file (f)
;;
;; OPTIONS:
;;    calspec   store interpolated calibrator spectrum in this variable if given
;;
function NMagCal, name=name, f=f, calspec=calspec, pl=pl
	restore, '$MIDITOOLS/local/cal/midi_cohen_merged.dat'
	;;
	;; some tests
	if keyword_set(name) and not keyword_set(f) then begin
		ix=where(calcat.name eq name)
		if (ix ne -1) and (n_elements(ix) eq 1) then begin
			coords = calcat[ix].coords
		endif else begin
			print, 'Nothing found.'
		endelse
	endif else if keyword_set(f) and not keyword_set(name) then begin
		RA = midigetkeyword('RA',f)
		DEC = midigetkeyword('DEC',f)
		coords = {RA:RA, DEC:DEC}
	endif
	;; get data
	p  = match_with_mcc(coords.RA,coords.DEC)
	if keyword_set(pl) then print, p.mcc_name
	if keyword_set(pl) then print, 'Diameter: (' + strtrim(p.theta,2) + ' +/- ' + strtrim(p.theta_err,2) + ') mas'
	restore, '$MIDITOOLS/MIDI/w.sav'
	calspec = interpol(p.specfnu,p.speclam,w)
	if keyword_set(pl) then plot, w, calspec, xtitle='lambda (micron)', ytitle='flux (Jy)', title=p.mcc_name
	;;
	;; 9 micron flux
	if keyword_set(pl) then print, '9 micron flux: ' + strtrim(total(calspec[115:118])/4,2)
	return, p
end