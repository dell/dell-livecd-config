#!/bin/sh

SCRIPT_DIR=$(cd $(dirname $0); pwd)
GPG_KEY=$SCRIPT_DIR/RPM-GPG-KEY-PGuay.txt

source $SCRIPT_DIR/default.conf

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
get_firmware_packages() {
	
	if [ -f $SCRIPT_DIR/primary.xml ]
	  then
		echo "Deleting primary.xml"
		rm -f $SCRIPT_DIR/primary.xml
	fi
	
        wget $DELL_FIRMWARE_REPO_URL/repodata/primary.xml.gz
	gunzip primary.xml.gz
	echo "%packages" > firmware_packages_list.ks
	./extract_rpms.pl primary.xml | sort| uniq >>  firmware_packages_list.ks
	echo "%end" >> firmware_packages_list.ks
	
}

rm -rf $SCRIPT_DIR/livecd 
mkdir -p $SCRIPT_DIR/livecd
TEMP_DIR=$SCRIPT_DIR/temp
mkdir -p $TEMP_DIR

perl -p -e "s|##SCRIPT_DIR##|$SCRIPT_DIR|g;" $SCRIPT_DIR/livecd-config.ks.in > $SCRIPT_DIR/livecd-config.ks.tmp
perl -p -e "s|##TEMP_DIR##|$TEMP_DIR|g;" $SCRIPT_DIR/livecd-config.ks.tmp > $SCRIPT_DIR/livecd-config.ks


for varname in 			\
	CENTOS_RELEASED_URL	\
	CENTOS_UPDATES_URL	\
	CENTOS_ADDONS_URL	\
	CENTOS_EXTRAS_URL	\
	CENTOS_PLUS_URL		\
	CENTOS_FAST_URL		\
	DELL_HARDWARE_REPO_URL	\
	DELL_SOFTWARE_REPO_URL	\
	DELL_FIRMWARE_REPO_URL
do
	cp $SCRIPT_DIR/livecd-config.ks $SCRIPT_DIR/livecd-config.tmp
	perl -p -e "s|##$varname##|${!varname}|g;" $SCRIPT_DIR/livecd-config.tmp> $SCRIPT_DIR/livecd-config.ks
done

rm $SCRIPT_DIR/livecd-config.tmp  #remove the temporary file

createrepo $SCRIPT_DIR/repository
import_key

get_firmware_packages
#remove conflicting packages

for package in  $FIRMWARE_EXCLUDE_PACKAGES
do
	cp firmware_packages_list.ks firmware_packages_list.tmp
      	perl -p -e "s|$package||g;" firmware_packages_list.tmp > firmware_packages_list.ks
done

rm firmware_packages_list.tmp # remove the temporary
mkdir -p $SCRIPT_DIR/cache/yum-cache

export OMIIGNORESYSID=1
livecd-creator --config livecd-config.ks -t $SCRIPT_DIR/livecd --fslabel Dell_Live_CentOS --cache $SCRIPT_DIR/cache/


#Making a copy of the source rpms

if [ $COPY_SOURCES == 1 ]
then
	for src_rpm in `cat $SCRIPT_DIR/temp/packages |grep -v -i system_bios| grep  -v Firmware | grep -v componentid | grep  "src.rpm$" | sort | uniq`
	do
       	 	for source in \
			SRC_CENTOS_RELEASED_URL \
			SRC_CENTOS_UPDATES_URL \
			SRC_CENTOS_ADDONS_URL \
			SRC_CENTOS_EXTRAS_URL \
			SRC_CENTOS_PLUS_URL \
			SRC_CENTOS_FAST_URL
		do
			code=`curl --head ${!source}/$src_rpm 2> /dev/null | head -n 1 | cut -d " " -f2`
			if [ $code == 200 ]
			then
				wget   -P SRPMS  ${!source}/$src_rpm -o logfile
				break
				
			fi
		done 

	done

fi

#SHA1 SUM key 
sha1sum Dell_Live_CentOS.iso > Dell_Live_CentOS.sha1sum

#Removing all the temporary files
#rm -f livecd-config.ks firmware_packages_list.ks /home/packages logfile primary.xml DELL-RPM-GPG-KEY livecd-config.ks.tmp
