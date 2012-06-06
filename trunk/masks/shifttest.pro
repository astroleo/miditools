;;
;; FUNCTION SHIFTTEST
;;
;; PURPOSE
;; compute the shift between a fringe image and a given mask
;; per default: takes night+id of science obs and searches cal mask for that
;;
;; LIMITATIONS
;; - for the moment takes nearest cal no matter if it has photometry (nophot option)
;;
function shifttest, night, time_sci
	o=obs_good(night,time_sci)
	if o ne 1 then return, [-9999,-9999]

	time_cal = closestcal(night,time_sci)
	tag_cal = maketag(night,time_cal)
	mask = tag_cal + '.srcmask.fits'
	tag_sci = maketag(night,time_sci)
	fimage = tag_sci+'.fringeimages.fits'

	if file_test(mask) and file_test(fimage) then begin
		; code from Walter
			wave       = oirGetWavelength(mask)
			wrange = WHERE(wave GT 8.5 AND (wave LT 12.5))
			wmin   = MIN(wrange)
			wmax   = MAX(wrange)
	
			oldMask    = oirGetData(mask)
			fringeMask = oirGetData(fimage)
			tags       = TAG_NAMES(oldMask)
			ftags      = TAG_NAMES(fringeMask)
			dTags      = WHERE(STRPOS(tags,'DATA') GE 0)
			nTags      = N_ELEMENTS(dTags)
			dPos       = intarr(2)
			fPos       = intarr(2)
			  dPos[0] = WHERE(tags  EQ 'DATA1')
			  dPos[1] = WHERE(tags  EQ 'DATA2')
			  fPos[0] = WHERE(ftags EQ 'DATA1')
			  fPos[1] = WHERE(ftags EQ 'DATA2')
			;            find maximum of cross correlation with images
			;            shifted in y-direction
			yshift = FLTARR(2)
			nshift = 4
			xx     = indgen(2*nshift+1)-nshift
			yy     = FLTARR(2*nshift+1)
			for i=0,1 do begin
				dold = oldMask.(dPos[i])[wmin:wmax,*]
				dff  = FLOAT(pseudoComplex(fringeMask.(fPos[i]),/no))
				dff  = dff[wmin:wmax,*]
				if (i eq 1) then dff = -dff ; phase of I2 is negative
				for j=0,2*nshift do yy[j] = $
					TOTAL(dff*shift(dold,0,xx[j]))
				yshift[i] = pk(xx, yy)
				oldMask.(dPos[i]) = pshift(oldMask.(dPos[i]), 0, yshift[i])
			endfor
	;      print,'   Shifted masks by ',yshift,' pixels'
		return, yshift
	endif else return, [-999,-999]
end