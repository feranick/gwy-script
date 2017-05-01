#!/bin/bash
#
#
# GVSN-mac
# 
# Bash script to make and submit gwyddion nightly packages to Ubuntu ppa.
# v. 20160114
#
# Nicola Ferralis <feranick@hotmail.com>
# 
# GSVN-mac is licensed under the GNU Public License v.3
#

if [ "$1" = "-h" ]; then
echo
echo "Available arguments at launch-time:"
echo "\"--no-splash\": Gwyddion will be compiled without the splash screen"
echo "\"--dmg\": A dmg package will be made"
else



#------------------------------------------------------------
# Variable definition and functions
#------------------------------------------------------------

TMP=temp
DIRGW='/opt/local/var/macports/sources/rsync.macports.org/release/tarballs/ports/science/gwyddion'
#DIRGW=$(printf "%s\n" "$DIRGW" | sed 's/[][\.*^$/]/\\&/g')

#----------------------
# Remove splash screen
#----------------------
nosplash ()
{ 
sed "s/FALSE, FALSE, FALSE, FALSE, LOG_TO_FILE_DEFAULT, FALSE,/TRUE, FALSE, FALSE, FALSE, LOG_TO_FILE_DEFAULT, FALSE,/" < $1/app/gwyddion.c > gwyddion.c
cp gwyddion.c $1/app/gwyddion.c 
}


#------------------------------------------------------------
# Check what is the latest version of svn and stable
#------------------------------------------------------------

STR=$(curl http://gwyddion.net/download.php | sed -n '/gwyddion-head.tar.xz/p'| awk '{print $NF}')
STR=`echo ${STR:76:10}`

STR2=$(curl http://gwyddion.net/download.php | sed -n '/stable version Gwyddion/p' | awk '{print $NF}')
STR2=`echo ${STR2:0:4}`

#MPVER=$(sed -n '/version    /p' < $DIRGW/Portfile | awk '{print $NF}')
clear

#------------------------------------------------------------
# Main menu
#------------------------------------------------------------

echo "------------------------------------------------------------"
echo "Handle installation of development builds for Gwyddion"
echo "------------------------------------------------------------"
echo
echo "1. Install latest development snapshot ($STR)"
echo "2. Install latest stable from macports"
echo "3. Install latest stable from upstream ($STR2)"
echo "4. Cleanup previous builds"
echo "5. About"
echo
echo "0. Exit"

read TYPE

if [ "$TYPE" = "1" ]; then

 echo
 echo "This script requires administration rights. Please enter the password when asked."
 echo
 sudo port clean gwyddion
 sudo port selfupdate

 #------------------------------------------------------------
 # Download svn source
 #------------------------------------------------------------
 mkdir $TMP
 cd $TMP
 WDIR=`pwd`
 curl -O http://gwyddion.net/download/test/gwyddion-head.tar.xz
 tar xvaf gwyddion-head.tar.xz
 rm gwyddion-head.tar.xz

 #------------------------------------------------------------
 # Figure out latest svn version
 #------------------------------------------------------------

 NEW=$(ls -lrt | sed -n '/gwyddion-2/p' | awk '{print $NF}')
 DVER=`echo ${NEW:14}`

 #------------------------------------------------------------
 # Remove splash screen
 #------------------------------------------------------------
 if [ "$1" = "--no-splash" ] || [ "$2" = "--no-splash" ] ; then
  echo
  echo "Disabling splash screen"
  echo
  nosplash $NEW
fi
 
 #------------------------------------------------------------
 # Prepare Macports Portfile for new version
 #------------------------------------------------------------

 cp $DIRGW/Portfile .
 
 sed "s/.*revision.*/revision            ${DVER}/" Portfile > Portfile-svn

 #------------------------------------------------------------
 # Remove patchfile for version 2.26
 #------------------------------------------------------------

 OLD1=$(sed -n '/version             2/p' Portfile | awk '{print $NF}')

 
 if [ "$OLD1" = "2.26" ] ; then
  echo
  echo " Version 2.26 detected"
  echo " Removing 2.26 patches from Portfile" 
  echo
  sed "s/patchfile/#patchfile/" Portfile-svn > Portfile-svn2
  cp Portfile-svn2 Portfile-svn
 fi

 OLD="gwyddion-$OLD1"


 sudo cp Portfile-svn $DIRGW
 sudo mv $DIRGW/Portfile $DIRGW/Portfile-stable
 sudo cp $DIRGW/Portfile-svn $DIRGW/Portfile
 sudo port extract gwyddion
 cd $DIRGW
 cd work

#OLD=$(ls -lrt | sed -n '/gwyddion-2/p' | awk '{print $NF}')
 
 echo
 echo "--------------------------------------"
 echo "Current stable in Macports: $OLD"
 echo "New development version: $NEW"
 echo "--------------------------------------"
 echo
 
 #------------------------------------------------------------
 # Patch stable version in macports with new one from svn  
 #------------------------------------------------------------

 cd $WDIR
 cp -r $DIRGW/work/gwyddion* .
 diff -Nru $OLD $NEW > diff
 sudo cp diff $DIRGW/work

#--------------------------------------------------------------------
# Add "gwy_polynom_level-24.png" to pixmaps (new from 2.28-20120616)
#--------------------------------------------------------------------

 sudo cp $NEW/pixmaps/gwy_polynom_level-24.png $DIRGW/work/$OLD/pixmaps  


 cd $DIRGW/work
 sudo patch -p0 -i diff
 cd $WDIR

 #------------------------------------------------------------
 # Make a dmg package and copy it in the script's folder   
 #------------------------------------------------------------
if [ "$1" = "--dmg" ] || [ "$2" = "--dmg" ] ; then
 echo
 echo "Saving dmg file."
 echo
 sudo port dmg gwyddion
 cp $DIRGW/work/*.dmg ../$DIR
 echo "A copy of the dmg installation package has been saved in the script's folder"
 fi

 #------------------------------------------------------------
 # Make a dmg package and copy it in the script's folder
 #------------------------------------------------------------
 if [ "$1" = "--pkg" ] || [ "$2" = "--pkg" ] ; then
 echo
 echo "Saving pkg file."
 echo
 sudo port pkg gwyddion
 cp $DIRGW/work/*.pkg ../$DIR
 echo "A copy of the pkg installation package has been saved in the script's folder"
 fi


 #------------------------------------------------------------
 # Install new version from svn   
 #------------------------------------------------------------

 sudo port install gwyddion 
 cd ..

 #------------------------------------------------------------
 # Cleanup   
 #------------------------------------------------------------

 rm -r $TMP
 sudo port clean gwyddion
 
 echo
 echo Done!
 echo


elif [ "$TYPE" = "2" ]; then

 echo "This script requires administration rights. Please enter the password when asked."
 echo
 sudo port clean gwyddion
 sudo port selfupdate
 sudo port install gwyddion
 echo
 echo Done!
 echo

elif [ "$TYPE" = "3" ]; then

 echo
 echo "This script requires administration rights. Please enter the password when asked."
 echo
 sudo port clean gwyddion
 sudo port selfupdate

 mkdir $TMP
 cd $TMP
 cp $DIRGW/Portfile .

 #------------------------------------------------------------
 # Figure out if upstream version is different than macports
 #------------------------------------------------------------
 
 MPVER=$(sed -n '/version    /p' < Portfile | awk '{print $NF}')
 echo $mpver

 if [ "$MPVER" == "$STR2" ]; then
 echo
 echo "The version upstream is the same as than that in Macports ($MPVER)."
 echo
 cd ..
 rm -r $TMP
 else

 #------------------------------------------------------------
 # Download svn source
 #------------------------------------------------------------ 

 WDIR=`pwd`
 curl -O http://gwyddion.net/download/$STR2/gwyddion-$STR2.tar.gz
 tar xvzf gwyddion-$STR2.tar.gz
 rm gwyddion-$STR2.tar.gz
 NEW=$(ls -lrt | sed -n '/gwyddion-2/p' | awk '{print $NF}')
 DVER=`echo ${NEW:14}`

 #------------------------------------------------------------
 # Remove splash screen
 #------------------------------------------------------------
 if [ "$1" = "--no-splash" ] || [ "$2" = "--no-splash" ] ; then
 echo
 echo "Disabling splash screen"
 echo
 nosplash $NEW
 fi

 #------------------------------------------------------------
 # Prepare Macports Portfile for new version
 #------------------------------------------------------------ 

 cp $DIRGW/Portfile .
#sed "s/version             ${MPVER}/version             ${STR2}/" < Portfile > Portfile-ups
 sed "s/.*revision.*/revision            ${STR2}/" Portfile > Portfile-ups


#------------------------------------------------------------
# Remove patchfile for version 2.26
#------------------------------------------------------------

OLD1=$(sed -n '/version             2/p' Portfile | awk '{print $NF}')


if [ "$OLD1" = "2.26" ] ; then
echo
echo " Version 2.26 detected"
echo " Removing 2.26 patches from Portfile" 
echo
sed "s/patchfile/#patchfile/" Portfile-ups > Portfile-ups2
cp Portfile-ups2 Portfile-ups
fi

OLD="gwyddion-$OLD1"

 sudo cp Portfile-ups $DIRGW
 sudo mv $DIRGW/Portfile $DIRGW/Portfile-stable
 sudo cp $DIRGW/Portfile-ups $DIRGW/Portfile
 sudo port extract gwyddion
 cd $DIRGW
 cd work



#OLD=$(ls -lrt | sed -n '/gwyddion-2/p' | awk '{print $NF}')
 
 echo
 echo "--------------------------------------"
 echo "Current stable in Macports: $OLD"
 echo "New stable upstream version: $NEW"
 echo "--------------------------------------"
 echo

 #------------------------------------------------------------
 # Patch stable version in macports with new one from svn  
 #------------------------------------------------------------

 cd $WDIR 
 cp -r $DIRGW/work/gwyddion* .
 diff -Nru $OLD $NEW > diff
 sudo cp diff $DIRGW/work

 cd $DIRGW/work
 sudo patch -p0 -i diff
 cd $WDIR

#------------------------------------------------------------
# Make a dmg package and copy it in the script's folder
#------------------------------------------------------------
if [ "$1" = "--dmg" ] || [ "$2" = "--dmg" ] ; then
echo
echo "Saving dmg file."
echo
sudo port dmg gwyddion
cp $DIRGW/work/*.dmg ../$DIR
echo "A copy of the dmg installation package has been saved in the script's folder"
fi


#------------------------------------------------------------
# Make a dmg package and copy it in the script's folder
#------------------------------------------------------------
if [ "$1" = "--pkg" ] || [ "$2" = "--pkg" ] ; then
echo
echo "Saving pkg file."
echo
sudo port pkg gwyddion
cp $DIRGW/work/*.pkg ../$DIR
echo "A copy of the pkg installation package has been saved in the script's folder"
fi


 #------------------------------------------------------------
 # Install new version from svn   
 #------------------------------------------------------------

 sudo port install gwyddion 
 cd ..

 #------------------------------------------------------------
 # Cleanup   
 #------------------------------------------------------------

 rm -r $TMP
 sudo port clean gwyddion

 echo
 echo Done!
 echo

 fi

elif [ "$TYPE" = "4" ]; then
 echo
 echo "This will remove previously installed versions of gwyddion"
 sudo port -u uninstall
 echo
 echo Done!
 echo

elif [ "$TYPE" = "5" ]; then
 echo
 echo "Gsvn-mac - version 20120618b"
 echo "Bugs, comments, suggestions: Nicola Ferralis <feranick@hotmail.com>"
 echo "Gsvn is licensed under the GNU Public License v.3"
 echo
 echo "This script requires XCode and Macports. "
 echo

fi
fi
