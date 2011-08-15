#!/bin/sh
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
		;;
		Linux)
			OS="Linux"
			ZIPNAME="chrome-linux"
		;;
	esac
}

# Function to get the installed and current versions of Chromium.
# function get_info {}

system
echo $ZIPNAME.zip
