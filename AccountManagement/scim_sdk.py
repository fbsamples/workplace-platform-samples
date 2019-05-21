# Copyright 2017-present, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the license found in the
# LICENSE file in the root directory of this source tree.

import requests
import csv_header
import json
import urllib
import collections
import datetime
import time

#general constants
FIRST_ITEM = 0
EMPTY_RESPONSE = ''

# property constants
FIELD_USER_NAME = 'userName'
FIELD_MANAGER_ID = 'managerId'
FIELD_NAME = 'name'
FIELD_GIVEN_NAME = 'givenName'
FIELD_FAMILY_NAME = 'familyName'
FIELD_TITLE = 'title'
FIELD_DEPARTMENT = 'department'
FIELD_PHONE_NUMBERS = 'phoneNumbers'
FIELD_WORK = 'work'
FIELD_VALUE = 'value'
FIELD_ADDRESSES = 'addresses'
FIELD_FORMATTED = 'formatted'
FIELD_LOCALE = 'locale'
FIELD_ACTIVE = 'active'
FIELD_RESOURCES = 'Resources'
FIELD_TOTAL_RESULTS = "totalResults"
FIELD_ITEMS_PER_PAGE = "itemsPerPage"
FIELD_ERROR = 'error'
FIELD_MESSAGE = 'message'
FIELD_ID = 'id'
FIELD_TYPE = 'type'
FIELD_PRIMARY = 'primary'
FIELD_MANAGER = 'manager'
FIELD_SCHEMAS = 'schemas'
FIELD_EXTERNALID = 'externalID'
FIELD_COSTCENTER = 'costCenter'
FIELD_ORGANIZATION = 'organization'
FIELD_DIVISION = 'division'
FIELD_STARTDATE = 'startDate'
FIELD_TIMEZONE = 'timezone'

#request constants
HEADER_AUTH_KEY = 'Authorization'
HEADER_AUTH_VAL_PREFIX = 'Bearer '
USERS_RESOURCE_SUFFIX = 'Users'
HTTP_DELIM = '/'
EMAIL_LOOKUP_SUFFIX = '?filter=userName'
ESCAPED_EMAIL_LOOKUP_PREFIX = ' eq \"'
ESCAPED_EMAIL_LOOKUP_SUFFIX = '\"'
START_INDEX = "?startIndex="

#request json constants
SCHEME_CORE = 'urn:scim:schemas:core:1.0'
SCHEME_NTP = 'urn:scim:schemas:extension:enterprise:1.0'
SCHEME_TERMDATES = 'urn:scim:schemas:extension:facebook:starttermdates:1.0'

#response status code constants
RESPONSE_OK = 200
RESPONSE_CREATED = 201

#prompt constants
RESULT_STATUS_DELIM = ':'
EXPORT_RESULT_DELIM = " / "
CREATING_USER_PROMPT = 'Creating user '
DELETING_USER_PROMPT = 'Deleting user '
UPDATING_USER_PROMPT = 'Updating user '

#error constants
ERROR_RECORD_NOT_FOUND = 'Record not found for '
ERROR_NEWFIELDS_INVALID_FORMAT = 'newFields must be a dictionary using the following keys: '
ERROR_WITH_MESSAGE_PREFIX = 'Error'
ERROR_WITHOUT_MESSAGE = "Invalid request, no error message found"

def getHeaders(access_token):
	headers = {HEADER_AUTH_KEY: HEADER_AUTH_VAL_PREFIX + access_token}
	return headers

#create user
def createUser(scim_url, access_token, user_obj):
	print CREATING_USER_PROMPT + user_obj.get(csv_header.EMAIL_HEADER, None)
	url = scim_url + USERS_RESOURCE_SUFFIX
	data = getCreatJSON(user_obj)
	result = requests.post(url, headers=getHeaders(access_token), data=data)
	print str(result.status_code) + RESULT_STATUS_DELIM + result.reason
	return result.status_code == RESPONSE_CREATED

def getCreatJSON(user_obj):
	#set active to true for user creation
	user_obj[FIELD_ACTIVE] = True;
	json_obj = buildUserJSONObj(user_obj)
	return json.dumps(json_obj)

#delete user
def deleteUser(scim_url, access_token, email):
	print DELETING_USER_PROMPT + email
	oldRecord = getResourceFromEmail(scim_url, access_token, email)
	if not oldRecord:
		print ERROR_RECORD_NOT_FOUND + email
		return False
	url = scim_url + USERS_RESOURCE_SUFFIX + HTTP_DELIM + str(oldRecord[FIELD_ID])
	result = requests.delete(url, headers=getHeaders(access_token),)
	print str(result.status_code) + ':' + result.reason
	return result.status_code == RESPONSE_OK

#update user
def updateUser(scim_url, access_token, newFields):
	email = newFields.get(csv_header.EMAIL_HEADER, None)
	if email is None:
		print ERROR_NEWFIELDS_INVALID_FORMAT + csv_header.UPDATE_HEADERS
		return false
	print UPDATING_USER_PROMPT + email
	oldRecord = getResourceFromEmail(scim_url, access_token, email)
	if not oldRecord:
		print ERROR_RECORD_NOT_FOUND+ email
		return false
	newFields = buildUserJSONObj(newFields)
	newUserObj = mergeUserObjs(oldRecord,newFields)
	newUserJSON = json.dumps(newUserObj)
	url = scim_url + USERS_RESOURCE_SUFFIX + HTTP_DELIM + str(oldRecord[FIELD_ID])
	result = requests.put(url, headers=getHeaders(access_token), data=newUserJSON)
	print str(result.status_code) + RESULT_STATUS_DELIM + result.reason
	return result.status_code == RESPONSE_OK

def updateManager(scim_url, access_token, employeeEmail, managerEmail):
	managerUpdate = {csv_header.EMAIL_HEADER: employeeEmail}
	employeeRecord = getResourceFromEmail(scim_url, access_token, employeeEmail)
	managerRecord = getResourceFromEmail(scim_url, access_token, managerEmail)
	if not managerRecord:
		print ERROR_RECORD_NOT_FOUND + managerEmail
		return false
	if not employeeRecord:
		print ERROR_RECORD_NOT_FOUND + employeeEmail
		return false
	managerUpdate[FIELD_MANAGER_ID] = str(managerRecord[FIELD_ID])
	return updateUser(scim_url, access_token, managerUpdate)

def getResourceFromEmail(scim_url, access_token, email):
	url = scim_url +  USERS_RESOURCE_SUFFIX + EMAIL_LOOKUP_SUFFIX + urllib.quote(ESCAPED_EMAIL_LOOKUP_PREFIX + email + ESCAPED_EMAIL_LOOKUP_SUFFIX, safe='')
	result = requests.get(url, headers=getHeaders(access_token))
	resultObj = json.loads(result.text)
	if resultObj[FIELD_RESOURCES] and len(resultObj[FIELD_RESOURCES]) > 0:
		# get first match
		return resultObj[FIELD_RESOURCES][FIRST_ITEM]
	return None

#export users
def getUsers(scim_url, access_token, startIndex, userCollection):
	user_url = scim_url + USERS_RESOURCE_SUFFIX + HTTP_DELIM
	result = requests.get(user_url + START_INDEX + str(startIndex), headers=getHeaders(access_token))
	result_json = json.loads(result.text, result.encoding)
	totalResults = result_json[FIELD_TOTAL_RESULTS]
	itemsPerPage = result_json[FIELD_ITEMS_PER_PAGE]
	print str((startIndex + itemsPerPage) - 1) + EXPORT_RESULT_DELIM + str(totalResults)

	# Check if JSON is valid
	if result.status_code != RESPONSE_OK or FIELD_RESOURCES not in result_json:
		if FIELD_ERROR in result_json and FIELD_MESSAGE in result_json[FIELD_ERROR]:
			print ERROR_WITH_MESSAGE_PREFIX, result_json[FIELD_ERROR][FIELD_MESSAGE]
		else:
			print ERROR_WITHOUT_MESSAGE
		return None
	userCollection = userCollection + result_json[FIELD_RESOURCES]
	if itemsPerPage + startIndex <= totalResults:
		return getUsers(scim_url, access_token, startIndex + itemsPerPage, userCollection)
	return userCollection

def getUserProperty(item, root, child = None):
	if not child:
		if root in item:
			return item[root]
	else:
		if root in item and child in item[root]:
			return item[root][child]
	return EMPTY_RESPONSE

def getUserPropertyList(item, root, itemType, primary, returnType):
	if root in item:
		for items in item[root]:
			if FIELD_TYPE in items and items[FIELD_TYPE] == itemType and FIELD_PRIMARY in items and items[FIELD_PRIMARY] == primary and returnType in items:
				return items[returnType]
	return EMPTY_RESPONSE

def getManager(item, access_token, scim_url):
#Updated upstream
	if SCHEME_NTP in item and FIELD_MANAGER in item[SCHEME_NTP] and FIELD_MANAGER_ID in item[SCHEME_NTP][FIELD_MANAGER]:
		managerId = item[SCHEME_NTP][FIELD_MANAGER][FIELD_MANAGER_ID]
		manager_url  = scim_url + USERS_RESOURCE_SUFFIX + HTTP_DELIM + str(managerId)
		managerResult = requests.get(manager_url, headers=getHeaders(access_token))
		manager_json = json.loads(managerResult.text, managerResult.encoding)
		if FIELD_USER_NAME in item:
			return manager_json[FIELD_USER_NAME]
		else:
			return EMPTY_RESPONSE
	else:
		return EMPTY_RESPONSE

#helper methods
def getName(userObj):
	name = {}
	if userObj.get(csv_header.FIRST_NAME_HEADER, None):
		name[FIELD_GIVEN_NAME] = userObj[csv_header.FIRST_NAME_HEADER]
	if userObj.get(csv_header.LAST_NAME_HEADER, None):
		name[FIELD_FAMILY_NAME] = userObj[csv_header.LAST_NAME_HEADER]
	name[FIELD_FORMATTED] = name[FIELD_GIVEN_NAME] + ' ' + name[FIELD_FAMILY_NAME]
	return name

def mergeUserObjs(oldObj, newObj):
	# make sure to merge schema headers as to not lose any currently in record
	for key, value in newObj.iteritems():
		if isinstance(value, collections.Mapping):
			newValue = mergeUserObjs(oldObj.get(key, {}), value)
			oldObj[key] = newValue
		#preserve old schema values, for other arrays like phone number and
		#addresses replace values with new value
		elif isinstance(value, list) and key is FIELD_SCHEMAS:
			oldObj[key] = oldObj[key] + list(set(newObj[key]) - set(oldObj[key]))
		else:
			oldObj[key] = newObj[key]
	return oldObj

def buildUserJSONObj(userObj):
	data = {}
	schemas = [SCHEME_CORE]
	ent = {}
	keys = userObj.keys()
	if csv_header.EMAIL_HEADER in keys:
		data[FIELD_USER_NAME] = userObj.get(csv_header.EMAIL_HEADER, None)
	if csv_header.EXTERNALID_HEADER in keys:
		data[FIELD_EXTERNALID]  = userObj[csv_header.EXTERNALID_HEADER]
	if csv_header.FIRST_NAME_HEADER in keys or csv_header.LAST_NAME_HEADER in keys:
		data[FIELD_NAME]  = getName(userObj)
	if csv_header.JOB_HEADER in keys:
		data[FIELD_TITLE] = userObj[csv_header.JOB_HEADER]
	if csv_header.PHONE_HEADER in keys:
		data[FIELD_PHONE_NUMBERS] = [{FIELD_VALUE:userObj[csv_header.PHONE_HEADER], FIELD_TYPE:FIELD_WORK, FIELD_PRIMARY: True}]
	if csv_header.STARTDATE_HEADER in keys:
		d = datetime.datetime.strptime(userObj.get(csv_header.STARTDATE_HEADER), '%Y-%m-%d')
		data[SCHEME_TERMDATES] = {FIELD_STARTDATE:time.mktime(d.timetuple()), "termDate":0}
		schemas.append(SCHEME_TERMDATES)
	if csv_header.DEPARTMENT_HEADER in keys:
		ent[FIELD_DEPARTMENT] = userObj.get(csv_header.DEPARTMENT_HEADER, None)
	if csv_header.ORGANIZATION_HEADER in keys:
		ent[FIELD_ORGANIZATION] = userObj.get(csv_header.ORGANIZATION_HEADER, None)
	if csv_header.DIVISION_HEADER in keys:
		ent[FIELD_DIVISION] = userObj.get(csv_header.DIVISION_HEADER, None)
	if csv_header.COSTCENTER_HEADER in keys:
		ent[FIELD_COSTCENTER] = userObj.get(csv_header.COSTCENTER_HEADER, None)
	if csv_header.LOCATION_HEADER in keys:
		data[FIELD_ADDRESSES] = [{FIELD_TYPE:FIELD_WORK, FIELD_FORMATTED:userObj.get(csv_header.LOCATION_HEADER, None), FIELD_PRIMARY:True}]
	if csv_header.LOCALE_HEADER in keys:
		data[FIELD_LOCALE] = userObj.get(csv_header.LOCALE_HEADER, None)
	if csv_header.TIMEZONE_HEADER in keys:
		data[FIELD_TIMEZONE] = userObj.get(csv_header.TIMEZONE_HEADER, None)
	if FIELD_ID in keys:
		data[FIELD_ID] = userObj[FIELD_ID]
	if FIELD_ACTIVE in keys:
		data[FIELD_ACTIVE] = userObj.get(FIELD_ACTIVE, None)
	if FIELD_MANAGER_ID in keys:
		ent[FIELD_MANAGER] = {FIELD_MANAGER_ID:userObj.get(FIELD_MANAGER_ID, None)}
	if len(ent) > 0:		
		data[SCHEME_NTP] = ent
		schemas.append(SCHEME_NTP)


	#add schmeas to obj
	data[FIELD_SCHEMAS] = schemas

	return data
