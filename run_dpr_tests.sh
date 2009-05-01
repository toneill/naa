#!/bin/bash

#Constants
TRUE=1
FALSE=0

#DEBUG
DEBUG=$TRUE
ACTIVATE_CO_HACK=$TRUE

BUILDLOC="/home/dpuser/build/"
SCRIPTLOC="/home/dpuser/scripts/"
PROCESSING_SCRIPT="$SCRIPTLOC/python/processUnitTests.py"
DPR_TEST_RESULTS_LOC="$BUILDLOC/dpr/dist/results/"
LAST_RUN_FILE="/home/dpuser/.last"

if [ -n "$1" ]
then
	DPR_TEST_TARGET="$1"
else
	DPR_TEST_TARGET="test"
fi

CVS_USERNAME="matthewoliver"
XENA_MODULES="archive audio basic csv dataset email example_plugin html image multipage naa office pdf plaintext plugin_howto postscript project psd website xena xml"
DPR_MODULES="RollingChecker manifest sophos-bridge"
DPR_REDESIGN_MODULES="dpr" # fake-bridge"

function runCmd() {
	cmd="$1"
	if [ $DEBUG -eq 1 ]
	then
		$cmd
	else
		$cmd &> /dev/null
	fi
}

#Clear the last run file and add a heading
echo "Run DPR Tests" > $LAST_RUN_FILE
echo "=============" >> $LAST_RUN_FILE

# Write the last run time to ~/.last
echo "Started: `date`" >> ~/.last

# If the ACTIVATE_CO_HACK is true then delete the BUILDLOC so everything will need to be checked out fresh.
# There seems to be some issues when a CVS update seems to break the build process. A fresh check out 
# seems to always build fine.
if [ $ACTIVATE_CO_HACK == $TRUE ]
then
	echo "=============== Checkout Hack Activated ==============="
	echo "Removing '$BUILDLOC' and it contents!!!!!!"
	rm -Rfv $BUILDLOC
	echo "=============== Checkout Hack Complete ================"

	echo "== Checkout Hack Activated ==" >> $LAST_RUN_FILE
fi 

# Directory structure
mkdir $BUILDLOC &>/dev/null
cd $BUILDLOC

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
		runCmd "cvs -z3 -d:extssh:$CVS_USERNAME@dpr.cvs.sourceforge.net:/cvsroot/dpr co -P $DPR_MODULES $DPR_REDESIGN_MODULES"
		#Because DPR is being re-designed, grab the new branch for dpr and fakebridge
		#runCmd "cvs -z3 -d:extssh:$CVS_USERNAME@dpr.cvs.sourceforge.net:/cvsroot/dpr co -r dpr_redesign -P $DPR_REDESIGN_MODULES"
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
#echo "Building Fake-bridge.."
#cd fake-bridge
#runCmd "ant"
#checkFailed "Fake-bridge failed to build." $?
#cd ..

# Move xena plugins to DPR
echo "Moving Xena plugins to DPR.."
cd xena
runCmd "ant -f build_plugins.xml send_to_dpr"
checkFailed "Failed to move Xena plugins." $?
cd ..

# Run the DPR tests.
echo "Running DPR Tests.."
cd dpr
ant $DPR_TEST_TARGET 2>&1 | $PROCESSING_SCRIPT $DPR_TEST_RESULTS_LOC
checkFailed "Failed to run the DPR tests." $?

#Append the finish date to last run file
echo "Finished: `date`" >> ~/.last
