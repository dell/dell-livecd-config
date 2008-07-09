#!/bin/sh

# the purpose of this script is to be callable from cron. It will make a logfile and only output on failure.

set -e

SCRIPT_DIR=$(cd $(dirname $0); pwd)
cd $SCRIPT_DIR

rm -f build.log
exec > build.log 2>&1

_LOCK=$SCRIPT_DIR/.cron-build.lock
if ! lockfile -2 -r 2 $_LOCK; then
    # silently exit, since lock failure indicates another build running
    exit 1
fi
trap 'rm -f "$_LOCK"' EXIT INT QUIT HUP TERM

# we assume that we are going to be running this under cron in a non-root account
# must set up SUDO separately to allow this. Here is an example line for sudoers file:
# build ALL = NOPASSWD: /home/build/dell-livecd-config/build.sh
sudo $SCRIPT_DIR/build.sh
ret=$?

if [ $ret -eq 0 ]; then
	umask 002
	/usr/bin/mkisofs -r -o Dell_Live_CentOS_SRPMS.iso $SCRIPT_DIR/SRPMS
	rsync -avz Dell_Live_CentOS* /var/ftp/pub/linux.dell.com/srv/www/vhosts/linux.dell.com/html/files/firmware-livecd/
	rm -rf $SCRIPT_DIR/SRPMS
	rm -f Dell_Live_CentOS*
	echo "BUILD OF LIVECD WAS SUCCESSFUL" # SUCCESS!
	
else
	echo "BUILD FAILURE - $(date)"
fi
