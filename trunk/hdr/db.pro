@$MIDITOOLS/hdr/readhdr
@$MIDITOOLS/dr/tools
;;
;; FUNCTION TRACKPHOT
;;
;; PURPOSE:
;;    return db index of phot that corresponds to a fringe track observation
;;       result can be manually overriden by entering relevant information in $MIDITOOLS/local/obs/trackphots.dat
;;
;; if phot is not associated to a fringe track and not identified as bad in the abovementioned file, a warning will be issued.
;;
function trackphot, dbinc
	manuallist = read_text('$MIDITOOLS/local/obs/trackphots.dat')
	for i=1, n_elements(dbinc)-2 do begin
		ix = where(manuallist[0,*] eq dbinc[i].day and manuallist[1,*] eq dbinc[i].time)
		
		if dbinc[i].dpr eq 'PH' then begin
			if ix[0] ne -1 and n_elements(ix) eq 1 then begin
				;; look for manual association
				; some code to overcome IDL's peculiarities
				mday=manuallist[0,ix]
				mday=mday[0]
				mfringetime=manuallist[2,ix]
				mfringetime=mfringetime[0]
				if mfringetime eq '-1' then dbinc[i].id='-1' else begin
					ixp = where(dbinc.day eq mday and dbinc.time eq mfringetime)
					if n_elements(ixp) ne 1 or ixp[0] eq -1 or dbinc[ixp].id eq '-1' then stop else dbinc[i].id=dbinc[ixp].id
				endelse
			endif else if dbinc[i].id eq '-1' and dbinc[i+1].dpr eq 'PH' and dbinc[i].shut eq 'A' and dbinc[i+1].shut eq 'B' $
				and dbinc[i-1].id ne '-1' and dbinc[i-1].dpr eq 'FT' then begin
				;; try automatic classification
				dbinc[i].id = dbinc[i-1].id
				dbinc[i+1].id = dbinc[i-1].id
				i++
			endif else begin
				;; print warning if neither manual nor automatic classification worked
				print, ' ++++++++++++++++++++++++++++++++++++++++++++++++++++ '
				print, 'WARNING: Unidentified photometry ' + dbinc[i].day + '   ' + dbinc[i].time
				print, ' ++++++++++++++++++++++++++++++++++++++++++++++++++++ '
			endelse
		endif
	endfor
	
	;; do last entry separately
	i = n_elements(dbinc)-1
	if dbinc[i].dpr eq 'PH' and dbinc[i].id eq '-1' then begin
		ix = where(manuallist[0,*] eq dbinc[i].day and manuallist[1,*] eq dbinc[i].time)
		if ix[0] ne -1 and n_elements(ix) eq 1 then begin
			dbinc[i].id = manuallist[2,ix]
		endif else begin
			print, ' ++++++++++++++++++++++++++++++++++++++++++++++++++++ '
			print, 'WARNING: Unidentified photometry ' + dbinc[i].day + '   ' + dbinc[i].time
			print, ' ++++++++++++++++++++++++++++++++++++++++++++++++++++ '
		endelse
	endif

	return, dbinc
end

;;
;; DB_BUILD
;;
;; PURPOSE:
;;    build database (IDL struct file for the time being) including
;;    all relevant header information
;;    only needs to be called if structure of database has changed, otherwise
;;    run db_increment (much faster)
;;
pro db_build, nightfile=nightfile, dbfile=dbfile
	if keyword_set(nightfile) then nights = readnightfile(nightfile) else begin
		print, 'MIDIDATA is $MIDIDATA'
		spawn, 'ls $MIDIDATA', nights
	endelse
	
	if not keyword_set(dbfile) then dbfile='$MIDITOOLS/local/obs/obs_db.sav'
	
	;;
	print, 'Database is being built for ' + strtrim(n_elements(nights),2) + ' nights.'
	;;
	for i=0, n_elements(nights)-1 do begin
		print, 'Night: ' + strtrim(nights[i],2)
		cd, '$MIDIDATA/'+nights[i], current=current
		hdr = readhdr(midifiles())
		hdr = trackphot(hdr)
		if i eq 0 then db = hdr else db = [db, hdr]
	endfor
	save, db, filename=dbfile
	print, 'Saved database file (IDL SAV) to ' + dbfile + '.'
	cd, current
end
;;
;; DB_INCREMENT
;;
;; PURPOSE:
;;    increment database by a certain night
;;    adds information to existing dbfile
;;
;; OPTIONS:
;;    dbfile    give path to a dbfile, if not given defaults to '$MIDITOOLS/local/obs/obs_db.sav'
;;    replace   delete all entries of given night and replace by entries in current filelist
;;              (recursively calls this procedure)
;;
pro db_increment, night, dbfile=dbfile, replace=replace
	if not keyword_set(dbfile) then dbfile='$MIDITOOLS/local/obs/obs_db.sav'
	restore, dbfile
	if keyword_set(replace) then begin
		ix = where(db.day ne night)
		db = db[ix]
		save, db, filename=dbfile
		print, 'Removed all entries from ' + night + ' from the database.'
		db_increment, night, dbfile=dbfile
	endif else begin
		ix = where(db.day eq night)
		cd, '$MIDIDATA/'+night, current=current
		f = midifiles()
		if ix[0] ne -1 then begin
			print, 'Data from that night already exists!'
			print, strtrim(n_elements(ix),2) + ' entries of that night in the database.'
			print, strtrim(n_elements(f),2) + ' entries in current filelist.'
			print, 'Use /replace option to replace existing entries by new ones.'
		endif else begin
			print, 'Adding current filelist (this may take a little while)...'
			dbinc = readhdr(f)
			dbinc = trackphot(dbinc)
			db = [db, dbinc]
			save, db, filename=dbfile
			print, 'Added ' + strtrim(n_elements(f),2) + ' entries for ' +$
				night + ' to database file (IDL SAV) ' + dbfile + '.'		
		endelse
		cd, current
	endelse
end

pro db_inc_many, nightfile, replace=replace
	nights = readnightfile(nightfile)
	for i=0, n_elements(nights)-1 do begin
		db_increment, nights[i], replace=replace
	endfor
end
;;
;; DB_TESTNIGHT
;;
;; PURPOSE:
;;    display extracted and constructed information for that night before adding 
;;    it to the database
;;
;; OPTIONS:
;;    add a variable name for dbinc to inspect the data that would be added as 
;;    an increment to the database
;;
pro db_testnight, night, dbinc=dbinc, all=all
	cd, '$MIDIDATA/'+night, current=current
	f = midifiles()
	dbinc = readhdr(f)
	dbinc = trackphot(dbinc)
	if keyword_set(all) then begin
		for i = 0, n_elements(dbinc) -1 do begin
			print, dbinc[i].time + ' ' + dbinc[i].mcc_name + ' ' + dbinc[i].id + ' ' + dbinc[i].dpr + ' ' + dbinc[i].shut
		endfor
	endif else begin
		ix = where(dbinc.dpr eq 'FT')
		for i = 0, n_elements(ix) -1 do begin
			print, dbinc[ix[i]].time + ' ' + dbinc[ix[i]].mcc_name + ' ' + dbinc[ix[i]].id
		endfor
	endelse
	cd, current
end