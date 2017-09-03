#!/bin/bash
			test2=(`echo "$test" | openssl enc -d -base64 -aes-256-cbc -pass file:id_rsa.pub.key -nosalt`) #decrypt file path
