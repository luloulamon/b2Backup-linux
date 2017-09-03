#!/bin/bash

initialSync="initialSync.config"
exec `dos2unix DirsToBackup.config` #convert Windows EOL to Unix
dirs="DirsToBackup.config"

echo "Checking config files"

#check initialSync file exists
echo "Checking sync file"
if [ -f "$initialSync" ]; then 
	initialSync=$(<$initialSync)
	if [ -z $initialSync ]; then #check if the file is empty or null
		echo "Empty Sync file"
	else
		echo "Sync File Read"
	fi
else 
	echo "No sync file"
fi #initialSync check end

#check dirs file exists
echo "Checking dirs file"
if [ -f "$dirs" ]; then
	dirs=$(<$dirs)
	echo "Dirs loaded"
else
	echo "No directory list - touching to create file"
	touch $dirs
fi 

if [ $initialSync = 1 ]; then
	echo "Initial Sync running..."
	#simplistic encryption of the full path and name to obfuscate the backup names
	for i in ${dirs[@]}
	do
		files=(`find $i -type f`)
		#echo ${#dirs[@]}
		#echo ${#files[@]}
		#echo ${files[*]}
		for j in ${files[@]}
		do
			test=(`echo \`realpath $j\` | openssl enc -e -base64 -aes-256-cbc -pass file:id_rsa.pub.key -nosalt`) #access array item ${files[0]}
			echo `realpath $j`
			echo $test
			echo -en "\n"
			#realpath 
		done
	done
else
	echo "Starting find files changed..."
	for i in $dirs
	do
		changed=$(find $i -cmin -3600 -type f)
		echo $changed 
	done
fi



