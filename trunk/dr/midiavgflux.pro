@$MIDITOOLS/MIDI/l2c

; option: two: input is 2D array (wavelength x N), average over both dimensions

function midiavgflux, spec, lam, deltalam, two=two
	c0 = l2c(lam+deltalam)
	c1 = l2c(lam)
	c2 = l2c(lam-deltalam)
	if keyword_set(two) then avgflux = total(spec[c0:c2,*])/((c2-c0+1)*n_elements(spec[0,*])) else $
		avgflux = total(spec[c0:c2])/(c2-c0+1)

	return, avgflux
end