#!/bin/bash
##########################################################
#
#	This script is for restoring the backups from b2
#
##########################################################
convertUnix="0"

if [ "$convertUnix" -eq "1" ]; then
	echo $(dos2unix ./*)
fi

source "client.config" #read config entries from client config file
source "functions.bash" #read functions file
accountId=$(cut -f1 -d : "$apiKeyFile" |  tr -d '[:space:]') #read api credentials from config file
apiKey=$(cut -f2 -d : "$apiKeyFile" |  tr -d '[:space:]')

currTime=$(date)
echo "Restore Script Starting... $currTime" | writeLog
echo "Account ID: $accountId $apiKey" | ifDebug
b2 authorize-account "$accountId" "$apiKey"| ifDebug

fileToRestore=$1

encryptedPath=$(echo $fileToRestore | awk -F "-" '{print $1}' )
checksum=$(echo $fileToRestore | awk -F "-" '{print $2}')
checksum=${checksum%.*} # remove the file extension
localName=$(restoreFilePath "$encryptedPath")

echo "File to restore - $fileToRestore" | ifDebug
echo "Encrypted Path - $encryptedPath" | ifDebug
echo "Local decrypted filename and path - $localName" | ifDebug
echo "FileChecksum - $checksum" | ifDebug

restoreFile $fileToRestore $localName




			#test2=(`echo "$test" | openssl enc -d -base64 -aes-256-cbc -pass file:id_rsa.pub.key -nosalt`) #decrypt file path
			#openssl enc -d -in "/tmp/$filename" -out "/tmp/file" -aes-256-cbc -pass file:id_rsa.key -nosalt
#echo `sha1sum /tmp/file` openssl enc -base64 -A -aes-256-cbc -pass file:"$key1" -nosalt | base64 | tr -d "\n"
