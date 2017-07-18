//
//  ViewController.swift
//  jamf-migrator
//
//  Created by ladmin on 12/9/16.
//  Copyright © 2016 jamf. All rights reserved.
//

import Cocoa
import Foundation

//extension Dictionary {
//    init(elements:[(Key, Value)]) {
//        self.init()
//        for (key, value) in elements {
//            updateValue(value, forKey: key)
//        }
//    }
//}

class ViewController: NSViewController, URLSessionDelegate {

    // Main Window
    @IBOutlet var migrator_window: NSView!
    
    // Buttons
    @IBOutlet weak var allNone_button: NSButton!
    @IBOutlet weak var building_button: NSButton!
    @IBOutlet weak var dept_button: NSButton!
    @IBOutlet weak var categories_button: NSButton!
    @IBOutlet weak var fileshares_button: NSButton!
    @IBOutlet weak var sus_button: NSButton!
    @IBOutlet weak var netboot_button: NSButton!
//    @IBOutlet weak var all_groups_button: NSButton!
//    @IBOutlet weak var all_groups_button1: NSButton!
//    @IBOutlet weak var static_comp_grp_button: NSButton!
    @IBOutlet weak var ext_attribs_button: NSButton!
    @IBOutlet weak var sites_button: NSButton!
    @IBOutlet weak var scripts_button: NSButton!
    @IBOutlet weak var smart_comp_grps_button: NSButton!
    @IBOutlet weak var networks_button: NSButton!
    @IBOutlet weak var packages_button: NSButton!
    @IBOutlet weak var printers_button: NSButton!
    @IBOutlet weak var policies_button: NSButton!
    @IBOutlet weak var go_button: NSButton!
    
    // Labels
    @IBOutlet weak var building_label_field: NSTextField!
    @IBOutlet weak var departments_label_field: NSTextField!
    @IBOutlet weak var sites_label_field: NSTextField!
    @IBOutlet weak var categories_label_field: NSTextField!
    @IBOutlet weak var file_shares_label_field: NSTextField!
    @IBOutlet weak var sus_label_field: NSTextField!
    @IBOutlet weak var netboot_label_field: NSTextField!
    @IBOutlet weak var extension_attributes_label_field: NSTextField!
    @IBOutlet weak var scripts_label_field: NSTextField!
    @IBOutlet weak var smart_groups_label_field: NSTextField!
    @IBOutlet weak var network_segments_label_field: NSTextField!
    @IBOutlet weak var packages_label_field: NSTextField!
    @IBOutlet weak var printers_label_field: NSTextField!
    @IBOutlet weak var policies_label_field: NSTextField!
    
    // Source and destination fields
    @IBOutlet weak var source_jp_server_field: NSTextField!
    @IBOutlet weak var source_user_field: NSTextField!
    @IBOutlet weak var source_pwd_field: NSSecureTextField!
    @IBOutlet weak var dest_jp_server_field: NSTextField!
    @IBOutlet weak var dest_user_field: NSTextField!
    @IBOutlet weak var dest_pwd_field: NSSecureTextField!
        
    // plist and history variables
    let plistPath:String? = (NSHomeDirectory() + "/Library/Application Support/jamf-migrator/settings.plist")
    var format = PropertyListSerialization.PropertyListFormat.xml //format of the property list
    var plistData:[String:AnyObject] = [:]  //our server/username data
    var maxHistory: Int = 20
    var historyFile: String = ""
    let historyPath:String? = (NSHomeDirectory() + "/Library/Application Support/jamf-migrator/history/")
    var historyFileW: FileHandle?  = FileHandle(forUpdatingAtPath: "")
    
    // credentials
    var sourceCreds = ""
    var destCreds = ""
    
    // settings variables
    var source_jp_server: String = ""
    var source_user: String = ""
    var source_pass: String = ""
    var dest_jp_server: String = ""
    var dest_user: String = ""
    var dest_pass: String = ""
    var sourceBase64Creds: String = ""
    var destBase64Creds: String = ""
    
    var sourceURL = ""
    var destURL = ""
    
    var whiteText:NSColor = NSColor.white
    var greenText:NSColor = NSColor.green
    var yellowText:NSColor = NSColor.yellow
    var redText:NSColor = NSColor.red
    var changeColor:Bool = true
    
    // GET and POST fields
    @IBOutlet weak var object_name_field: NSTextField!  // object being migrated
    @IBOutlet weak var objects_completed_field: NSTextField!
    @IBOutlet weak var objects_found_field: NSTextField!
    
    @IBOutlet weak var get_name_field: NSTextField!
    @IBOutlet weak var get_completed_field: NSTextField!
    @IBOutlet weak var get_found_field: NSTextField!
    
    var AllEndpointsArray: [String] = ["buildings", "departments", "sites", "categories", "distributionpoints", "softwareupdateservers", "netbootservers", "computerextensionattributes", "scripts", "computergroups", "networksegments", "packages", "printers", "policies"]
    
    var getEndpointInProgress: String = ""     // end point currently in the GET queue
    var endpointInProgress: String = ""     // end point currently in the POST queue
    var endpointName: String = ""
    var POSTsuccessCount: Int = 0
    var failedCount: Int = 0
    
    // define list of items to migrate
    var objectsToMigrate: [String] = []
    
    var wipe_data: Bool = false
    
    let fm = FileManager()
    var theOpQ = OperationQueue() // create operation queue for API calls
    
    var authQ = DispatchQueue(label: "com.jamf.auth")
    
    var migrateOrWipe: String = ""
    var httpStatusCode: Int = 0
    var URLisValid: Bool = true
    var processGroup = DispatchGroup()
    
    
    @IBAction func allNone(_ sender: Any) {
        self.building_button.state = self.allNone_button.state
        self.dept_button.state = self.allNone_button.state
        self.categories_button.state = self.allNone_button.state
        self.fileshares_button.state = self.allNone_button.state
        self.sus_button.state = self.allNone_button.state
        self.netboot_button.state = self.allNone_button.state
//        self.all_groups_button.state = self.allNone_button.state
        self.smart_comp_grps_button.state = self.allNone_button.state
//        self.static_comp_grp_button.state = self.allNone_button.state
        self.ext_attribs_button.state = self.allNone_button.state
        self.sites_button.state = self.allNone_button.state
        self.scripts_button.state = self.allNone_button.state
        self.networks_button.state = self.allNone_button.state
        self.packages_button.state = self.allNone_button.state
        self.printers_button.state = self.allNone_button.state
        self.policies_button.state = self.allNone_button.state
    }
    
    @IBAction func Go(sender: AnyObject) {
        self.go_button.isEnabled = false
        clearProcessingFields()

        // credentials were entered check - start
        if source_user_field.stringValue == "" || source_pwd_field.stringValue == "" {
            alert_dialog(header: "Alert", message: "Must provide both a username and password for the source server.")
            self.go_button.isEnabled = true
            return
        }
        if dest_user_field.stringValue == "" || dest_pwd_field.stringValue == "" {
            alert_dialog(header: "Alert", message: "Must provide both a username and password for the destination server.")
            self.go_button.isEnabled = true
            return
        }
        // credentials check - end
        
        // set credentials - start
        self.source_jp_server = source_jp_server_field.stringValue
        self.source_user = source_user_field.stringValue
        self.source_pass = source_pwd_field.stringValue
        self.dest_jp_server = dest_jp_server_field.stringValue
        self.dest_user = dest_user_field.stringValue
        self.dest_pass = dest_pwd_field.stringValue
        
        // server is reachable - start
        if !(checkURL(theUrl: self.source_jp_server) == 0) {
            self.alert_dialog(header: "Attention", message: "The source server URL could not be contacted.")
            self.go_button.isEnabled = true
            return
        }
        if !(checkURL(theUrl: self.dest_jp_server) == 0) {
            self.alert_dialog(header: "Attention", message: "The destination server URL could not be contacted.")
            self.go_button.isEnabled = true
            return
        }
        // server is reachable - end
        
        sourceCreds = "\(source_user):\(source_pass)"
        let sourceUtf8Creds = sourceCreds.data(using: String.Encoding.utf8)
        sourceBase64Creds = (sourceUtf8Creds?.base64EncodedString())!
        
        destCreds = "\(dest_user):\(dest_pass)"
        let destUtf8Creds = destCreds.data(using: String.Encoding.utf8)
        destBase64Creds = (destUtf8Creds?.base64EncodedString())!
        // set credentials - end
        
        // check authentication - start
        self.authCheck(f_sourceURL: self.source_jp_server, f_credentials: self.sourceBase64Creds)  {
            (result: Bool) in
            if !result {
                NSLog("Source server authentication failure.")
                return
            } else {
                self.authCheck(f_sourceURL: self.dest_jp_server, f_credentials: self.destBase64Creds)  {
                    (result: Bool) in
                    if !result {
                        NSLog("Destination server authentication failure.")
                        return
                    } else {
                    // verify source server URL - start
                    let sourceURL = URL(string: self.source_jp_server_field.stringValue)
                    let task_sourceURL = URLSession.shared.dataTask(with: sourceURL!) { _, response, _ in
                        if (response as? HTTPURLResponse) != nil || (response as? HTTPURLResponse) == nil {
                            //print(HTTPURLResponse.statusCode)
                            //===== change to go to function to check dest. server, which forwards to migrate if all is well
                            // verify destination server URL - start
                            let destinationURL = URL(string: self.dest_jp_server_field.stringValue)
                            let task_destinationURL = URLSession.shared.dataTask(with: destinationURL!) { _, response, _ in
                                if (response as? HTTPURLResponse) != nil || (response as? HTTPURLResponse) == nil {
                                    //print("Destination server response: \(response)")
                                    NSLog("Destination server response: \(response)")
                                    if(!self.theOpQ.isSuspended) {
                                        self.startMigrating()
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        //print("Destination server response: \(response)")
                                        NSLog("Destination server response: \(response)")
                                        self.alert_dialog(header: "Attention", message: "The destination server URL could not be validated.")
                                    }
                                    
                                    NSLog("Failed to connect to destination server.")
                                    self.go_button.isEnabled = true
                                    return
                                }
                            }   // let task for destinationURL - end
                            
                            task_destinationURL.resume()
                            // verify source destination URL - end
                            
                            //===== change to go to function to check dest. server, which forwards to migrate if all is well
                            //self.startMigrating()
                        } else {
                            DispatchQueue.main.async {
                                self.alert_dialog(header: "Attention", message: "The source server URL could not be validated.")
                            }
                            NSLog("Failed to connect source server.")
                            self.go_button.isEnabled = true
                            return
                        }
                    }   // let task for soureURL - end
                    task_sourceURL.resume()
                    // verify source server URL - end
                    }
                }
            }   // else check dest URL auth - end
        }
    // check authentication - end

        //print("operations in Auth que: \(theOpQ.operationCount)")
        //print("operations Auth que: \(theOpQ.operations)")
    }
    
//    @IBAction func SmartAndStaticGroups(sender: AnyObject) {
//        self.smart_comp_grps_button.state = self.all_groups_button.state
//        self.static_comp_grp_button.state = self.all_groups_button.state
//    }

    @IBAction func QuitNow(sender: AnyObject) {
        // check for file that sets mode to delete data from destination server, delete if found - start
        rmDELETE()
        // check for file that allows deleting data from destination server, delete if found - end
        self.go_button.isEnabled = true
        NSApplication.shared().terminate(self)
    }
    
//========================== migration functions ==========================//
    
    func authCheck(f_sourceURL: String, f_credentials: String, completion: @escaping (Bool) -> Void) {
        var validCredentials:Bool = false
        print("--- checking authentication to: \(f_sourceURL)")
        //theOpQ.maxConcurrentOperationCount = 1
        //let semaphore = DispatchSemaphore(value: 0)
        //print("operations in Auth que: \(theOpQ.operationCount)")
        //print("operations Auth que: \(theOpQ.operations)")
        
        authQ.sync {
            var myURL = "\(f_sourceURL)/JSSResource/buildings"
            myURL = myURL.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
            print("checking: \(myURL)")

            let encodedURL = NSURL(string: myURL)
            let request = NSMutableURLRequest(url: encodedURL as! URL)
            //let request = NSMutableURLRequest(url: encodedURL as! URL, cachePolicy: NSURLRequest.CachePolicy(rawValue: 1)!, timeoutInterval: 10)
            request.httpMethod = "GET"
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(f_credentials)", "Content-Type" : "application/json", "Accept" : "application/json"]
            let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: request as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse {
                    print("\(myURL) auth check httpResponse: \(httpResponse.statusCode)")
                    
                    if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
                        print("\(myURL) auth httpResponse, between 199 and 299: \(httpResponse.statusCode)")
                        validCredentials = true
                        completion(validCredentials)
                    } else {
                        print("\n\n---------- status code ----------")
                        print(httpResponse.statusCode)
                        self.httpStatusCode = httpResponse.statusCode
                        print("---------- status code ----------")
                        print("\n\n---------- response ----------")
                        print(httpResponse)
                        print("---------- response ----------\n\n")
                        self.theOpQ.cancelAllOperations()
                        switch self.httpStatusCode {
                        case 401:
                            self.alert_dialog(header: "Authentication Failure", message: "Please verify username and password for:\n\(f_sourceURL)")
                        default:
                            self.alert_dialog(header: "Error", message: "An unknown error occured trying to query the source server.")
                        }
                        //                        401 - wrong username and/or password
                        //                        409 - unable to create object; already exists or data missing or xml error
                        self.go_button.isEnabled = true
                        completion(validCredentials)
                    }   // if httpResponse/else - end
                }   // if let httpResponse - end
                if error != nil {
                }
            })  // let task = session - end
            task.resume()
        }   // authQ - end
    }   // func authCheck - end
    
    func startMigrating() {
        print("startMigrating")
        // check for file that allow deleting data from destination server - start
        var isDir: ObjCBool = false
        if (fm.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/DELETE", isDirectory: &isDir)) {
            NSLog("Removing data from destination server - \(dest_jp_server_field.stringValue)")
            wipe_data = true
            
            self.dest_jp_server = dest_jp_server_field.stringValue
            self.dest_user = dest_user_field.stringValue
            self.dest_pass = dest_pwd_field.stringValue
            migrateOrWipe = "----------- Starting To Wipe Data -----------\n"
        } else {
            NSLog("Migrating data from \(source_jp_server_field.stringValue) to \(dest_jp_server_field.stringValue).")
            // verify source and destination are not the same - start
            if source_jp_server_field.stringValue == dest_jp_server_field.stringValue {
                alert_dialog(header: "Alert", message: "Source and destination servers cannot be the same.")
                self.go_button.isEnabled = true
                return
            }
            // verify source and destination are not the same - end
            wipe_data = false
            
            migrateOrWipe = "----------- Starting Migration -----------\n"
        }
        // check for file that allow deleting data from destination server - end
        
        // set credentials - start
        sourceCreds = "\(source_user):\(source_pass)"
        let sourceUtf8Creds = sourceCreds.data(using: String.Encoding.utf8)
        sourceBase64Creds = (sourceUtf8Creds?.base64EncodedString())!
        
        destCreds = "\(dest_user):\(dest_pass)"
        let destUtf8Creds = destCreds.data(using: String.Encoding.utf8)
        destBase64Creds = (destUtf8Creds?.base64EncodedString())!
        // set credentials - end
        
        historyFile = getCurrentTime() + "_migration.txt"
        isDir = false
        if !(fm.fileExists(atPath: historyPath! + historyFile, isDirectory: &isDir)) {
            _ = try? fm.createDirectory(atPath: historyPath!, withIntermediateDirectories: true, attributes: nil )
        }
        fm.createFile(atPath: historyPath! + historyFile, contents: nil, attributes: nil)
        historyFileW = FileHandle(forUpdatingAtPath: (historyPath! + historyFile))
        
        writeToHistory(stringOfText: migrateOrWipe)
        go_button.isEnabled = false
        
        // make sure the labels can change color when we start
        changeColor = true
        // initialize list of items to migrate
        objectsToMigrate.removeAll()
        
        // set all the labels to white - start
        DispatchQueue.main.async {
            for i in (0..<self.AllEndpointsArray.count) {
                self.labelColor(endpoint: self.AllEndpointsArray[i], theColor: self.whiteText)
            }
        }
        // set all the labels to white - end
        if building_button.state == 1 {
            objectsToMigrate += ["buildings"]
        }   // if building_button.state - end
        
        if dept_button.state == 1 {
            objectsToMigrate += ["departments"]
        }   // if dept_button.state - end
        
        if sites_button.state == 1 {
            objectsToMigrate += ["sites"]
        }   // if sites_button.state - end
        
        if categories_button.state == 1 {
            objectsToMigrate += ["categories"]
        }   // if categories_button.state - end
        
        if fileshares_button.state == 1 {
            objectsToMigrate += ["distributionpoints"]
        }   // if fileshares_button.state - end
        
        if sus_button.state == 1 {
            objectsToMigrate += ["softwareupdateservers"]
        }   // if sus_button.state - end
        
        if netboot_button.state == 1 {
            objectsToMigrate += ["netbootservers"]
        }   // if netboot_button.state - end
        
        if ext_attribs_button.state == 1 {
            objectsToMigrate += ["computerextensionattributes"]
        }
        
        if scripts_button.state == 1 {
            objectsToMigrate += ["scripts"]
        }
        
        if smart_comp_grps_button.state == 1 {
            objectsToMigrate += ["computergroups"]
        }
        
        if networks_button.state == 1 {
            objectsToMigrate += ["networksegments"]
        }
        
        if packages_button.state == 1 {
            objectsToMigrate += ["packages"]
        }
        
        if printers_button.state == 1 {
            objectsToMigrate += ["printers"]
        }
        
        if policies_button.state == 1 {
            objectsToMigrate += ["policies"]
        }
        
        if wipe_data {
            // set server and credentials used for wipe
            sourceBase64Creds = destBase64Creds
            self.source_jp_server = dest_jp_server
            // move sites to the end of the array
            let siteIndex = objectsToMigrate.index(of: "sites")
            if siteIndex != nil {
                let siteTmp = objectsToMigrate.remove(at: siteIndex!)
                objectsToMigrate.insert(siteTmp, at: objectsToMigrate.count)
            }
        }   // if wipe_data - end
        
        // loop through process of migrating or removing - start
        for i in (0..<objectsToMigrate.count) {
            print("Starting to migrate \(objectsToMigrate[i])")
            self.getEndpoints(endpoint: objectsToMigrate[i])  {
                (result: String) in
                print("\(result)")
            }
        }   // loop through process of migrating or removing - end
    }

    
    func getEndpoints(endpoint: String, completion: (_ result: String) -> Void) {
        print("Getting \(endpoint)")
        theOpQ.maxConcurrentOperationCount = 1
        let semaphore = DispatchSemaphore(value: 0)

//        print("operations in que: \(theOpQ.operationCount)")
//        print("operations que: \(theOpQ.operations)")
//        
//        for i in 0..<theOpQ.operationCount {
//            print("Queued item \(i): \(theOpQ.operations[i])")
//        }

        theOpQ.addOperation {
            var myURL = "\(self.source_jp_server)/JSSResource/\(endpoint)"
            myURL = myURL.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")

            let encodedURL = NSURL(string: myURL)
            let request = NSMutableURLRequest(url: encodedURL as! URL)
            request.httpMethod = "GET"
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(self.sourceBase64Creds)", "Content-Type" : "application/json", "Accept" : "application/json"]
            let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: request as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse {
                    print("httpResponse: \(httpResponse.statusCode)")
                    //print(httpResponse)
                    //print(NSString(data: data!, encoding: String.Encoding.utf8.rawValue)!)
                    //let departmentInfo = String(data: data!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
                    //print("Department Info: \(departmentInfo)\n\n")
                    //var deptArray: [String] = []

                    do {
                        let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                        if let endpointJSON = json as? [String: Any] {
                            //print("endpointJSON: \(endpointJSON))")
                            print("\n-------- Getting all \(endpoint) --------")
                            switch endpoint {
                            case "buildings", "departments", "sites", "categories", "scripts", "packages", "printers":
                                print("processing building/deptartment/site/category/script/package/printer")
                                if let endpointInfo = endpointJSON[endpoint] as? [Any] {
                                    let endpointCount: Int = endpointInfo.count
                                    print("\(endpoint) found: \(endpointCount)")
                                    
                                    if endpointCount > 0 {
                                        for i in (0..<endpointCount) {
                                            let record = endpointInfo[i] as! [String : AnyObject]
                                            let xmlID: Int = (record["id"] as! Int)
                                            let xmlName: String = (record["name"] as! String)

                                            if !self.wipe_data  {
                                                self.endPointByID(endpoint: endpoint, endpointID: xmlID, endpointCurrent: (i+1), endpointCount: endpointCount)
                                            } else {
                                                self.RemoveEndpoints(endpointType: endpoint, endPointID: xmlID, endpointName: xmlName, endpointCurrent: (i+1), endpointCount: endpointCount)
                                                }
                                        }   // for i in - end
                                    }   // if endpointCount - end
                                }   // end if let buildings, departments...

                            case "distributionpoints":
                                print("processing distributionpoints")
                                if let endpointInfo = endpointJSON["distribution_points"] as? [Any] {
                                    let endpointCount: Int = endpointInfo.count
                                    print("distributionpoints found: \(endpointCount)")
   
                                    if endpointCount > 0 {
                                        for i in (0..<endpointCount) {
                                            let record = endpointInfo[i] as! [String : AnyObject]
                                            // fetch full category XML
                                            let xmlID: Int = (record["id"] as! Int)
                                            let xmlName: String = (record["name"] as! String)

                                            if !self.wipe_data  {
                                                self.endPointByID(endpoint: endpoint, endpointID: xmlID, endpointCurrent: (i+1), endpointCount: endpointCount)
                                            } else {
                                                self.RemoveEndpoints(endpointType: endpoint, endPointID: xmlID, endpointName: xmlName, endpointCurrent: (i+1), endpointCount: endpointCount)
                                            }
                                        }   //for i in (0..<endpointCount) - end
                                    }   // if endpointCount - end
                            }   // end if let distributionpoints
                            case "netbootservers":
                                print("processing netbootservers")
                                if let endpointInfo = endpointJSON["netboot_servers"] as? [Any] {
                                    let endpointCount: Int = endpointInfo.count
                                    print("netbootservers found: \(endpointCount)")
                                    
                                    if endpointCount > 0 {
                                        for i in (0..<endpointCount) {
                                            let record = endpointInfo[i] as! [String : AnyObject]
                                            // fetch full category XML
                                            let xmlID: Int = (record["id"] as! Int)
                                            let xmlName: String = (record["name"] as! String)

                                            if !self.wipe_data  {
                                                self.endPointByID(endpoint: endpoint, endpointID: xmlID, endpointCurrent: (i+1), endpointCount: endpointCount)
                                            } else {
                                                self.RemoveEndpoints(endpointType: endpoint, endPointID: xmlID, endpointName: xmlName, endpointCurrent: (i+1), endpointCount: endpointCount)
                                            }
                                        }   //for i in (0..<endpointCount) - end
                                    }   // if endpointCount - end
                            }   // end if let netbootservers
                            case "softwareupdateservers":
                                print("processing softwareupdateservers")
                                if let endpointInfo = endpointJSON["software_update_servers"] as? [Any] {
                                    let endpointCount: Int = endpointInfo.count
                                    print("softwareupdateservers found: \(endpointCount)")
                                    
                                    if endpointCount > 0 {
                                        for i in (0..<endpointCount) {
                                            let record = endpointInfo[i] as! [String : AnyObject]
                                            // fetch full category XML
                                            let xmlID: Int = (record["id"] as! Int)
                                            let xmlName: String = (record["name"] as! String)

                                            if !self.wipe_data  {
                                                self.endPointByID(endpoint: endpoint, endpointID: xmlID, endpointCurrent: (i+1), endpointCount: endpointCount)
                                            } else {
                                                self.RemoveEndpoints(endpointType: endpoint, endPointID: xmlID, endpointName: xmlName, endpointCurrent: (i+1), endpointCount: endpointCount)
                                            }
                                        }   //for i in (0..<endpointCount) - end
                                    }   // if endpointCount - end
                            }   // end if let softwareupdateservers
                            case "networksegments":
                                print("processing network segments")
                                if let endpointInfo = endpointJSON["network_segments"] as? [Any] {
                                    //                        print("Network Segments: \(endpointInfo)")
                                    //                        exit(0)
                                    let endpointCount: Int = endpointInfo.count
                                    
                                    //self.migrationStatus(endpoint: "network segments", count: endpointCount)
                                    
                                    print("Network segments found: \(endpointCount)")
                                    if endpointCount > 0 {
                                        for i in (0..<endpointCount) {
                                            let record = endpointInfo[i] as! [String : AnyObject]
                                            // fetch full network segment XML
                                            let xmlID: Int = (record["id"] as! Int)
                                            let xmlName: String = (record["name"] as! String)

                                            if !self.wipe_data  {
                                                self.endPointByID(endpoint: endpoint, endpointID: xmlID, endpointCurrent: (i+1), endpointCount: endpointCount)
                                            } else {
                                                self.RemoveEndpoints(endpointType: endpoint, endPointID: xmlID, endpointName: xmlName, endpointCurrent: (i+1), endpointCount: endpointCount)
                                            }
                                        }   //for i in (0..<endpointCount) - end
                                    }   // if endpointCount - end
                            }   // end if let networksegments
                            case "computergroups":
                                print("processing computer groups")
                                if let endpointInfo = endpointJSON["computer_groups"] as? [Any] {
                                    
                                    let endpointCount: Int = endpointInfo.count
                                    print("groups found: \(endpointCount)")
                                    var staticCount = 0
                                    //self.migrationStatus(endpoint: "computer groups", count: endpointCount)
                                    
                                    if endpointCount > 0 {
                                        // find number of static groups
                                        for i in (0..<endpointCount) {
                                            let record = endpointInfo[i] as! [String : AnyObject]
                                            //let xmlID: Int = (record["id"] as! Int)
                                            let smart: Bool = (record["is_smart"] as! Bool)
                                            if !smart {
                                               staticCount += 1
                                            }
                                        }
                                        print("\(staticCount) static groups")
                                        // verify we have smart groups
                                        if (endpointCount-staticCount) > 0 {
                                            for i in (0..<endpointCount) {
                                                let record = endpointInfo[i] as! [String : AnyObject]
                                                print("record: \(record)")
                                                // fetch full network segment XML
                                                let xmlID: Int = (record["id"] as! Int)
                                                let xmlName: String = (record["name"] as! String)
                                                let smart: Bool = (record["is_smart"] as! Bool)
                                                
                                                // want to skip build in smart groups, All Managed Clients/Servers
                                                let name: String = (record["name"] as! String)
                                                if name != "All Managed Clients" && name != "All Managed Servers" && smart {
                                                    if !self.wipe_data  {
                                                        self.endPointByID(endpoint: endpoint, endpointID: xmlID, endpointCurrent: (i+1), endpointCount: (endpointCount-staticCount))
                                                    } else {
                                                        self.RemoveEndpoints(endpointType: endpoint, endPointID: xmlID, endpointName: xmlName, endpointCurrent: (i+1), endpointCount: (endpointCount-staticCount))
                                                    }   // if !wipe_data - end
                                                }   // if name - end
                                            }   // for i in - end
                                        }   // if (endpointCount-staticCount) - end
                                    }
                                }   // if let endpointInfo = endpointJSON["computer_groups"] - end
                            case "computerextensionattributes":
                                print("processing computerextensionattributes")
                                if let endpointInfo = endpointJSON["computer_extension_attributes"] as? [Any] {
                                    print("EAs found: \(endpointInfo)")
                                    let endpointCount: Int = endpointInfo.count
                                    print("Computer Attributes found: \(endpointCount)")
                                    //                            exit(0)

                                    if endpointCount > 0 {
                                        for i in (0..<endpointCount) {
                                            let record = endpointInfo[i] as! [String : AnyObject]
                                            // fetch full EA XML
                                            let xmlID: Int = (record["id"] as! Int)
                                            let xmlName: String = (record["name"] as! String)
                                            
                                            if !self.wipe_data  {
                                                self.endPointByID(endpoint: endpoint, endpointID: xmlID, endpointCurrent: (i+1), endpointCount: endpointCount)
                                            } else {
                                                self.RemoveEndpoints(endpointType: endpoint, endPointID: xmlID, endpointName: xmlName, endpointCurrent: (i+1), endpointCount: endpointCount)
                                            }
                                        }   // for i in (0..<endpointCount) - end
                                    }   // if endpointCount - end
                            }   // if let endpointInfo = endpointJSON["computerextensionattributes"] - end

                            case "policies":
                                print("processing \(endpoint)")
                                if let endpointInfo = endpointJSON[endpoint] as? [Any] {
                                    let endpointCount: Int = endpointInfo.count
                                    print("\(endpoint) found: \(endpointCount)")
                                    
                                    if endpointCount > 0 {
                                        for i in (0..<endpointCount) {
                                            let record = endpointInfo[i] as! [String : AnyObject]
                                            let xmlID: Int = (record["id"] as! Int)
                                            let xmlName: String = (record["name"] as! String)
                                            
                                            if xmlName.range(of:"[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] at", options: .regularExpression) == nil && xmlName != "Update Inventory" {
                                                //let result = xmlName.substring(with:range)
                                                //print("\tresult: \(result)")
                                                // non-recon created policy
                                                print("name: \(xmlName)\txmlID: \(xmlID)\ti: \(i+1)")
                                                if !self.wipe_data  {
                                                    self.endPointByID(endpoint: endpoint, endpointID: xmlID, endpointCurrent: (i+1), endpointCount: endpointCount)
                                                } else {
                                                    self.RemoveEndpoints(endpointType: endpoint, endPointID: xmlID, endpointName: xmlName, endpointCurrent: (i+1), endpointCount: endpointCount)
                                                }   //if-else !self.wipe_data - end
                                                
                                            }   // if xmlName.range - end
                                        }   // for i in (0..<endpointCount)
                                    }   // if endpointCount > 0
                                }   //if let endpointInfo = endpointJSON - end
                                
                            default:
                                break
                            }   // switch - end
                        }   // if let endpointJSON - end
                        
                    } // catch {
//                        NSLog("error serializing JSON: \(error)")
//                    }   // end do/catch
                    
                    if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
                        //print("httpResponse, between 199 and 299: \(httpResponse.statusCode)")
                    } else {
                        // something went wrong
                        //self.writeToHistory(stringOfText: "**** \(self.getName(endpoint: endpointType, objectXML: endPointXML)) - Failed\n")
                        print("\n\n---------- status code ----------")
                        print(httpResponse.statusCode)
                        self.httpStatusCode = httpResponse.statusCode
                        print("---------- status code ----------")
                        print("\n\n---------- response ----------")
                        print(httpResponse)
                        print("---------- response ----------\n\n")
                        self.theOpQ.cancelAllOperations()
                        switch self.httpStatusCode {
                        case 401:
                            self.alert_dialog(header: "Authentication Failure", message: "Please verify username and password for the source server.")
                        default:
                            self.alert_dialog(header: "Error", message: "An unknown error occured trying to query the source server.")
                        }

                        //                        401 - wrong username and/or password
                        //                        409 - unable to create object; already exists or data missing or xml error
                        self.go_button.isEnabled = true
                        return
                        
                    }   // if httpResponse/else - end
                }   // if let httpResponse - end
                semaphore.signal()
                if error != nil {
                }
            })  // let task = session - end
            //print("GET")
            task.resume()
            semaphore.wait()
        }   // theOpQ - end
        completion("Got endpoint - \(endpoint)")
    }
    
    func endPointByID(endpoint: String, endpointID: Int, endpointCurrent: Int, endpointCount: Int) {
        theOpQ.maxConcurrentOperationCount = 1
        let semaphore = DispatchSemaphore(value: 0)
        theOpQ.addOperation {
            var myURL = "\(self.source_jp_server)/JSSResource/\(endpoint)/id/\(endpointID)"
            myURL = myURL.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
            let encodedURL = NSURL(string: myURL)
            let request = NSMutableURLRequest(url: encodedURL as! URL)
            request.httpMethod = "GET"
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(self.sourceBase64Creds)", "Content-Type" : "text/xml", "Accept" : "text/xml"]
            let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: request as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                
                if let httpResponse = response as? HTTPURLResponse {
//                    print("EA data:")
//                    print(NSString(data: data!, encoding: String.Encoding.utf8.rawValue)!)
                    var PostXML = String(data: data!, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
                    // strip out <id> tag from XML
                    let regexID = try! NSRegularExpression(pattern: "<id>+[0-9]+</id>", options:.caseInsensitive)
                    PostXML = regexID.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "")
 //                   print("\n\nRemoved id tag: \(XMLString)")

                    switch endpoint {
                    case "buildings", "departments", "sites", "categories", "distributionpoints", "netbootservers", "softwareupdateservers", "computerextensionattributes", "scripts", "printers":
                        print("processing " + endpoint + " - verbose")
                        //print("\nXML: \(PostXML)")
                        
                        DispatchQueue.main.async {
                            if self.getEndpointInProgress != endpoint {
                                self.endpointInProgress = endpoint
                                self.getStatusInit(endpoint: endpoint, count: endpointCount)

                            }
                                self.get_completed_field.stringValue = "\(endpointCurrent)"
                            
                        }
                        
                        self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount)
                    case "networksegments":
                        print("processing network segments - verbose")
                        // remove items not transfered; distribution points, netboot server, SUS from XML
                        let regexDistro1 = try! NSRegularExpression(pattern: "<distribution_server>(.*?)</distribution_server>", options:.caseInsensitive)
                        let regexDistro2 = try! NSRegularExpression(pattern: "<distribution_point>(.*?)</distribution_point>", options:.caseInsensitive)
                        let regexDistro3 = try! NSRegularExpression(pattern: "<url>(.*?)</url>", options:.caseInsensitive)
                        let regexNetBoot = try! NSRegularExpression(pattern: "<netboot_server>(.*?)</netboot_server>", options:.caseInsensitive)
                        let regexSUS = try! NSRegularExpression(pattern: "<swu_server>(.*?)</swu_server>", options:.caseInsensitive)
                        PostXML = regexDistro1.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<distribution_server/>")
                        // if not migrating file shares remove then from network segments xml - start
                        if self.fileshares_button.state == 0 {
                            PostXML = regexDistro2.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<distribution_point/>")
                            PostXML = regexDistro3.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<url/>")
                        }
                        // if not migrating file shares remove then from network segments xml - end
                        // if not migrating netboot server remove then from network segments xml - start
                        if self.netboot_button.state == 0 {
                            PostXML = regexNetBoot.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<netboot_server/>")
                        }
                        // if not migrating netboot server remove then from network segments xml - end
                        // if not migrating software update server remove then from network segments xml - start
                        if self.sus_button.state == 0 {
                            PostXML = regexSUS.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<swu_server/>")
                        }
                        // if not migrating software update server remove then from network segments xml - end
                        
                        //print("\nXML: \(PostXML)")

                            if self.getEndpointInProgress != endpoint {
                                self.endpointInProgress = endpoint
                                self.getStatusInit(endpoint: endpoint, count: endpointCount)
                            }
                                self.get_completed_field.stringValue = "\(endpointCurrent)"
                        
                    	self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount)
                    case "computergroups":
                        print("processing smart groups - verbose")
                        // remove computers that are a member of the smart group from XML
                        let regexComp = try! NSRegularExpression(pattern: "<computers>(.*?)</computers>", options:.caseInsensitive)
                        PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "")
                        //print("\nXML: \(PostXML)")

                            if self.getEndpointInProgress != endpoint {
                                self.endpointInProgress = endpoint
                                self.getStatusInit(endpoint: endpoint, count: endpointCount)
//                                self.get_name_field.stringValue = endpoint
//                                self.get_found_field.stringValue = "\(endpointCount)"
//                                self.get_completed_field.stringValue = "0"
                        }
                                self.get_completed_field.stringValue = "\(endpointCurrent)"
                        
                    	self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount)
                        
                    case "packages":
                        print("processing packages - verbose")
                        // remove 'No category assigned' from XML
                        let regexComp = try! NSRegularExpression(pattern: "<category>No category assigned</category>", options:.caseInsensitive)
                        PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<category/>")
                        //print("\nXML: \(PostXML)")
                        
                        if self.getEndpointInProgress != endpoint {
                            self.endpointInProgress = endpoint
                            self.getStatusInit(endpoint: endpoint, count: endpointCount)
                        }
                        self.get_completed_field.stringValue = "\(endpointCurrent)"
                        
                        self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount)
                        
                    case "policies":
                        print("processing policies - verbose")
                        // remove individual objects that are scoped to the policy from XML
                        var regexComp = try! NSRegularExpression(pattern: "<computers>(.*?)</computers>", options:.caseInsensitive)
                        PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<computers/>")
                        regexComp = try! NSRegularExpression(pattern: "<self_service_icon>(.*?)</self_service_icon>", options:.caseInsensitive)
                        PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<self_service_icon/>")
                        //print("\nXML: \(PostXML)")
                        
                        if self.getEndpointInProgress != endpoint {
                            self.endpointInProgress = endpoint
                            self.getStatusInit(endpoint: endpoint, count: endpointCount)
                        }
                        self.get_completed_field.stringValue = "\(endpointCurrent)"
                        
                        self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount)
                        
                    default:
                        print("Unknown endpoint")
                    }   // switch - end
                    
                    if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
                        //print("\(httpResponse.statusCode)\t\t\(httpResponse.allHeaderFields)")
                    } else {
                        //print("\(httpResponse.statusCode)\t\t\(httpResponse.allHeaderFields)")
                    }   // if httpResponse/else - end
                }   // if let httpResponse - end
                semaphore.signal()
                if error != nil {
                }
            })  // let task = session - end
            //print("GET")
            task.resume()
            semaphore.wait()
        }   // theOpQ - end
    }
    
    func CreateEndpoints(endpointType: String, endPointXML: String, endpointCurrent: Int, endpointCount: Int) {
        // this is where we create the new endpoint
        print("----- Posting #\(endpointCurrent): \(endpointType) -----")
        theOpQ.maxConcurrentOperationCount = 1
        let semaphore = DispatchSemaphore(value: 0)
        let encodedXML = endPointXML.data(using: String.Encoding.utf8)

        theOpQ.addOperation {
            var DestURL = "\(self.dest_jp_server_field.stringValue)/JSSResource/" + endpointType + "/id/0"
            DestURL = DestURL.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
            let encodedURL = NSURL(string: DestURL)
            let request = NSMutableURLRequest(url: encodedURL as! URL)
            request.httpMethod = "POST"
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(self.destBase64Creds)", "Content-Type" : "text/xml", "Accept" : "text/xml"]
            request.httpBody = encodedXML!
            let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: request as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse {
                    //print(httpResponse.statusCode)
                    //print(httpResponse)
                    //print("POST XML-\(endpointCurrent): endpointType: \(endpointType)  endpointNumber: \(endpointCurrent)")
                    DispatchQueue.main.async {
                        self.migrationStatus(endpoint: endpointType, count: endpointCount)
                        //self.object_name_field.stringValue = endpointType
                        self.objects_completed_field.stringValue = "\(endpointCurrent)"
//                        if endpointCount == endpointCurrent && self.changeColor {
//                            self.labelColor(endpoint: endpointType, theColor: self.greenText)
                        //                        }
                        if self.objectsToMigrate.last == endpointType && endpointCount == endpointCurrent {
                            self.go_button.isEnabled = true
                            print("Done")
                        }
                    }
                    // look to see if we are processing the next endpointType - start
                    if self.endpointInProgress != endpointType {
                        self.writeToHistory(stringOfText: "Migrating \(endpointType)\n")
                        self.endpointInProgress = endpointType
                        self.changeColor = true
                        self.POSTsuccessCount = 0
                    }   // look to see if we are processing the next endpointType - end
                    if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
                        self.writeToHistory(stringOfText: "\t\(self.getName(endpoint: endpointType, objectXML: endPointXML))\n")

                        self.POSTsuccessCount += 1
                        if endpointCount == endpointCurrent && self.changeColor {
                            self.labelColor(endpoint: endpointType, theColor: self.greenText)
                        }
//                        print("\n\n---------- Success ----------")
//                        print("\(endPointXML)")
//                        print("---------- Success ----------")
                    } else {
                        // create failed
                        self.labelColor(endpoint: endpointType, theColor: self.yellowText)
                        self.changeColor = false
                        self.writeToHistory(stringOfText: "**** \(self.getName(endpoint: endpointType, objectXML: endPointXML)) - Failed\n")
                        if self.POSTsuccessCount == 0 && endpointCount == endpointCurrent {
                            self.labelColor(endpoint: endpointType, theColor: self.redText)
                        }
                        NSLog("Failed with status code: \(httpResponse.statusCode)\nFailed to create:\n\(endPointXML)\nHTTP response: \(httpResponse)")
                        print("\n\n---------- Fail ----------")
                        print("\(endPointXML)")
                        print("---------- Fail ----------")
                        print("---------- status code ----------")
                        print(httpResponse.statusCode)
                        print("---------- status code ----------\n\n")
//                        print("\n\n---------- response ----------")
//                        print(httpResponse)
//                        print("---------- response ----------\n\n")
//                        401 - wrong username and/or password
//                        409 - unable to create object; already exists or data missing or xml error
                    }
                }
                semaphore.signal()
                if error != nil {
                }
            })
            task.resume()
            semaphore.wait()
        }   // theOpQ.addOperation - end
    }
    
    func RemoveEndpoints(endpointType: String, endPointID: Int, endpointName: String, endpointCurrent: Int, endpointCount: Int) {
        // this is where we delete the endpoint
        //print("removing \(endpointType) with ID \(endPointID)")
        theOpQ.maxConcurrentOperationCount = 1
        let semaphore = DispatchSemaphore(value: 0)

        theOpQ.addOperation {
            var DestURL = "\(self.dest_jp_server_field.stringValue)/JSSResource/" + endpointType + "/id/\(endPointID)"
            DestURL = DestURL.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
            let encodedURL = NSURL(string: DestURL)
            let request = NSMutableURLRequest(url: encodedURL as! URL)
            request.httpMethod = "DELETE"
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(self.destBase64Creds)", "Content-Type" : "text/xml", "Accept" : "text/xml"]
            //request.httpBody = encodedXML!
            let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: request as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse {
                    //print(httpResponse.statusCode)
                    //print(httpResponse)
                    
                    DispatchQueue.main.async {
                        self.migrationStatus(endpoint: endpointType, count: endpointCount)
                        self.objects_completed_field.stringValue = "\(endpointCurrent)"
                        
                        // look to see if we are processing the next endpointType - start
                        if self.endpointInProgress != endpointType {
                            self.endpointInProgress = endpointType
                            self.changeColor = true
                            self.POSTsuccessCount = 0
                            self.writeToHistory(stringOfText: "Removing \(endpointType)\n")
                        }   // look to see if we are processing the next endpointType - end
                        //self.object_name_field.stringValue = endpointType
                        self.objects_completed_field.stringValue = "\(endpointCurrent)"

                    }
                    if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
                        self.writeToHistory(stringOfText: "\t\(endpointName)\n")
                        self.POSTsuccessCount += 1
                        if endpointCount == endpointCurrent && self.changeColor {
                            self.labelColor(endpoint: endpointType, theColor: self.greenText)
                        }
                    
                    } else {
                        self.labelColor(endpoint: endpointType, theColor: self.yellowText)
                        self.changeColor = false
                        self.writeToHistory(stringOfText: "**** Failed to remove: \(endpointName)\n")
                        if self.POSTsuccessCount == 0 && endpointCount == endpointCurrent {
                            self.labelColor(endpoint: endpointType, theColor: self.redText)
                        }
                        print("\n\n---------- Fail ----------")
                        print("\(endPointID)")
                        print("---------- Fail ----------\n\n")
                        print("\n\n---------- status code ----------")
                        print(httpResponse.statusCode)
                        print("---------- status code ----------")
                    }
                    
                }
                if self.objectsToMigrate.last == endpointType && endpointCount == endpointCurrent {
                    // check for file that allows deleting data from destination server, delete if found - start
                    self.rmDELETE()
                    // check for file that allows deleting data from destination server, delete if found - end
                    self.go_button.isEnabled = true
                    print("Done")
                }
                semaphore.signal()
                if error != nil {
                }
            })  // let task = session.dataTask -end
            task.resume()
            semaphore.wait()
        }   // theOpQ.addOperation - end
    }
    
//============================= Utility functions =============================
    
    func alert_dialog(header: String, message: String) {
        let dialog: NSAlert = NSAlert()
        dialog.messageText = header
        dialog.informativeText = message
        dialog.alertStyle = NSAlertStyle.warning
        dialog.addButton(withTitle: "OK")
        dialog.runModal()
        //return true
    }   // func alert_dialog - end
    
    func checkURL(theUrl: String) -> Int8 {
        
        var port = ""
        let task_telnet = Process()
        let str = theUrl.lowercased().replacingOccurrences(of: "https://", with: "")
        
        var str_array = str.components(separatedBy: ":")
        
        let fqdn = str_array[0]
        
        if str_array.count > 1 {
            let port_array = str_array[1].components(separatedBy: "/")
            port = port_array[0]
        } else {
            port = "443"
        }
        
        task_telnet.launchPath = "/bin/bash"
        task_telnet.arguments = ["-c", "nc -z -G 10 \(fqdn) \(port)"]
        
        task_telnet.launch()
        task_telnet.waitUntilExit()
        let result = task_telnet.terminationStatus
        
        return(Int8(result))
    }   // func telnetServer - end
    
//    func checkURL(theURL: String) -> Bool {
//        var isValid = false
//        if let theUrlEncoded = NSURL(string: theURL) {
//            do {
//                let availCheck = try String(contentsOf: theUrlEncoded as URL)
//                print("\(availCheck)")
//                isValid = true
//            } catch {
//                print("could not load \(theURL)")
//                isValid = false
//            }
//        } else {
//            print("bad URL: \(theURL)")
//            return false
//        }
//        return isValid
//    }

    func clearProcessingFields() {
        DispatchQueue.main.async {
            self.get_name_field.stringValue = ""
            self.get_completed_field.stringValue = ""
            self.get_found_field.stringValue = ""
            self.object_name_field.stringValue = ""
            self.objects_completed_field.stringValue = ""
            self.objects_found_field.stringValue = ""
        }
    }
    
    func getCurrentTime() -> String {
        let date = NSDate()
        let date_formatter = DateFormatter()
        date_formatter.dateFormat = "YYYYMMdd_HHmmss"
        let stringDate = date_formatter.string(from: date as Date)
        
        return stringDate
    }
    
    func getName(endpoint: String, objectXML: String) -> String {
        var theName: String = ""
        var dropChars: Int = 0
        if let nameTemp = objectXML.range(of: "<name>") {
            let firstPart = String(objectXML.characters.prefix(through: nameTemp.upperBound).dropLast())
            dropChars = firstPart.characters.count
        }
        if let nameTmp = objectXML.range(of: "</name>") {
            let nameTmp2 = String(objectXML.characters.prefix(through: nameTmp.lowerBound))
            theName = String(nameTmp2.characters.dropFirst(dropChars).dropLast())
        }
        return(theName)
    }
    
    func getStatusInit(endpoint: String, count: Int) {
        self.get_name_field.stringValue = endpoint
        self.get_found_field.stringValue = "\(count)"
        self.get_completed_field.stringValue = "0"
    }
    
    func getStatusUpdate(endpoint: String, count: Int) {
            //self.get_name_field.stringValue = endpoint
            //self.get_found_field.stringValue = "\(count)"
            self.get_completed_field.stringValue = "\(count)"
    }
    
    func historyCleanup() {
        var historyArray: [String] = []
        var historyCount: Int = 0
        do {
            let historyFiles = try fm.contentsOfDirectory(atPath: historyPath!)
            
            for historyFile in historyFiles {
                let filePath: String = historyPath! + historyFile
                historyArray.append(filePath)
            }
            //            print(String(historyArray.count) + " files found:\n")
            historyArray.sort()
            historyCount = historyArray.count
            // remove old history files
            if historyCount-1 >= maxHistory {
                for i in (0..<historyCount-maxHistory) {
                    //print(i)
                    NSLog("Deleting: " + historyArray[i])
                    
                    do {
                        try fm.removeItem(atPath: historyArray[i])
                    }
                    catch let error as NSError {
                        print("Ooops! Something went wrong: \(error)")
                    }
                }
            }
        } catch {
            print("no history")
        }
    }   // func historyCleanup - end
    
    func migrationStatus(endpoint: String, count: Int) {
        object_name_field.stringValue = endpoint
        objects_found_field.stringValue = "\(count)"
    }
    
    func labelColor(endpoint: String, theColor: NSColor) {
        switch endpoint {
        case "buildings":
            building_label_field.textColor = theColor
        case "departments":
            departments_label_field.textColor = theColor
        case "sites":
            sites_label_field.textColor = theColor
        case "categories":
            categories_label_field.textColor = theColor
        case "distributionpoints":
            file_shares_label_field.textColor = theColor
        case "softwareupdateservers":
            sus_label_field.textColor = theColor
        case "netbootservers":
            netboot_label_field.textColor = theColor
        case "computerextensionattributes":
            extension_attributes_label_field.textColor = theColor
        case "scripts":
            scripts_label_field.textColor = theColor
        case "computergroups":
            smart_groups_label_field.textColor = theColor
        case "networksegments":
            network_segments_label_field.textColor = theColor
        case "packages":
            packages_label_field.textColor = theColor
        case "printers":
            printers_label_field.textColor = theColor
        case "policies":
            policies_label_field.textColor = theColor
        default:
            print("unknown label")
        }
    }
    
    func rmDELETE() {
        var isDir: ObjCBool = false
        if (self.fm.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/DELETE", isDirectory: &isDir)) {
            do {
                try self.fm.removeItem(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/DELETE")
            }
            catch let error as NSError {
                NSLog("Unable to delete file! Something went wrong: \(error)")
            }
        }
    }
    
    func SaveSettings() {
        //if !wipe_data {
            plistData["source_jp_server"] = source_jp_server_field.stringValue as AnyObject?
            plistData["source_user"] = source_user_field.stringValue as AnyObject?
            plistData["dest_jp_server"] = dest_jp_server_field.stringValue as AnyObject?
            plistData["dest_user"] = dest_user_field.stringValue as AnyObject?
            plistData["maxHistory"] = maxHistory as AnyObject?
            (plistData as NSDictionary).write(toFile: plistPath!, atomically: false)
        //}
    }
    
    func writeToHistory(stringOfText: String) {
        self.historyFileW?.seekToEndOfFile()
        let historyText = (stringOfText as NSString).data(using: String.Encoding.utf8.rawValue)
        self.historyFileW?.write(historyText!)
    }
    
    override func viewDidAppear() {
        //self.all_groups_button.setButtonType(NSSwitchButton)
        self.view.layer?.backgroundColor = CGColor(red: 0x11/255.0, green: 0x1E/255.0, blue: 0x3A/255.0, alpha: 1.0)
        let def_plist = Bundle.main.path(forResource: "settings", ofType: "plist")!
        var isDir: ObjCBool = true
        
        // Create Application Support folder for the app if missing - start
        let app_support_path = NSHomeDirectory() + "/Library/Application Support/jamf-migrator"
        if !(fm.fileExists(atPath: app_support_path, isDirectory: &isDir)) {
            let manager = FileManager.default
            do {
                try manager.createDirectory(atPath: app_support_path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                NSLog("Problem creating '/Library/Application Support/jamf-migrator' folder:  \(error)")
            }
        }
        // Create Application Support folder for the app if missing - end
        
        // Create preference file if missing - start
        isDir = true
        if !(fm.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/settings.plist", isDirectory: &isDir)) {
            do {
                try fm.copyItem(atPath: def_plist, toPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/settings.plist")
                //migrator.makeKeyAndOrderFront(self)
            }
            catch let error as NSError {
                NSLog("File copy failed! Something went wrong: \(error)")
            }
        }
        // Create preference file if missing - end
        
        // check for file that allows deleting data from destination server, delete if found - start
        self.rmDELETE()
        // check for file that allows deleting data from destination server, delete if found - end
        
        // read environment settings - start
        let plistXML = FileManager.default.contents(atPath: plistPath!)!
        do{
            plistData = try PropertyListSerialization.propertyList(from: plistXML,
                                                                   options: .mutableContainersAndLeaves,
                                                                   format: &format)
                as! [String:AnyObject]
        }
        catch{
            NSLog("Error reading plist: \(error), format: \(format)")
        }
        if plistData["source_jp_server"] != nil {
            source_jp_server = plistData["source_jp_server"] as! String
            source_jp_server_field.stringValue = source_jp_server
        }
        if plistData["source_user"] != nil {
            source_user = plistData["source_user"] as! String
            source_user_field.stringValue = source_user
        }
        if plistData["dest_jp_server"] != nil {
            dest_jp_server = plistData["dest_jp_server"] as! String
            dest_jp_server_field.stringValue = dest_jp_server
        }
        if plistData["dest_user"] != nil {
            dest_user = plistData["dest_user"] as! String
            dest_user_field.stringValue = dest_user
        }
        if plistData["maxHistory"] != nil {
            maxHistory = plistData["maxHistory"] as! Int
        }
        // read environment settings - end

        source_jp_server_field.becomeFirstResponder()

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        // Sellect all items to be migrated
        allNone_button.state = 1
        building_button.state = 1
        categories_button.state = 1
        dept_button.state = 1
        sites_button.state = 1
        netboot_button.state = 1
        sus_button.state = 1
        fileshares_button.state = 1
        ext_attribs_button.state = 1
        smart_comp_grps_button.state = 1
        scripts_button.state = 1
        networks_button.state = 1
        packages_button.state = 1
        printers_button.state = 1
        policies_button.state = 1

        source_jp_server_field.becomeFirstResponder()
        go_button.isEnabled = true
        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    override func viewDidDisappear() {
        // Insert code here to tear down your application
        SaveSettings()
        historyCleanup()
    }
    
    // http://timekl.com/blog/2015/08/21/shipping-an-app-with-app-transport-security/
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    

    // handle untrusted certs?
//    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
//        
//        completionHandler(Foundation.URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
//        
//    }
}

