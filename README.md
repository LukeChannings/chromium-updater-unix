#Chromium Manager#

Chromium Manager is a Shell script that has been tested on Linux and BSD. (Including OS X.)
Manager has various functions, the primary function is to upgrade Chromium to the latest
SVN Revision, however, it can also install specific revisions, as well as listing the installed
and latest version on Chromium. (Both release version and SVN version.)

#Support#

Chromium Manager has been tested on various Linux distributions, including Ubuntu and CentOS, 
and has also been tested on OS X 10.5+. (Chromium is not supported on OS X Tiger.)

#Usage#

./chromium-manager [-i] [-r <revision>] [-u] [-s] [-v] <parameters>
Options:
1. -i                      Install the latest SVN revision.
2. -r <revision>           Install a specific SVN revision.
3. -u                      Print this usage.
4. -s                      Show version information for installed and latest versions.
5. -v                      Print script version.

Parameters:
1. -n                      Download only, do not install.
2. -I                      Ignore version checking.
3. -k                      Do not remove install files.
4. -R                      Run Chromium after installing.
