#!/bin/sh

SCRIPT_DIR=$(cd $(dirname $0); pwd)
GPG_KEY=$SCRIPT_DIR/RPM-GPG-KEY-PGuay.txt
_LOCK=$SCRIPT_DIR/.build.lock

source $SCRIPT_DIR/default.conf

if ! lockfile -2 -r 2 $_LOCK; then
    echo "Another build appears to be running."
    echo "Build startup not completed. Please stop the other"
    echo "instance before starting another build."
    exit 1
fi
trap 'rm -f "$_LOCK"' EXIT INT QUIT HUP TERM

if [ "$1" = "--config" -a -e "$2" ]; then
	source $2
fi

import_key() {
    email=$(gpg -v $GPG_KEY 2>/dev/null  | grep 1024D | perl -p -i -e 's/.*<(.*)>/\1/')

    HAVE_KEY=0
    for key in $(rpm -qa | grep gpg-pubkey)
    do
        if rpm -qi $key | grep -q "^Summary.*$email"; then
            HAVE_KEY=1;
            break;
        fi
    done
    if [ $HAVE_KEY != 1 ]; then
	echo "Importing key"
    	rpm --import $GPG_KEY
    fi
}

#function to extract all the name of all the firmware packages available in firmware repo
get_firmware_packages() {
	
	if [ -f $SCRIPT_DIR/primary.xml ]
	  then
		echo "Deleting primary.xml"
		rm -f $SCRIPT_DIR/primary.xml
	fi
	
        wget -P $SCRIPT_DIR $DELL_FIRMWARE_REPO_URL/repodata/primary.xml.gz
	gunzip $SCRIPT_DIR/primary.xml.gz
	echo "%packages" > $SCRIPT_DIR/firmware_packages_list.ks
	$SCRIPT_DIR/extract_rpms.pl primary.xml | sort| uniq >>  $SCRIPT_DIR/firmware_packages_list.ks
	echo "%end" >> $SCRIPT_DIR/firmware_packages_list.ks
	#final list of available firmware updates is available in firmware_packages_list.ks file.
	#This file is included in livecd-config.ks file, to add the firmware packages to the final list of packages to be
	#installed on the livecd.
	
}

#remove any left overs from previous runs
rm -rf $SCRIPT_DIR/livecd/* 
TEMP_DIR=$SCRIPT_DIR/temp
if [ ! -d $TEMP_DIR ] 
then
	mkdir -p $TEMP_DIR
fi

cp $SCRIPT_DIR/livecd-config.ks.in $SCRIPT_DIR/livecd-config.ks


for varname in 			\
	CENTOS_RELEASED_URL	\
	CENTOS_UPDATES_URL	\
	DELL_HARDWARE_REPO_URL	\
	DELL_SOFTWARE_REPO_URL	\
	DELL_FIRMWARE_REPO_URL	\
	SRC_CENTOS_RELEASED_URL	\
	SRC_CENTOS_UPDATES_URL	\
	NAMESERVER		\
	SCRIPT_DIR	\
	TEMP_DIR
do
	cp $SCRIPT_DIR/livecd-config.ks $SCRIPT_DIR/livecd-config.tmp
	perl -p -e "s|##$varname##|${!varname}|g;" $SCRIPT_DIR/livecd-config.tmp> $SCRIPT_DIR/livecd-config.ks
done

#create a local repository
createrepo $SCRIPT_DIR/repository

import_key

get_firmware_packages

#remove conflicting packages
# this can be eleminated after the conflicts are resolved
for package in  $FIRMWARE_EXCLUDE_PACKAGES
do
	cp $SCRIPT_DIR/firmware_packages_list.ks $SCRIPT_DIR/firmware_packages_list.tmp
      	perl -p -e "s|$package||g;" $SCRIPT_DIR/firmware_packages_list.tmp > $SCRIPT_DIR/firmware_packages_list.ks
done

#directory to cache rpms- to be used by livecd-creator to install to $INSTALL_ROOT
mkdir -p $SCRIPT_DIR/cache/yum-cache

export OMIIGNORESYSID=1 #enviromnent setting for OMSA installation.
/usr/bin/livecd-creator --config $SCRIPT_DIR/livecd-config.ks -t $SCRIPT_DIR/livecd --fslabel Dell_Live_CentOS --cache $SCRIPT_DIR/cache/


#Making a copy of the source rpms to comply with GPL.
#if [ $COPY_SOURCES == 1 ]
#then
#	for src_rpm in `cat $SCRIPT_DIR/temp/packages |grep -v -i system_bios| grep  -v Firmware | grep -v componentid | grep  "src.rpm$" | sort | uniq`
#	do
 #      	 	for source in \
#			SRC_CENTOS_RELEASED_URL \
#			SRC_CENTOS_UPDATES_URL \
#			SRC_CENTOS_ADDONS_URL \
#			SRC_CENTOS_EXTRAS_URL \
#			SRC_CENTOS_PLUS_URL \
#			SRC_CENTOS_FAST_URL
#		do
#			code=`curl --head ${!source}/$src_rpm 2> /dev/null | head -n 1 | cut -d " " -f2`
#			if [ $code == 200 ]
#			then
#				wget   -P $SCRIPT_DIR/SRPMS  ${!source}/$src_rpm -o logfile
#				break
				
#			fi
#		done 
#
#	done

#fi


#temp/wget contains all the urls of the source rpms of packages installed in livecd.
if [ -f $SCRIPT_DIR/temp/wget ]
then
	rm -rf $SCRIPT_DIR/SRPMS/* #delete the previous copy of the sources.
	for url in `cat $SCRIPT_DIR/temp/wget| grep http|sort|uniq`
	do
		wget -P $SCRIPT_DIR/SRPMS $url -o logfile
	done
fi


#SHA1 SUM key 
sha1sum $SCRIPT_DIR/Dell_Live_CentOS.iso > $SCRIPT_DIR/Dell_Live_CentOS.sha1sum

#Removing all the temporary files
rm -f $SCRIPT_DIR/livecd-config.ks $SCRIPT_DIR/firmware_packages_list.ks $SCRIPT_DIR/temp/wget1 $SCRIPT_DIR/logfile $SCRIPT_DIR/primary.xml $SCRIPT_DIR/DELL-RPM-GPG-KEY $SCRIPT_DIR/livecd-config.ks.tmp $SCRIPT_DIR/livecd-config.tmp $SCRIPT_DIR/firmware_packages_list.tmp
