; also read time <-> format in a way to easy oplot in gainplot!

;; helper function: remove quotation marks, check for number
function polish_data, arr
	arr = reform(arr)
	ix = where(arr eq 'N/A')
	if ix[0] ne -1 then arr[ix] = '-1'
	arr = float(arr)
	return,arr
end


;; helper function to read date time string and convert it into hours since midnight
function read_time, arr
	arr = reform(arr)
	farr = fltarr(n_elements(arr))
	for i=0, n_elements(arr)-1 do begin
		hhmmss = strsplit(arr[i],':',/extract)
		t_UT = fix(hhmmss[0]) + fix(hhmmss[1])/60. + fix(hhmmss[2])/3600.
		if t_UT gt 14 then t_UT -= 24.
		farr[i] = t_UT
	endfor
	farr = farr[sort(farr)]
	return, farr
end

function ambismooth, t_ut, ambi, sm
	ix_good = where(ambi ne -1 and t_ut ne -1)
	ambismooth = smooth(ambi[ix_good], sm)
	t_utsmooth = smooth(t_ut[ix_good], sm)
	smoothdimm = {t_ut:t_utsmooth, ambi:ambismooth}
	return, smoothdimm
end


;; read a file of comma-separated values as exported from
;; http://archive.eso.org/wdb/wdb/eso/ambient_paranal/form
;;

function read_dimm, night
	txt_file = '$MIDILOCAL/obs/DIMM/'+night+'.txt'
	IDL_file = '$MIDILOCAL/obs/DIMM/'+night+'.sav'
	if not file_test(IDL_file) then begin
		if file_test(txt_file) then begin
			a = read_text(txt_file)
			t_UT = read_time(a[1,*])
			ra = polish_data(a[2,*])
			dec = polish_data(a[3,*])
			seeing = polish_data(a[4,*])
			airmass = polish_data(a[5,*])
			flux_rms = polish_data(a[6,*])
			tau0 = polish_data(a[7,*])
			theta0 = polish_data(a[8,*])
	
			dimm = {t_UT:t_UT, ra:ra, dec:dec, airmass:airmass, seeing:seeing, flux_rms:flux_rms, tau0:tau0, theta0:theta0}
			save, dimm, filename=IDL_file
		endif else begin
			print, 'File not found: ' + txt_file
			stop
		endelse
	endif else restore, IDL_file
	return, dimm
end