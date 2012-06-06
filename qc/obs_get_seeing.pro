;; FUNCTION obs_get_seeing
;;
;; returns 5-minute average value of seeing for a given observation
;;
function obs_get_seeing, night, time, verbose=verbose
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	dimm = read_dimm(night)
	
	; check if time array is sorted monotonically in time
;	if sort(dimm.t_ut) ne lonarr(n_elements(t_ut)) then stop ; doesn't work -- IDL cannot compare arrays this way
	
	seeingsmooth = 5 ; roughly 5 minutes
	seeing = smooth(dimm.seeing,seeingsmooth)
	ix = where(db.day eq night and db.time eq time)
	
	; find closest entry in time
	t_ut = hhmmss(time)
	ix_s = value_locate(dimm.t_ut, t_ut)
	
	if ix_s[0] eq -1 then begin
		if keyword_set(verbose) then lprint, 'No seeing available for ' + night + ' / ' + time
		return, -1.
	endif
	
	if ix_s eq n_elements(dimm.t_ut)-1 then return, seeing[ix_s-1] else begin
		; verify that we are in the correct interval
		if not (dimm.t_ut[ix_s] le t_ut and dimm.t_ut[ix_s+1] ge t_ut) then return, -1.
		if abs(seeing[ix_s] - t_ut) gt abs(seeing[ix_s+1] - t_ut) then return, seeing[ix_s+1] else return, seeing[ix_s]
	endelse
end