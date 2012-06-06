; function read var text saves columns of a textfile to a struct, allowing the rows to be of variable length, otherwise like read_text

; currently specifically adapted to read '[good|bad]data_*_man.txt' files

function read_text_var, filename, sep=sep
	if not keyword_set(sep) then sep = ' '
	openr,lun,filename,/get_lun
	line=''
	i=0
	while not eof(lun) do begin
		readf,lun,line
		while (strmid(line,0,1) eq '#') and not eof(lun) do readf,lun,line
		commentcol = strpos(line,'#')
		if commentcol ne -1 then line = strmid(line,0,commentcol-1)
		oneline = strtrim(strsplit(line, sep, /extract),2)
		;;
		;; build struct
		one={night:oneline[0], time:oneline[1], sourcename:oneline[2], comment:oneline[3]}
		if (i eq 0) then data = one else data = [data, one]
		i=i+1
	endwhile
	free_lun, lun
	return, data
end
