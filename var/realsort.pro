;; sort an array (rev: reverse order)
function realsort, arr, rev=rev
	if keyword_set(rev) then return, arr[reverse[sort(arr)]] else return, arr[sort(arr)]
end