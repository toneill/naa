#!/bin/bash

if [ "$1" == "help" ]
then
	echo ""
        echo "Pass in your sourceforge username and which branch you wish to check out (i.e. stable or testing)."
        echo 'I.e. "./build-xena-dpr.sh csmart testing"'
        echo ""
        exit 0

elif [ "$1" == "" ]
then
        echo ""
        echo "You must tell me your sourceforge username. Exiting."
        echo ""
        exit 1
fi

if [ "$2" != "stable" -a "$2" != "testing" ]
then
        echo ""
        echo "You must tell me which branch you want, stable or testing. Exiting"
        echo ""
	exit 1
fi

DATE=`date +%Y-%m-%d-%H:%M`
BUILDLOC=~/Desktop/$2

# Directory structure
mkdir $BUILDLOC &>/dev/null
cd $BUILDLOC
mkdir source-$DATE
cd source-$DATE

# Check out Xena
clear
echo "Checking out Xena $2 from *urgh* CVS *urgh*.."
echo ""
sleep 2

if [ $2 == testing ]
then
	cvs -z3 -d:extssh:$1@xena.cvs.sourceforge.net:/cvsroot/xena co -r testing -P archive audio basic csv dataset email example_plugin html image multipage naa office pdf plaintext plugin_howto postscript project psd website website-plugin xena xml

	if [ $? != 0 ]
	then
		echo 'There was an error checking out Xena, sorry!'
		echo ""
		exit 1
	fi

else
	cvs -z3 -d:extssh:$1@xena.cvs.sourceforge.net:/cvsroot/xena co -P archive audio basic csv dataset email example_plugin html image multipage naa office pdf plaintext plugin_howto postscript project psd website website-plugin xena xml
fi

if [ $? != 0 ]
then
	echo 'There was an error checking out Xena, sorry!'
	echo ""
	exit 1
fi

clear
echo "Checking out Xena $2 from *urgh* CVS *urgh*.."

# Check out DPR (note, fake-bridge is now in test-utils)
echo "Checking out DPR $2 from *urgh* CVS *urgh*.."
echo ""
sleep 2
if [ $2 == testing ]
then
	cvs -z3 -d:extssh:$1@dpr.cvs.sourceforge.net:/cvsroot/dpr co -r testing -P dpr manifest RollingChecker
	if [ $? != 0 ]
	then
		echo 'There was an error checking out DPR, sorry!'
		echo ""
		exit 1
	fi
else
	cvs -z3 -d:extssh:$1@dpr.cvs.sourceforge.net:/cvsroot/dpr co -P dpr manifest RollingChecker
	if [ $? != 0 ]
	then
		echo 'There was an error checking out DPR, sorry!'
		echo ""
		exit 1
	fi
fi

clear
echo "Checking out Xena from *urgh* CVS *urgh*.."
echo "Checking out DPR from *urgh* CVS *urgh*.."

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

