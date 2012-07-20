;;
;; FUNCTION db_time2id
;;
;; return deprecated 'id' identifier given new night+time unique identifier
;;
function db_time2id, night, time
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	ix = where(db.day eq night and db.time eq time)
	if n_elements(ix) ne 1 or ix[0] eq -1 or db[ix].id eq '-1' then stop $
		else return, db[ix].id
end