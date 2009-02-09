/**
 * This file is part of DPR.
 * 
 * DPR is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 2 of the License, or (at your option) any later version.
 * 
 * DPR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with DPR; if not, write to the Free Software Foundation, Inc., 59 Temple
 * Place, Suite 330, Boston, MA 02111-1307 USA
 * 
 * 
 * @author Andrew Keeling
 * @author Dan Spasojevic
 * @author Justin Waddell
 */

/*
 * Created on 8/09/2006 andrek24
 */
package au.gov.naa.digipres.dpr.core.importexport;

import java.io.File;
import java.io.IOException;
import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Set;
import java.util.logging.Logger;

import au.gov.naa.digipres.dpr.core.Constants;
import au.gov.naa.digipres.dpr.core.DPRClient;
import au.gov.naa.digipres.dpr.dao.ReprocessingJobDAO;
import au.gov.naa.digipres.dpr.dao.UserDAO;
import au.gov.naa.digipres.dpr.model.facility.Facility;
import au.gov.naa.digipres.dpr.model.job.JobStatus;
import au.gov.naa.digipres.dpr.model.reprocessingjob.DRReprocessingJobProcessingRecord;
import au.gov.naa.digipres.dpr.model.reprocessingjob.PFReprocessingJobProcessingRecord;
import au.gov.naa.digipres.dpr.model.reprocessingjob.ReprocessingDataObject;
import au.gov.naa.digipres.dpr.model.reprocessingjob.ReprocessingJob;
import au.gov.naa.digipres.dpr.model.reprocessingjob.ReprocessingJobAIP;
import au.gov.naa.digipres.dpr.model.user.User;
import au.gov.naa.digipres.dpr.task.Task;
import au.gov.naa.digipres.dpr.util.carrier.VolumeNameFinder;

import com.db4o.Db4o;
import com.db4o.ObjectContainer;
import com.db4o.ObjectSet;

/**
 * Take a db40 file, and get the reprocessing job out and stick it on the current facility. Deal with large numbers of data objects, the merging of
 * reprocessing jobs, you name it.
 * 
 * FIXME This really needs to implement a listener - these operations may take substantial time and a calling application may want some way of knowing
 * what is going on.
 * 
 * FIXME Logging really needs to be fixed up also.
 */
public class ReprocessingJobImporter {

	DecimalFormat memFormatter = new DecimalFormat("###,###,###");

	private Logger logger = Logger.getLogger(this.getClass().getName());

	private List<ImportExportListener> listenerList = new ArrayList<ImportExportListener>();

	private DPRClient dprClient;
	private Task task;
	private ReprocessingJobDAO reprocessingJobDAO;
	private User currentUser;

	private Facility facility;

	private File reprocessingJobFile;
	private String inputCarrierLocation;
	private String inputCarrierID;

	public ReprocessingJobImporter(File reprocessingJobFile, User user, Task task) {

		dprClient = task.getDPRClient();
		this.task = task;
		reprocessingJobDAO = dprClient.getDataAccessManager().getReprocessingJobDAO(task);
		this.reprocessingJobFile = reprocessingJobFile;
		currentUser = user;
		facility = dprClient.getCurrentFacility();

		inputCarrierLocation = reprocessingJobFile.getParent();
		inputCarrierID = VolumeNameFinder.getVolumeName(inputCarrierLocation);

	}

	/**
	 * <p>Perform the import. This will use the supplied {@link ReprocessingJobDAO} to save the 
	 * imported {@link ReprocessingJob} into the persistence layer. This method will control the
	 * transactions.</p>
	 * <p>An Import exception may be thrown in the following cases:
	 * <ul>
	 * <li>Attempt to import on the quarantine facility</li>
	 * <li>Failure to load or during reading of the db4o file</li>
	 * </ul>
	 * </p>
	 * 
	 * @return An instance of the {@link ReprocessingJob} retrieved from the persistence layer
	 * after the import has finished.
	 * @throws ImportException If there is an error during import.
	 */
	public ReprocessingJob doImport() throws ImportException {

		if (facility.equals(Facility.QUARANTINE_FACILITY)) {
			fireShowError("Import Failed", "Can not import into this facility!");
			throw new ImportException("Can not import into this facility!");
		}

		showMem("Entered do import.");

		fireImportStarted();

		ReprocessingJob reprocessingJob = null;
		ObjectContainer db = null;

		// Get our 'transfer job' object - it will have no data objects associated with it.
		try {
			logger.finest("Start: " + new Date());
			// DB4O version

			// Ensure that we load the entire transfer job by setting cascadeOnActivate and by setting a ridiculously large activationDepth
			Db4o.configure().objectClass(ReprocessingJob.class).cascadeOnActivate(true);
			Db4o.configure().activationDepth(300);

			db = Db4o.openFile(reprocessingJobFile.getAbsolutePath());
			showMem("Opened db4o file.");
			ObjectSet reprocessingJobSet = db.query(ReprocessingJob.class);
			showMem("Have our reprocessing job.");

			if (reprocessingJobSet.hasNext()) {
				reprocessingJob = (ReprocessingJob) reprocessingJobSet.next();
			}
			if (reprocessingJob == null) {
				throw new IOException("Could not get reprocessing job.");
			}
			logger.finest("End: " + new Date());
		} catch (Exception e) {
			fireShowException("Import Failed", "An exception occurred when loading from the db4o database file", e);
			throw new ImportException(e);
		}

		// Handle the synchronisation of users -- only import new users, ignore existing ones!
		showMem("Doing user stuff.");
		dprClient.getDataAccessManager().beginTransaction();
		//  Existing users will be filtered out here...
		UserDAO userDAO = dprClient.getDataAccessManager().getUserDAO(task);
		userDAO.synchroniseUsers(reprocessingJob.getUserListForReprocessingJob());
		dprClient.getDataAccessManager().commitTransaction();
		showMem("User stuff complete.");

		// Now save the transfer job.
		dprClient.getDataAccessManager().beginTransaction();
		if (reprocessingJobDAO.getReprocessingJobByJobNumber(reprocessingJob.getJobNumber()) == null) {
			importNewReprocessingJob(reprocessingJob, db);
		} else {
			// Check that we can actually do this...
			if (reprocessingJob.getJobStatus().equals(JobStatus.REPROCESSING_MARKED_COMPLETED)) {
				importExistingReprocessingJob(reprocessingJob, db);
			} else {
				fireShowError("Error importing transfer job",
				              "You cannot import a transfer job that already exists on this\nfacility unless it has been marked as sent for reprocessing.\n"
				                      + "Job Number: " + reprocessingJob.getJobNumber() + " Facility: " + facility.getDescription() + " Job Status: "
				                      + reprocessingJob.getJobStatus());
			}
		}
		dprClient.getDataAccessManager().commitTransaction();

		db.close();

		// Import has finished
		fireImportFinished();
		showMem("leaving do import.");

		// Get a fresh handle on the transfer job.
		return reprocessingJobDAO.getReprocessingJobByJobNumber(reprocessingJob.getJobNumber());
	}

	private void importExistingReprocessingJob(ReprocessingJob incomingReprocessingJob, ObjectContainer db) {
		if (dprClient.getCurrentFacility().equals(Facility.QUARANTINE_FACILITY)
		    || dprClient.getCurrentFacility().equals(Facility.PRESERVATION_FACILITY)) {
			throw new UnsupportedOperationException("Cannot import an existing reprocessing job into this facility.");
		}

		// So if we are an existing transfer job into DR, add any newly imported PF records
		// and the new PF record.
		ReprocessingJob existingReprocessingJob = reprocessingJobDAO.getReprocessingJobByJobNumber(incomingReprocessingJob.getJobNumber());

		if (dprClient.getCurrentFacility().equals(Facility.DIGITAL_REPOSITORY)) {
			DRReprocessingJobProcessingRecord drReprocessingJobRecord = existingReprocessingJob.addNewDRProcessingRecord();
			drReprocessingJobRecord.setImportRecord(existingReprocessingJob.getMostRecentPFRecord());
			drReprocessingJobRecord.setImportedBy(currentUser);
			drReprocessingJobRecord.setDateImported(new Date());
			drReprocessingJobRecord.setInputCarrierLocation(inputCarrierLocation);
			drReprocessingJobRecord.setInputCarrierId(inputCarrierID);
			existingReprocessingJob.setJobStatus(JobStatus.IMPORTED_INTO_DR);
			reprocessingJobDAO.saveReprocessingJob(existingReprocessingJob);
			Iterator<Object> aipIterator = reprocessingJobDAO.getAIPsForReprocessingJob(existingReprocessingJob);
			while (aipIterator.hasNext()) {
				ReprocessingJobAIP aip = (ReprocessingJobAIP) aipIterator.next();
				if (Boolean.TRUE.equals(aip.getDeleted())) {
					logger.finest("Skipping deleted AIP from previous processing attempt : " + aip.getXenaId());
				} else {
					logger.finest("Adding new AIP DR Record : " + aip.getXenaId());
					aip.addNewDRProcessingRecord();
					reprocessingJobDAO.saveAIP(aip);
				}
			}

		}

	}

	/**
	 * <p>Check that the current facility is PF, throw an exception if this is not the case. </p>
	 * 
	 * <p>Import a new transfer job into the current facility; replicate the records from the previous
	 * facility into the persistence context and add new records for the current facility.</p>
	 * 
	 * <p>Transaction boundaries are outside of this method.</p>
	 * 
	 */
	private void importNewReprocessingJob(ReprocessingJob reprocessingJob, ObjectContainer db) {
		// This is a new transfer job. Hooray!
		// Import our transfer job.
		showMem("importing job.");

		// Facility check...
		if (dprClient.getCurrentFacility().equals(Facility.QUARANTINE_FACILITY) || dprClient.getCurrentFacility().equals(Facility.DIGITAL_REPOSITORY)) {
			throw new UnsupportedOperationException("Cannot import a new reprocessing job into this facility.");
		}

		reprocessingJobDAO.importNewReprocessingJob(reprocessingJob);

		// Add PF stuff.
		PFReprocessingJobProcessingRecord importRecord = reprocessingJob.addNewPFProcessingRecord();
		importRecord.setImportedToPFBy(currentUser);
		importRecord.setImportedToPFDate(new Date());
		importRecord.setInputCarrierLocation(inputCarrierLocation);
		importRecord.setInputCarrierId(inputCarrierID);
		reprocessingJob.setJobStatus(JobStatus.IMPORTED_AS_REPROCESSING_JOB);

		reprocessingJobDAO.saveReprocessingJob(reprocessingJob);
		showMem("Job imported, starting objects.");
		int i = 0;
		fireStartDataObjectLoad(reprocessingJob.getNumDataObjects());
		Set<String> savedCompositeDataObjectIds = new HashSet<String>();
		// Add our data objects (and the AIPs...)
		ObjectSet dataObjectSet = db.query(ReprocessingDataObject.class);
		for (; dataObjectSet.hasNext();) {
			ReprocessingDataObject nextDataObject = (ReprocessingDataObject) dataObjectSet.next();
			logger.fine("retrieved from db4o data Object: " + nextDataObject.getFileName());
			if (savedCompositeDataObjectIds.contains(nextDataObject.getId())) {
				continue;
			}
			Set<ReprocessingDataObject> dataObjectGraph = new HashSet<ReprocessingDataObject>();
			addDependentDataObjects(nextDataObject, dataObjectGraph);
			for (ReprocessingDataObject dataObjectToSave : dataObjectGraph) {
				if (dataObjectGraph.size() != 1) {
					savedCompositeDataObjectIds.add(dataObjectToSave.getId());
				}
				reprocessingJobDAO.importNewDataObject(dataObjectToSave);
				// The current reprocessing job object the data object is pointing to is stale - update it. 
				dataObjectToSave.setReprocessingJob(reprocessingJob);
				logger.finest("Saving data object: " + dataObjectToSave.getFileName());

				// Add PF Record stuff.
				dataObjectToSave.addNewPFProcessingRecord(reprocessingJob.getMostRecentPFRecord());
				reprocessingJobDAO.saveReprocessingDataObject(dataObjectToSave);

				fireDataObjectLoaded(dataObjectToSave.getFileName());
			}
			if (++i % Constants.MONITOR_DATA_OBJECT_COUNT == 0) {
				showMem("Saved: " + i + " data objects.");
			}
		}
		showMem("Data objects all saved.");
	}

	/**
	 * Get 'dependent' data objects for this data object - that is all data objects that are linked to aips associated
	 * with this data object. This is quick for data objects with a one-to-one or one-to-many relation with aips. In the
	 * general case, this will simply add the data object to the list and finish.
	 * @param currentDataObject - Data object for which we are getting all 'associated' data objects - that is those
	 * linked to via the aips for this data object (most likely just this one, but potentially a number of other
	 * ones...)
	 * @param workingList - the current list of data objects that have already been added to our working list.
	 */
	private void addDependentDataObjects(ReprocessingDataObject currentDataObject, Set<ReprocessingDataObject> workingList) {
		// add this one to the working list.
		workingList.add(currentDataObject);
		for (ReprocessingJobAIP reprocessingJobAIP : currentDataObject.getAllAIPs()) {
			for (ReprocessingDataObject dependentDataObject : reprocessingJobAIP.getSourceDataObjects()) {
				if (!workingList.contains(dependentDataObject)) {
					addDependentDataObjects(dependentDataObject, workingList);
				}
			}
		}
	}

	private void showMem(String mesg) {
		long usedMemory;
		usedMemory = Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory();
		logger.fine(mesg + " mem:" + memFormatter.format(usedMemory) + " bytes");
		//
		System.gc();
		System.gc();
		System.gc();
		logger.finest("GCed'D! mem:" + memFormatter.format(usedMemory) + " bytes");
	}

	public boolean addImportListener(ImportExportListener e) {
		return listenerList.add(e);
	}

	private void fireImportStarted() {
		for (ImportExportListener listener : listenerList) {
			listener.startImport();
		}
	}

	private void fireImportFinished() {
		for (ImportExportListener listener : listenerList) {
			listener.finishImport();
		}
	}

	private void fireStartDataObjectLoad(int numDataObjects) {
		for (ImportExportListener listener : listenerList) {
			listener.startDataObjectLoad(numDataObjects);
		}
	}

	private void fireDataObjectLoaded(String dataObjectName) {
		for (ImportExportListener listener : listenerList) {
			listener.dataObjectLoaded(dataObjectName);
		}
	}

	private void fireShowException(String title, String error, Exception e) {
		for (ImportExportListener listener : listenerList) {
			listener.showException(title, error, e);
		}
	}

	private void fireShowError(String title, String message) {
		for (ImportExportListener listener : listenerList) {
			listener.showError(title, message);
		}
	}

	public class ImportException extends Exception {

		private static final long serialVersionUID = 1L;

		/**
		 * 
		 */
		public ImportException() {
			super();
		}

		/**
		 * @param message
		 * @param cause
		 */
		public ImportException(String message, Throwable cause) {
			super(message, cause);
		}

		/**
		 * @param message
		 */
		public ImportException(String message) {
			super(message);
		}

		/**
		 * @param cause
		 */
		public ImportException(Throwable cause) {
			super(cause);
		}
	}

}
