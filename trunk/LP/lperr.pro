pro lperr,x,y,x_lo,x_hi,y_lo,y_hi, color=color
	oplot, [[x-x_lo,x+x_hi]], [[y,y]], color=color
	oplot, [[x,x]], [[y-y_lo,y+y_hi]], color=color
end