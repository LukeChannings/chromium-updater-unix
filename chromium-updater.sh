#!/bin/bash
#
# Chromium Updater
# - For Mac and Linux
# Copyright 2011 Luke Channings
#

# Function to set operating variables.
function system
{
	# Check if the system is OS X or Linux.
	UNAME=`uname`
	case $UNAME in
		Darwin)
			OS="Mac"
			ZIPNAME="chrome-mac"
			INSTALLPATH="/Applications"
			INSTALLNAME="Chromium.app"
		;;
		Linux)
			OS="Linux"
			ZIPNAME="chrome-linux"
			INSTALLPATH="/opt/"
			INSTALLNAME="chromium"
		;;
	esac
}

# Function to get the installed and current versions of Chromium.
function get_info {

	# Call System
	system

	# Check if Chromium is installed.
	if [ $INSTALLPATH/$INSTALLNAME ]; then
		echo "Chromium exists."
	fi

}

get_info
