#!/usr/bin/env python
import sys
try:
	import pyinotify
except:
	print "pyinotify not installed" 
	sys.exit(1)
import EventHandler

DEFAULT_DIR = "/tmp"

def main(watch_dir, logfile):
	directory = ""
	if len(watch_dir) > 0:
		directory = watch_dir
	else:
		directory = DEFAULT_DIR

	wm = pyinotify.WatchManager()
	handler = EventHandler.EventHandler()
	handler.openlog(logfile)

	notifier = pyinotify.Notifier(wm, handler)
	wdd = wm.add_watch(directory, EventHandler.mask, rec=True, auto_add=True)

	notifier.loop()

if __name__ == "__main__":
	if len(sys.argv) < 3:
		print "Usage: ", sys.argv[0], " <path to monitor> <logfile>"
		sys.exit(1)
 	
	main(sys.argv[1], sys.argv[2])
