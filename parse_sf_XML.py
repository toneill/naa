# This script only works for the SouceForge Project Data Backups (XML Data Export 1.0).
# 	URL: https://sourceforge.net/export/xml_export.php?group_id=116934
from xml.dom.minidom import parse
import time

#This should be changed to a passed in param.
dom = parse("dpr_xml2.xml")

buglist = []
featlist = []

bugfile = "/tmp/xml_bug_results"
featurefile = "/tmp/xml_feature_results"

DEBUG = False

message_str = """
MESSAGE
Name: %(name)s
Date (GMT): %(date)s
Body: 
%(body)s
"""

artifact_str = """
== ARTIFACT ==
ID: %(id)s
Date (GMT): %(date)s
Submitted by: %(by)s
Assigned to: %(to)s
Status: %(status)s
Resolution: %(resolution)s
Summary: %(summary)s
Details: 
%(details)s
"""

def epochToDateString(epoch):
	return "%d/%.2d/%.2d %d:%d:%d" % time.gmtime(float(epoch))[:6]

for node in dom.getElementsByTagName('artifact'):
	isBug = False
	isFeature = False
	isClosed = False
	data = {}
	messages = []
	id = ""
	status = ""
	resolution = ""
	summary = ""
	details = ""
	sub_by = ""
	ass_to = ""
	open_date = ""
	messages = []
	art_fields = node.getElementsByTagName('field')
	for field in art_fields:
		if field.getAttribute("name") == 'status' and field.childNodes[0].data == "Closed":
			isClosed = True
		if field.getAttribute("name") == 'artifact_type' and field.childNodes[0].data == "Bugs":
			isBug = True
		if field.getAttribute("name") == 'artifact_type' and field.childNodes[0].data == "Feature Requests":
			isFeature = True
		if field.getAttribute("name") == 'status':
			status = field.childNodes[0].data
		if field.getAttribute("name") == 'artifact_id':
			id = field.childNodes[0].data
		if field.getAttribute("name") == 'resolution':
                        resolution = field.childNodes[0].data
		if field.getAttribute("name") == 'summary':
                        summary = field.childNodes[0].data
		if field.getAttribute("name") == 'details':
                        details = field.childNodes[0].data
		if field.getAttribute("name") == 'submitted_by':
                        sub_by = field.childNodes[0].data
		if field.getAttribute("name") == 'assigned_to':
                        ass_to = field.childNodes[0].data
		if field.getAttribute("name") == 'open_date':
                        open_date = field.childNodes[0].data
		

	data = {'id':id, 'status': status, 'resolution':resolution, 'summary':summary, 'details':details, 'by':sub_by, 'to':ass_to, 'date':epochToDateString(open_date)}

	#Get messages
	art_messages = node.getElementsByTagName('message')
        for mess in art_messages:
		username = ""
		body = ""
		add_date = ""
		message = {}
		message_fields = mess.getElementsByTagName('field')
		for field in message_fields:
			if field.getAttribute("name") == 'user_name':
	                        username = field.childNodes[0].data 
			if field.getAttribute("name") == 'body':
	                        body = field.childNodes[0].data
			if field.getAttribute("name") == 'adddate':
	                        add_date = field.childNodes[0].data
		
		newmessage = {'name': username, 'body':body,'date':epochToDateString(add_date)}	
		messages.append(newmessage)	
		
	data["messages"] = messages	

	if isClosed == False and isBug:
		buglist.append(data)
	elif isClosed == False and isFeature:
		featlist.append(data)

if DEBUG:
	print "No. Bugs:", len(buglist)
	print "No. Features:", len(featlist)

append = False
if featurefile == bugfile:
	append = True

outfile = file(bugfile,'w')
outfile.write("==== BUG LIST ====\n\n")
if DEBUG:
	print "==== BUG LIST ===="
for item in buglist:
	outfile.write(artifact_str % item)
	
	#write messages
	if item.has_key("messages"):
		messages = item["messages"]
		for message in messages:
			outfile.write(message_str % message)
	if DEBUG:
		print item

if append:
	outfile.write("\n\n==== FEATURE LIST ====\n\n")
else:
	outfile.close()
	outfile = file(featurefile,'w')
	outfile.write("==== FEATURE LIST ====\n\n")

if DEBUG:
	print "==== FEATURE LIST ===="

for item in featlist:
	outfile.write(artifact_str % item)
	
	#write messages
	if item.has_key("messages"):
		messages = item["messages"]
		for message in messages:
			outfile.write(message_str % message)
	if DEBUG:
		print item

outfile.close()
