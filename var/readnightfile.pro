; read nightfile
function readnightfile, nightfile
	openr, lun, nightfile, /get_lun
	line=''
	i=0
	while not eof(lun) do begin
		readf,lun,line
		if i eq 0 then nights = line else nights = [nights, line]
		i=i+1
	endwhile
	free_lun,lun
	return, nights
end