#!/bin/sh

SCRIPT_DIR=$(cd $(dirname $0); pwd)
GPG_KEY=$SCRIPT_DIR/RPM-GPG-KEY-PGuay.txt

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

rm -rf $SCRIPT_DIR/livecd

perl -p -e "s|##SCRIPT_DIR##|$SCRIPT_DIR|g;" $SCRIPT_DIR/livecd-config.ks.in > $SCRIPT_DIR/livecd-config.ks

createrepo $SCRIPT_DIR/repository
import_key

livecd-creator --config livecd-config.ks -t $SCRIPT_DIR/livecd --fslabel Dell_Live_CentOS --cache $SCRIPT_DIR/cache/

