#!/bin/bash

find -type f -name "*.config" -exec + | xargs dos2unix #clean all config files to unix format

source "client.config" #read config entries from client config file
accountId=$(cut -f1 -d : apikey.config |  tr -d '[:space:]') #read api credentials from config file
apiKey=$(cut -f2 -d : apikey.config |  tr -d '[:space:]')

#function to write onto log files for echo statements
function writeLog {

    if [ -t 0 ]
    then
        data=$1
	    echo "nopipe"
    else
        data=$(cat)
        if [ "$DEBUG" -eq "1" ]; then #if debugging echo onto stdout as well
	        echo  "$data" >> "$logFile"
	        echo "DEBUG:: $data"
	    else
	        echo  "$data" >> "$logFile"
	    fi
    fi

}

#function to write onto log files for the manifest
function writeULog {

    if [ -t 0 ]
    then
        data=$1
	    echo "nopipe"
    else
        data=$(cat)
        if [ "$DEBUG" -eq "1" ]; then #if debugging echo onto stdout as well
	        echo  "$data" >> "$uploadLog"
	        echo "DEBUG:: $data"
	    else
	        echo  "$data" >> "$uploadLog"
	    fi
    fi

}

#function to output debug messages onto logfile as stdout, data has to be piped into it
function ifDebug {
    if [ "$DEBUG" -eq "1" ]; then
        if [ -t 0 ]
        then
            data=$1
	        echo "No Message"
        else
            data=$(cat)
            echo "DEBUG:: $data" >> "$logFile"
	        echo "DEBUG:: $data"
        fi
    fi
}

function encryptFile {
    fullpath=$(realpath "$1")
	
	#simplistic encryption of the full path and name to obfuscate the backup names
	filename=$(openssl enc -e -in "$fullpath "-base64 -aes-256-cbc -pass file:"$key1" -nosalt | tr -d "/") #create encrypted filename
	echo "Uploading $fullpath" | writeLog
    echo "Filename $filename" | ifDebug
	#echo -en "\n"
	
	fileChecksum=$(sha1sum "$fullpath") #create filechecksum to add as part of filename
	enc e -openssl -in "$fullpath" -out "$tempFolder/$filename" -aes-256-cbc -pass file:"$key2" -nosalt #create encrypted file to upload to backblaze
	checksum=$(sha1sum "$tempFolder/$filename") #create a file checksum for encrypted file for backblaze upload confirmation
	echo "Encrypted checksum $checksum" | ifDebug
	b2 upload-file --sha1 "$checksum" --threads 4 "$bucketName" "$tempFolder/$filename" "$filename-$fileChecksum.enc" | writeLog
	rm -f "$tempFolder/$filename" #remove encrypted file from $tempFolder
	echo "$fullpath - $filename-$fileChecksum.enc" | writeULog
}

currTime=$(date)
echo "Backup Script Starting... $currTime" | writeLog
echo "$dirs" | ifDebug
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
if [ -f "$dirs" ]; then
	dirs=$(<$dirs)
	echo "Dirs loaded" | writeLog
else
	echo "No directory list - touching to create file, enter directories to back up in this file" | writeLog
	touch "$dirs"
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

		files=$(find $i -type f )
		echo "File list ${#files[@]}" | ifDebug
		#echo "Files ${files[*]}"
		#iterate through all the files in the dir
		for j in "${files[@]}"
		do
			
			fullpath=$(realpath "$j")
			#simplistic encryption of the full path and name to obfuscate the backup names
			filename=$(openssl enc -e -in "$fullpath "-base64 -aes-256-cbc -pass file:"$key1" -nosalt | tr -d "/") #create encrypted filename
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
