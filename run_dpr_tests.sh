#!/bin/bash

DATE=`date +%y%m%d%H%M`
BUILDLOC=~/build/
SCRIPTLOC=~/scripts/

CVS_USERNAME="matthewoliver"
XENA_MODULES="archive audio basic csv dataset email example_plugin html image multipage naa office pdf plaintext plugin_howto postscript project psd website xena xml"
DPR_MODULES="RollingChecker manifest sophos-bridge"
DPR_REDESIGN_MODULES="dpr fake-bridge"

# Directory structure
mkdir $BUILDLOC &>/dev/null
cd $BUILDLOC
#mkdir source-$DATE
#cd source-$DATE

function updateXena() {
	if [ -e xena ]
	then
		for x in $XENA_MODULES
		do
			cd $x
			cvs update
			cd ..
		done
	else
		# Check out Xena
		echo "Checking out Xena from *urgh* CVS *urgh*.."
		cvs -z3 -d:extssh:$CVS_USERNAME@xena.cvs.sourceforge.net:/cvsroot/xena co -P $XENA_MODULES #&>/dev/null
	fi
}
updateXena

function updateDPR() {
	if [ -e dpr ]
	then
		for x in $DPR_MODULES $DPR_REDESIGN_MODULES
		do
			cd $x
			cvs update
			cd ..
		done
	else
		# Check out DPR
		echo "Checking out DPR from *urgh* CVS *urgh*.."
		cvs -z3 -d:extssh:$CVS_USERNAME@dpr.cvs.sourceforge.net:/cvsroot/dpr co -P $DPR_MODULES # &>/dev/null
		#Because DPR is being re-designed, grab the new branch for dpr and fakebridge
		cvs -z3 -d:extssh:$CVS_USERNAME@dpr.cvs.sourceforge.net:/cvsroot/dpr co -r dpr_redesign -P $DPR_REDESIGN_MODULES #&>/dev/null
	fi
}
updateDPR

#Bypass up MANIFEST.MF issue
cp -iv $SCRIPTLOC/ReprocessingJobImporter.java $BUILDLOC/source-$DATE/dpr/src/au/gov/naa/digipres/dpr/core/importexport/ReprocessingJobImporter.java

# Build Xena
echo "Building Xena.."
cd xena
#ant &>/dev/null
#ant -f build_plugins.xml &>/dev/null
ant clean
ant
ant -f build_plugins.xml

# Build DPR
echo "Building DPR.."
cd ../dpr
#ant init &>/dev/null
#ant dist &>/dev/null
ant clean
ant init
ant test

#Building fake-bridge
cd ../fake-bridge
ant clean
ant
ant #&>/dev/null

