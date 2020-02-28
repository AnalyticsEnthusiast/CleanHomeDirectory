#!/bin/bash

# Interactive program that takes a username as an argument (or optional home directory argument from the user) and goes through each file greater than 100K, asks to remove, backup or keep.
# Clean home directory utility

help() {
	echo "Usage: $0 [ -u User] [-h Home Directory ]" 1>$2
}

exit_abnormal() {
	help
	exit 1
}

check_user_exists() {
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

NAME=
DIRECTORY=

while getops "u:h" option; do
case ${option} in
u )
	NAME=$OPTARG
	if [[ check_user_exists "$NAME" -eq 0 ]];
	then
		echo "User $OPTARG exists"
	else
		echo "User does not exist. Please provide a valid user"
		exit 1
	fi
;;
h ) 
	DIRECTORY=$OPTARG
	if [[ check_home_directory_exists "$NAME" "$DIRECTORY" -eq 0 ]];
	then
		echo "Valid Home directory: $DIRECTORY"
	else
		echo "Not a valid home directory for that user"
		exit 1
	fi
;;
\? )
	exit_abnormal
: )
	echo "Invalid option: Script requires an argument" 1>&2
	exit 1
;;
esac
done

# Print user ask text
ask1(){
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
	echo "Would you like to keep this file? -> $file_name\n"
	read -p "(K|B|D): " response
	
	if [[ ${response,,} = "K" ]];
	then
		echo "Keeping file"
	
	elif [[ ${response,,} = "B" ]];
	then
		echo "Sending file to Backup...."
		cp "$path_to_file" /tmp/backup
		
	elif [[ ${response,,} = "D" ]];
	then
		rm -f "$path_to_file"
		echo "File $path_to_file Deleted"
	else
		echo "Not a valid argument. Keeping file by default."
	fi
}


main(){	
	# Make a temporary backup directory in /tmp that will store files
	mkdir /tmp/backup
	
	# Ask user what they would like to do with the files
	FIRST=1
	while IFS=$'\n' read -r line;
	do
		if [[ FIRST -eq 1 ]];
		then
			FIRST=0
			ask1
			ask2 "$line"
		else
			ask2 "$line"
		fi
	done < <(find $1 -type f -size +100k -exec ls -hl {} \;)
	
	# Make backup of the file in /tmp/backup
	d=$(date | tr ' ' '_' | tr ':' '_')
	name=$(echo "/tmp/backup_$d.tar.gz")
	tar cvzf "$name" /tmp/backup/
	
	# Remove backup directory to clean up
	rm -rf /tmp/backup
}









