#!/bin/bash

find -type f -name "*.config" | xargs dos2unix #clean all config files to unix format
find -type f -name "*.bash" | xargs dos2unix #clean all config files to unix format

source "client.config" #read config entries from client config file
source "functions.bash" #read functions file
accountId=$(cut -f1 -d : apikey.config |  tr -d '[:space:]') #read api credentials from config file
apiKey=$(cut -f2 -d : apikey.config |  tr -d '[:space:]')

currTime=$(date)
echo "Backup Script Starting... $currTime" | writeLog
echo "$dirsList" | ifDebug
echo "Account ID: $accountId $apiKey" | ifDebug
b2 authorize-account "$accountId" "$apiKey"| ifDebug


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
	#dirs=$(<$dirs)
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
    
	#iterate through all directories in the dir list file
	for i in "${dirs[@]}"
	do
	    echo "Current dir $i" | ifDebug
		
		#read the find results and place into array properly, this covers files with special chars in the names
		files=()
		while IFS=  read -r -d $'\0'; do
			files+=("$REPLY")
		done < <(find $i -type f -print0)
		echo "File list ${#files[@]}" | ifDebug
		#echo "File list ${files[@]}" | ifDebug
		#echo "Files ${files[*]}"
		#iterate through all the files in the dir
		read -p "Do you want to start backing up? " -n 1 -r
		echo ""
		if [ "$DEBUG" -eq "0" ]; then
		        REPLY="y"
		fi
		if [[ $REPLY =~ ^[Yy]$ ]]
		then
			for j in "${files[@]}"
			do
				
				fullpath=$(realpath "$j")
				echo "Uploading $fullpath" | writeLog
				
				filename=$(encryptFileName "$j") #create encrypted filename
				
				echo "Filename $filename" | ifDebug
				#echo -en "\n"
				fileChecksum=$(sha1sum "$fullpath") #create filechecksum to add as part of filename
				encryptFile "$j" "$filename"
				
			done
		else
			exit 500
		fi
	done
	currTime=$(date)
	echo "Initial Sync Done $currTime" | writeLog
	echo "$currTime" > "$initialSyncFile" #date the initialSync
else
	echo "Not First Sync, checking for updates" | writeLog
    #iterate through all directories in the dir list file
	for i in "${dirs[@]}"
	do
	    echo "Current item $i" | ifDebug

		files=$(find "$i" -type f -newermt "$fileModifiedAge") #find files that have beed modified/updated 1 week ago
		echo "File list ${#files[@]}" | writeLog
		#echo "Files ${files[*]}" | ifDebug
		
		#iterate through all the files in the dir
		for j in "${files[@]}"
		do
		    #echo "Current file $j" | ifDebug
			fullpath=$(realpath "$j")
			#simplistic encryption of the full path and name to obfuscate the backup names
			filename=$(openssl enc -e -in "$fullpath" -base64 -aes-256-cbc -pass file:"$key1" -nosalt | tr -d "/") #create encrypted filename
			echo "Uploading $fullpath" | writeLog
		    echo "Filename $filename" | ifDebug
			#echo -en "\n"
			fileChecksum=$(sha1sum "$fullpath") #create filechecksum to add as part of filename
	 		openssl enc -e -in "$fullpath" -out "$tempFolder/$filename" -aes-256-cbc -pass file:"$key2" -nosalt #create encrypted file to upload to backblaze
			checksum=$(sha1sum "$tempFolder/$filename") #create a file checksum for encrypted file for backblaze upload confirmation
			echo "Encrypted checksum $checksum" | ifDebug
			b2 upload-file --sha1 "$checksum" --threads 4 "$bucketName" "$tempFolder/$filename" "$filename-$fileChecksum.enc" | writeLog
			rm -f "$tempFolder/$filename" #remove encrypted file from $tempFolder
			echo "$fullpath - $filename-$fileChecksum.enc" | writeULog
			
		done
	done
	currTime=$(date)
	echo "Update Sync Done $currTime" | writeLog
fi
