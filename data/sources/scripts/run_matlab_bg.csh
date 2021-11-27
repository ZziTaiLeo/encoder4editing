#! /bin/csh -f
#
# Runs a matlab command in the background. Change MATLAB_CMD below 
# to use matlab from a different location.
#
# Author: Itay Maoz, October 2010

# Clear the DISPLAY.
unsetenv DISPLAY  # unset DISPLAY for some shels

set MATLAB_CMD = "/usr/local/bin/matlabr2010b"

# Call MATLAB with the appropriate input and output,
# make it immune to hangups and quits using ''nohup'',
# and run it in the background.
nohup $MATLAB_CMD -nodisplay -nodesktop -nojvm -nosplash -r $1 > $2 &
