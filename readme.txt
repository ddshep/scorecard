The master Stata program is programs/run.do.  To execute the program, you'll need to change the root directory at the top of run.do.  All other Stata programs are called from within this file.  

- build.do assembles the raw Scorecard data and applies value labels to all the categorical variables.

- dropVars.do takes the built data and drops a bunch of the excess variables that we don't use for our analysis to speed up run time.

- rank.do generates the list of suggested colleges that "outrank" each school based on our algorithm parameters

build.do will download the raw data from the web through a Unix shell. I'm not certain that this step will work if you're running Stata for Windows.  The syntax may be Mac-specific.  Let me know if that's the case and I can send you the data files.

All of the output, including the list of suggested schools and some graphs and descriptive statistics about the sample restrictions, gets stored in the output directory.  The output directory can’t be seen in the repo as is.  It gets created when you run the program.