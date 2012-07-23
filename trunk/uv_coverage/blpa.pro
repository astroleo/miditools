;
; This function takes the xyz coordinates from the headers with LST,
; RA, DEC and returns baseline and position angle for that observation.
;
function blpa, xyz, lst, ra, dec
; with code from Roy van Boekel
   x1 = xyz[0].x
   y1 = xyz[0].y
   z1 = xyz[0].z
   x2 = xyz[1].x
   y2 = xyz[1].y
   z2 = xyz[1].z
   ;
   ; baseline components in meters
   ;
   B_E=(x2-x1)
   B_N=(y2-y1)
   B_L=(z2-z1)

  ha=((lst/3600.)*(360./24.)-RA)*!dpi/180. ;; source hour angle in radians
  dec=dec*!dpi/180.      ;; source declination and
  bl=-24.62587*!dpi/180. ;; Paranal lattitude in radians

  u=(B_E*cos(ha)-B_N*sin(bl)*sin(ha)+B_L*cos(bl)*sin(ha))
  v=(B_E*sin(dec)*sin(ha)+B_N*(sin(bl)*sin(dec)*cos(ha)+cos(bl)*cos(dec))$
                         -B_L*(cos(bl)*sin(dec)*cos(ha)-sin(bl)*cos(dec)))

bl = sqrt(u^2+v^2)
pa = atan(u/v)*180./!dpi
if pa le 0. then pa+=180
blpa = {bl:bl,pa:pa}
  dec=dec*180/!dpi ;; change the declination back to degrees
  return,blpa
end
