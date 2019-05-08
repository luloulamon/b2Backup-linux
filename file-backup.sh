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
