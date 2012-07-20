;; PRO DB_QUERY_SRC
;;
;; PURPOSE:
;;    query obs DB for a specific source
;;
;; OPTIONS:
;;    prog    only use data from the given programme
;;    dbfile  observation database file to use
;;
;;
;;
;;
;;
;;
;;
;;
;;
;;
;;
;;
;;
;;
;;
;;
;;
;;
;;
;;
;;
; NEEDS UPDATE!
;;
;;
;;
;;
;;
;;
;;
;;
;;
;;
;;
;;
;;
;;
;;
;;
;;
pro DB_QUERY_SRC, mcc_name, prog=prog, dbfile=dbfile, bl=bl, dpr=dpr
	if not keyword_set(dbfile) then dbfile = '$MIDITOOLS/local/obs/obs_db.sav'
	; find all data for that source and print some info
	restore, dbfile
	if keyword_set(bl) then ix = where(db.mcc_name eq mcc_name and db.telescope eq bl) else $
		ix = where(db.mcc_name eq mcc_name)
	if keyword_set(dpr) then begin
		ix2 = where(db[ix].dpr eq dpr)
		ix = ix[ix2]
	endif
	if keyword_set(prog) then begin
		for i = 0, n_elements(ix) - 1 do begin
			prog1 = strsplit(db[ix[i]].prog,'(',/EXTRACT)
			prog2 = prog1[0]
			if (prog2 eq prog) then begin
				ix1 = i
				if n_elements(ixlist) eq 0 then ixlist = ix1 else ixlist = [ixlist, ix1]
			endif
		endfor
		ix = ix[ixlist]
	endif
	print, 'Observation information for ' + mcc_name
	for i = 0, n_elements(ix) - 1 do begin
		
		ngood=-1
		if db[ix[i]].dpr eq 'FT' then o = obs_good(db[ix[i]].day, db[ix[i]].time, ngood=ngood) else $
			if db[ix[i]].dpr eq 'PH' then o = obs_good(db[ix[i]].day, db[ix[i]].time, /phot) else $
				o = -1

		if o ne -1 then obs_good = string(o,format='(I2)') else obs_good = '  '
		ngood = string(ngood,format='(I6)')
		
		if (db[ix[i]].dpr eq 'FT' and db[ix[i]].chopfrq ne 0) then chopwarning = '!!! Chopped !!!' else chopwarning = ''
		
		if (i mod 20 eq 0) then print, '=====     ', db[ix[i]].mcc_name, '     =====   BL   DPR    PROGRAM-ID  NGOOD  GOOD? SEEING   AIRMASS    HA   MODE'
		ha = db[ix[i]].lst/3600. - db[ix[i]].ra / 15.
		print, db[ix[i]].day, '  ', db[ix[i]].time, '   ', $
		   '   ', db[ix[i]].telescope, '   ', db[ix[i]].dpr, '  ', db[ix[i]].prog, '  ', ngood, '   ', obs_good, $
		   '   ', strtrim(db[ix[i]].seeing,2), '   ', strtrim(db[ix[i]].airm,2), '   ', strtrim(ha,2) , '   ', strtrim(db[ix[i]].mode,2), '   ', strtrim(db[ix[i]].grism,2) + chopwarning
	endfor
end

pro DB_QUERY_SRC_GUID, mcc_name
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	ix = where(db.mcc_name eq mcc_name and db.dpr eq 'FT') ; only look at FT for the moment
	for i=0, n_elements(ix)-1 do begin
		ra = sixty(db[ix[i]].guid_ra)
		dec = sixty(db[ix[i]].guid_dec)
		print, db[ix[i]].day, '  ', db[ix[i]].time, '   ', db[ix[i]].id, '   ', db[ix[i]].telescope, '   ', db[ix[i]].dpr, strtrim(db[ix[i]].seeing,2), '   ', strtrim(db[ix[i]].airm,2), '   ;', $
		strtrim(ra[0],2), 'h ',strtrim(ra[1],2), 'm ',strtrim(ra[2],2), 's ;',strtrim(dec[0],2), 'deg ',strtrim(dec[1],2), 'm ',strtrim(dec[2],2), 's ',  strtrim(db[ix[i]].guid_mag,2)$
		, '   ', strtrim(db[ix[i]].guid_mode,2), '   ', strtrim(db[ix[i]].guid_status,2)
	endfor
end


pro DB_QUERY_NIGHT, night, prog=prog, dbfile=dbfile, dpr=dpr
	if not keyword_set(dbfile) then dbfile = '$MIDITOOLS/local/obs/obs_db.sav'
	; find all data for that night and print some info
	restore, dbfile
	ix = where(db.day eq night)

	if keyword_set(dpr) then begin
		ix2 = where(db[ix].dpr eq dpr)
		ix = ix[ix2]
	endif

	if keyword_set(prog) then begin
		for i = 0, n_elements(ix) - 1 do begin
			prog1 = strsplit(db[ix[i]].prog,'(',/EXTRACT)
			prog2 = prog1[0]
			if (prog2 eq prog) then begin
				ix1 = i
				if n_elements(ixlist) eq 0 then ixlist = ix1 else ixlist = [ixlist, ix1]
			endif
		endfor
		ix = ix[ixlist]
	endif
	print, 'Observation information for ' + night
	for i = 0, n_elements(ix) - 1 do begin
		if db[ix[i]].id ne '-1' then id = db[ix[i]].id else id = '  '
		if strlen(id) eq 2 then a = ' ' else a=''
		print, db[ix[i]].mcc_name, '    ', db[ix[i]].day, '   ', db[ix[i]].time, '    ', $
		   id, a, '    ', db[ix[i]].telescope, '     ', db[ix[i]].dpr, '   ', db[ix[i]].shut, '   ', db[ix[i]].prog, '   ', db[ix[i]].grism, '   ', db[ix[i]].catg, '   ', db[ix[i]].mode
	endfor
end

pro DB_QUERY_SEEING, prog=prog, dbfile=dbfile
	if not keyword_set(dbfile) then dbfile = '$MIDITOOLS/local/obs/obs_db.sav'
	; find all data for that night and print some info
	restore, dbfile
	ix = where(db.day eq '2010-05-29')
	if keyword_set(prog) then begin
		for i = 0, n_elements(ix) - 1 do begin
			prog1 = strsplit(db[ix[i]].prog,'(',/EXTRACT)
			prog2 = prog1[0]
			if (prog2 eq prog) then begin
				ix1 = i
				if n_elements(ixlist) eq 0 then ixlist = ix1 else ixlist = [ixlist, ix1]
			endif
		endfor
		ix = ix[ixlist]
	endif
	stop
	print, 'Observation information for ' + night
	for i = 0, n_elements(ix) - 1 do begin
		if db[ix[i]].id ne '-1' then id = db[ix[i]].id else id = '  '
		if strlen(id) eq 2 then a = ' ' else a=''
		print, db[ix[i]].mcc_name, '    ', db[ix[i]].day, 'T', db[ix[i]].time, '    ', $
		   id, a, '    ', db[ix[i]].telescope, '     ', db[ix[i]].dpr, '   ', db[ix[i]].shut, '   ', db[ix[i]].prog, '   ', db[ix[i]].grism, '   ', db[ix[i]].catg, '   ', db[ix[i]].mode
	endfor
end