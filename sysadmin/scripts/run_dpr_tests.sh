#!/bin/bash

#Constants
TRUE=1
FALSE=0

#DEBUG
DEBUG=$TRUE
#ACTIVATE_CO_HACK=$FALSE
ACTIVATE_CO_HACK=$TRUE

BUILDLOC="/home/dpuser/build/"
SCRIPTLOC="/home/dpuser/scripts/"
PROCESSING_SCRIPT="$SCRIPTLOC/python/processUnitTests.py"
CHECK_CVS_STATUS_SCRIPT="$SCRIPTLOC/python/cvs_status.py"
DPR_TEST_RESULTS_LOC="$BUILDLOC/dpr/dist/results/"
DPR_TESTING_TEST_RESULTS_LOC="$BUILDLOC/dpr_testing/dist/results/"
DPR_TEST_TITLE="DPR Stable"
DPR_TESTING_TEST_TITLE="DPR Testing"
LAST_RUN_FILE="/home/dpuser/.last"

if [ -n "$1" ]
then
	DPR_TEST_TARGET="$1"
else
	DPR_TEST_TARGET="test"
fi

CVS_USERNAME="matthewoliver"
XENA_MODULES="archive audio basic csv dataset email example_plugin html image multipage naa office pdf plaintext plugin_howto postscript project psd website xena xml"
DPR_MODULES="RollingChecker manifest sophos-bridge dpr"
DPR_TESTING_MODULES="dpr"
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

# Lets piggy back of this script and run the new Check CVS Status scripts..
$CHECK_CVS_STATUS_SCRIPT

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
		for x in $DPR_MODULES
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
		#runCmd "cvs -z3 -d:extssh:$CVS_USERNAME@dpr.cvs.sourceforge.net:/cvsroot/dpr co -r dpr_redesign -P $DPR_REDESIGN_MODULES"
	fi
}
updateDPR


function updateDPRTesting() {
	if [ -e dpr_testing ]
	then
		for x in dpr_testing
		do
			cd $x
			runCmd "cvs update" 
			cd ..
		done
	else
		# Check out DPR
		echo "Checking out DPR Testing from *urgh* CVS *urgh*.."
		runCmd "cvs -z3 -d:extssh:$CVS_USERNAME@dpr.cvs.sourceforge.net:/cvsroot/dpr co -d dpr_testing -r testing -P $DPR_TESTING_MODULES"
		#Because DPR is being re-designed, grab the new branch for dpr and fakebridge
		#runCmd "cvs -z3 -d:extssh:$CVS_USERNAME@dpr.cvs.sourceforge.net:/cvsroot/dpr co -r dpr_redesign -P $DPR_REDESIGN_MODULES"
	fi
}
updateDPRTesting

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

# Build DPR stable
echo "Building DPR Stable.."
cd dpr
runCmd "ant init"
checkFailed "DPR failed to init." $?
runCmd "ant dist"
checkFailed "DPR failed to build." $?
cd ..

# Build DPR testing
echo "Building DPR Testing.."
cd dpr_testing
runCmd "ant init"
checkFailed "DPR testing failed to init." $?
runCmd "ant dist"
checkFailed "DPR testing failed to build." $?
cd ..

# Move xena plugins to DPR and DPR Testing
echo "Moving Xena plugins to DPR.."
cd xena
runCmd "ant -f build_plugins.xml send_to_dpr"
checkFailed "Failed to move Xena plugins." $?
cd ..
echo "Moving Xena plugins to DPR Testing..."
cd dpr
runCmd "cp -R plugins ../dpr_testing/plugins"
checkFailed "Failed to move plugins to DPR Testing." $?
runCmd "cp -R dist/plugins ../dpr_testing/dist/plugins"
checkFailed "Failed to move plugins to DPR Testing." $?
cd ..

# Run the DPR tests on stable.
echo "Running DPR Tests.."
cd dpr
ant $DPR_TEST_TARGET 2>&1 | $PROCESSING_SCRIPT $DPR_TEST_RESULTS_LOC "$DPR_TEST_TITLE"
checkFailed "Failed to run the DPR tests." $?
cd ..

# Run the DPR tests on testing.
echo "Running DPR Testing Tests.."
cd dpr_testing
ant $DPR_TEST_TARGET 2>&1 | $PROCESSING_SCRIPT $DPR_TESTING_TEST_RESULTS_LOC "$DPR_TESTING_TEST_TITLE"
checkFailed "Failed to run the DPR Testing tests." $?

#Append the finish date to last run file
echo "Finished: `date`" >> ~/.last
