#!/usr/bin/env python

# Copyright 2009 "Matthew Oliver" <matt@oliver.net.au>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# NOTE: This script uses the mk-table-checksum command from maatkit to check the checksums.
#  There are ubuntu/debian and fedora packages: 
#	debian/ubuntu: apt-get install maatkit
#	fedora: yum install maatkit

import os
import sys
from send_email import send_email

#Global variables
DATABASES = ( "qf", "pf", "dr" )
DATABASE_SERVERS = (
		{'host':'server1','username':'root', 'password':'master', 'port':'3306'},
		{'host':'server2','username':'root', 'password':'master', 'port':'3306'},
	)
MK_TABLE_CHECKSUM_CMD="mk-table-checksum %s --databases %s --checksum"
SERVERS_STR = "h=%(host)s,u=%(username)s,p=%(password)s,P=%(port)s"

#Email settings
#email_to = ['matthew.oliver@naa.gov.au','justin.waddell@naa.gov.au', 'ian.little@naa.gov.au','michael.carden@naa.gov.au','christopher.smart@naa.gov.au']
email_to = ['matthew.oliver@naa.gov.au']
email_subject = 'MySQL Checksum Report - Checksum %s'
email_from = 'dpuser@naa.gov.au'
email_attachments = []
email_server = 'localhost'
email_msg_success = "Database checksum completed successfully on the following hosts:"
email_msg_failure = "Database checksum FAILED! \nOutput:"

#DEBUG = True
DEBUG = False

table_ok = "%s... OK"
table_error = "%s... ERROR:"

errors = []

def parse_tables(tables):
	for table in tables.keys():
		checksums = tables[table]

		# Initalise
		checksum = checksums[0][0]
		not_match = False
		
		# Check the checksums
		for item in checksums:
			if item[0] != checksum:
				not_match = True
				break
		
		if not_match:
			msg_str = table_error % (table)
			print msg_str
			errors.append(msg_str)
			for x in checksums:
				msg_str = "  %s  %s" % (x[0], x[1])
				print msg_str
				errors.append(msg_str)
		else:
			print table_ok % (table)

def run_table_checksum():
	databases = ",".join(DATABASES)
	db_servers = [ SERVERS_STR % (d) for d in DATABASE_SERVERS ]
	
	#Get a list of hosts, this is to help processing the output.
	db_hosts = [ "%(host)s" % (d) for d in DATABASE_SERVERS  ]

	if DEBUG:
		print "DATABASES:", databases
		print "DB_SERVERS:" 
		for x in db_servers:
			print x
	
	try:
		output = os.popen(MK_TABLE_CHECKSUM_CMD % (" ".join(db_servers), databases))
	except:
		print "ERROR: Could not run command '%s', Make sure you have the maatkit package installed or which the database settings" %(MK_TABLE_CHECKSUM_CMD % (" ".join(db_servers), databases))
		sys.exit(1)

	# Parse the output and turn it into a structure we can test, which will support any number of database hosts.
	#   {'tablename without host':[(checksum, full tablename)]}
	tables = {}
	line = output.readline()
	while line != "":
		if DEBUG:
			print "LINE:", line
		
		tmp = line.split()
		checksum = tmp[0]
		table = tmp[1]
		
		index = table.find(".")
		table_hash = table[index +1:]
		
		if tables.has_key(table_hash):
			tables[table_hash].append((checksum, table))
		else:
			tables[table_hash] = [(checksum, table)]
		
		line = output.readline()
	
	if DEBUG:
		print "TABLES:", tables
	
	# Now parse the tables dictionary and actually do the check.
	parse_tables(tables)

def generate_report():
	msg = ""
	result = ""
	if len(errors) == 0:
		# Success
		msg += "%s\n" % (email_msg_success)
		for host in DATABASE_SERVERS:
			msg += "\t%s\n" % (host["host"])
		result = "PASSED"
	else:
		# Failure
		msg += "%s\n" % (email_msg_failure)
		for line in errors:
			msg += "  %s\n" % (str(line))
		result = "FAILED"
	
	if DEBUG:
		print "EMAIL_MSG: ", msg 	

	# Send the email
	send_email(email_from, email_to, email_subject % (result), msg, email_attachments, email_server) 

def main():
	run_table_checksum()
	generate_report()

if __name__ == "__main__":
	main()
