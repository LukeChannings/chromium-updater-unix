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
			DMDOPTS="-sO" # Download Options.
			DMDDOPTS="-O" # File download option.
			DMSOPTS="-s" # Streaming Options.
		;;
		Linux)
			OS="Linux"
			ZIPNAME="chrome-linux"
			INSTALLPATH="/opt/"
			INSTALLBASE="chromium"
			INSTALLNAME="chrome"
			DM="wget" # Download Manager
			DMDOPTS="-q" # Download Options.
			DMDDOPTS="" # File download option.
			DMSOPTS="-qO-" # Streaming Options
		;;
		\?)
			echo "This system is not supported."
			exit
		;;
	esac

	ZIPOPTS="-q"
	ECHOOPTS="-n"

}

# Function to turn an SVN Revision number into a version number.
# $1 - SVN Revision Number.
getVersion(){

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
		echo "Installed and requested versions are the same. Nothing to do here."
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

		# Test that the revision exists.
		REVISIONEXISTS=`$DM $DMSOPTS "http://build.chromium.org/f/chromium/snapshots/$OS/$1/REVISIONS" | grep 404`

		if [ -z "$REVISIONEXISTS" ]; then
			echo "Downloading r$1...			"
			$DM "http://build.chromium.org/f/chromium/snapshots/$OS/$1/$ZIPNAME.zip" $DMDDOPTS

		else
			echo "Revision $1 does not exist. Fatal."
			exit
		fi
		
		# Extract.
		printf "Extracting...\t\t\t"
		unzip $ZIPOPTS $ZIPNAME.zip
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
		if [ $OS == "Linux" ]; then
			
			echo "Installing requires root. Please enter your password:"
			
			# Make /opt/chromium if it doesn't exist already.
			if [ ! -d /opt/chromium ]; then sudo mkdir /opt/chromium; fi

			# Make it writable.
			sudo chmod -R 775 /opt/chromium

			# Install.
			sudo cp -R chrome-linux/ /opt/chromium
		
		# If Installing on OS X...
		elif [ $OS == "Mac" ]; then

			# Copy the app to /Applications.
			cp -R chrome-mac/Chromium.app /Applications/
		fi

		echo "Installed Chromium version $CURRENTVERSION. (SVN r$1)"

	fi

}

# Function to update Chromium to the latest version.
update() {

	# Get info on installed version.
	get_info

	# Call install.
	install $CURRENTREV

}

update
