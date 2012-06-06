;;
;; FUNCTION LOADF
;;
;; PURPOSE:
;;    return filelist of an observation, identified with night and time
;;    change directory to the raw data directory of that night
;;
;; REQUIRED INPUTS:
;;    night         day of night begin (string), e.g. '2011-04-20'
;;    time          time of science observation (string), e.g. '02:14:34'
;;
;; OPTIONS:
;;    nophot        do not search for photometry files;
;;                     if not set: skips tracks where no photometry is found
;;
;; LIMITATIONS:
;;    currently only works with nophot option set
;;
function loadf, night, time, nophot=nophot
	cd, '$MIDIDATA/'+night
	
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	ix = where(db.day eq night and db.time eq time)
	if ix[0] eq -1 then begin
		print, "No such night/time!"
		stop
	endif
	if not keyword_set(nophot) then begin
		lprint, 'needs to be adapted for phot with time!'
		stop
		f = strarr(3)
		ix_FT = where(db[ix].dpr eq 'FT')
		ix_PHOTA = where(db[ix].dpr eq 'PH' and db[ix].shut eq 'A')
		ix_PHOTB = where(db[ix].dpr eq 'PH' and db[ix].shut eq 'B')
		f[0] = db[ix[ix_FT]].f

		for i=0, n_elements(ix_PHOTA)-1 do begin
			f[1] += db[ix[ix_PHOTA[i]]].f + ' '
		endfor
		f[1] = strmid(f[1],0,strlen(f[1])-1)

		for i=0, n_elements(ix_PHOTB)-1 do begin
			f[2] += db[ix[ix_PHOTB[i]]].f + ' '
		endfor
		f[2] = strmid(f[2],0,strlen(f[2])-1)
	endif
	
	return, db[ix].f
end