;; 
;; FUNCTION obs_get_max_rms (clouds)
;;
;; returns the maximum DIMM rms of a given observation (night/time) within a 
;;    certain interval before and after that observation
;;
;; dt is given in hours
;;
function obs_get_max_rms, night, time, dt
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	dimm = read_dimm(night)
	cloudsmooth = 10 ; roughly 5 minutes
	clouds = smooth(dimm.flux_rms,cloudsmooth)
	ix = where(db.day eq night and db.time eq time)
	
	; find closest entry in time
	t_ut = hhmmss(time)
	if t_ut-dt lt dimm.t_ut[0] then t1 = t_ut[0] else t1 = t_ut-dt
	if t_ut+dt gt dimm.t_ut[n_elements(dimm.t_ut)-1] then t2 = dimm.t_ut[n_elements(dimm.t_ut)-1] else t2 = t_ut+dt
	ix_c1 = value_locate(dimm.t_ut, t1)
	ix_c2 = value_locate(dimm.t_ut, t2)
	if ix_c1 eq -1 then return, -1
	if ix_c2 eq -1 then return, -1
	return, max(clouds[ix_c1:ix_c2])
end