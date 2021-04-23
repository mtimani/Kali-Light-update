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
  exit
fi

#Cleaning up
rm -rf /usr/bin/geckodriver
rm -rf /usr/bin/kali-update
rm -rf /usr/bin/burp-update
rm -rf /usr/bin/burpsuite
rm -rf /var/log/burp-update.log
rm -rf /var/log/kali-update.log
rm -rf /burp-update-scripts/
docker stop nessus
docker rm nessus
docker rmi nessus

#Install Update Script
chown root:root kali-update
chmod 744 kali-update
mv kali-update /usr/bin/

#Update Kali
kali-update

#Firewall Setup
sudo apt-get install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable

#Disabling root login
passwd -l root

#Update Repos
echo "deb https://http.kali.org/kali kali-rolling main non-free contrib" > /etc/apt/sources.list

#Download Firefox Driver
wget "https://github.com/mozilla/geckodriver/releases/download/v0.29.1/geckodriver-v0.29.1-linux64.tar.gz"
tar -xzvf geckodriver-v0.29.1-linux64.tar.gz
rm -rf geckodriver-v0.29.1-linux64.tar.gz
chmod 755 geckodriver
chown $user:$user geckodriver
mv geckodriver /usr/bin/

#Setup cron for the update of Kali
echo -e "$(sudo crontab -u root -l)\n00 22 * * * kali-update" | sudo crontab -u root -

#Update Firefox
sudo rm -rf /opt/firefox
sudo rm -rf /usr/lib/firefox
sudo rm -rf /usr/bin/firefox
wget -O firefox.tar.bz2 "https://download.mozilla.org/?product=firefox-latest&os=linux64"
sudo tar xjf firefox.tar.bz2 -C /opt
sudo mkdir /usr/lib/firefox
sudo ln -s /opt/firefox/firefox /usr/lib/firefox/firefox
sudo ln -s /opt/firefox/firefox /usr/bin/firefox
sudo rm -rf firefox.tar.bz2

#Install Docker
sudo apt-get install docker.io -y

#Load Nessus & Burp images in Docker
docker load < nessus_docker.tar.gz
docker load < burpsuite_docker.tar.gz

#Install pip & venv
sudo apt install python3-pip -y
sudo apt-get install python3 python3-venv -y

#Create venv
chown root:root burp-update
chmod 744 burp-update
mv burp-update /usr/bin/
chown root:root burp-update-helper
chmod 755 burp-update-helper
mv burp-update-helper /usr/bin/
mkdir /burp-update-scripts
chmod +x webscraper.py
mv webscraper.py /burp-update-scripts/
python3 -m venv /burp-update-scripts/env
source /burp-update-scripts/env/bin/activate
pip install -r requirements.txt
chown root:root requirements.txt
chmod 644 requirements.txt
mv requirements.txt /burp-update-scripts/
touch /burp-update-scripts/burp-update.log
chown -R $user:$user /burp-update-scripts/
ln -s /burp-update-scripts/burp-update.log /var/log/burp-update.log
deactivate

#Update Burp
burp-update $user

#Setup cron for the update of Burp
echo -e "$(sudo crontab -u root -l)\n30 22 * * SAT burp-update ${user}" | sudo crontab -u root -

#Install Nessus Docker Image from archive
docker run --name nessus -d -p 8834:8834 nessus

#Setup Launch Script For Nessus Docker Image
chmod 744 nessus
chown root:root nessus
mv nessus /usr/bin

#Setup Update Script For Nessus Docker Image
chmod 744 nessus-update
chown root:root nessus-update
mv nessus-update /usr/bin

#Setup Cron For The Nessus Docker Image Update
echo -e "$(sudo crontab -u root -l)\n00 23 * * SAT nessus-update" | sudo crontab -u root -

#Downloading SecLists
sudo apt-get install seclists -y

#Openjdk
sudo apt-get install openjdk-11-jdk -y
sudo apt-get install openjdk-11-jre -y

#Update JDK
wget --no-check-certificate -c --header "Cookie: oraclelicense=accept-securebackup-cookie" https://download.oracle.com/otn-pub/java/jdk/15.0.2+7/0d1cfde4252546c6931946de8db48ee2/jdk-15.0.2_linux-x64_bin.tar.gz
sudo mkdir /usr/lib/jvm
sudo tar -xzvf jdk-15.0.2_linux-x64_bin.tar.gz -C /usr/lib/jvm
sudo echo -e "PATH=$PATH:/usr/lib/jvm/jdk-15.0.2/bin:/usr/bin/geckodriver" | sudo tee -a /etc/environment
sudo echo -e "JAVA_HOME='/usr/lib/jvm/jdk-15.0.2'" | sudo tee -a /etc/environment
sudo update-alternatives --install "/usr/bin/java" "java" "/usr/lib/jvm/jdk-15.0.2/bin/java" 0
sudo update-alternatives --install "/usr/bin/javac" "javac" "/usr/lib/jvm/jdk-15.0.2/bin/javac" 0
sudo update-alternatives --set java /usr/lib/jvm/jdk-15.0.2/bin/java
sudo update-alternatives --set javac /usr/lib/jvm/jdk-15.0.2/bin/javac
sudo rm -rf jdk-15.0.2_linux-x64_bin.tar.gz

#Move Full Update Script to /usr/bin
cd $current_dir
chmod 744 update
chown root:root update
mv update /usr/bin

#Restart Cron
sudo service cron restart

#Launch Config
cd $current_dir
./configuration.sh
su $user -c "gsettings set org.gnome.desktop.background picture-uri file:///usr/share/images/desktop-base/desktop-background.png"

#PoolAudit Account Creation & Password Modification
#useradd $user -m -G sudo
#echo "$user:MdpTemp" | chpasswd
#passwd --expire $user

#Reboot
reboot
