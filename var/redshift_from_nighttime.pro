function redshift_from_nighttime, night, time
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	ix = where(db.day eq night and db.time eq time)
	a=read_text('$MIDITOOLS/local/obs/sources_info.txt',sep='/')
	ix2 = where(a[0,*] eq db[ix].mcc_name)
	if ix2 eq -1 then begin
;		print, -1
		return, -1
	endif else begin
		z = float(a[13,ix2])
;		print, z
		return, z[0]
	endelse
end