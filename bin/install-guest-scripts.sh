#!/bin/bash -ex

# This is the home (parent) dir to install the scripts.
GUEST_SCRIPTS_HOME=/opt/guests-scripts

# Path to admin credentials file.
CREDENTIALS_FILE_PATH=/home/heitor/.openstack-rc/auto-admin-openrc.sh

# tmp cron file
TMP_CRON_FILE=/tmp/cron_content.tmp

# Content of cron line for auto update of users
#CRONLINE="*/2	*	*	*	*	/bin/bash -l $GUEST_SCRIPTS_HOME/bin/update-guests-by-time.sh --credentials $CREDENTIALS_FILE_PATH"
CRONLINE="*	0	*	*	*	/bin/bash -l $GUEST_SCRIPTS_HOME/bin/update-guests-by-time.sh --credentials $CREDENTIALS_FILE_PATH"

# Copy the scripts to the destination directory.
copy_scripts() {
	mkdir -p $GUEST_SCRIPTS_HOME
	#cp -r ../ $GUEST_SCRIPTS_HOME
	rsync -a --exclude='.*' ../ $GUEST_SCRIPTS_HOME/
}

# Configure variables to point to the new install location.
configure_variables() {
	for script in cleanup-guest.sh create-guest.sh delete-guest.sh list-guest.sh suspend-guest.sh update-guests-by-time.sh; do
		sed -r -i "s,^PARENT_DIR=.*,PARENT_DIR=$GUEST_SCRIPTS_HOME,g" $GUEST_SCRIPTS_HOME/bin/cleanup-guest.sh
	done
}

update_crontab() {
	local crongrep=`crontab -l | grep -v "#" |grep update-guests-by-time.sh `
	if [ ! -z "$crongrep" ]; then
		echo "cron already installed"
	else
		crontab -l > $TMP_CRON_FILE
		echo "$CRONLINE" >> $TMP_CRON_FILE
		crontab $TMP_CRON_FILE
	fi

}

main() {
	copy_scripts;
	configure_variables;
	update_crontab;
}

main $@;
