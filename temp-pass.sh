#!/bin/bash

#Check if script is ran as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi
 
#Check the number of arguments
if [[ $# -ne 1 ]]
  then echo -e "Error! Script must have an argument!\nUsage: ./setup.sh non-root_username"
  exit
fi
  
user=$1
current_dir=$(pwd)

#Check if the user provided in the argument exists
if ! id $user &>/dev/null
  then echo "User not found! Enter a valid Username as an argument!"
  echo "Usage: ./setup.sh non-root_username"
  exit
fi 

#Check that the user provided in the argument is not root
if [ $user == 'root' ]
  then echo "User must not be root ! Enter a valid Username as an argument!"
  echo "Usage: ./setup.sh non-root_username"
fi

#PoolAudit Account Creation & Password Modification
useradd $user -m -G sudo
echo "$user:MdpTemp" | chpasswd
passwd --expire $user
