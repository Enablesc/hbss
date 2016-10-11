#!/bin/bash

if [ "$(id -u)" == "0" ]
then
	printf "This program never will be run as root user\n"
	exit 1
fi

if [ -f "/etc/cronbackup.cfg" ]
then
	source "/etc/cronbackup.cfg"
else
	printf 'No configuration file found\n'
	exit 1
fi

if [ "x${TMPFILE}" == "x" ]
then
	printf "Temporal directory can\'t be empty\n"
	exit 1
fi

if [ "x${DEST_EMAIL}" == "x" ]
then
	printf "Destination email can\'t be empty\n"
	exit 1
fi

if [ "x${RETENTION}" == "x" ] 
then
	printf "Retention level can\'t be empty\n"
	exit 1
fi

if [ "x${BACKUPTOOL}" == "x" ] 
then
	printf "Backup tool can\'t be empty\n"
	exit 1
fi

HOUR=$(date +%H)
BACKUP_IDS=()

#
# Populate backup ids array
#

create_backups_array()
{
	#
	# Clear global array
	#
	BACKUPS_IDS=()


	#
	# Populate then with new one values
	#
	for i in $(${BACKUPTOOL} -ld | sed -r  's/^[^0-9]*([0-9]+).*/\1/' | sed -r  's/[^0-9]*//'|sed '/^$/d')
	do
		BACKUP_IDS+=("${i}")
	done

	return 0
}


#
# Create a list with paths of files to delete
#
create_delete_list()
{
	local id=${1}
	if [ "${id}" == "x" ]
	then
		printf 'ID is empty\n'
		return 1
	fi

	rm -f /tmp/older_logs.*
	if ! ${BACKUPTOOL} -ll --backup-id=${id} > "${TMPFILE}"
	then
		printf 'Failed to create delete files list\n'
		rm -f /tmp/older_logs.*
		return 1
	fi

	return 0
}


#
# Delete log files using delete list
#
delete_old_log_files()
{
	local input_file="${1}"

	if [ "x${input_file}" == "x" ]
	then
		printf 'Delete list is empty\n'
		return 1
	fi

	while read line
	do
		rm -f "${line}"
	done < ${input_file}

	return 0
}


send_mail()
{
	local message="${@}"
	echo "${message}" | mail -s "SAP HANA" ${DEST_EMAIL}
}


#
# Create backup and delete necesry things
#
create_backup()
{

	#
	# First run a backup
	#

	local suffix=$(date +%d-%m-%Y_%H:%M)

	if ! ${BACKUPTOOL} --suffix="${suffix}"
	then
		printf 'Backup failed. Sending email to hana DBA .....\n'
		send_mail "*** FAILED *** Backup in $(hostname) with suffix $(date +%d-%m-%Y_%H:%M)"
		exit 1
	else
		[ "${DEBUG}" == "1" ] && send_mail "Sucefull backup in $(hostname) with suffix ${suffix}"
	fi


	#
	# Refresh backups id array
	#
	create_backups_array


	#
	# Set local variables
	#
	local last_id="${BACKUP_IDS[0]}"
	local index_id="${#BACKUP_IDS[@]}"


	#
	# If hour is the first of day, delete all other older
	#

	if (( ${HOUR} == 8 ))
	then
		create_delete_list ${last_id}
		delete_old_log_files "${TMPFILE}"
		${BACKUPTOOL} -cd --backup-id=${last_id}
	elif (( ${HOUR} >= 11 || ${HOUR} <= 18 ))
	then
		if (( ${index_id} < ${RETENTION} ))
		then
			return 0
		fi

		if (( ${index_id} >= ${RETENTION} ))
		then
			local use_id=${BACKUP_IDS[${RETENTION}-1]}

			printf 'Deleteting older backups than %s ...\n' ${use_id}

			create_delete_list ${use_id}
			delete_old_log_files ${TMPFILE}
			${BACKUPTOOL} -cd --backup-id=${use_id}
		fi
	fi

	return 0
}


create_backup
