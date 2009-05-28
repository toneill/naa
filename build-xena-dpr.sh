#!/bin/bash

DATE=`date +%y%m%d%H%M`
BUILDLOC=~/Desktop
SCRIPTLOC=~/code/naa/

# Directory structure
mkdir $BUILDLOC &>/dev/null
cd $BUILDLOC
mkdir source-$DATE
cd source-$DATE

# Check out Xena
clear
echo "Checking out Xena from *urgh* CVS *urgh*.."
echo ""
sleep 2
cvs -z3 -d:extssh:csmart@xena.cvs.sourceforge.net:/cvsroot/xena co -P archive audio basic csv dataset email example_plugin html image multipage naa office pdf plaintext plugin_howto postscript project psd website xena xml >/dev/null

if [ $? != 0 ]
then
	echo 'There was an error checking out Xena, sorry!'
	echo ""
	exit 1
fi

clear
echo "Checking out Xena from *urgh* CVS *urgh*.."

# Check out DPR (note, fake-bridge is now in test-utils)
echo "Checking out DPR from *urgh* CVS *urgh*.."
echo ""
sleep 2
cvs -z3 -d:extssh:csmart@dpr.cvs.sourceforge.net:/cvsroot/dpr co -P dpr manifest RollingChecker >/dev/null
#To get the testing branch, uncomment the following
#cvs -z3 -d:extssh:csmart@dpr.cvs.sourceforge.net:/cvsroot/dpr co -r testing -P dpr &>/dev/null

if [ $? != 0 ]
then
	echo 'There was an error checking out DPR, sorry!'
	echo ""
	exit 1
fi

clear
echo "Checking out Xena from *urgh* CVS *urgh*.."
echo "Checking out DPR from *urgh* CVS *urgh*.."

#Bypass up MANIFEST.MF issue
#cp -iv $SCRIPTLOC/ReprocessingJobImporter.java $BUILDLOC/source-$DATE/dpr/src/au/gov/naa/digipres/dpr/core/importexport/ReprocessingJobImporter.java

# Build Xena
echo "Building Xena.."
sleep 2
cd xena
#ant &>/dev/null
#ant -f build_plugins.xml &>/dev/null
ant >/dev/null

if [ $? != 0 ]
then
	echo 'There was an error building Xena, sorry!'
	echo ""
	exit 1
fi

ant -f build_plugins.xml >/dev/null

if [ $? != 0 ]
then
	echo 'There was an error building the Xena plugins, sorry!'
	echo ""
	exit 1
fi

clear
echo "Checking out Xena from *urgh* CVS *urgh*.."
echo "Checking out DPR from *urgh* CVS *urgh*.."
echo "Building Xena.."

# Build DPR
echo "Building DPR.."
cd ../dpr
#ant init &>/dev/null
#ant dist &>/dev/null
ant init >/dev/null

if [ $? != 0 ]
then
	echo 'There was an error building DPR, sorry!'
	echo ""
	exit 1
fi

ant dist >/dev/null

if [ $? != 0 ]
then
	echo 'There was an error building DPR, sorry!'
	echo ""
	exit 1
fi

#Building fake-bridge (not needed anymore, included in DPR)
#cd ../fake-bridge
#ant
#ant &>/dev/null

#Building checksum-checker
echo "Building Rolling Checksum Checker.."
cd ../RollingChecker
ant dist >/dev/null
#ant &>/dev/null

if [ $? != 0 ]
then
	echo 'There was an error building Rolling Checksum Checker, sorry!'
	echo ""
	exit 1
fi

# Compile dist
echo "Gathering binaries.."
cd $BUILDLOC
cp -a source-$DATE/dpr/dist ./dist-$DATE
#Fake bridge not needed now, included in DPR
#cp -a source-$DATE/fake-bridge/dist/* ./dist-$DATE
cp -a source-$DATE/RollingChecker/dist/* ./dist-$DATE
cp -a source-$DATE/xena/dist/* ./dist-$DATE
chmod a+x dist-$DATE/*sh

#Cleanup CVS junk
rm -Rf `find $BUILDLOC/dist-$DATE -name CVS*`
rm -Rf `find $BUILDLOC/dist-$DATE -name .cvs*`

# Echo out result
echo ""
echo "OK, Xena and DPR have been built in $BUILDLOC/dist-$DATE"
echo 'Do not forget to commit the new build number!'
echo ""

