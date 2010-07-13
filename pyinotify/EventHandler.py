import pyinotify
import datetime

mask = pyinotify.IN_DELETE | pyinotify.IN_CREATE | pyinotify.IN_ACCESS | pyinotify.IN_MODIFY | pyinotify.IN_MOVED_FROM | pyinotify.IN_MOVED_TO 

class EventHandler(pyinotify.ProcessEvent):
	log = ""
	flog = None
	def process_IN_CREATE(self, event):
		self.write_msg("CREATING", event.pathname) 

	def process_IN_DELETE(self, event):
		self.write_msg("REMOVING", event.pathname) 

	def process_IN_ACCESS(self, event):
		self.write_msg("ACCESSED", event.pathname) 

	def process_IN_MODIFY(self, event):
		self.write_msg("MODIFIED", event.pathname) 

	def process_IN_MOVED_FROM(self, event):
		self.write_msg("FILE MOVED FROM", event.pathname) 

	def process_IN_MOVED_TO(self, event):
		self.write_msg("FILE MOVED INTO", event.pathname) 
	
	def openlog(self, logfile):
		self.log = logfile
		self.flog = file(self.log, 'a')

	def write_msg(self, event, msg):
		out_msg = self.generate_timestamp() + "\t" + event + ": " + msg + "\n"
		if len(self.log) > 0:
			self.flog.write(out_msg)
			self.flog.flush()
			print "LOGGED", out_msg
		else:
			print "NOT LOGGED", out_msg

	def generate_timestamp(self):
	        d = datetime.datetime.now()
        	datestr = "%d/%.2d/%.2d-%.2d:%.2d:%.2d" % (d.year, d.month, d.day, d.hour, d.minute, d.second)
	        return datestr

