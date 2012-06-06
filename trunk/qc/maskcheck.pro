;; PRO Maskcheck: collect all mask shift positions
;;

function onemaskcheck, night, sciid, oldews=oldews
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	calid = closestcal(night, sciid, /withphot, /verbose)
	caltag = maketag(night,calid)
	shifta = midigetkeyword('YSHIFTA',caltag+'.newmask.fits')
	shiftb = midigetkeyword('YSHIFTB',caltag+'.newmask.fits')
	shiftab = midigetkeyword('YSHIFT',caltag+'.newmask.fits')
	
	one = {night:night, calid:calid, shifta:shifta, shiftb:shiftb, shiftab:shiftab}
	return, one
end

pro maskcheck, maskdata
	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	ix = where(db.mcc_name eq 'NGC5128' and db.dpr eq 'FT' and db.grism eq 'PRISM' and db.day ne '2006-01-20'and db.day ne '2010-05-31' and db.day ne '2010-05-30')
	for i=0, n_elements(ix)-1 do begin
		print, db[ix[i]].day, db[ix[i]].id
		one = onemaskcheck(db[ix[i]].day, db[ix[i]].id)
		if i eq 0 then maskdata = one else maskdata = [maskdata, one]
	endfor
end