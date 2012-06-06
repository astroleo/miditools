;; FUNCTION obs_get_tau0
;;
;; like obs_get_ft_seeing, but returns tau0
function obs_get_tau0, night, time
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	dimm = read_dimm(night)
	
	seeingsmooth = 5 ; roughly 5 minutes
	tau0 = smooth(dimm.tau0,seeingsmooth)
	ix = where(db.day eq night and db.time eq time)
	
	; find closest entry in time
	t_ut = hhmmss(time)
	ix_s = value_locate(dimm.t_ut, t_ut)
	
	if ix_s[0] eq -1 then begin
		if keyword_set(verbose) then lprint, 'No tau0 available for ' + night + ' / ' + time
		return, -1.
	endif
	
	if ix_s eq n_elements(dimm.t_ut)-1 then return, tau0[ix_s-1] else begin
		; verify that we are in the correct interval
		if not (dimm.t_ut[ix_s] le t_ut and dimm.t_ut[ix_s+1] ge t_ut) then return, -1. else $
		return, tau0[ix_s]
	endelse
end