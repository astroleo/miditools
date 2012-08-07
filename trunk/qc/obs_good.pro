@$MIDITOOLS/qc/o3.pro
;; FUNCTION OBS_GOOD
;;
;; PURPOSE:
;;    Determine the quality of a fringe track or photometry observation given its night and time
;;       Per default, obs_good will return the quality of the *fringe track* observation associated with that night,time
;;
;; REQUIRED INPUT:
;;    night, time
;;
;; OPTIONS
;;    o3      named variable, will contain the value of o3 (for its definition see qc/o3.pro)
;;    NGOOD   named variable, will contain the number of good frames as evaluated by EWS' oirAutoFlag given the parameters used during data reduction
;;    phot    set this option if you want the output to refer to the photometry associated with this night,time (NOT the fringe track)
;;    cts     named variable, will contain the average counts of the correlated flux. Cannot be used together with the phot option
;;
;; RETURN VALUE
;;  1    if observation is good as determined from NGOOD and o3 criterium (see there)
;;  0    if observation is bad as determined from NGOOD and, if corr.fits is available, o3
;; -1    if tests could not be performed (e.g. the reduced data are not available)
;;
function obs_good, night, time, o3=o3, NGOOD=NGOOD, phot=phot, cts=cts
	if keyword_set(phot) and keyword_set(NGOOD) then stop
	if not keyword_set(phot) and keyword_set(cts) then stop
	
	if keyword_set(phot) then begin
		restore, '$MIDITOOLS/local/obs/obs_db.sav'
		ix_track = where(db.day eq night and db.time eq time and db.dpr eq 'FT')
		ix_phot = where(db.day eq night and db.id eq db[ix_track].id and db.dpr eq 'PH')
		if ix_phot[0] eq -1 then return, -1
	endif

	;;
	;; preparation
	tag = maketag(night,time)
	;;
	;; tests	
	if keyword_set(phot) then m = man_bad_phot(night,time) else $
		m = man_bad_track(night,time)
	
	if keyword_set(phot) then good = man_good_phot(night,time) else $
		good = man_good_track(night,time)
	
	if keyword_set(phot) then begin
		o3A = o3(tag, /A)
		o3B = o3(tag, /B)
		o3 = -1
	endif else o3 = o3(tag, /corr)
	
	if keyword_set(phot) then begin
		;; test for photometries
		cts = ncounts_phot(night, time)
	endif else begin
		;; test for fringe tracks
		flagfile = tag+'.flag.fits'
		if not file_test(flagfile) then begin
			NGOOD = -1
			return, -1
		endif else $
			NGOOD = long(midigetkeyword('NGOOD',flagfile))
	endelse
	
	if m eq 0 then begin
		o3 = '-1'
		NGOOD = '-1'
	endif
	
	;;
	;; parameters
	cts_min = 450
	NGOOD_min = 500
	o3_max = 0.76 ; be careful before changing this -- it's precisely balanced...

	if keyword_set(phot) then begin	
		;;
		;; judgement for photometries tracks
		if good eq 1 then return, 1 else $
			if m eq 1 and cts[0] ge cts_min and cts[1] ge cts_min then return, 1 else $
;			if m eq 1 and cts[0] ge cts_min and cts[1] ge cts_min and o3A le o3_max and o3B le o3_max then return, 1 else $
			if m eq 1 and (cts[0] lt cts_min or cts[1] lt cts_min) then return, 0 else $
			if m eq 0 then return, 0 else return, -1
	endif else begin
		;;
		;; judgement for fringe tracks
		if good eq 1 then return, 1 else $
			if m eq 1 and o3 le o3_max and NGOOD gt NGOOD_min then return, 1 else $
			if m eq 1 and (o3 gt o3_max or NGOOD le NGOOD_min) then return, 0 else $
			if m eq 0 then return, 0 else return, -1
	endelse
end