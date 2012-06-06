;;
;; helper function to extract time in decimal format as hours before / after midnight UT
;;
function hhmmss, timestring
	for i=0, n_elements(timestring)-1 do begin
		a = strsplit(timestring[i],':',/extract)
		hh = float(a[0]) + 1/60. * float(a[1]) ;; UT hours
		if hh gt 14. then hh -= 24.
		if i eq 0 then all_hh = hh else all_hh = [all_hh, hh]
	endfor
	return, all_hh
end
