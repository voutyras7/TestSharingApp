# TestSharingApp
CloudKit sharing app example

The app is used to test certain features of the cloud sharing. It is based on snippets of a larger app and uses an existing container 
from the larger app. Features tested are add, deletion and sharing records. The original app uses UIKit, as does this example.  
Conversion to SwiftUI is not practical at this time.
Currently the share feature does not work correctly. While the app does bring up the UICloudSharingController, but the Controller 
will not display the add users option. Help is needed here: 

@IBAction func shareRecord(_ sender: Any) {
        let recIDString = selNo.text!
        print("cloudID=",recIDString)
        // from func shareRecord, share Example
        let sRecord = recIDString
        lazy var container = CKContainer(identifier: Config.containerIdentifier)
        lazy var database = container.privateCloudDatabase
        let recordZone = CKRecordZone(zoneName: "myZone")
        let cloudRecordID = CKRecord.ID(recordName: sRecord, zoneID: recordZone.zoneID)
        print("now retrieving record for id:", sRecord, cloudRecordID)
        Task {
        print("task testrecord...")
        let testRecord = try await database.record(for: cloudRecordID)
        // End finding CKRecord
        print("ckrecord:",testRecord)
        do {
            let (share, container) = try await fetchTestShare(sRecord: testRecord) //
            print("fetching testShare")
            // mv call to viewcontroller should go here
            let sharingController = UICloudSharingController(share: share, container: container)
            // from example CloudKitShare
            sharingController.popoverPresentationController?.sourceView = sender as? UIView
            sharingController.delegate = self
            sharingController.availablePermissions = [.allowPublic, .allowReadOnly, .allowReadWrite]
            self.present(sharingController, animated: true) {
                print("... presenting controller")
            } // self.spinner.stopAnimating() }
        } // end do
        } // task
    }

func fetchTestShare(sRecord: CKRecord) async throws -> (CKShare, CKContainer) { //based on sharing example from apple
        print("fetchTestShare called")
            guard let existingShare = sRecord.share else {
                let share = CKShare(rootRecord: sRecord) // new share
                share[CKShare.SystemFieldKey.title] = "CabNet Record Sharing->"
                _ = try await database.modifyRecords(saving: [sRecord, share], deleting: []) // modifying record to be share
                print("... modified database record for new share")
                return (share, container)
            }
            // already existing share to be added to
            guard let share = try await database.record(for: existingShare.recordID) as? CKShare else {
                print("... share record modification could not be performed")
                throw anError.invalidRemoteShare
            }
            return (share, container)
    }
