# Copyright 2017-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

# -*- coding: utf-8 -*-

#general imports
import csv
import sys
import json
import requests
import re

#project imports
import scim_sdk
import csv_header

reload(sys)
sys.setdefaultencoding('utf-8')

#track errors in any validation or magic
ERRORS = []

#prompts
VALID_FILE = '---> Valid File <---'
VALIDATING_PROMPT = 'validating...'
UPDATING_USERS_PROMPT = 'Updating users...'
CREATE_USERS_PROMPT = 'Creating users...'
UPDATING_MANAGERS_PROMPT = 'Updating managers...'
DELETING_USERS_PROMPT = 'Deleting users...'
EXPORTING_USERS_PROMPT = 'Exporting users to: '
START_ERRORS_PROMPT = '==========START ERRORS=========='
END_ERRORS_PROMPT = '==========END ERRORS=========='

#input prompts
ACCESS_TOKEN_INPUT_PROMPT = 'Access token? '
SCIM_URL_INPUT_PROMPT = 'SCIM URL? '
UPDATE_COMMAND = '-u'
CREATE_COMMAND = '-c'
EXPORT_COMMAND = '-e'
DELETE_COMMAND = '-d'

#error messages
ERROR_FAILED_CREATE = 'Failed to create user with email '
ERROR_UPDATE_MANAGER = 'Failed to update manager for user with email '
ERROR_UPDATE_MANAGER_2 = ' and manager '
ERROR_FAILED_DELETE = 'Failed to delete user with email '
ERROR_COLUMN_COUNT = 'There are '
ERROR_COLUMN_COUNT_2 = ' columns in row '
ERROR_COLUMN_COUNT_3 = ' but there should be '
ERROR_INVALID_HEADER_TITLE = ' is not a valid header title'
ERROR_MISSING_HEADER = 'You need to include all required headers:'
ERROR_MISSING_ACCESS_TOKEN = 'Access token is required, exiting...'
ERROR_INVALID_SCIM_URL = 'Valid SCIM URL is required, exiting...'
ERROR_INVALID_COMMAND_LINE_USAGE = 'Invalid Usage. Must use either:\n>python scim_agent.py <command> <filename>\nor\n>python scim_agent.py <command> <filename> <access_token> <scim_url>'

#other constants
NOT_FOUND = -1
COLUMN_NAME_TO_NUMBER_MAP = {}
USERS_KEY = 'users'
MANAGER_PAIRS_KEYS = 'managerPairs'
MANAGER_PAIRS_EMPLOYEE_KEY = 'employee'
MANAGER_PAIRS_MANAGER_KEY = 'manager'

#file constants
FILE_WRITE_PERMISSION = 'wb'
FILE_DELIM = ','
FILE_QUOTE = '"'

#scim url constants for validating SCIM url param
SCIM_URL = 'https://www.facebook.com/scim/v1/'

#command base functions
def updateUsers(filename, access_token, scim_url):
	# clear errors if any from previous calls
	del ERRORS[:]
	print(VALIDATING_PROMPT)
	userGroups = validateCSV(filename, csv_header.CREATE_UPDATE_EXPECTED_HEADERS, csv_header.CREATE_UPDATE_REQUIRED_HEADERS)
	if ERRORS:
		return ERRORS[:]
	print(UPDATING_USERS_PROMPT)
	for email in userGroups[USERS_KEY]:
		scim_sdk.updateUser(scim_url, access_token, userGroups[USERS_KEY][email])
	#update manager
	updateManagers(access_token, scim_url, userGroups[MANAGER_PAIRS_KEYS])
	return ERRORS[:]

def createUsers(filename, access_token, scim_url):
	# clear errors if any from previous calls
	del ERRORS[:]
	print(VALIDATING_PROMPT)
	userGroups = validateCSV(filename, csv_header.CREATE_UPDATE_EXPECTED_HEADERS, csv_header.CREATE_UPDATE_REQUIRED_HEADERS)
	if ERRORS:
		return ERRORS[:]
	print(CREATE_USERS_PROMPT)
	for email in userGroups[USERS_KEY]:
		result = scim_sdk.createUser(scim_url, access_token, userGroups[USERS_KEY][email])
		if not result:
			ERRORS.append(ERROR_FAILED_CREATE + email)
	#update manager
	updateManagers(access_token, scim_url, userGroups[MANAGER_PAIRS_KEYS])
	return ERRORS[:]

def updateManagers(access_token, scim_url, managerPairs):
	print(UPDATING_MANAGERS_PROMPT)
	for managerPair in managerPairs:
		if not scim_sdk.updateManager(scim_url, access_token, managerPair[MANAGER_PAIRS_EMPLOYEE_KEY], managerPair[MANAGER_PAIRS_MANAGER_KEY]):
			ERRORS.append(ERROR_UPDATE_MANAGER + managerPair[MANAGER_PAIRS_EMPLOYEE_KEY] + ERROR_UPDATE_MANAGER_2 + managerPair[MANAGER_PAIRS_MANAGER_KEY])

def deleteUsers(filename, access_token, scim_url):
	# clear errors if any from previous calls
	del ERRORS[:]
	print(VALIDATING_PROMPT)
	userGroups = validateCSV(filename, csv_header.DELETION_HEADERS, csv_header.DELETION_HEADERS)
	if ERRORS:
		return ERRORS[:]
	print(DELETING_USERS_PROMPT)
	for email in userGroups[USERS_KEY]:
		if not scim_sdk.deleteUser(scim_url, access_token, email):
			ERRORS.append(ERROR_FAILED_DELETE + email)
	return ERRORS[:]

def exportUsers(filename, access_token, scim_url):
	print(EXPORTING_USERS_PROMPT + filename)
	userCollection = []
	userCollection = scim_sdk.getUsers(scim_url, access_token, 1, userCollection)
	with open(filename, FILE_WRITE_PERMISSION) as csvfile:
		writer = csv.writer(csvfile, delimiter= FILE_DELIM, quotechar=FILE_QUOTE, quoting=csv.QUOTE_MINIMAL)
		# CSV Header
		header = csv_header.CREATE_UPDATE_EXPECTED_HEADERS
		writer.writerow(header)
		if userCollection:
			for item in userCollection:
				row = buildExportRow(item, access_token, scim_url)
				writer.writerow(row)


def buildExportRow(item, access_token, scim_url):
	email = scim_sdk.getUserProperty(item, scim_sdk.FIELD_USER_NAME)
	firstName = scim_sdk.getUserProperty(item, scim_sdk.FIELD_NAME, scim_sdk.FIELD_GIVEN_NAME)
	lastName = scim_sdk.getUserProperty(item, scim_sdk.FIELD_NAME, scim_sdk.FIELD_FAMILY_NAME)
	title = scim_sdk.getUserProperty(item, scim_sdk.FIELD_TITLE)
	department = scim_sdk.getUserProperty(item, scim_sdk.SCHEME_NTP, scim_sdk.FIELD_DEPARTMENT)
	phoneNumber = scim_sdk.getUserPropertyList(item, scim_sdk.FIELD_PHONE_NUMBERS, scim_sdk.FIELD_WORK, True, scim_sdk.FIELD_VALUE)
	location = scim_sdk.getUserPropertyList(item, scim_sdk.FIELD_ADDRESSES, scim_sdk.FIELD_WORK, True, scim_sdk.FIELD_FORMATTED)
	locale = scim_sdk.getUserProperty(item, scim_sdk.FIELD_LOCALE)
	manager = scim_sdk.getManager(item, access_token, scim_url)
	timezone = scim_sdk.getUserProperty(item, scim_sdk.FIELD_TIMEZONE)
	externalId = scim_sdk.getUserProperty(item, scim_sdk.FIELD_EXTERNALID)
	organization = scim_sdk.getUserProperty(item, scim_sdk.SCHEME_NTP, scim_sdk.FIELD_ORGANIZATION)
	division = scim_sdk.getUserProperty(item, scim_sdk.SCHEME_NTP, scim_sdk.FIELD_DIVISION)
	costCenter = scim_sdk.getUserProperty(item, scim_sdk.SCHEME_NTP, scim_sdk.FIELD_COSTCENTER)
	startDate = scim_sdk.getUserProperty(item, scim_sdk.SCHEME_TERMDATES, scim_sdk.FIELD_STARTDATE)

	return [email, firstName, lastName, title, department, phoneNumber, location, locale, manager, timezone, externalId, organization, division, costCenter, startDate]

def validateCSV(filename, expected_headers, required_headers):
	# reset the column mapping if any previous values
	COLUMN_NAME_TO_NUMBER_MAP.clear()
	f = open(filename)
	csv_f = csv.reader(f)
	headers = next(csv_f)
	headers_count = len(headers)
	validateHeaders(headers, expected_headers, required_headers)
	if ERRORS:
		print(ERRORS)
		return
	users = {}
	userGroups = {}
	userGroups[MANAGER_PAIRS_KEYS] = []
	#validate each row
	for row in csv_f:
		validateColumnCount(row, headers_count, str(csv_f.line_num))
		if ERRORS:
			print(ERRORS)
			return
		user = buildUserObject(row, str(csv_f.line_num), expected_headers)
		users[user[csv_header.EMAIL_HEADER]] = user
		if csv_header.MANAGER_HEADER in user and user[csv_header.MANAGER_HEADER]:
			userGroups[MANAGER_PAIRS_KEYS].append({MANAGER_PAIRS_EMPLOYEE_KEY: user[csv_header.EMAIL_HEADER], MANAGER_PAIRS_MANAGER_KEY: user[csv_header.MANAGER_HEADER]})
	f.close()
	userGroups[USERS_KEY] = users

	#if valid file then print out some flair
	if len(ERRORS) == 0:
		print(VALID_FILE)
	return userGroups

def buildUserObject(row, row_num, expected_headers):
	#build user objects and group assocs
	userObj = {}
	for col in expected_headers:
		addColumnVal(userObj, row, col)
	return userObj

def addColumnVal(userObj, row, column_name):
	val = getColumnVal(row, column_name)
	if val:
		userObj[column_name] = val


def validateColumnCount(row, headers_count, line_num):
	row_count = len(row)
	if row_count is not headers_count:
		ERRORS.append(ERROR_COLUMN_COUNT + str(row_count) + ERROR_COLUMN_COUNT_2 + line_num + ERROR_COLUMN_COUNT_3 + str(headers_count))


def validateHeaders(headers, expected_headers, required_headers):
	#set column place for columns and validate that valid columns exist
	for idx, header in enumerate(headers):
		header = header.lower()
		#check if user creation column, if so we ignore duplicates and set last seen
		if header in expected_headers:
			COLUMN_NAME_TO_NUMBER_MAP[header] = idx
		#not valid column so add error
		else:
			ERRORS.append(header.lower() + ERROR_INVALID_HEADER_TITLE)

	#check if all required headers are included
	if all(x in COLUMN_NAME_TO_NUMBER_MAP.keys() for x in required_headers) is not True:
		ERRORS.append(ERROR_MISSING_HEADER + str(required_headers))

#UTILS
def getColumnVal(row, column_name):
	clm_idx = COLUMN_NAME_TO_NUMBER_MAP.get(column_name, NOT_FOUND)
	#double negatives are our friends
	if clm_idx is not NOT_FOUND:
		return row[clm_idx]
	return None

def getParams(command, filename):
	access_token = raw_input(ACCESS_TOKEN_INPUT_PROMPT)
	if not access_token:
		print(ERROR_MISSING_ACCESS_TOKEN)
		return
	func_arg[command](filename, access_token, SCIM_URL)


#MAIN FUNCTION
#2 types of usage
#without params >python scim_agent.py <command> <filename>
#with params >python scim_agent.py <command> <filename> <access_token> <scim_url>
func_arg = {UPDATE_COMMAND: updateUsers, CREATE_COMMAND: createUsers, EXPORT_COMMAND: exportUsers, DELETE_COMMAND: deleteUsers}
if __name__ == '__main__':
	if len(sys.argv) == 3:
		getParams(sys.argv[1],sys.argv[2])
	elif len(sys.argv) == 4:
		func_arg[sys.argv[1]](sys.argv[2], sys.argv[3], SCIM_URL)
	else:
		print(ERROR_INVALID_COMMAND_LINE_USAGE)
	if ERRORS:
		print(START_ERRORS_PROMPT)
		for error in ERRORS:
			print(error)
		print(END_ERRORS_PROMPT)
