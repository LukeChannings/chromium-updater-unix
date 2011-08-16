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
			DMSOPTS="-qO-" # Streaming Options
		;;
		\?)
			echo "This system is not supported."
			exit
		;;
	esac

	ZIPOPTS="-q"

	# Set Debugging parameter to true.
	DEBUG=true

}

# Function to get the installed and current versions of Chromium.
function get_info {

	# Call System
	system

	# Check for Debug parameter.
	if $DEBUG; then
		# Set Option overrides for debugging.
		if [ $OS == "Mac" ]; then
			DMOPTS="-O"
			DMSOPTS=""
		elif [ $OS == "Linux" ]; then
			DMOPTS=""
			DMSOPTS="-O-"
		fi
	fi

	# Check if Chromium is installed.
	if [ -d $INSTALLPATH/$INSTALLBASE ]; then
		INSTALLED=true
	else
		INSTALLED=false
	fi

	# Get information on the installed Chromium version.
	if $INSTALLED; then
		# Find version.
		INSTALLEDVERSION=`$INSTALLPATH/$INSTALLBASE/$INSTALLNAME --version | sed "s/Chromium//" | sed "s/ //g"`
		# Find SVN Revision. (Only possible on OS X sadly.)
		if [ $OS == "Mac" ]; then
			INSTALLEDREV=`cat /Applications/Chromium.app/Contents/Info.plist | grep -A 1 SVNRevision | grep -o "[[:digit:]]\+"`
		fi
	fi

	# Get information on the latest Chromium version.
	CURRENTREV=`$DM $DMSOPTS http://build.chromium.org/f/chromium/snapshots/$OS/LATEST`
	CURRENTVERSION=`$DM $DMSOPTS http://src.chromium.org/viewvc/chrome/trunk/src/chrome/VERSION?revision=$CURRENTREV | \
	sed -e 's/MAJOR=//' -e 's/MINOR=/./' -e 's/BUILD=/./' -e 's/PATCH=/./' | tr -d '\n'`

	echo "$CURRENTVERSION = $INSTALLEDVERSION"
	exit

}


# Function to install Chromium.
#
# Parameters:
# $1 - SVN Revision to install.
# $2 - No install bool.
#
install() {

	# Friendly user message...
	printf "Gathering info...\t\t"

	# Call get_info.
	get_info

	# Check for a Revision number.
	if [ -z "$1" ]; then
		REV=$CURRENTREV
		UPDATING=true
	else
		REV=$1
		UPDATING=false
	fi

	# Check for NOINSTALL.
	if [ -z "$2" ]; then
		NOINSTALL=false
	else
		NOINSTALL=true
	fi

	# Make a temporary folder in which to put downloaded files.
	TMPNAME="tmp_$REV"
	if [ ! -d $TMPNAME ]; then mkdir $TMPNAME; fi
	cd $TMPNAME

	if [ "$1" == true ]; then
		# If updating then check the current version against the installed version.
		if [ "$CURRENTVERSION" == "$INSTALLEDVERSION" ]; then
			echo "Chromium is on the latest version. ($CURRENTVERSION). Nothing to do here."
			exit
		else
			echo "Updating Chromium to r$REV."
		fi
	else
		echo "Using revision r$REV"
	fi

	# Check for an existing zip.
	if [ -f chrome-mac.zip -o -f chrome-linux.zip ]; then
		read -p "Found an existing zip file. Do you want to use it? (Y/N) " USEEXISTING
		case $USEEXISTING in
			y|Y|Yes|YES)
				USEEXISTING=true
			;;
			n|N|No|NO)
				USEEXISTING=false
				rm chrome-mac.zip chrome-linux.zip 2> /dev/null
			;;
		esac
	else
		USEEXISTING=false
	fi

	# Download Chromium when we're not using existing file.
	if ! $USEEXISTING ; then

		# Test that the revision exists.
		REVISIONEXISTS=`$DM $DMSOPTS "http://build.chromium.org/f/chromium/snapshots/$OS/$REV/REVISIONS" | grep 404`

		if [ -z "$REVISIONEXISTS" ]; then
			printf "Downloading...\t\t\t"
			$DM "http://build.chromium.org/f/chromium/snapshots/$OS/$REV/$ZIPNAME.zip" $DMDOPTS
			printf "Done\n"

		else
			echo "Revision does not exist. Fatal."
			exit
		fi
	fi

	# Extract.
	printf "Extracting...\t\t\t"
	unzip $ZIPOPTS $ZIPNAME.zip
	echo "Done."

	# Install
	if ! $NOINSTALL; then
		printf "Installing...\t\t\t"
		echo "Not really done..."
	fi

}

install
