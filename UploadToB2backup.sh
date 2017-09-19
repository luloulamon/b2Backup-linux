#!/bin/bash

exec find -type f -name "*.config" | xargs dos2unix #clean all config files to unix format

source "client.config" #read config entries from client config file
accountId=$(cat apikey.config | cut -f1 -d : |  tr -d '[:space:]') #read api credentials from config file
apiKey=$(cat apikey.config | cut -f2 -d : |  tr -d '[:space:]')

#function to write onto log files for echo statements
function writeLog {

    if [ -t 0 ]
    then
        data=$1
	    echo "nopipe"
    else
        data=$(cat)
        if [ $DEBUG -eq "1" ]; then #if debugging echo onto stdout as well
	        echo  $data >> $logFile
	        echo "DEBUG:: $data"
	    else
	        echo  $data >> $logFile
	    fi
    fi

}

#function to output debug messages onto logfile as stdout
function ifDebug {
    if [ $DEBUG -eq "1" ]; then
        if [ -t 0 ]
        then
            data=$1
	        echo "No Message"
        else
            data=$(cat)
            echo "DEBUG:: $data" >> $logFile
	        echo "DEBUG:: $data"
        fi
    fi
}




echo "$dirs" | ifDebug
echo "Account ID: $accountId $apiKey" | ifDebug
echo `b2 authorize-account $accountId $apiKey`| ifDebug


echo "Checking config files" | writeLog

#check initialSync file exists
echo "Checking sync file" | writeLog
if [ -f "$initialSync" ]; then 
	initialSync=$(<$initialSync)
	if [ -z $initialSync ]; then #check if the file is empty or null
		echo "Empty Sync file" | writeLog
	else
		echo "Sync File Read" | writeLog
	fi
else 
	echo "No sync file, creating blank sync file" | writeLog
    touch "$initialSync"
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

if [ -s $intialSync ]; then
	echo "Initial Sync running..." | writeLog
    echo "directory ${#dirs[@]}" | ifDebug
    
	#simplistic encryption of the full path and name to obfuscate the backup names
	for i in "${dirs[@]}"
	do
	    echo "Current item $i" | ifDebug

		files=(`find $i -type f`)
		echo "File list ${#files[@]}" | ifDebug
		#echo ${files[*]}
		for j in "${files[@]}"
		do
			fullpath=(`realpath $j`)
			filename=(`echo $fullpath | openssl enc -e -base64 -aes-256-cbc -pass file:$key1 -nosalt | tr -d "/"`) #create encrypted filename
			echo "Uploading $fullpath" | writeLog
		    echo "Filename $filename" | ifDebug
			#echo -en "\n"
			fileChecksum=(`sha1sum $fullpath`) #create filechecksum to add as part of filename
	 		openssl enc -e -in $fullpath -out "/tmp/$filename" -aes-256-cbc -pass file:$key2 -nosalt #create encrypted file to upload to backblaze
			checksum=(`sha1sum /tmp/$filename`) #create a file checksum for encrypted file for backblaze upload confirmation
			echo "Encrypted checksum $checksum" | ifDebug
			b2 upload-file --sha1 $checksum --threads 4 "$bucketName" "/tmp/$filename" "$filename-$fileChecksum.enc" | writeLog
			rm -f "/tmp/$filename" #remove encrypted file from /tmp
			
			
		done
	done
	echo `date` >> $initialSync
else
    if [ -s $dirs ]; then
	    echo "Starting find files changed..."
	    for i in $dirs
	    do
		    changed=$(find $i -cmin -3600 -type f)
		    echo $changed 
	    done
	 else
	    echo "Empty Dirs file"
	 fi
fi




