#!/bin/bash

exec `dos2unix DirsToBackup.txt`
dirs=$(<DirsToBackup.txt)
echo  $dirs 
for i in $dirs
do
	echo $i
	ls $i
	find $i -mtime -1 -ls | echo
done


