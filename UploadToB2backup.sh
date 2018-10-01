#!/bin/bash

convertUnix="0"

if [ "$convertUnix" -eq "1" ]; then
	echo $(dos2unix ./*)
fi

#find . -type f -name "*.config" -print0 | xargs dos2unix #clean all config files to unix format
#find . -type f -name "*.bash"  -print0 | xargs dos2unix #clean all config files to unix format

source "client.config" #read config entries from client config file
source "functions.bash" #read functions file
accountId=$(cut -f1 -d : "$apiKeyFile" |  tr -d '[:space:]') #read api credentials from config file
apiKey=$(cut -f2 -d : "$apiKeyFile" |  tr -d '[:space:]')
latestLog=$(getLatestUploadLog)

currTime=$(date)
echo "DEBUG IS ON.............$DEBUG" | ifDebug
echo "Backup Script Starting... $currTime" | writeLog
echo "$dirsList" | ifDebug
echo "Account ID: $accountId $apiKey" | ifDebug
b2 authorize-account "$accountId" "$apiKey"| writeLog 

echo "Checking binaries.." $(checkBinaries) | ifDebug

echo "Checking config files" | writeLog

#check initialSync file exists
echo "Checking sync file" | writeLog
if [ -f "$initialSyncFile" ]; then
	initialSync=$(head -n 1 "$initialSyncFile")
	echo "First line: $initialSync and length is ${#initialSync}" | ifDebug
	if [  ${#initialSync} -eq 0 ]; then #check if the file is empty or null
		echo "Empty Sync file" | writeLog
	else
		echo "Sync File Read" | writeLog
	fi
else
	echo "No sync file, creating blank sync file" | writeLog
    touch "$initialSyncFile"
fi #initialSync check end

#check dirs file exists
echo "Checking dirs file" | writeLog
if [ -f "$dirsList" ]; then

	readarray -t dirs < $dirsList #force to read as proper array
	echo "Dirs loaded" | writeLog
else
	echo "No directory list - touching to create file, enter directories to back up in this file" | writeLog
	touch "$dirsList"
fi

echo "Done checking config files" | writeLog

#check sync file has length greater than 0
if [ ${#initialSync} -eq 0  ]; then
	echo "Initial Sync running..." | writeLog
    echo "directory ${#dirs[@]}" | ifDebug
    counter=0

	#iterate through all directories in the dir list file
	for i in "${dirs[@]}"
	do
	    echo "Current dir $i" | ifDebug

		#read the find results and place into array properly, this covers files with special chars in the names
		files=()
        #iterate through all the files in the dir
		while IFS=  read -r -d $'\0'; do
			files+=("$REPLY")
		done < <(find "$i" -type f -print0)
		echo "Files in list ${#files[@]}" | ifDebug

		echo "lololo $DEBUG"		
		if [ "$DEBUG" -eq 0 ]; then
		        ANSWER="y"
		else
			read -p "Do you want to start backing up? " -r ANSWER
			echo "$ANSWER yooo"
		fi

		#Get response from user for debugging
		if [[ $ANSWER =~ ^[Yy]$ ]]
		then
			for j in "${files[@]}"
			do

				fullpath=$(realpath "$j")
				echo "Uploading $fullpath" | writeLog

				filename=$(encryptFileName "$j") #create encrypted filename

				echo "Filename $filename" | ifDebug
				#echo -en "\n"

				encryptFile "$j" "$filename"    #Encrypt file via function
				counter=$((counter + 1))   #increase upload counter

			done
		else
			exit 500
		fi
	done
	currTime=$(date)
	echo "Total Files Uploaded: $counter"
	echo "Initial Sync Done $currTime" | writeLog
	echo "$currTime" > "$initialSyncFile" #date the initialSync
else
    counter=0
    echo "Not First Sync, checking for updates" | writeLog
    #iterate through all directories in the dir list file
	for i in "${dirs[@]}"
	do
	    echo "Current dir $i" | ifDebug

		#read the find results and place into array properly, this covers files with special chars in the names
		files=()
		while IFS=  read -r -d $'\0'; do
			toAdd="$(checkFileUploaded $REPLY)"
			if [ "$toAdd" -gt "0" ]
			then
				echo "File is in log - $REPLY" | ifDebug
				files+=("$REPLY")
			fi
		done < <(find "$i" -type f -newerct "$initialSync" -print0) #known issue where this seems to only work based on day and not the exact time.... so all files created or modified on the same day will be backed up again.
		echo "File list ${files[@]}" | ifDebug

		#iterate through all the files in the dir
		if [ "$DEBUG" -eq "0" ]; then
		        ANSWER="y"
	 	else
                        read -p "Do you want to start backing up? " -r ANSWER
                        echo "$ANSWER yooo"
		fi

		if [[ $ANSWER =~ ^[Yy]$ ]]
		then
			for j in "${files[@]}"
			do

				fullpath=$(realpath "$j")
				echo "Uploading $fullpath" | writeLog

				filename=$(encryptFileName "$j") #create encrypted filename

				echo "Filename $filename" | ifDebug
				#echo -en "\n"

				encryptFile "$j" "$filename"
				counter=$((counter + 1))

			done
		else
			exit 500
		fi
	done
	currTime=$(date)
	echo "Total Files Uploaded: $counter"
	echo "Update Sync Done $currTime" | writeLog
fi
