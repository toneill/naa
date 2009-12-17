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

# This script uses the mk-table-checksum script from maatkit to check the checksums 

import os

#Global variables
DATABASES = ( "qf", "pf", "dr" )
DATABASE_SERVERS = (
		{'host':'server1','username':'root', 'password':'master', 'port':'3306'},
		{'host':'server2','username':'root', 'password':'master', 'port':'3306'},
	)
MK_TABLE_CHECKSUM_CMD="mk-table-checksum %s --databases %s --checksum"
SERVERS_STR = "h=%(host)s,u=%(username)s,p=%(password)s,P=%(port)s"

EMAIL_TO = ("matthew.oliver@naa.gov.au")
EMAIL_SUBJECT = "%s"

#DEBUG = True
DEBUG = False

table_ok = "%s... OK"
table_error = "%s... ERROR:"

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
			print table_error % (table)
			for x in checksums:
				print "  ", x[0], "  ", x[1]
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
	
	output = os.popen(MK_TABLE_CHECKSUM_CMD % (" ".join(db_servers), databases))

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


def main():
	run_table_checksum()

if __name__ == "__main__":
	main()
