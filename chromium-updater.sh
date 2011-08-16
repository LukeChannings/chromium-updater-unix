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
		;;
		Linux)
			OS="Linux"
			ZIPNAME="chrome-linux"
			INSTALLPATH="/opt/"
			INSTALLBASE="chromium"
			INSTALLNAME="chrome"
		;;
		\?)
			echo "This system is not supported."
			exit
		;;
	esac
}

# Function to get the installed and current versions of Chromium.
function get_info {

	# Call System
	system

	# Check if Chromium is installed.
	if [ -d $INSTALLPATH/$INSTALLBASE ]; then
		INSTALLED=true
	else
		INSTALLED=false
	fi

	# Get information on the installed Chromium version.
	if $INSTALLED; then
		# Find version.
		INSTALLEDVERSION=`$INSTALLPATH/$INSTALLBASE/$INSTALLNAME --version`
		# Find SVN Revision. (Only possible on OS X sadly.)
		if [ $OS == "Mac" ]; then
			INSTALLEDREV=`cat /Applications/Chromium.app/Contents/Info.plist | grep -A 1 SVNRevision | grep -o "[[:digit:]]\+"`
		fi
	fi

	# Get information on the latest Chromium version.
	if [ $OS == "Mac" ]; then
		CURRENTREV=`curl -s http://build.chromium.org/f/chromium/snapshots/Mac/LATEST`
		CURRENTVERSIONRAW=`curl -s http://src.chromium.org/viewvc/chrome/trunk/src/chrome/VERSION?revision=$CURRENTREV`
	elif [ $OS == "Linux" ]; then
		CURRENTREV=`wget -qO- http://build.chromium.org/f/chromium/snapshots/Linux/LATEST`
		CURRENTVERSIONRAW=`wget -qO- http://src.chromium.org/viewvc/chrome/trunk/src/chrome/VERSION?revision=$CURRENTREV`
	fi
	
	CURRENTVERSION=`echo $CURRENTVERSIONRAW | sed -e 's/MAJOR=//' -e 's/MINOR=//' -e 's/BUILD=//' -e 's/PATCH=//' -e 's/ /./g'`
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


		if [ $OS == "Mac" ]; then
			DM="curl"
			STREAMOPTS="-s"
			OPTS="-sO"
		elif [ $OS == "Linux" ]; then
			DM="wget"
			STREAMOPTS="-qO-"
			OPTS="-q"
		fi

		# Test that the revision exists.
		REVISIONEXISTS=`$DM $STREAMOPTS "http://build.chromium.org/f/chromium/snapshots/$OS/$REV/REVISIONS" | grep 404`

		if [ -z "$REVISIONEXISTS" ]; then
			echo "Downloading..."
			$DM "http://build.chromium.org/f/chromium/snapshots/$OS/$REV/$ZIPNAME.zip" $OPTS

		else
			echo "Revision does not exist. Fatal."
			exit
		fi
	fi

	# Extract.
	echo "Extracting..."
	if [ $OS == "Mac" ]; then
		unzip -qo chrome-mac.zip
	elif [ $OS == "Linux" ]; then
		unzip -qo chrome-linux.zip
	fi

	# Install
	if ! $NOINSTALL; then
		echo "Installing..."
	fi

}

install "96866"
