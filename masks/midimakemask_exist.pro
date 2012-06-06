;;
;; purpose: take a mask as generated from a calibrator fringe image and shift to target
;;          fringe image; use existing .fringeimages.fits files if they exist
;;          adapted from EWS midiMakeMask as of 2012-01-25
;;
PRO midiMakeMask_exist, base, initialMask=initialMask,$
   shiftOnly=shiftOnly, smooth=smooth, gsmooth=gsmooth, $
   ave=ave, factor=factor, outfile=outfile
;       set defaults
   if (NOT KEYWORD_SET(factor)) then factor = 1.0
   if (NOT KEYWORD_SET(shiftOnly)) then shift = 0 else shift = 1

   wave       = oirGetWavelength(initialMask)
   wrange = WHERE(wave GT 8.5 AND (wave LT 12.5))
   wmin   = MIN(wrange)
   wmax   = MAX(wrange)
;            for weak sources it may be best to only shift mask
   if (shift eq 0) then begin
      print,'   Creating and storing mask ',base+'.srcmask.fits'
      maskimage = midiMskFit(base+'.fringeimages.fits', base, factor=factor)
   endif else begin
      print,'   Measuring shift from input mask to fringe image'
;            get data from disk and find which images we want from struct

	if not file_test(initialMask) and file_test(base+'.fringeimages.fits') then stop
	
      oldMask    = oirGetData(initialMask)
      fringeMask = oirGetData(base+'.fringeimages.fits')
      tags       = TAG_NAMES(oldMask)
      ftags      = TAG_NAMES(fringeMask)
      dTags      = WHERE(STRPOS(tags,'DATA') GE 0)
      nTags      = N_ELEMENTS(dTags)
      dPos       = intarr(2)
      fPos       = intarr(2)
      if (nTags EQ 2) then begin
         dPos[0] = WHERE(tags  EQ 'DATA1')
         dPos[1] = WHERE(tags  EQ 'DATA2')
         fPos[0] = WHERE(ftags EQ 'DATA1')
         fPos[1] = WHERE(ftags EQ 'DATA2')
      endif else if (nTags EQ 4) then begin
         dPos[0] = WHERE(tags  EQ 'DATA2')
         dPos[1] = WHERE(tags  EQ 'DATA3')
         fPos[0] = WHERE(ftags EQ 'DATA2')
         fPos[1] = WHERE(ftags EQ 'DATA3')
      endif else begin
         print,'huh?? number of data channels = ',nTags
         RETURN
      endelse
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
      print,'   Shifted masks by ',yshift,' pixels'
;              write shifted mask to disk
      oirNewData, initialMask, outfile, oldMask, /copy
   endelse
;       display new/old masks (.data2) and fringe image
   oldMask = oirGetData(initialMask, col='data2')
   oldMask = oldMask.data2[100,*]

   newMask = oirGetData(outfile,col='data2')
   newMask = newMask.data2[100,*]

   fringeImage = oirGetData(base+'.fringeimages.fits')
;  fringeImage = pseudoComplex(fringeImage.data1,/no) $
;     - pseudoComplex(fringeImage.data2,/no)
   fringeImage = - pseudoComplex(fringeImage.data2,/no)
   fringeImage = TOTAL(FLOAT(fringeImage[wmin:wmax,*]),1)

   plot,oldMask,linestyle=2,yrange=[-.2,1.2]
   oplot,newMask
   oplot,fringeImage/max(fringeImage), col=255
RETURN
END

