The master Stata program is programs/run.do.  All other Stata programs are called from within it:

- build.do assembles the raw Scorecard data and applies value labels to all the categorical variables. 

- dropVars.do takes the built data and drops a bunch of the excess variables that we don't use for our
analysis to speed up run time

- rank.do generates the list of suggested colleges that "outrank" each school based on our algorithm parameters

run.do will initialize the data directories and download the raw data from the web through a Unix shell.  
I'm not certain that this step will work if you're running Stata for Windows.  The syntax may be Mac-specific.
Let me know if that's the case and I can send you the data files.