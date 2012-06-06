;; MAKEFRINGEIMAGE
;;
;; PURPOSE:
;; produce fringe image files, if they don't exist already
;; use midiFringeImage to produce them
;; midiFringeImage expects that tag.groupdelay.fits and tag.ungroupdelay.fits 
;; files do already exist. This routine will create these files using lpw if they don't
;; (these files have been created or will be created using a calibrator fringe image mask)
;;
pro mfi, night, base, file, noave=noave
	cd, '$MIDIDATA/'+night, current=current
	midiFringeImage, base, file, noave=noave
	cd, current
end

pro makefringeimage, night, time
	base = maketag(night,time)
	gdfile = base +'.groupdelay.fits'
	ungdfile = base +'.ungroupdelay.fits'
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	ix=where(db.day eq night and db.time eq time)

	frimgfile = '$MIDIREDDIR/'+night+'/'+repstr(time,':','')+'.fringeimages.fits'
	if obs_good(night, time) eq 0 then lprint, night+' / '+time + ': Dataset not reducible.' else $
	if not file_test(frimgfile) then begin
		lprint, 'Creating fringe images for ' + night + ' / ' + time
		
		;;
		;; try to produce groupdelay and ungroupdelay files if they do not exist
		if not (file_test(gdfile) and file_test(ungdfile)) then begin
			if db[ix].catg eq 'CALIB' then begin
				lprint, gdfile + ' and / or ' + ungdfile + ' are missing... Reducing calibrator '+night+' / '+time
				lpw, night, time, /calonly
			endif else begin
				lprint, gdfile + ' and / or ' + ungdfile + ' are missing... Reducing target '+night+' / '+time
				lpw, night, time, /skipexcal
			endelse
		endif

		;;
		;; if groupdelay and ungroupdelay files were not created, give up
		if (file_test(gdfile) and file_test(ungdfile)) then begin
			file = loadf(night, time, /nophot)
			;;
			;; detect correct /dave setting
			;;
			track = midigetkeyword('DET NRTS MODE',file)
			if track eq 'OBS_FRINGE_TRACK_DISPERSED_OFF' then begin
				mfi, night, base, file, noave=0
			endif else if track eq 'OBS_FRINGE_TRACK_DISPERSED' then begin
				mfi, night, base, file, noave=1
			endif else begin
				lprint, 'mode not recognized: ' + track
			endelse
		endif else lprint, gdfile + ' and / or ' + ungdfile + ' are missing and could not be created for '+night+' / '+time
	endif else lprint, 'Fringe images for ' + night + ' / ' + time + ' already exist. Skipping this dataset.'
end