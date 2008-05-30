#!/bin/sh

SCRIPT_DIR=$(cd $(dirname $0); pwd)

rm -rf $SCRIPT_DIR/livecd

perl -p -e "s/##SCRIPT_DIR##/$SCRIPT_DIR/g;' livecd-config.ks.in > livecd-config.ks

livecd-creator --config livecd-config.ks -t $SCRIPT_DIR/livecd --fslabel Dell_Live_CentOS --cache $SCRIPT_DIR/cache/

