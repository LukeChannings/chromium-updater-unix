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
	elif [ $OS == "Linux" ]; then
		CURRENTREV=`wget -qO- http://build.chromium.org/f/chromium/snapshots/Linux/LATEST`
	fi
}

get_info

if $INSTALLED; then
	echo "Chromium version $INSTALLEDVERSION"
	if [ $OS == "Mac" ]; then echo "Chromium SVN Revision $INSTALLEDREV"; fi
fi

echo "Latest revision is $CURRENTREV"
