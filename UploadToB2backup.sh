#!/bin/bash

echo $(dos2unix ./*)
#find . -type f -name "*.config" -print0 | xargs dos2unix #clean all config files to unix format
#find . -type f -name "*.bash"  -print0 | xargs dos2unix #clean all config files to unix format

source "client.config" #read config entries from client config file
source "functions.bash" #read functions file
accountId=$(cut -f1 -d : apikey.config |  tr -d '[:space:]') #read api credentials from config file
apiKey=$(cut -f2 -d : apikey.config |  tr -d '[:space:]')

currTime=$(date)
echo "Backup Script Starting... $currTime" | writeLog
echo "$dirsList" | ifDebug
echo "Account ID: $accountId $apiKey" | ifDebug
b2 authorize-account "$accountId" "$apiKey"| ifDebug

echo "Checking binaries.." + checkBinaries | ifDebug

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


		read -p "Do you want to start backing up? " -n 1 -r
		echo ""
		if [ "$DEBUG" -eq "0" ]; then
		        REPLY="y"
		fi
		
		#Get response from user for debugging
		if [[ $REPLY =~ ^[Yy]$ ]]
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
			files+=("$REPLY")
		done < <(find "$i" -type f -newermt "$fileModifiedAge" -print0)
		echo "File list ${#files[@]}" | ifDebug

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
