# Check connectivity to domains logged in Har file.
  
**Language:** Python v3.7

## DISCLAIMER
Use at your own risk. This script is only provided to assist with connectivity check to URLs being accessed in browser.

## DESCRIPTION
This script uses Har file as input to filter out all the domains which were accessed while har logging was enabled. Then script runs a simple ping test to check if those domains are rechecable or not from the network/device you are running this script from.

## SETUP
### Part 1
1. Go to any website -> right click -> Inspect. 
2. Go to "Network" tab. 
3. Start the network log recoding. Usually its automatically turned on and shows as a red dot on the Network Panel.
4. Operate various functionalities of the website. Better to try out each unique feature of website. 
5. Stop the recoding and download the logs as har file. 

### Part 2
1. Download this script. 
2. Preferably, keep both har file from step 1 and this script in same folder. 

## RUN

Open command line terminal of your platform. Change the run directory of your command line where the scipt is present and run the script as follows:

```python
python ConnectivityTest.py sample_filename.har
```
or 
```
python ConnectivityTest.py /Users/testuser/Download/sample_filename.har
```

where <sample_filename.har> is the filename of har file downloaded in Setup Part 1. Incase the script and har file are in different locations, you can also pass the absolute filepath.
