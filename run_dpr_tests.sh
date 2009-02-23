#!/bin/bash

#DEBUG
# on = 1
# off = 0
DEBUG=0

DATE=`date +%y%m%d%H%M`
BUILDLOC="/home/dpuser/build/"
SCRIPTLOC="/home/dpuser/scripts/"
PROCESSING_SCRIPT="$SCRIPTLOC/python/processUnitTests.py"
DPR_TEST_RESULTS_LOC="$BUILDLOC/dpr/dist/results/"

if [ -n "$1" ]
then
	DPR_TEST_TARGET="$1"
else
	DPR_TEST_TARGET="test"
fi

CVS_USERNAME="matthewoliver"
XENA_MODULES="archive audio basic csv dataset email example_plugin html image multipage naa office pdf plaintext plugin_howto postscript project psd website xena xml"
DPR_MODULES="RollingChecker manifest sophos-bridge"
DPR_REDESIGN_MODULES="dpr fake-bridge"

function runCmd() {
	cmd="$1"
	if [ $DEBUG -eq 1 ]
	then
		$cmd
	else
		$cmd &> /dev/null
	fi
}

# Directory structure
mkdir $BUILDLOC &>/dev/null
cd $BUILDLOC

# Write the last run time to ~/.last
echo "`date`" > ~/.last

function updateXena() {
	if [ -e xena ]
	then
		for x in $XENA_MODULES
		do
			cd $x
			runCmd "cvs update"
			cd ..
		done
	else
		# Check out Xena
		echo "Checking out Xena from *urgh* CVS *urgh*.."
		runCmd "cvs -z3 -d:extssh:$CVS_USERNAME@xena.cvs.sourceforge.net:/cvsroot/xena co -P $XENA_MODULES"
	fi
}
updateXena

function updateDPR() {
	if [ -e dpr ]
	then
		for x in $DPR_MODULES $DPR_REDESIGN_MODULES
		do
			cd $x
			runCmd "cvs update" 
			cd ..
		done
	else
		# Check out DPR
		echo "Checking out DPR from *urgh* CVS *urgh*.."
		runCmd "cvs -z3 -d:extssh:$CVS_USERNAME@dpr.cvs.sourceforge.net:/cvsroot/dpr co -P $DPR_MODULES"
		#Because DPR is being re-designed, grab the new branch for dpr and fakebridge
		runCmd "cvs -z3 -d:extssh:$CVS_USERNAME@dpr.cvs.sourceforge.net:/cvsroot/dpr co -r dpr_redesign -P $DPR_REDESIGN_MODULES"
	fi
}
updateDPR

function checkFailed() {
	msg="$1"
	errorCode=$2
	
	if [ $errorCode -gt 0 ] 
	then
		echo "$msg"
		exit 1
	fi
}

# Build Xena
echo "Building Xena.."
cd xena
checkFailed "Xena failed to clean." $?
runCmd "ant"
checkFailed "Xena failed to build." $?
runCmd "ant -f build_plugins.xml"
checkFailed "Xena Plugins failed to build." $?
cd ..

# Build DPR
echo "Building DPR.."
cd dpr
runCmd "ant init"
checkFailed "Xena failed to init." $?
runCmd "ant dist"
checkFailed "Xena failed to build." $?
cd ..

#Building fake-bridge
echo "Building Fake-bridge.."
cd fake-bridge
runCmd "ant"
checkFailed "Fake-bridge failed to build." $?
cd ..

# Move xena plugins to DPR
echo "Moving Xena plugins to DPR.."
cd xena
runCmd "ant -f build_plugins.xml send_to_dpr"
checkFailed "Failed to move Xena plugins." $?
cd ..

# Run the DPR tests.
echo "Running DPR Tests.."
cd dpr
runCmd "ant $DPR_TEST_TARGET 2>&1 | $PROCESSING_SCRIPT $DPR_TEST_RESULTS_LOC"
checkFailed "Failed to run the DPR tests." $?
