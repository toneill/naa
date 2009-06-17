#!/usr/bin/env python

import os
import sys
from subprocess import Popen
from time import sleep

#Memory stats constants
PROGRAM_SIZE = 0
MEMORY_SIZE = 1
SHARED_PAGES = 2
CODE_PAGES = 3
DATA_STACK_PAGES = 4
LIBRARY_PAGES = 5
DIRTY_PAGES = 6

#Reported Stats
report = {PROGRAM_SIZE: ("Program","K"), MEMORY_SIZE: ("Memory","K")}

#Time interval
INTERVAL = 0.01

def get_column_stats(mem_stats, index):
	"""Returns (avg_size, max_size)
	"""
	sum = 0.0
	max = 0.0
	for row in mem_stats:
		sum += float(row[index])
		if max < float(row[index]):
			max = float(row[index])
	
	if len(mem_stats) > 0:
		return (sum / len(mem_stats), max)
	else:
		return (sum, max)
	

def grab_mem(filename):
	return file(filename,"r").readlines()[0]

def poll_mem(pid, mem_stats, proc):
	mem_file_loc = "/proc/%d/statm" % (pid)
	while os.path.isfile(mem_file_loc):
		mem_stats.append(grab_mem(mem_file_loc).strip().split())
		proc.poll()
		sleep(INTERVAL)
	return mem_stats

def main(args):
	proc = Popen(args)
	pid = proc.pid
	mem_stats = []
	mem_stats = poll_mem(pid, mem_stats,proc)

	#Print to memory results
	for index in report.keys():
		res = get_column_stats(mem_stats, index)
		print "%s Avg: %d %s" % (report[index][0], res[0], report[index][1])
		print "%s Max: %d %s" % (report[index][0], res[1], report[index][1])
	out = file('/tmp/out','w')
	for item in mem_stats:
		out.write("\t".join(item) + "\n")
 	out.close()
if __name__ == "__main__":
	main(sys.argv[1:])
