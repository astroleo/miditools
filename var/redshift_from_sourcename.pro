function redshift_from_sourcename, sourcename
	a=read_text('$MIDITOOLS/local/obs/sources_info.txt',sep='/')
	ix2 = where(a[0,*] eq sourcename)
	if ix2 eq -1 then stop

	z = float(a[13,ix2])
	return, z[0]
end