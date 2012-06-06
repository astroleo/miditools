;; FUNCTION READ_MP
;; 
;; PURPOSE:
;;    Helper function to read in blank separated text files
;;    Comments may be added by prefixing a line with #
;;    A line can also be followed by a # and a comment
;;
;; PARAMETERS
;;    sep    alternative separator
;;
function read_text, filename, sep=sep
	if not keyword_set(sep) then sep = ' '
	openr,lun,filename,/get_lun
	line=''
	i=0
	while not eof(lun) do begin
		readf,lun,line
		while (strmid(line,0,1) eq '#') do readf,lun,line
		commentcol = strpos(line,'#')
		if commentcol ne -1 then line = strmid(line,0,commentcol-1)
		oneline = strtrim(strsplit(line, sep, /extract),2)
		if (i eq 0) then data = oneline else data = [[data], [oneline]]
		i=i+1
	endwhile
	free_lun, lun
	return, data
end