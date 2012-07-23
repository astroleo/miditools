;;
;; READHDR
;; 
;; PURPOSE:
;;    read out a file list as produced with midigui[s], return header as list of structs
;;    give every fringe track an id (s1, s2, ... and c1, c2, ...) depending on cal or sci category
;; 
;; USAGE:
;;    reads a file list as returned by midigui[s]
;;    all files in f must be from one and only one night
;;    returns a struct with header information for all files in f
;; 
;; WARNINGS:
;;    may contain wrong program IDs (if given wrong in the OB)
;;
;; REVISION HISTORY
;;
;; 2011-04-25    now reading (archive) filename from header keyword 'ARCFILE'
;;
function readhdr, f
   if not keyword_set(f) then f = midiguis()
   ;
   ; Check if files exist
   ;
   for i=0, n_elements(f)-1 do begin
      files = strsplit(f[i],' ',/EXTRACT)
      for j=0, n_elements(files)-1 do begin
         ftest = '[ -f ' + files[j] + ' ] && echo "1" || echo "2"'
         spawn, ftest, result
         if result ne 1 then begin
            print, 'file ' + files[j] + ' not found.'
            stop
         endif
      endfor
   endfor
   ;
   isci = 1 ; start numbering sci IDs with 1...
   ical = 1 ; start numbering cal IDs with 1...
   ;
   for i=0, n_elements(f)-1 do begin
      files = strsplit(f[i],' ',/EXTRACT)
      ;;
		;;    using whichnight.sh to extract the day (it will give the day of night begin)
		spawn, '$MIDITOOLS/f/whichnight.sh ' + f[i], day
		day = day[0]
		;;
		;; make sure that we have only data from one night
		if i eq 0 then dayday = day else begin
			if day ne dayday then begin
	   		print, 'dayday: ', dayday, ' ne day: ', day
  		 		stop
			endif
		endelse
      ;;
      ;; check for HIGH_SENS / SCI_PHOT
      bc = strtrim(midigetkeyword('INS OPT1 NAME',f[i]),2)
      if bc eq 'SCI_PHOT' then beamcombiner = 'SCI_PHOT' $
      	else if bc eq 'HIGH_SENS' then beamcombiner = 'HIGH_SENS' $
      	else if bc eq 'OPEN' then beamcombiner = 'OPEN' $
      	else begin
      		print, 'Beamcombiner ' + bc + ' not recognized.'
      		continue
      	endelse
     	;;
      ;; checks for DPR types fringe search and -track are slightly more complicated than 
      ;; for the other DPR types since ESO uses various dpr types for the
      ;; same data types, e.g. 'FRINGE_TRACK,OBJECT,FOURIER' (only for mjd < 54420?)
      ;; and 'TRACK,OBJECT,DISPERSED' for fringe tracks in HIGH_SENSE
		;;
		dprtype = midigetkeyword('DPR TYPE',f[i])
		if strmatch(dprtype,'*TRACK*') then dpr = 'FT' $
		else if strmatch(dprtype,'*PHOTOMETRY*') then dpr = 'PH' $
		else if strmatch(dprtype,'*SEARCH*') then dpr = 'FS' $
      else if (dprtype eq 'COARSE,OBJECT') then dpr = 'AQ' $
		else begin
			print, 'Unrecognized DPR type: ', dprtype
			continue
		endelse     	
		;;
      shutter = strtrim(midigetkeyword('INS SHUT NAME',f[i]),2)
      if (shutter eq 'AOPEN') then shut = 'A' else if (shutter eq 'BOPEN') then shut = 'B' else if (shutter eq 'ABOPEN') then shut = 'AB' $
      else begin print, shutter, ' not recognized.' & continue & endelse
      filter = strtrim(midigetkeyword('INS FILT NAME',f[i]),2)
      grism = strtrim(midigetkeyword('INS GRIS ID',f[i]),2)
      mode = strtrim(midigetkeyword('DET NRTS MODE',f[i]),2)
;      telescope =  strsplit(midigetkeyword('TELESCOP',f[i]),'-',/EXTRACT)
;      telescope = telescope[2]
		stations = [strtrim(midigetkeyword('ISS CONF STATION1',f[i]),2), strtrim(midigetkeyword('ISS CONF STATION2',f[i]),2)]
;		stations_ix = 
		stations = stations[sort(stations)]
		telescope = stations[0] + stations[1]
      datetime = strsplit(midigetkeyword('DATE-OBS',f[i]),'T',/EXTRACT)
      prog = strtrim(midigetkeyword('OBS PROG ID',f[i]),2)
  		chopfrq = float(midigetkeyword('ISS CHOP FREQ', f[i]))
      time = strsplit(datetime[1],'.',/EXTRACT)
      ra = double(midigetkeyword('RA',f[i]))
      dec = double(midigetkeyword('DEC',f[i]))
      lst = strtrim(midigetkeyword('LST',f[i]),2)
      lst = double(lst)
      mjd_start = double(midigetkeyword('MJD-OBS',f[i]))
      x1 = double(midigetkeyword('ISS CONF T1X',f[i]))
      y1 = double(midigetkeyword('ISS CONF T1Y',f[i]))
      z1 = double(midigetkeyword('ISS CONF T1Z',f[i]))
      x2 = double(midigetkeyword('ISS CONF T2X',f[i]))
      y2 = double(midigetkeyword('ISS CONF T2Y',f[i]))
      z2 = double(midigetkeyword('ISS CONF T2Z',f[i]))
      xyz = [{x:x1,y:y1,z:z1},{x:x2,y:y2,z:z2}]
      ;
      blpa = blpa(xyz,lst,ra,dec)
      dit = double(midigetkeyword('DET DIT',f[i])) ;; in seconds
      ;;
      ;; get NDIT of all files that belong to one observation
      ;;
      ndit = 0
      for j = 0, n_elements(files)-1 do begin
         ndit += long(midigetkeyword('DET NDIT',files[j]))
      endfor
      airm = float(midigetkeyword('ISS AIRM START',f[i]))
		;;
		INS_PRES1_MEAN = float(midigetkeyword('INS PRES1 MEAN',f[i]))
      ;;
      ;; MACAO guide star
      guid_ra = double(midigetkeyword('COU GUID RA',f[i]))  ;; attention: RA info is weird!
      guid_dec = double(midigetkeyword('COU GUID DEC',f[i]))
      guid_mag = double(midigetkeyword('COU GUID MAG',f[i]))
      guid_mode = string(midigetkeyword('COU GUID MODE',f[i]))
      guid_status = string(midigetkeyword('COU GUID STATUS',f[i]))
      ;;
      p = match_with_mcc(ra,dec)
      mcc_name = p.mcc_name
      ;;
      ;; archive file names
      archivef = ''
      for j=0, n_elements(files) - 1 do begin
	      archivef += string(midigetkeyword('ARCFILE',files[j])) + ' '
	   endfor
	   archivef = strmid(archivef,0,strlen(archivef)-1)
		;;
		;; automatically get category via mcc (DPR CATG is often wrong)
		if p.is_sci eq 1 then catg = 'SCIENCE' else catg = 'CALIB'
		;;
	   ;; numbering of fringe tracks (IDs)
	   ;;
		if (dpr eq 'FT') and (catg eq 'SCIENCE') then begin
			id = 's' + strtrim(isci,2)
			isci++
		endif else if (dpr eq 'FT') and (catg eq 'CALIB') then begin
			id = 'c' + strtrim(ical,2)
			ical++
		endif else id = '-1'
		;;
		;; all entries between seeing and COU_AO2_WFE_RMS are only added for legacy compatibility
		;; 
      onehdr = {id:id,dpr:dpr,catg:catg,$
		shut:shut,beamcombiner:beamcombiner,filter:filter,grism:grism,mode:mode,chopfrq:chopfrq,$
		telescope:telescope,prog:prog,day:day,mjd_start:mjd_start,time:time[0],lst:lst,ra:ra,dec:dec,$
		dit:dit,ndit:ndit, airm:airm,$
		seeing:-1., $
   COU_AO1_ENC_MEAN: -1., $
   COU_AO1_ENC_RMS: -1., $
   COU_AO1_FWHM_MEAN: -1., $
   COU_AO1_FWHM_RMS: -1., $
   COU_AO1_L0_MEAN: -1., $
   COU_AO1_L0_RMS: -1., $
   COU_AO1_R0_MEAN: -1., $
   COU_AO1_R0_RMS: -1., $
   COU_AO1_STREHL_MEAN: -1., $
   COU_AO1_STREHL_RMS: -1., $
   COU_AO1_T0_MEAN: -1., $
   COU_AO1_T0_RMS: -1., $
   COU_AO1_WFE_MEAN: -1., $
   COU_AO1_WFE_RMS: -1., $
   COU_AO2_ENC_MEAN: -1., $
   COU_AO2_ENC_RMS: -1., $
   COU_AO2_FWHM_MEAN: -1., $
   COU_AO2_FWHM_RMS: -1., $
   COU_AO2_L0_MEAN: -1., $
   COU_AO2_L0_RMS: -1., $
   COU_AO2_R0_MEAN: -1., $
   COU_AO2_R0_RMS: -1., $
   COU_AO2_STREHL_MEAN: -1., $
   COU_AO2_STREHL_RMS: -1., $
   COU_AO2_T0_MEAN: -1., $
   COU_AO2_T0_RMS: -1., $
   COU_AO2_WFE_MEAN: -1., $
   COU_AO2_WFE_RMS: -1., $
		INS_PRES1_MEAN:INS_PRES1_MEAN, $
		guid_ra:guid_ra, guid_dec:guid_dec, guid_mag:guid_mag, guid_mode:guid_mode, guid_status:guid_status,$
		bl:blpa.bl,pa:blpa.pa,mcc_name:mcc_name,f:archivef}
      if n_elements(hdr) eq 0 then hdr = onehdr else hdr = [hdr, onehdr]
   endfor
   if n_elements(hdr) eq 0 then hdr = -1
   return, hdr
end