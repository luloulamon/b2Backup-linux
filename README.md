##########################################################################################
# b2Backup-linux
 Uses bash script with b2 python CLI to encrypt and upload to a Backblaze B2 backup bucket.

Just a simple project as I wanted to implement my own backup system that fully encrypts the files but still retains paths for future restores.


##########################################################################################

## Encryption method:

Uses OpenSSL with a password key file (tested using an RSA key generated via ssh-keygen)

It is preferred to have 2 different password key files to prevent a single hack to be able to break the filename and the file itself. 

Uses a base64 AES-256-CBC method to produce the filename as well as concatenating a sha1sum for confirmation of the file contents once decrypted (on restore).

Filenames are also base64'd after the encryption to ensure they are valid as filenames

Uses AES-256-CBC as well for the file encryption, this is simplified by not adding a salt for reduced complexity on decryption. 


## REQUIREMENT:
Since this is a bash script, this obviously requires BASH.

This is currently tested and being run on Windows 10 with the Ubuntu BASH shell system running as well as ArchLinux.

**Caveat on running it within Windows is that it needs to run using SUDO or as root even if it is only running to backup user directories.**

Read about it here: https://www.howtogeek.com/249966/how-to-install-and-use-the-linux-bash-shell-on-windows-10/



## Files:

client.config - Required to have variables set for configuration, pointing to important files required for information such as directories to backup and API key.

DirsToBackup.config - List of directory paths to check for files and backup, creates a blank one when not available. This name can be changed in the client.config tile to any name.

apikey.config - file that contains the Backblaze App API key in the format "ACCOUNTID:APIKEY" where the account id and API key are separated by ":". This file name can be changed in the client.config file.

#### DEBUG:

Can enable debug logging and terminal echo by enabling DEBUG=1 on the client.config file.

#### LOGS:

upload log - stores a manifest/list of all files uploaded today and their corresponding encrypted filenames

backup log - log file for each showing what the script has done on that run



