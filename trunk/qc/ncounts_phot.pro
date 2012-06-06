function ncounts_phot, night, time_sci
	scitag = maketag(night,time_sci)
	sci_phot_file = scitag + '.photometry.fits'
	if not file_test(sci_phot_file) then return, [-1,-1,-1]
	raw_cts = oirgetdata(sci_phot_file)

	restore, '$MIDITOOLS/local/obs/obs_db.sav'
	ix = where(db.day eq night and db.time eq time_sci)

	if db[ix].grism eq 'GRISM' then restore, '$MIDITOOLS/MIDI/w_grism.sav' else restore, '$MIDITOOLS/MIDI/w.sav'
	w_Nband = where(w gt 8. and w lt 13.)
	
	avg_A = avg(raw_cts[3].data1[w_Nband])
	avg_B = avg(raw_cts[4].data1[w_Nband])
	avg_AB = avg(raw_cts[5].data1[w_Nband])
	return, [avg_A, avg_B, avg_AB]
end