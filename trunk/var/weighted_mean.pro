;;
;; computes error-weighted mean and error of mean given arrays of data and errors
;;
function weighted_mean, data, errors
	m = total(data/errors^2) / total(1/errors^2)
	m_err = sqrt(1/total(1/errors^2))
	return, {m:m, m_err:m_err}
end