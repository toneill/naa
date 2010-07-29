#!/usr/bin/env python
"""processUnitTests.py

This script reads lines from stdin and looks for JUnit failed tests.
Once a 'BUILD FAILED' or 'BUILD SUCCESSFUL' is recieved processing
stdin stops and if there were any failed tests, and email report is
send.

Usage: %s [<Base Results Directory>]

	<Base Results Directory> is the location the unit rest results
		are saved to. (dpr/dist/results usually) 
"""
import os
import sys
from send_email import send_email

failMap = {}
DEBUG = True
#DEBUG = False
results_base = "/home/dpuser/build/dpr/dist/results/"
BUILD_SUCCESSFUL = "BUILD SUCCESSFUL"
BUILD_FAILED = "BUILD FAILED"

subject_heading = "Title"

#EMAIL SETTINGS
email_from = "dpuser@naa.gov.au"
email_to = ["matthew.oliver@naa.gov.au" ,"michael.carden@naa.gov.au", "justin.waddell@naa.gov.au"]
email_subject = "DPR unit test failure report"
email_server = "localhost"

def process_attachments(attachments):
	for attachment in attachments:
		lines = file(attachment).readlines()
		outfile = file(attachment, "w")
		for line in lines:
			outfile.write(line.replace("\n","\r\n"))
		outfile.close()

def generateReport():
	if DEBUG:
		print "Number of failures:", len(failMap)
	
	#Generate the email
	email_attachments = []
	email_msg = "The following tests failed:\n"
	
	keys = failMap.keys()
	keys.sort()
	for x in keys:
		email_msg += "\t%s" % (x)
		email_attachments.append("%s/%s" % (results_base, failMap[x]))
	
	email_msg += "\nNOTE: Full details of each failed unit test attached."

	#Because the attachments are going to be viewed in LookOut on a winblows machine
	#we need to change the line endings.
	process_attachments(email_attachments)

	#send the email
	send_email(email_from, email_to, subject_heading + " - " + email_subject, email_msg, email_attachments, email_server)

def processLine(failLine):
	if DEBUG:
		print failLine
	if failLine.find("FAILED") > -1  and failLine.find("[junit]") > -1:
		#found a failure so add it and the path to the test log to the map.
	        filename = "TEST-%s.txt" % (failLine.split()[-2])
		if DEBUG:
			print "Filename =", filename
		failMap[failLine] = filename

def main():
	global subject_heading
	if len(sys.argv) > 1:
		results_base = str(sys.argv[1])
		subject_heading = str(sys.argv[2])
	if DEBUG:
		print 'Results Base:', results_base
		print 'Title:', subject_heading

	#Read a line from stdin and process it.
	failLine = sys.stdin.readline()
	while len(failLine) != 0:
		if failLine.startswith(BUILD_FAILED) or failLine.startswith(BUILD_SUCCESSFUL):
			break 
		processLine(failLine)
		failLine = sys.stdin.readline()
	
	if len(failMap) > 0:
		generateReport()



if __name__ == "__main__":
	main()
