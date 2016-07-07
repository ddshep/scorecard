***********************************************

// keep currently operating schools 
assert inlist(curroper, 0, 1)
keep if curroper 

save $root/data/scratch/clean, replace

***********************************************