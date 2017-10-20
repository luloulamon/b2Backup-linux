#!/bin/bash
			test2=(`echo "$test" | openssl enc -d -base64 -aes-256-cbc -pass file:id_rsa.pub.key -nosalt`) #decrypt file path
			openssl enc -d -in "/tmp/$filename" -out "/tmp/file" -aes-256-cbc -pass file:id_rsa.key -nosalt 
echo `sha1sum /tmp/file`