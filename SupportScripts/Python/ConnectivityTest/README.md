# Check connectivity to domains logged in Har file.
  
**Language:** Python v3.7

## DISCLAIMER
Use at your own risk. This script is only provided to assist with connectivity check to URLs being accessed by browser while navigating a website.

## DESCRIPTION
This script uses Har file as input to filter out all the domains which were accessed while har logging was enabled. Then script runs a simple ping test to check if those domains are rechecable from the network/device you are running this script from. We recommend to run this script 2-3 times to ensure any random packet drops do not give wrong results.
Note: This script has only been tested on Mac. However it should work with Windows and Linux platforms as well. 

## SETUP
### Part 1
1. Go to any website -> right click -> Inspect. 
2. Go to "Network" tab. 
3. Start the network log recoding. Usually its automatically turned on and shows as a red dot on the Network Panel.
4. Operate various functionalities of the website. Better to try out each unique feature of website to ensure all urls are captured. 
5. Stop the recoding and download the logs as har file. 

### Part 2
1. Download this script. 
2. Preferably, keep both har file from step 1 and this script in same folder. 

## RUN

Open command line terminal of your platform. Change the directory of your command line to where the scipt is present and run the script. <sample_filename.har> is the filename of har file downloaded in Setup Part 1. Incase the script and har file are in different locations, you can also pass the absolute filepath as shown below in example 2.

```python
python ConnectivityTest.py sample_filename.har
```
or 
```python
python ConnectivityTest.py /Users/testuser/Download/sample_filename.har
```


