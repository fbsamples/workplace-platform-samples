# Copyright (c) Meta Platforms, Inc. and affiliates.
# All rights reserved.
# 
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

#!/usr/bin/python
import json        # For parsing JSON and run
import platform    # For getting the operating system name
import subprocess  # For executing a shell command
import sys         # For running ping command
from urllib.parse import urlparse   #For parsing URLs efficiently

# Check platform
param = '-n' if platform.system().lower()=='windows' else '-c'
# Define URL set to store unique URL found in har file
urlset = set()

# Load har file that is provided as argument in an object
with open(sys.argv[1]) as f:
  obj=json.load(f)

# Extract domains found in har file into set.
for entry in obj['log']['entries']:
  urlset.add(urlparse(entry['request']['url']).netloc)
  urlset.add(urlparse(entry['response']['redirectURL']).netloc)


# Remove any empty sting from set
urlset.discard('')

# Ping every domain found in har to check connectivity
for host in urlset:
  # Building the command. Ex: "ping -c 1 google.com"
  command = ['ping', param, '1', host]
  # Run the ping test to the domain. 
  response = subprocess.call(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)   
  # If ping is successful, print reacheable or else print unrecheable.
  if response == 0:
    print(host + ' is reachable!')
  else:
    print(host + ' is unreachable!')


