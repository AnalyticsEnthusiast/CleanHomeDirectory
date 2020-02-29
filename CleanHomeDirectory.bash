#!/bin/bash

# Interactive program that takes a username as an argument (or optional home directory argument from the user) and goes through each file greater than 100K, asks to remove, backup or keep.
# Clean home directory utility

# Variables
D=$(date | tr ' ' '_' | tr ':' '_')
NAME=""
DIRECTORY=""
no_args="true"
LOG_FILE_PATH="CleanHomeDirectory_log_$D.log"

help() {
	echo "Usage: $0 [ -u Username ] [-h Help Text ] [ -l Path to Directory to store log file ]" 1>&2
}

exit_abnormal() {
	help
	exit 1
}

exit_no_permissions() {
	echo "User does not have permission to run this script."
	echo "User must have sudo permissions."
	exit 1
}

check_user_exists() {
	
	#if [[ "$1" = "-h" ]];
	#then
	#	echo "No username provided"
	#	return 1
	#fi


	grep $1 /etc/passwd
	if [[ $? -eq 0 ]];
	then
		return 0
	else
		return 1
	fi
}

check_home_directory_exists() {
	# Users actual home dir
	home_dir=$(grep $1 /etc/passwd | awk -F ':' '{ print $6 }')

	if [[ "$home_dir" = "$2" ]];
	then
		return 0
	else
		return 1
	fi
}

# Print user ask text
ask1(){
	echo ""
	echo "You will be given a list of files."
	echo "Please indicate what you would like to do with this file."
	echo "(1) Enter 'K' to Keep the file."
	echo "(2) Enter 'B' to send the file to backup."
	echo "(3) Enter 'D' to Delete the file."
}


# Print user ask text
ask2(){
	file_name=$(echo "$1" | awk -F ' ' '{ print $9 }' | awk -F '/' '{ print $NF }')
	path_to_file=$(echo "$1" | awk -F ' ' '{ print $9 }')
	size=$(echo "$1" | awk -F ' ' '{ print $5 }')
	d=$(date)
	echo "Would you like to keep this file? -> $path_to_file ($size)"
	read -p "(K|B|D): " response
	
	if [[ "${response^}" == "K" ]];
	then
		echo "$d: File $path_to_file kept" | tee -a "$LOG_FILE_PATH"
	
	elif [[ "${response^}" == "B" ]];
	then
		echo "$d: File $path_to_file moved to Backup" | tee -a "$LOG_FILE_PATH"
		#mv "$path_to_file" /tmp/backup
		cp "$path_to_file" /tmp/backup
		
	elif [[ "${response^}" == "D" ]];
	then
		rm -f "$path_to_file"
		echo "$d: File $path_to_file Deleted" | tee -a "$LOG_FILE_PATH"
	else
		echo "Not a valid argument. Keeping file by default."
	fi
}


main(){	
	# Make a temporary backup directory in /tmp that will store files
	rm -rf /tmp/backup 1>&2 /dev/null
	mkdir /tmp/backup
	
	# Ask user what they would like to do with the files
	FIRST=1
	while IFS=$'\n' read -r line;
	do
		if [[ "$FIRST" -eq 1 ]];
		then
			FIRST=0
			ask1 
			ask2 "$line" </dev/tty
		else
			ask2 "$line" </dev/tty
		fi
	done < <(find $1 -type f -size +100k -exec ls -hl {} \;)
	
	# Make backup of the file in /tmp/backup
	name=$(echo "/tmp/backup_$D.tar.gz")
	tar cvzf "$name" /tmp/backup 2> /dev/null
	
	# Remove backup directory to clean up
	rm -rf /tmp/backup 1> /dev/null 2> /dev/null
}

while getopts "u:l:h" option; do

#Check that the user invoking the script has the correct permissions.
#sudo -v 2> /dev/null 
#[[ "$?" -eq 1 ]] && { exit_no_permissions; }

case ${option} in
h )
	help
	exit 1
;;
u )
	NAME="$OPTARG"
	#result=$(check_user_exists "$NAME")
	#if [[ $? -eq 0 ]];
	#then
	#	DIRECTORY=$(grep "$NAME" /etc/passwd | awk -F ':' '{ print $6 }')
	#	main "${DIRECTORY}"
	#else
	#	echo "User does not exist. Please provide a valid user"
	#	exit 1
	#fi
;;
#h ) 
#	if [[ -z ${NAME} ]];
#	then
#		echo "No username provided"
#		exit_abnormal
#	fi
#	DIRECTORY="$OPTARG"
#	result=$(check_home_directory_exists "$NAME" "$DIRECTORY")
#	if [[ $? -eq 0 ]];
#	then
#		echo "Valid Home directory: $DIRECTORY"
#		main "${DIRECTORY}"
#	else
#		echo "Not a valid home directory for that user"
#		exit 1
#	fi
#;;
l )
	LOG_PATH="$OPTARG"
	LOG_FILE_PATH="$LOG_PATH/$LOG_FILE_PATH"
	echo "Sending logs to $LOG_FILE_PATH" 
;;
\? )
	echo "Script requires an argument"
	exit_abnormal
;;
: )
	echo "Invalid option: Script requires an argument" 1>&2 
	exit_abnormal
;;
esac
no_args="false"
done
#shift $((OPTIND -1))

[[ "$no_args" = "true" ]] && { exit_abnormal; } 

#Check that the user invoking the script has the correct permissions.
sudo -v 2> /dev/null
[[ "$?" -eq 1 ]] && { exit_no_permissions; }

result=$(check_user_exists "$NAME")

if [[ $? -eq 0 ]];
        then
                DIRECTORY=$(grep "$NAME" /etc/passwd | awk -F ':' '{ print $6 }')
                main "${DIRECTORY}"
        else
                echo "User does not exist. Please provide a valid user"
                exit 1
fi
