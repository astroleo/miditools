;; calculates the visibility of a calibrator on a given BL,
;; assuming the calibrator is a uniform disk of the given diameter,
;; for each point in the wavelength grid.
;; units: lambda [micron]
;;        BL [m]
;;        diameter [mas]
;;
;; with code from Roy van Boekel
;;
function calibrator_visibility,lambda,diameter,BL
	xx=dblarr(n_elements(lambda))
	
	for i=0,n_elements(lambda)-1 do $
		xx[i]=!dpi*(diameter/(1000.*3600.*180/!dpi))*BL/(1d-6*lambda[i])

	UD_vis2=(2.*beselj(xx,1)/xx)^2
	UD_vis=sqrt(UD_vis2)
	return, UD_vis
end