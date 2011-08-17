#!/bin/bash
#
# Chromium Updater
# - For Mac and Linux
# Copyright 2011 Luke Channings
#

# Function to set operating variables.
function system {
	# Check if the system is OS X or Linux.
	UNAME=`uname`
	case $UNAME in
		Darwin)
			OS="Mac"
			ZIPNAME="chrome-mac"
			INSTALLPATH="/Applications"
			INSTALLBASE="Chromium.app"
			INSTALLNAME="/Contents/MacOS/Chromium"
			DM="curl" #Download Manager.
			DMDDOPTS="-O" # File download option.
			DMSOPTS="-s" # Streaming Options.
            # Check not Tiger.
                TIGERCHECK=`system_profiler SPSoftwareDataType | grep 'System Version' | grep "10.4"`
            if [ ! -z "$TIGERCHECK" ]; then
                echo "Chromium does not support OS X Tiger. Please upgrade OS X Leopard at least."
                exit
            fi
		;;
		Linux)
			if [ `uname -p` == "x86_64" ]; then
				OS="Linux_x64"
			else
				OS="Linux"
			fi
			ZIPNAME="chrome-linux"
			INSTALLPATH="/opt"
			INSTALLBASE="chromium"
			INSTALLNAME="chrome"
			DM="wget" # Download Manager
			DMDDOPTS="" # File download option.
			DMSOPTS="-qO-" # Streaming Options
		;;
		\?)
			echo "This system is not supported."
			exit
		;;
	esac

	SYSTEMCALLED=true

}

# Function to turn an SVN Revision number into a version number.
# $1 - SVN Revision Number.
getVersion(){

	# Make sure system was called.
	if [ -z "$SYSTEMCALLED" ]; then
		system
	fi

	# Make sure there is a revision number to work with.
	if [ -z "$1" ]; then
		echo "getVersion() was not passed a revision number."
		exit
	fi

	# Find the Version number of the revision.
	RETURNEDVERSION=`$DM $DMSOPTS http://src.chromium.org/viewvc/chrome/trunk/src/chrome/VERSION?revision=$1 | \
	sed -e 's/MAJOR=//' -e 's/MINOR=/./' -e 's/BUILD=/./' -e 's/PATCH=/./' | tr -d '\n'`

}

# Function to get the installed and current versions of Chromium.
# $1: True - Disable current revision lookup.
get_info() {

	# Call System
	system

	# Message...
	printf "Gathering info...\t\t\t"

	# Check Revision lookup parameter.
	if [ -z "$1" ]; then
		LOOKUPLATESTREVISION=true
	else
		LOOKUPLATESTREVISION=false
	fi

	# Get information on the installed Chromium version.
	if [ -f $INSTALLPATH/$INSTALLBASE/$INSTALLNAME ]; then
		# Find version.
		INSTALLEDVERSION=`$INSTALLPATH/$INSTALLBASE/$INSTALLNAME --version | sed "s/Chromium//" | sed "s/ //g"`
		# Find SVN Revision. (Only possible on OS X sadly.)
		if [ $OS == "Mac" ]; then
			INSTALLEDREV=`cat /Applications/Chromium.app/Contents/Info.plist | grep -A 1 SVNRevision | grep -o "[[:digit:]]\+"`
		fi
		# Set installed variable for other functions.
		INSTALLED=true
	else
		INSTALLED=false
	fi
	
	# Find the latest SVN Revision and its version.
	if $LOOKUPLATESTREVISION; then
		# Find the Revision number.
		CURRENTREV=`$DM $DMSOPTS http://build.chromium.org/f/chromium/snapshots/$OS/LATEST`
		# Get the version from the SVN Revision.
		getVersion $CURRENTREV
		CURRENTVERSION=$RETURNEDVERSION
	fi

	echo "Done."
}
# Function to install Chromium.
#
# Parameters:
# $1 - SVN Revision to install.
# $2 - No install bool.
#
install() {

	# Check for a Revision number.
	if [ -z "$1" ]; then
		echo "Install function requires a revision variable."
		exit
	else
		# Find the version.
		getVersion $1
		VERSION=$RETURNEDVERSION
	fi

	# Check that the version about to be installed is not the same
	# as the version currently installed.
	if [ "$VERSION" == "$INSTALLEDVERSION" ]; then
		echo "The requested version is already installed. Nothing to do here."
		exit
	fi

	# Check for NOINSTALL.
	if [ -z "$2" ]; then
		NOINSTALL=false
	else
		NOINSTALL=true
	fi

	# Make a temporary folder in which to put downloaded files.
	TMPNAME="chromium_r$1"
	if [ ! -d $TMPNAME ]; then mkdir $TMPNAME; fi
	cd $TMPNAME
	
	# Check for an existing zip.
	if [ -d chrome-mac -o -d chrome-linux ]; then
		read -p "Found an existing download. Do you want to use it? (Y/N) " USEEXISTING
		case $USEEXISTING in
			y|Y|Yes|YES)
				USEEXISTING=true
			;;
			n|N|No|NO|\?)
				USEEXISTING=false
				rm -rf chrome-mac.zip chrome-linux.zip chrome-mac chrome-linux 2> /dev/null
			;;
		esac
	else
		USEEXISTING=false
	fi

	# Download Chromium when we're not using existing file.
	if ! $USEEXISTING ; then

		# ^C Trap.
		trap "rm -rf $PWD;echo ""; exit" SIGINT

		# Test that the revision exists.
		REVISIONEXISTS=`$DM $DMSOPTS "http://build.chromium.org/f/chromium/snapshots/$OS/$1/REVISIONS" | grep 404`

		if [ -z "$REVISIONEXISTS" ]; then
			echo "Downloading r$1...			"
			rm chrome-linux.zip chrome-mac.zip 2> /dev/null # In case there is a .n naming conflict.
			$DM "http://build.chromium.org/f/chromium/snapshots/$OS/$1/$ZIPNAME.zip" $DMDDOPTS

			if $?; then

		else
			echo "Revision $1 does not exist. Fatal."
			exit
		fi
		
		# Extract.
		printf "Extracting...\t\t\t"
		unzip -q $ZIPNAME.zip
		echo "Done."

	fi

	# Install
	if ! $NOINSTALL; then

		# If Chromium is installed...
		if $INSTALLED; then

			# Kill any running instance.
			killall chromium 2> /dev/null
			
			# Delete the current version.
			rm -rf $INSTALLPATH/$INSTALLBASE
		fi

		# If installing on Linux...
		if [[ $OS =~ Linux.* ]]; then
			
			echo "Installing requires root. Please enter your password:"

			# Some distro's don't have a symlink to /lib/libbz2.1.0
			for i in `ls /lib | grep libbz2`; do
				# Make one.
				sudo ln -s $i /lib/libbz2.so.1.0
				# Exit the loop.
				break
			done
			
			# Delete existing Chromium if it exists.
			if $INSTALLED; then sudo rm -rf $INSTALLPATH/chromium; fi

			# Copy the new Chromium.
			sudo cp -R chrome-linux $INSTALLPATH/chromium

			# Change ownership.
			sudo chown -R `whoami` $INSTALLPATH/chromium

			# Change Mode.
			chmod -R 700 $INSTALLPATH/chromium/

            # If there is no Chromium entry, then make one.
            if [ ! -f /usr/share/applications/google-chromium.desktop ]; then

			# Create a .desktop for Chromium.
            cat > google-chromium.desktop << "EOF"
[Desktop Entry]
Version=1.0
Name=Chromium
GenericName=Web Browser
Comment=Access the Internet
Exec=/opt/chromium/chrome %U
Terminal=false
Icon=/opt/chromium/product_logo_48.png
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml_xml;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ftp;
X-Ayatana-Desktop-Shortcuts=NewWindow;NewIncognito

[NewWindow Shortcut Group]
Name=New Window
Exec=/opt/chromium/chrome
TargetEnvironment=Unity

[NewIncognito Shortcut Group]
Name=New Incognito Window
Exec=/opt/chromium/chrome --incognito
TargetEnvironment=Unity
EOF


            # Install google-chromium.desktop
            sudo xdg-desktop-menu install google-chromium.desktop

            fi
		# If Installing on OS X...
		elif [ $OS == "Mac" ]; then

			# Copy the app to /Applications.
			cp -R chrome-mac/Chromium.app /Applications/
		fi

		echo "Installed Chromium version $CURRENTVERSION. (SVN r$1)"

        # Cleanup.
        rm -rf $PWD

	fi

	# Exit. (Prevents printing of usage.)
	exit

}

# Usage.
usage(){

	printf "Usage:\n"
	printf -- "-u\t\t\tUpgrade Chromium to the latest SVN revision.\n"
	printf -- "-r <revision>\t\t\tInstall a specific SVN revision.\n"
	printf -- "-U\t\t\tPrint this usage.\n"
	printf -- "-v\t\t\tPrint script version.\n"

	exit

}

# Options.
while getopts ":ur:Uv" opt; do
	case $opt in
		U)
			usage
		;;
		u)
			# Upgrade.
			echo "Upgrading..."
			get_info
			install $CURRENTREV
		;;
		r)
			# Install inputted revision.
			if [ -z "$OPTARG" ]; then
				echo "-r requires a revision number."
				exit
			fi

			# Install the requested revision.
			install $OPTARG
		;;
		v)
			echo "Chromium Updater - version 0.9"
			exit
		;;
		\?)
			echo "Invalid option -$OPTARG."
			usage
		;;
	esac
done

# Print the usage. (Should only occur if there are no switches or -U is passed.)
usage
