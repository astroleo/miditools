pro db_red_inc, one, db_red_file
	if file_test(db_red_file) then begin
		restore, db_red_file
		reddb = [reddb, one]					
		save, reddb, filename=db_red_file
	endif else begin
		reddb = one
		save, reddb, filename=db_red_file
	endelse
end