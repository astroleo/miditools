;;
;; PRO MASK_SELECT
;;
;; PURPOSE:
;;    select a mask for a science track observation, based on closestcal's fringeimage
;;    compares the automatically found mask with a manually maintained list of observations
;;        that require the mask to be shifted, computes shifted mask if it doesn't exist 
;;        and gives back the filename of the shifted mask
;;    if no shift is required, returns default calmask
;;
;; REQUIRED INPUT:
;;    night         day of night begin (string), e.g. '2011-04-20'
;;    time          time of science observation (string), e.g. '01:23:45'
;;
;; OPTIONAL INPUT:
;;    mask          set this to a named variable to return maskname (otherwise the whole procedure is quite pointless)
;;    forcecalmask  force to use cal mask (needed for initial generation of science fringeimage)
;;
;; LIMITATIONS:
;;     so far works only for fringe track masks (not for photometry masks)
;;
pro mask_select, night, time_sci, mask=mask, forcecalmask=forcecalmask
	;;
	;; calibrator mask
	time_cal = closestcal(night, time_sci, /verbose, bestix=bestix)
	caltag = maketag(night, time_cal)
	calmask = caltag + '.srcmask.fits'
	
	scitag = maketag(night, time_sci)
	;;
	;; manual list of shifted science fringeimages
	list = read_text('$MIDITOOLS/local/obs/fringeshifts.txt')
	ix = where(list[0,*] eq night and list[1,*] eq time_sci)
	
	if ix[0] eq -1 or keyword_set(forcecalmask) then mask = calmask else begin
		lprint, 'mask_select: Creating shifted target mask for ' + night + ' / ' + time_sci
		mask = caltag+'_'+repstr(time_sci,':','')+'.srcmask.fits'
		if not file_test(mask) then begin
			midiMakeMask_exist, scitag, initialmask=calmask, /shiftonly, outfile=mask
		endif
	endelse
end