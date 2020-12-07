# code to print out IOS and Android Workplace App download QR Codes and print out deeplinked QR Codes for Access Codes
import pyqrcode
IOS = 0
accessFile = "workplace_access_codes.csv"
WorkplaceIOSURL = "https://apps.apple.com/us/app/workplace-by-facebook/id944921229"
wpiosurl = pyqrcode.create(WorkplaceIOSURL)
wpiosurl.svg('WorkplaceIOS.svg', scale=4)
WorkChatIOSURL = "https://apps.apple.com/us/app/workplace-chat-by-facebook/id958124798"
wciosurl = pyqrcode.create(WorkChatIOSURL)
wciosurl.svg('WorkChatIOS.svg', scale=4)
WorkplaceAndroidURL = "https://play.google.com/store/apps/details?id=com.facebook.work"
wpandurl = pyqrcode.create(WorkplaceAndroidURL)
wpandurl.svg('WorkplaceAndroid.svg', scale=4)
WorkChatAndroidURL = "https://play.google.com/store/apps/details?id=com.facebook.workchat"
wcandurl = pyqrcode.create(WorkChatAndroidURL)
wcandurl.svg('WorkChatAndroid.svg', scale=4)

#Get the list of userNames
with open(accessFile, "r") as f:
  first = f.readline()
  first = first.rstrip("\r\n")
  fields = first.split(',')
  users = []
  for line in f:
    line = line.rstrip("\r\n")
    values = line.split(',')
    user = {}
    for i in range(len(fields)):
      user[fields[i]] = values[i]
    if user['Access Code'] != "":
      URL = "fb-work-emailless://accesscode?access_code=%s" % user['Access Code']
      accessURL = pyqrcode.create(URL)
      fname = "%sAccessCode.svg" % user['Username']
      accessURL.svg(fname, scale=4)
