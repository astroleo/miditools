;;
;; This function tries to estimate the mean and error of a MIDI single-dish flux 
;;    measurement of an object, where the flux is averaged over a number of obs
;;    and a number of wavelength channels.
;;
;; It is assumed that the variance in MIDI spectra is composed of a zero point
;;    variance and a channel-to-channel 'photon-noise' variance.
;;
;; The error of a flux value averaged over a number of observations and 
;;    wavelengths is then given by
;;
;; sigma_tot^2 = 1/N_obs * (<sigma>^2_obs,lambda/N_lambda + <Sigma>^2_lambda)
;;
;; where:
;;    N_obs                  is the number of measurements
;;    N_lambda               is the number of wavelength channels
;;    <sigma>^2_obs,lambda   is the value of the 'photon-noise' error
;;                              (as derived by EWS), averaged over all obs and 
;;                              wavelength channels
;;    <Sigma>^2_lambda       is the variance due to background fluctuations, 
;;                              averaged over the wavelength range in question
;;
;; POSSIBLE IMPROVEMENTS: determine zero-point variation directly from photometry
;;                        data, not from struct
;;
;;
function lpavgphot, sourcename, lam, dlam, source
	restore, '$PROJECTS/LP/errors/weakphoterr.sav'
	ix = where(source.obsgood eq 1)
	nn = n_elements(ix)
	print, 'Averaging flux for ' + strtrim(nn,2) + ' out of ' + strtrim(n_elements(source),2) + ' good spectra.'

	if n_elements(ix) gt 1 then begin
		spec      = total(source[ix].spec,2)/n_elements(ix)
		spec_rms1 = total(source[ix].spec_rms,2)/n_elements(ix)
	endif else if ix[0] ne -1 then begin
		spec      = source[ix].spec
		spec_rms1 = source[ix].spec_rms
	endif else begin
		lprint, 'No good spectra for ' + sourcename
		stop
	endelse
	
	;;
	;; add zero-point variation to spectrum rms
	spec_rms = sqrt(spec_rms1^2/nn + weakphoterr.avg_zerovar^2)

	avg = fltarr(3)
	avg_rms = fltarr(3)
	
	for i=0, n_elements(lam)-1 do begin		
		avg[i]     = average_vis(spec, lam[i], dlam[i])
		;;
		;; avg_rms1 = <sigma_short>_{obs,lambda}/sqrt(N_lambda)
		avg_rms1   = average_vis(spec_rms, lam[i], dlam[i],/err)
		;;
		;; compute <sigma_long>_{lambda}^2
		sl2 = average_vis(weakphoterr.avg_zerovar,lam[i], dlam[i])
		avg_rms[i] = sqrt(1./nn * (avg_rms1^2 + sl2))
	endfor

	midi = {avg:avg, avg_rms:avg_rms, spec:spec, spec_rms:spec_rms}
	return, midi
end
