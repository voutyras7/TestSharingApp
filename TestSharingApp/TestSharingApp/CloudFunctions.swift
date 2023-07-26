//
//  CloudFunctions.swift
//  TestSharingApp
//
//  Created by admin on 7/24/23.
//

import Foundation
import CloudKit
import UIKit

public struct cabStruct {  // creates variable type for each column
    var recID: CKRecord.ID!
    var recordZone: CKRecordZone!
    var recString: String!
    var recNos: String!
    var recTime: Int!
    var fName: String!
    var fileList: URL!
    var file1: URL!
    var file2: URL!
}

public var nAStruct = [cabStruct]()
public let container = CKContainer(identifier: "iCloud.cabNetC1")
private let database = CKContainer(identifier: "iCloud.cabNetC1").privateCloudDatabase

public func anyDateToInt(dateIn: Date) -> Int {
    // Converts any format date to integer
    let date = dateIn.timeIntervalSince1970
    let dInt = Int(date)
    return dInt
}

//public var errorMess = ""

public extension UIViewController{
    enum Config {
        /// iCloud container identifier.
        /// Update this if you wish to use your own iCloud container.
        static let containerIdentifier = "iCloud.cabNetC1"
        
    }

    enum anError: Error {
        case invalidRemoteShare
    }

    
    
    func getItems() async throws -> [String] {
        //ref:  https://stackoverflow.com/questions/68292170/swift-continuation-doesnt-make-await-continue
        var recString: [String] = []
        nAStruct = []
        let pred = NSPredicate(value: true)
        let sort = NSSortDescriptor(key: "recNo", ascending: false)
        let query = CKQuery(recordType: "cabRecord", predicate: pred) // recordType must be established in console
        query.sortDescriptors = [sort]
        print("Let's go!")
        
        let items: [cabStruct] = await withCheckedContinuation { continuation in
            let op = CKQueryOperation(query: query)
            op.desiredKeys = ["recNo", "recTime", "recString"]
            op.resultsLimit = 1000
            op.recordMatchedBlock = { (recordId, result) in
                switch result {
                case let .success(record):
                    //print(record)
                    var cabRec = cabStruct()  //
                    cabRec.recID = record.recordID
                    cabRec.recTime = record["recTime"]
                    cabRec.recNos = record["recNo"]
                    cabRec.recString = record["recString"]
                    
                    nAStruct.append(cabRec)
                    
                case let .failure(error):
                    
                    print("something went wrong", error)
                }
                //print("recordMatchedBlock")
            }
            
            op.queryResultBlock = { result in
                print("queryCompletionBlock: Jobs done!")
                // remove duplicate record nos.
                // ...
                continuation.resume(returning: [])
            }
            
            database.add(op)
        }
        print("All done!")
        print("No of cloud records retrieved:",nAStruct.count)
        
        for i in 0 ..< nAStruct.count {
            let eR = nAStruct[i].recString.components(separatedBy: ",")
            if eR[6] == "TestApp" { // only show TestApp data
                recString.append(eR[0] + "-" + eR[1] + ": " + eR[3])
            }
            if i == nAStruct.count - 1 {
                print("..cloud loading complete")
            }
        }
        
        return recString
    }
    
    func chkCloudAcctStat2() { //completion: (_ success: String) -> Void) {
    // checks cloud acct, returns either "available" or "skip"
    //var acctChk = ""
    // https://stackoverflow.com/questions/32335942/check-if-user-is-logged-into-icloud-swift-ios
    //  https://developer.apple.com/documentation/cloudkit/designing_and_creating_a_cloudkit_database#//apple_ref/doc/uid/TP40014987-CH3-SW11
    container.accountStatus { accountStatus, error in
        switch accountStatus {
        case .available:
        print("Cloud acct avail.")
        //cloudFlag = "Yes" // what is this used for??
        default:
        print("iCloud is NOT available")
    } // case
    } // acct status
    //completion(acctChk)
    return
}
    func fetchTestShare(sRecord: CKRecord) async throws -> (CKShare, CKContainer) { //based on sharing example from apple
        print("fetchTestShare called??")
        
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
    func cloudAdd(recText: String, xrecNo: String) {
        print("cloudAdd initiated---")
        let newTime = String(anyDateToInt(dateIn: Date()))
        let recIDString = xrecNo + "-" + newTime
        let customZone = CKRecordZone(zoneName: "myZone")
        let recordID = CKRecord.ID(recordName: recIDString, zoneID: customZone.zoneID)
        let record = CKRecord(recordType: "cabRecord", recordID: recordID)
        
        // make recString compatible with existing database
        // header = "0RecordNo, 1Date(seconds from 1970), 2FolderName, 3FileName(title), 4Notes, 5Photo(fullPath?), 6TypeRec, 7Color, 8Share, 9Expire, 10Link(URL), 11CloudState(cloud or blank), 12ExtraFile(full path?), 13RecState(delete or blank)
        
        let updatedRec =  "\(xrecNo),\(newTime),\("MainFolder/TestApp"),\(recText),\(""),\(""),\("TestApp"),\("clear"),\(""),\(""),\(""),\("Yes"),\(""),\("")"
        
        record.setValue(updatedRec, forKey: "recString")
        record.setValue(xrecNo, forKey: "recNo")
        record.setValue(Int(newTime), forKey: "recTime")
        
            database.save(record) { record, error in // deleted [weak self]
                if record != nil, error == nil {
                    print("** Saved new record in iCloud:",recText)
                    lastRec = lastRec + 1
                    defaults.set(lastRec, forKey: "lastRec")
                    cStatus = "Save Successful"
                    NotificationCenter.default.post(name: .passStatus, object: self)
                    
                } else {
                    print("Error in save")
                    cStatus = "Save Failure"
                    NotificationCenter.default.post(name: .passStatus, object: self)
                }
        }
    } // end cloudAdd function

    func checkFName1(fName: String, com: String, cLimit: Int) -> String {
        // verify fName is for allowable characters
        // fName is input name
        // com is indicator if comma is allowed and to be replaced by ;;
        var chkName = ""; var pattern = "[^A-Za-z0-9-_]+"
        // check for bad characters and length
        chkName = fName.removingPercentEncoding!
        chkName = chkName.trimmingCharacters(in: .whitespacesAndNewlines)
        chkName = chkName.replacingOccurrences(of: " ", with: "_")
        if com == "yes" {
            chkName = chkName.replacingOccurrences(of: ",", with: ";;")
            pattern = "[^A-Za-z0-9-_;]+" // character exceptions
            }
        chkName=chkName.replacingOccurrences(of: pattern, with: "", options: [.regularExpression])
        if chkName.count > cLimit { // truncate if too long
            chkName=String(chkName.prefix(cLimit))
            }
        
        return chkName
    }
    
    func delCloudRec(recIDName: String, zone: String) {
        // Deletes cloud record. Device record must already be deleted.
            var cloudRecordID = CKRecord.ID(recordName: recIDName)
            if zone == "myZone" { // special case for custome zone
                let customZone = CKRecordZone(zoneName: "myZone")
                cloudRecordID = CKRecord.ID(recordName: recIDName, zoneID: customZone.zoneID)
                }
            //let cloudRecordID = CKRecord.ID(recordName: recIDName)
        database.delete(withRecordID: cloudRecordID) { (recordID, err) in
            //DispatchQueue.main.async {
                if err != nil { // Deleting non-existent recordID does not create error here ?? need existence test first 
                    let err = err!
                    print("Error occurred while deleting from cloud")
                    print(err.localizedDescription)
                    cStatus = "Deletion Error"
                    NotificationCenter.default.post(name: .passStatus, object: self)
                } else {
                    print("Cloud record ",recIDName, " deleted.")
                    cStatus = "Delete Process Complete"
                    NotificationCenter.default.post(name: .passStatus, object: self)
                    }
               // }
            }
        }
        
    
    
    
} // end extension VC
public extension Notification.Name {
    static let passStatus = Notification.Name(rawValue: "passStatus")
    
}
