#!/bin/bash
#
#
# GVSN-mac
# 
# Bash script to make and submit gwyddion nightly packages to Ubuntu ppa.
# v. 20111205
#
# Nicola Ferralis <feranick@hotmail.com>
# 
# GSVN-mac is licensed under the GNU Public License v.3
#

if [ "$1" = "-h" ]; then
echo
echo "If the argument \"--no-splash\" is passed at launch,"
echo "Gwyddion will be compiled without the splash screen"
echo
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

STR=$(curl http://gwyddion.net/download.php | sed -n '/gwyddion-head.tar.gz/p'| awk '{print $NF}')
STR=`echo ${STR:76:10}`

STR2=$(curl http://gwyddion.net/download.php | sed -n '/Stable version/p' | awk '{print $NF}')
STR2=`echo ${STR2:1:4}`
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
 curl -O http://gwyddion.net/download/test/gwyddion-head.tar.gz
 tar xvzf gwyddion-head.tar.gz
 rm gwyddion-head.tar.gz

 #------------------------------------------------------------
 # Figure out latest svn version
 #------------------------------------------------------------

 NEW=$(ls -lrt | sed -n '/gwyddion-2/p' | awk '{print $NF}')
 DVER=`echo ${NEW:14}`

 #------------------------------------------------------------
 # Remove splash screen
 #------------------------------------------------------------
 if [ "$1" = "--no-splash" ]; then
 echo
 echo "Disabling splash screen"
 echo
 nosplash $NEW
 fi
 
 #------------------------------------------------------------
 # Prepare Macports Portfile for new version
 #------------------------------------------------------------

 cp $DIRGW/Portfile .
 sed "s/# revision            1/revision            ${DVER}/" < Portfile > Portfile-svn

 sudo cp Portfile-svn $DIRGW
 sudo mv $DIRGW/Portfile $DIRGW/Portfile-stable
 sudo cp $DIRGW/Portfile-svn $DIRGW/Portfile
 sudo port extract gwyddion
 cd $DIRGW
 cd work

 OLD=$(ls -lrt | sed -n '/gwyddion-2/p' | awk '{print $NF}')
 echo $OLD
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

 cd $DIRGW/work
 sudo patch -p0 -i diff

 #------------------------------------------------------------
 # Make a dmg package and copy it in the script's folder   
 #------------------------------------------------------------

 cd $WDIR
 sudo port dmg gwyddion
 cp $DIRGW/work/*.dmg ../$DIR 

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
 echo "A copy of the dmg installation package has been saved in the script's folder"
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
 if [ "$1" = "1" ]; then
 echo
 echo "Disabling splash screen"
 echo
 nosplash $1
 fi

 #------------------------------------------------------------
 # Prepare Macports Portfile for new version
 #------------------------------------------------------------ 

 cp $DIRGW/Portfile .
 sed "s/version             ${MPVER}/version             ${STR2}/" < Portfile > Portfile-ups

 sudo cp Portfile-ups $DIRGW
 sudo mv $DIRGW/Portfile $DIRGW/Portfile-stable
 sudo cp $DIRGW/Portfile-ups $DIRGW/Portfile
 sudo port extract gwyddion
 cd $DIRGW
 cd work

 OLD=$(ls -lrt | sed -n '/gwyddion-2/p' | awk '{print $NF}')
 echo $OLD
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

 #------------------------------------------------------------
 # Make a dmg package and copy it in the script's folder   
 #------------------------------------------------------------

 cd $WDIR
 sudo port dmg gwyddion
 cp $DIRGW/work/*.dmg ../$DIR 

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
 echo "A copy of the dmg installation package has been saved in the script's folder"
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
 echo "Gsvn-mac - version 20111205"
 echo "Bugs, comments, suggestions: Nicola Ferralis <feranick@hotmail.com>"
 echo "Gsvn is licensed under the GNU Public License v.3"
 echo
 echo "This script requires XCode and Macports. "
 echo

fi
fi
