
;
; extend structure (from Roy)
;
function extend_structure,input,fieldname,fieldvalue
  ;; first make a new "copy" of the structure input
  names=tag_names(input)
  for i=0,n_elements(names)-1 do begin
    command='x=input[0].'+string(names[i])
    dummy=execute(command)
    name=string(names[i])
    value=x
    if (i eq 0) then one=create_struct(name,value) $
    else one=create_struct(one,name,value)
  endfor
  ;; generate the desired field to be added
  if (n_elements(fieldvalue) eq 1) then $
    one=create_struct(one,fieldname,fieldvalue[0]) else $
      one=create_struct(one,fieldname,fieldvalue)

  n=n_elements(input)
  output=replicate(one,n)

  if (n gt 1) then begin
    for j=1,n-1 do begin
      for i=0,n_elements(names)-1 do begin
        ;; copy the rest of the old values
        command='output[j].'+string(names[i])+'=input[j].'+string(names[i])
        dummy=execute(command)
      endfor
    ;; now put in the rest of the values
    command='output[j].'+fieldname+'=input[j].'+fieldname
    endfor
  endif

  return,output
end
;
; match with mcc (from Roy) -- modified to also recognize science sources
;
function match_with_mcc,RA,DEC
;match_radius_cal  = 10.        ;; matching radius for calibrators
; [arcsec]. If the source position is within match_radius_cal of a 
; known calibrator, it is assumed that this source is a calibrator.
matching_radius = 10
matching_radius_sci = 30
restore, '$MIDITOOLS/cal/midi_cohen_merged.dat'

;;
;; first check if it's any of the science sources
;;
scisrcs=read_sources('$MIDITOOLS/local/obs/sources.txt')
is_sci=0

for i=0, n_elements(scisrcs)-1 do begin
	r = 3600. * sqrt(((RA-scisrcs[i].RA) * cos(DEC*!pi/180.))^2 + (DEC-scisrcs[i].DEC)^2)
	if (r le matching_radius_sci) then begin
	 mcc_name=scisrcs[i].name
    F12=-999.
    theta=-999.
    theta_err=-999.
    theta_chisq=-999.
    speclam=calcat[0].spec.lam
    specfnu=calcat[0].spec.Fnu
    spectral_type=scisrcs[i].name
    origin=''
    is_sci=1
	endif
endfor

if (is_sci eq 0) then begin
	radii=3600.*sqrt(((RA-calcat.coords.RA)*cos(DEC*!pi/180.))^2+$
		(DEC-calcat.coords.dec)^2)  ;; arcseconds
	indx=where(radii le matching_radius)
	if (indx[0] ne -1) then begin
		ii=indx[0]
		mcc_name=calcat[ii].name
		F12=calcat[ii].F12.Fnu
		theta=calcat[ii].diam.theta
		theta_err=calcat[ii].diam.err
		speclam=calcat[ii].spec.lam
		specfnu=calcat[ii].spec.Fnu
		spectral_type=calcat[ii].spectral_type
		origin=calcat[ii].origin
	endif else begin
		mcc_name='no_match!'
		F12=-999.
		theta=-999.
		theta_err=-999.
		theta_chisq=-999.
		speclam=calcat[0].spec.lam
		specfnu=calcat[0].spec.Fnu
		spectral_type='no_match!'
		origin='no_match!'
	endelse
endif

  p={mcc_name: mcc_name}
  p=extend_structure(p,'irasF12',F12)
  p=extend_structure(p,'theta',theta)
  p=extend_structure(p,'theta_err',theta_err)
  p=extend_structure(p,'speclam',speclam)
  p=extend_structure(p,'specfnu',specfnu)
  p=extend_structure(p,'spectral_type',spectral_type)
  p=extend_structure(p,'origin',origin)
  p=extend_structure(p,'is_sci',is_sci)
	;;
	;; interpolate calibrator spectrum for MIDI wavelength grid
	;;
	restore,'$MIDITOOLS/MIDI/w.sav'
	calspec_midi=interpol(p.specfnu,p.speclam,w)
	p=extend_structure(p,'w_midi',w)
	p=extend_structure(p,'calphot_midi',calspec_midi)
	;;
  return,p
end
