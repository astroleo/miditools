@$MIDITOOLS/MIDI/l2c
;; purpose: average a visamp or corramp array of 171 at lambda over delta lambda
;;
;; two	corrvis is a 2D array, then 1st dimension must be wavelength
;; err   calculate the error of the mean
;;
function average_vis, corrvis, lam, deltalam, two=two, err=err
	c0 = l2c(lam+deltalam)
	c1 = l2c(lam)
	c2 = l2c(lam-deltalam)
	if not keyword_set(err) then begin
		if keyword_set(two) then return, total(corrvis[c0:c2,*],1)/(c2-c0+1) else $
			return, total(corrvis[c0:c2],1)/(c2-c0+1)
	endif

	if keyword_set(err) then begin
		if keyword_set(two) then return, total(corrvis[c0:c2,*],1)/(c2-c0+1)^(3./2) else $
			return, total(corrvis[c0:c2],1)/(c2-c0+1)^(3./2)
	endif
end
