;; FUNCTION ARR_TO_LIST
;;
;; PURPOSE:
;;    Takes an IDL array and returns a list of blank separated values (like an EWS file list)
;;
function arr_to_list, array
	list = ''
	for i=0, n_elements(array)-1 do begin
		list += array[i]
		if i ne n_elements(array)-1 then list += ' '
	endfor
	return, list
end

;;
;; function AUTOSHIFTMASK
;;
;; use EWS tools to auto generate mask: shift EWS mask to max position using oirMakePhotoSpectra's autoshift
;;
function autoshiftmask, Afile, Bfile, mask, outmask
	spawn, 'oirShiftMask -A ' + Afile + ' -B ' + Bfile + ' -out ' +  outmask + ' -refMask ' + mask, exit_status=exit_status
	return, exit_status
end
;;
;; calculates the Rayleigh Jeans flux of a blackbody with given 10 micron flux
;;
function RJflux, F10_jy, lam_mu
	return, F10_jy * 10^2 * lam_mu^(-2.)
end