//
//  ViewController.swift
//  TestSharingApp
//
//  Created by admin on 7/24/23.
//

// This app is being prepared for help from Apple support.  It comes from snippets of the cabNetX app
// The app is made for testing purposes only.  It will load data from cloud on each launch.

import UIKit
import CloudKit

let defaults = UserDefaults.standard
var lastRec = defaults.value(forKey: "lastRec") as? Int ?? 1000
var cStatus = ""

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICloudSharingControllerDelegate {
    
    var tableRecords: [String] = []
    
    func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
        let alert = UIAlertController(title: "Failed to save a share.",
                                      message: "\(error) ", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true) {
           // self.spinner.stopAnimating()
        }
        
    }
    
    func itemTitle(for csc: UICloudSharingController) -> String? {
        // required function
        return "CabNet Share"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //print("number of records",tableRecords.count)
        return tableRecords.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
           let cell = table.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! CustomTableViewCell
        cell.label.text = tableRecords[indexPath.row]
        //print("index:",indexPath.row)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let recComps = tableRecords[indexPath.row].components(separatedBy: ": ")
        selNo.text = recComps[0]
        recordText.text = recComps[1]
        
        print("selected:", recordText.text!)
    }
    
    @IBOutlet weak var recNo: UILabel!
    
    @IBOutlet weak var recContent: UITextField!
    
    @IBAction func recAdd(_ sender: Any) {
        let rString = checkFName1(fName: recContent.text!, com: "No", cLimit: 240)
        if rString != "" {
            cloudAdd(recText: rString, xrecNo: recNo.text!)
            print("done with task")
        } // text not nil
    }
    
    @IBOutlet weak var table: UITableView!
    
    
    @IBOutlet weak var loadButton: UIButton!
    @IBAction func loadData(_ sender: Any) {
        Task {
            spinner.isHidden = false
            spinner.startAnimating()
            chkCloudAcctStat2() // checks for cloud availability first
            // getItems retrieves all records from cloud for test App simplicity
            // actual App checks for latest update and only loads what is necessary
            tableRecords = try await getItems()
            print("Records loaded:", tableRecords.count)
            table.reloadData()
            spinner.stopAnimating()
            spinner.isHidden = true  
        }
    }

    @IBOutlet var spinner: UIActivityIndicatorView!

    @IBOutlet weak var selNo: UILabel!
    @IBOutlet weak var recordText: UILabel!
    
    @IBAction func delRecord(_ sender: Any) {
        
        delCloudRec(recIDName: selNo.text!, zone: "myZone")
    }
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
    
    @IBOutlet weak var shareResult: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        recNo.text = String(lastRec + 1)
        table.dataSource = self
        table.delegate = self
        spinner.isHidden = true
        NotificationCenter.default.addObserver(forName: .passStatus, object: nil, queue: OperationQueue.main) { (notification) in
            self.recNo.text = String(lastRec + 1)
            self.recContent.text = ""
            self.shareResult.text = cStatus
            
        }
        
        
    }


}

