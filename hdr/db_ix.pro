;;
;; FUNCTION db_ix
;;
;; return index of obs database for a given observation, identified by night, 
;;    id and dpr type (default = 'FT')
;;
function db_ix, night, id, dpr=dpr
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	if not keyword_set(dpr) then dpr = 'FT'
	ix = where(db.day eq night and db.id eq id and db.dpr eq dpr)
	if dpr eq 'FT' and n_elements(ix) ne 1 or ix[0] eq -1 then stop $
		else return, ix
end