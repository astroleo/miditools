;;
;; FUNCTION DIMM_pointing_diff
;;
;; PURPOSE
;; Returns angular difference (on sky) of DIMM pointing and VLTI pointing
;;
;; if pointing changes during obs, returns -1.
;;
function dimm_pointing_diff, night, time
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	ix = where(db.day eq night and db.time eq time)
	dimm = read_dimm(night)
	pointingsmooth = 5 ; just under 3 minutes
	
	; find closest entry in time
	t_ut = hhmmss(time)
	ix_dimm = value_locate(dimm.t_ut, t_ut)
	if ix_dimm[0] eq -1 then return, -1.
;	print, 'DIMM pointing: RA = ' + strtrim(dimm.ra[ix_dimm],2) + ', DEC = ' + strtrim(dimm.dec[ix_dimm],2)
;	print, 'VLTI pointing: RA = ' + strtrim(db[ix].ra,2) + ', DEC = ' + strtrim(db[ix].dec,2)
	
	dist_deg = sqrt(((db[ix].ra - dimm.ra[ix_dimm]) * cos(db[ix].dec * !pi/180.))^2 + (db[ix].dec - dimm.dec[ix_dimm])^2)
	dist_deg = min([[dist_deg],[abs(dist_deg-360)]])

;	print, 'Difference in degrees: ' + strtrim(dist_deg,2)
	
	return, dist_deg
end