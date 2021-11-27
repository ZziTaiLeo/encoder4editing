README

Library PMK was downloaded from http://people.csail.mit.edu/jjl/libpmk/
See http://people.csail.mit.edu/jjl/libpmk/documentation/ for documentation

For our purpose, we used 3 tools:
hierarchical-cluster-point-set.out
clusters-to-pyramids.out
pyramid-match-kernel.out

All 3 binaries were compiled on windows 32 bit and linux 64 bit, and can be found on windows, linux64 directories.

The tar file with sources as downloaded from the site is libpmk-2.4.tar.gz
The tar file libpmk-2.4-win.tar.gz contains the necessary changes to have it compile on windows.
To compile them, simply do:

tar -zxvf libpmk-2.4.tar.gz
cd libpmk-2.4
make libpmk
make libpmk_util
make tools

