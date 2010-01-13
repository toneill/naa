#!/usr/bin/env python

import sys
import os
import datetime
from send_email import send_email

# Global Variables
PROXY = "10.0.1.45"
NETWORK = "10.0.0.0/22"

IPTABLES_CUSTOM_CHAIN = "DOWNLOADED"
IPTABLES_CREATE_CHAIN = "iptables -N " + IPTABLES_CUSTOM_CHAIN
IPTABLES_DELETE_CHAIN = "iptables -X " + IPTABLES_CUSTOM_CHAIN 
IPTABLES_PROXY_RULE = "INPUT %s -s " + PROXY + " -j " + IPTABLES_CUSTOM_CHAIN
IPTABLES_NOT_NETWORK_RULE = "INPUT %s ! -s " + NETWORK + " -j " + IPTABLES_CUSTOM_CHAIN

IPTABLES_REPORT_CMD = "iptables -L -n -x -v --line-numbers"

# Result column indexes
TIMESTAMP_IDX = 0
PROXY_IDX = 1
NOT_NETWORK_IDX = 2

# Format of the folling files: date	proxy bytes	non-network bytes
# NOTE: Seperated by tabs (\t)
LAST_RESULT = "netmon.last"
RESULT_LOG = "netmon.log"

# Email reporting variables
EMAIL_TO = ['matthew.oliver@naa.gov.au']
EMAIL_FROM = 'dpuser@naa.gov.au'
EMAIL_SUBJECT = 'Network Usage Report - %s'
EMAIL_ATTACHMENTS = []
EMAIL_SERVER = 'localhost'
EMAIL_MSG = """Network usage between: %s and %s
Proxy Traffic:
  Usage: %s
  Current Total: %s

Non Network Traffic:
  Usage: %s
  Current Total: %s
"""


def human_readable(bytes):
	if bytes < 1024:
		return str(bytes)
	for x in 'K', 'M','G':
		bytes /= 1024
		if bytes < 1024:
			return "%d%s" % (bytes, x)
	if bytes > 1024:
		return "%d%s" % (bytes, 'G')

def make_human_readable(results):
	return (results[0], human_readable(results[1]), human_readable(results[2]))

def get_totals():
	timestamp = generate_timestamp()
	result = os.popen(IPTABLES_REPORT_CMD)
	proxy_bytes = 0 
	network_bytes = 0
	
	# Parse the output. 
	# 1. Find "Chain INPUT" that way we know we have the right chain.
	# 2. Look for 1 and 2 in the first column, as they are our rules.
	# 3. Find out which one is the proxy one.
	# 4. return totals.
	start = False
	for line in result:
		if line.startswith("Chain INPUT"):
			start = True
		elif line.startswith("Chain"):
			start = False
		elif start:
			cols = line.split()
			if len(cols) != 0:
				if cols[0] == '1' or cols[0] == '2':
					# Found our rules
					if cols[8] == PROXY:
						proxy_bytes = int(cols[2])
					else:
						network_bytes = int(cols[2])
	
	return (timestamp, proxy_bytes, network_bytes)
	

def generate_timestamp():
	d = datetime.datetime.now()
	datestr = "%d/%.2d/%.2d-%.2d:%.2d:%.2d" % (d.year, d.month, d.day, d.hour, d.minute, d.second)
	return datestr

def get_last():
	if os.path.exists(LAST_RESULT):
		lstFile = file(LAST_RESULT).readlines()
		result = lstFile[0].strip().split()
		result[1] = int(result[1])
		result[2] = int(result[2])
		return tuple(result)
	else:
		return (generate_timestamp(), 0, 0)

def _cleanup_iptables():
	os.system("iptables -D %s" % (IPTABLES_PROXY_RULE % ("")))
	os.system("iptables -D %s" % (IPTABLES_NOT_NETWORK_RULE % ("")))
	os.system(IPTABLES_DELETE_CHAIN)

def start():
	# Incase the rules alread exist lets remove them
	_cleanup_iptables()
	
	# Now we can add them
	os.system(IPTABLES_CREATE_CHAIN)
	os.system("iptables -I %s" % (IPTABLES_PROXY_RULE % ("1")))
	os.system("iptables -I %s" % (IPTABLES_NOT_NETWORK_RULE % ("1")))

def stop():
	# Delete the rules 
	_cleanup_iptables()

def report():
	last = get_last()
	
	# Now we need to get the byte totals from iptables.
	new_totals = get_totals()
	
	proxy_usage = 0
	not_network_usage = 0
	if last[PROXY_IDX] > new_totals[PROXY_IDX]:
		# Counters must have been reset.
		proxy_usage = new_totals[PROXT_IDX]
		not_network_usage = new_totals[NOT_NETWORK_IDX]
	else:
		# Do the calc
		proxy_usage = new_totals[PROXY_IDX] - last[PROXY_IDX]
		not_network_usage = new_totals[NOT_NETWORK_IDX] - last[NOT_NETWORK_IDX]
	
	result = (new_totals[TIMESTAMP_IDX],proxy_usage, not_network_usage)
	result_str = "Timestamp: %s Proxied: %s Off Network: %s"

	# Write out the new last totals to the log and last.
	last_file = file(LAST_RESULT, 'w')
	last_file.write("%s\t%d\t%d\n" % new_totals)
	last_file.close()

	log = file(RESULT_LOG, 'a')
	log.write("%s\t%d\t%d\n" % new_totals)
	log.close()

	last = make_human_readable(last)
	new_totals = make_human_readable(new_totals)
	result = make_human_readable(result)


	print "Last Total - " + result_str % last
	print "New Total - " + result_str % new_totals
	print "New Usage - " + result_str % result

	# Send the email report
	msg = EMAIL_MSG % (last[TIMESTAMP_IDX],result[TIMESTAMP_IDX], result[PROXY_IDX], new_totals[PROXY_IDX], result[NOT_NETWORK_IDX], new_totals[NOT_NETWORK_IDX])
	send_email(EMAIL_FROM, EMAIL_TO, EMAIL_SUBJECT % (result[TIMESTAMP_IDX]), msg, EMAIL_ATTACHMENTS, EMAIL_SERVER)
	

def main(args):
	if len(args) == 0:
		# Run report
		report()
	elif str(args[0]).upper() == "CLEAR":
		stop()
	elif str(args[0]).upper() == "FLUSH":
		stop()
	elif str(args[0]).upper() == "STOP":
		stop()
	elif str(args[0]).upper() == "INITIATE":
		start()
	elif str(args[0]).upper() == "START":
		start()
	elif str(args[0]).upper() == "INITIALISE":
		start()
	elif str(args[0]).upper() == "REPORT":
		report()

if __name__ == "__main__":
	main(sys.argv[1:])
