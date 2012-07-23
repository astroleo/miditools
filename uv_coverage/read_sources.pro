;; reads sources file with RA in hh mm ss, DEC in dd mm ss (signed + or -!)
;; returns co-ordinates in degrees
;;
function read_sources, file
	a=read_text(file, sep=" ")
	name = reform(a[0,*])
	ra_hh = reform(float(a[1,*]))
	ra_mm = reform(float(a[2,*]))
	ra_ss = reform(float(a[3,*]))
	dec_sign = strmid(a[4,*],0,1)
	dec_dd = abs(reform(float(a[4,*])))
	dec_mm = reform(float(a[5,*]))
	dec_ss = reform(float(a[6,*]))
	
	RA = 15.*(ra_hh + ra_mm/60. + ra_ss/3600.)
	DEC = fltarr(n_elements(RA))

	for i=0, n_elements(a[1,*])-1 do begin
		if dec_sign[i] eq '+' then DEC[i] = (dec_dd[i] + dec_mm[i]/60. + dec_ss[i]/3600.) else $
			DEC[i] = -(dec_dd[i] + dec_mm[i]/60. + dec_ss[i]/3600.)
		one = {name:name[i], ra:RA[i], dec:DEC[i]}
		if i eq 0 then sources=one else sources = [sources, one]
	endfor
	return, sources
end