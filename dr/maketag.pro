;;
;; function MAKETAG
;;
;; PURPOSE:
;;    takes night and time, optionally also the data reduction directory, and
;;    returns the EWS tag.
;;
;; REQUIRED INPUT:
;;    night         day of night begin (string), e.g. '2011-04-20'
;;    time          time of science observation (string), e.g. '01:23:45'
;;
;; OPTIONS:
;;    reddir        give data reduction directory (default: $MIDIREDDIR)
;;    stacks        returns tag for a stack of files as produced by lpsourcew_stack
;;
function maketag, night, time, reddir=reddir, stack=stack
	if not keyword_set(reddir) then reddir=getenv('MIDIREDDIR')
	;
	d=reddir + '/' + night
	if not file_test(d) then spawn, 'mkdir ' + d
	;
	if keyword_set(stack) then begin
		t = maketag(stack.night, (*stack.times)[0])
		times = *stack.times
		if n_elements(times) eq 1 then return, t else begin
			for i=1, n_elements(times)-1 do t += '+' + repstr(times[i],':','')
			return, t
		endelse
	endif else return, reddir + '/' + night + '/' + repstr(time,':','')
end
