; find closest channel to lambda (in mu)
;;
;; uses PRISM wavelength calibration per default, set /grism to use GRISM calibration
;;
function l2c, lambda, grism=grism
	if keyword_set(grism) then begin
		restore, '$MIDITOOLS/MIDI/w_grism.sav'
		nn = n_elements(w)
		for i=0, n_elements(lambda)-1 do begin
			if lambda[i] ge w[nn-1] then stop
			if lambda[i] le w[0] then stop
			channel = 0
			while w[channel] le lambda[i] do channel++
			if i eq 0 then channels = channel else channels = [channels, channel]
		endfor
	endif else begin
		restore, '$MIDITOOLS/MIDI/w.sav'
		nn = n_elements(w)
		for i=0, n_elements(lambda)-1 do begin
			if lambda[i] ge 13.7 then stop
			if lambda[i] le 5.25 then stop
			channel = 170
			while w[channel] le lambda[i] do channel--
			if i eq 0 then channels = channel else channels = [channels, channel]
		endfor
	endelse
	return, channels
end