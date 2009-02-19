#!/bin/bash

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

# Directory structure
mkdir $BUILDLOC &>/dev/null
cd $BUILDLOC

function updateXena() {
	if [ -e xena ]
	then
		for x in $XENA_MODULES
		do
			cd $x
			cvs update &>/dev/null
			cd ..
		done
	else
		# Check out Xena
		echo "Checking out Xena from *urgh* CVS *urgh*.."
		cvs -z3 -d:extssh:$CVS_USERNAME@xena.cvs.sourceforge.net:/cvsroot/xena co -P $XENA_MODULES &>/dev/null
	fi
}
updateXena

function updateDPR() {
	if [ -e dpr ]
	then
		for x in $DPR_MODULES $DPR_REDESIGN_MODULES
		do
			cd $x
			cvs update &>/dev/null
			cd ..
		done
	else
		# Check out DPR
		echo "Checking out DPR from *urgh* CVS *urgh*.."
		cvs -z3 -d:extssh:$CVS_USERNAME@dpr.cvs.sourceforge.net:/cvsroot/dpr co -P $DPR_MODULES  &>/dev/null
		#Because DPR is being re-designed, grab the new branch for dpr and fakebridge
		cvs -z3 -d:extssh:$CVS_USERNAME@dpr.cvs.sourceforge.net:/cvsroot/dpr co -r dpr_redesign -P $DPR_REDESIGN_MODULES &>/dev/null
	fi
}
updateDPR

# Build Xena
echo "Building Xena.."
cd xena
ant clean &>/dev/null
ant &>/dev/null
ant -f build_plugins.xml &>/dev/null
cd ..

# Build DPR
echo "Building DPR.."
cd dpr
ant clean &>/dev/null
ant init &>/dev/null
ant dist &>/dev/null
cd ..

#Building fake-bridge
echo "Building Fake-bridge.."
cd fake-bridge
ant &>/dev/null
cd ..

# Run the DPR tests.
echo "Running DPR Tests.."
cd dpr
ant $DPR_TEST_TARGET 2>&1 | $PROCESSING_SCRIPT $DPR_TEST_RESULTS_LOC
