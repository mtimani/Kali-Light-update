#!/usr/bin/python3

#Imports
from selenium import webdriver
from selenium.webdriver.firefox.options import Options
from time import sleep
from os import system
import subprocess
import sys
from datetime import date

if len(sys.argv) != 2:
    print("Error! Script must have an argument!\nUsage: ./webscraper.py non-root_username")
    exit()

user = sys.argv[1]

sys.stdout = open('/burp-update-scripts/burp-update.log','a')
today = date.today()
d1 = today.strftime("%d/%m/%Y")

print("\n\n\nChecking for updates : " + d1 + "\n")

#Opening latest.txt to get the latest installed version
try:
    fd = open("/burp-update-scripts/latest.txt","r")
    latestInstalled = fd.readline()
    fd.close()
except OSError:
    latestInstalled = ""

#Download Directory
downloadDir = f"/home/{user}/Downloads/"

#Burp Releases Url
url = 'https://portswigger.net/burp/releases?initialTab=community#community'

#Start a Firefox instance
options = Options()
options.headless = True
browser = webdriver.Firefox(options=options)

#Getting Burp Page && Waiting for response
browser.get(url)
browser.maximize_window()
sleep(5)

#WebScraping
counter = 1
stopCondition = False
while not(stopCondition):
    webElement = browser.find_element_by_xpath(f'/html/body/section[2]/div[2]/div/div[1]/div[{counter}]/div/div[2]/label').text
    
    #Check if the release is stable
    if webElement == "Stable":
        version = browser.find_element_by_xpath(f'/html/body/section[2]/div[2]/div/div[1]/div[{counter}]/div/div[4]/form/input').get_attribute('version')

        #Check if the latest version of Burp is installed
        if version != latestInstalled:

            #Update file containing the latest version info
            fd = open("/burp-update-scripts/latest.txt","w")
            fd.write(version)
            fd.close()

            #Log the new version
            print(f"Updating Burp Professional to version {version}\n")

            #Download the latest Pro version of Burp
            system(f"cd /home/{user}/Downloads && wget 'https://portswigger.net/burp/releases/download?product=pro&version={version}&type=Jar'")

            #Get the checksum from Burp website
            webElement = browser.find_element_by_xpath(f'/html/body/section[2]/div[2]/div/div[1]/div[{counter}]/div/div[4]/form/select[1]').click()
            webElement = browser.find_element_by_xpath(f'/html/body/section[2]/div[2]/div/div[1]/div[{counter}]/div/div[4]/form/select[1]/option[1]').click()
            webElement = browser.find_element_by_xpath(f'/html/body/section[2]/div[2]/div/div[1]/div[{counter}]/div/div[4]/form/select[2]').click()
            webElement = browser.find_element_by_xpath(f'/html/body/section[2]/div[2]/div/div[1]/div[{counter}]/div/div[4]/form/select[2]/option[1]').click()
            webElement = browser.find_element_by_xpath(f'/html/body/section[2]/div[2]/div/div[1]/div[{counter}]/div/div[4]/form/label').click()
            correctChecksum = browser.find_element_by_xpath(f'/html/body/section[2]/div[2]/div/div[1]/div[{counter}]/div/div[5]/div/span[2]').text
            correctChecksum = correctChecksum.split()
            correctChecksum = correctChecksum[1]

            #Calculate downloaded checksum
            system(f"cd /home/{user}/Downloads && mv 'download?product=pro&version={version}&type=Jar' burpsuite")
            downloadedChecksum = subprocess.check_output('md5sum /home/timani/Downloads/burpsuite | awk "{print \$1}"', shell=True)
            downloadedChecksum = downloadedChecksum.decode("utf-8")
            downloadedChecksum = downloadedChecksum[:-1]
            
            #Compare the two checksums
            if correctChecksum != downloadedChecksum:
                browser.close()
                exit()

            #Exit program
            browser.close()
            sys.stdout.close()
            stopCondition = True
        else:
            #If latest version installed, exit code
            print("No updates found!\n")
            browser.close()
            exit()
    
    #Else continue looping
    counter += 1
