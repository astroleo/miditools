;;
;; FUNCTION dt2ix (date+time to database index)
;;
;; return index of obs database for a given observation, identified by night and time
;;
function db_ix, night, time
	a=strsplit(time,':',/extract)
	;;
	;; check that time is really a time
	if n_elements(a) ne 3 then stop
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	ix = where(db.day eq night and db.time eq time)
	if n_elements(ix) ne 1 or ix[0] eq -1 then stop $
		else return, ix
end