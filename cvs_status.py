#!/usr/bin/env python
"""Parses the output to the 'cvs status' command."""

import os
from send_email import send_email

#Global Variables
DEBUG = False
CVS_HELPER_CMD= '/home/dpuser/scripts/python/cvs_helper.sh'
ignore_status_flags = ('Up-to-date','Locally Modified')

#cvs_repos is a dictionary of repo path -> (repo name, cvsroot). e.g. {'dpr-testing':('DPR Testing Branch','CVSROOT'),'dpr':'DPR Stable Branch'}
cvs_repos = {
		'/home/dpuser/build/dpr_testing':('DPR Testing Branch','/cvsroot/dpr/dpr/'),
		'/home/dpuser/build/dpr':('DPR Stable Branch','/cvsroot/dpr/dpr/'),
}

#Email settings
email_to = ['matthew.oliver@naa.gov.au','justin.waddell@naa.gov.au', 'ian.little@naa.gov.au','michael.carden@naa.gov.au','christopher.smart@naa.gov.au']
email_subject = '%s Updated'
email_from = 'dpuser@naa.gov.au'
email_attachments = []
email_server = 'localhost'


debug_output = """+-+-+-+-+-+
Filename: %(filename)s
Status: %(status)s

Working Revision: %(wrevision)s  Repo Revision: %(rrevision)s
Repo Filename: %(rfilename)s

Sticky Tag: %(stag)s 
Sticky Date: %(sdate)s
Sticky Options: %(soptions)s
"""

list_output = """=============================
Filename: %(filename)s		Status: %(status)s 
Revision: %(rrevision)s		Date: %(rdate)s		Author: %(rauth)s
Comments: 
"""

#Constants
FILENAME = "filename"
STATUS = "status"
WORKING_REV = "wrevision"
REPO_REV = "rrevision"
REPO_FILENAME = "rfilename"
STICKY_TAG = "stag"
STICKY_DATE = "sdate"
STICKY_OPTIONS = "soptions"
REV_DATE = "rdate"
REV_AUTHOR = "rauth"
REV_COMMENTS = "rcomments"

def parse_status(output):
	inItem = False
	changed_items = []
	item = {}
	line = output.readline()
	while line != "":
		line = line.strip()
		if line.startswith("File:"):
			if len(item.keys()) > 0:
				changed_items.append(item)
				item = {}
			
			#Split the line and grab the status
			tmpStr = line.split(':')
			status = tmpStr[-1].strip()
			filename = tmpStr[1].replace("Status","").strip()
			if status in ignore_status_flags:
				inItem = False
			else:
				inItem = True
				item[FILENAME] = filename
				item[STATUS] = status
		
		if line.startswith("Working revision:") and inItem:
			item[WORKING_REV] = str(line.split()[-1])

		if line.startswith("Repository revision:") and inItem:
			tmpStr = line.split()
			item[REPO_REV] = str(tmpStr[-2])
			item[REPO_FILENAME] = str(tmpStr[-1])

		if line.startswith("Sticky Tag:") and inItem:
			item[STICKY_TAG] = str(line.split(':')[-1]).strip()

		if line.startswith("Sticky Date:") and inItem:
			item[STICKY_DATE] = str(line.split()[-1])

		if line.startswith("Sticky Options:") and inItem:
			item[STICKY_OPTIONS] = str(line.split()[-1])

		# Read the next line
		line = output.readline()

	if len(item.keys()) > 0:
		changed_items.append(item)
	
	output.close()

	if DEBUG:
		print "Number Items:", len(changed_items)
		for item in changed_items:
			print debug_output % item
	return changed_items

def add_revision_comments(results, repo):
	for item in results:
		#generate the filename in the format required
		filename = item[REPO_FILENAME]
		filename = filename.replace(cvs_repos[repo][-1],"")
		filename = filename.split(',')[0]

		#Call the CVS batch script to get the log information for the file.
		output = get_cvs_log(repo, filename, item[REPO_REV])
		
		output_lines = output.readlines()
		output.close()
		
		if output_lines[-1].startswith("====="):
			output_lines = output_lines[:-1]
		
		#Grab the Date, Author, and comment.
		i = 0
		found = False
		while i < len(output_lines) and not found:
			if output_lines[i].startswith("revision %s" % (item[REPO_REV])):
				found = True
			i+=1
		
		if not found:
			#could not find the revision info... 
			
			#Add some place holders for the dictionary variables then
			item[REV_DATE] = "N/A"
			item[REV_AUTHOR] = "N/A"
			item[REV_COMMENTS] = ["N/A"]
			
		else:
			output_lines = output_lines[i:]
			for line in output_lines:
				if line.startswith("date:"):
					tmpList = line.split(';')
					for token in tmpList:
						token = token.strip()
						if token.startswith("date:"): 
							tmp = token.split()[1:]
							item[REV_DATE] = " ".join(tmp).strip()
						elif token.startswith("author"):
							item[REV_AUTHOR] = token.split(':')[-1].strip()
				else:
					#Assume a part of the comment
					if item.has_key(REV_COMMENTS):
						item[REV_COMMENTS].append(line.strip())
					else:
						item[REV_COMMENTS] = [line.strip()]
	return results
		
def generate_report(results, repo):
	msg = "The following has been changed in the %s repository:\n" % (repo)
	for item in results:
		if DEBUG:
			print item
		item_msg = list_output % item
		for line in item[REV_COMMENTS]:
			if not line.startswith("==========="):
				item_msg += "\t%s\n" % (line)
		msg += item_msg
	
	if DEBUG:
		print "MESSAGE:",msg
	#Send the email
	send_email(email_from, email_to, email_subject % (cvs_repos[repo][0]), msg, email_attachments, email_server)

def get_cvs_status(repo):
	output = os.popen("%s %s %s" % (CVS_HELPER_CMD, "status", repo))
	return output

def get_cvs_log(repo, filename, revision):
	output = os.popen("%s %s %s %s %s" % (CVS_HELPER_CMD, "revision", repo, filename, revision))
	return output

def main():
	for repo in cvs_repos.keys():
		if DEBUG:
			print repo

		results = parse_status(get_cvs_status(repo))
		if len(results) > 0:
			results = add_revision_comments(results,repo)
			generate_report(results, repo)


if __name__ == "__main__":
	main()
