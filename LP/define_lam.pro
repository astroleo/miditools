	;;
	;; define wavelengths and intervals for averaging
	;;
pro define_lam, z=z, lam=lam, dlam=dlam
	if not keyword_set(z) then z=0
	lam_max = 12.75
	lamz = 12.0 * (1+z)
	if lamz gt lam_max then lamz = lam_max

	; lamID 0     1     2     3     4
	lam  = [8.5, 10.5, 12.5, 11.0, lamz]
	dlam = [0.2,  0.2,  0.2, 1.0, 0.2]
	nlam = n_elements(lam)
	if nlam ne n_elements(dlam) then stop
end