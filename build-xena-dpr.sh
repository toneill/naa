#!/bin/bash

DATE=`date +%y%m%d%H%M`
BUILDLOC=~/Desktop

# Directory structure
mkdir $BUILDLOC &>/dev/null
cd $BUILDLOC
mkdir source-$DATE
cd source-$DATE

# Check out Xena
echo "Checking out Xena from *urgh* CVS *urgh*.."
cvs -z3 -d:extssh:csmart@xena.cvs.sourceforge.net:/cvsroot/xena co -P archive audio basic csv dataset email example_plugin html image multipage naa office pdf plaintext plugin_howto postscript project psd website xena xml &>/dev/null

# Check out DPR
echo "Checking out DPR from *urgh* CVS *urgh*.."
cvs -z3 -d:extssh:csmart@dpr.cvs.sourceforge.net:/cvsroot/dpr co -P RollingChecker dpr dpr_prototype fake-bridge manifest sophos-bridge &>/dev/null

# Build Xena
echo "Building Xena.."
cd xena
ant &>/dev/null
ant -f build_plugins.xml &>/dev/null

# Build DPR
echo "Building DPR.."
cd ../dpr
ant init &>/dev/null
ant dist &>/dev/null

# Compile dist
echo "Gathering binaries.."
cd $BUILDLOC
cp -a source-$DATE/dpr/dist ./dist-$DATE
cp -a source-$DATE/xena/dist/* ./dist-$DATE

# Echo out result
echo ""
echo "OK, Xena and DPR have been built in $BUILDLOC/dist-$DATE"
echo "Don't forget to commit the new build number."


