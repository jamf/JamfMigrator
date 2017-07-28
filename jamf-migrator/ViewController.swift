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

class ViewController: NSViewController, URLSessionDelegate, NSTableViewDelegate, NSTableViewDataSource {

    // Main Window
    @IBOutlet var migrator_window: NSView!
    @IBOutlet weak var modeTab_TabView: NSTabView!
    
    // Help Window
    @IBAction func showHelpWindow(_ sender: AnyObject) {
        // 1
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let helpWindowController = storyboard.instantiateController(withIdentifier: "Help View Controller") as! NSWindowController
        
        if let helpWindow = helpWindowController.window {
            
            // 2
            let helpViewController = helpWindow.contentViewController as! HelpViewController
            
            // 3
            let application = NSApplication.shared()
            application.runModal(for: helpWindow)
            // 4
            helpWindow.close()
        }
    }

    
    // Buttons
    @IBOutlet weak var allNone_button: NSButton!
    @IBOutlet weak var advcompsearch_button: NSButton!
    @IBOutlet weak var building_button: NSButton!
    @IBOutlet weak var categories_button: NSButton!
    @IBOutlet weak var computers_button: NSButton!
    @IBOutlet weak var dept_button: NSButton!
    @IBOutlet weak var sites_button: NSButton!
    @IBOutlet weak var fileshares_button: NSButton!
    @IBOutlet weak var sus_button: NSButton!
    @IBOutlet weak var ldapservers_button: NSButton!
    @IBOutlet weak var netboot_button: NSButton!
    @IBOutlet weak var osxconfigurationprofiles_button: NSButton!
//    @IBOutlet weak var all_groups_button: NSButton!
//    @IBOutlet weak var all_groups_button1: NSButton!
//    @IBOutlet weak var static_comp_grp_button: NSButton!
    @IBOutlet weak var ext_attribs_button: NSButton!
    @IBOutlet weak var scripts_button: NSButton!
    @IBOutlet weak var smart_comp_grps_button: NSButton!
    @IBOutlet weak var static_comp_grps_button: NSButton!
    @IBOutlet weak var networks_button: NSButton!
    @IBOutlet weak var packages_button: NSButton!
    @IBOutlet weak var printers_button: NSButton!
    @IBOutlet weak var policies_button: NSButton!
    @IBOutlet weak var users_button: NSButton!
    @IBOutlet weak var go_button: NSButton!
    
    // Migration mode tabs/var
    @IBOutlet weak var bulk_tabViewItem: NSTabViewItem! // bulk_tabViewItem.tabState.rawValue = 0 if active, 1 if not active
    @IBOutlet weak var selective_tabViewItem: NSTabViewItem!
    @IBOutlet weak var sectionToMigrate_button: NSPopUpButton!
    var migrationMode = ""  // either buld or selective
    var goSender = ""
    
    // button labels
    @IBOutlet weak var advcompsearch_label_field: NSTextField!
    @IBOutlet weak var building_label_field: NSTextField!
    @IBOutlet weak var categories_label_field: NSTextField!
    @IBOutlet weak var computers_label_field: NSTextField!
    @IBOutlet weak var departments_label_field: NSTextField!
    @IBOutlet weak var sites_label_field: NSTextField!
    @IBOutlet weak var file_shares_label_field: NSTextField!
    @IBOutlet weak var sus_label_field: NSTextField!
    @IBOutlet weak var ldapservers_label_field: NSTextField!
    @IBOutlet weak var netboot_label_field: NSTextField!
    @IBOutlet weak var osxconfigurationprofiles_label_field: NSTextField!
    @IBOutlet weak var extension_attributes_label_field: NSTextField!
    @IBOutlet weak var scripts_label_field: NSTextField!
    @IBOutlet weak var smart_groups_label_field: NSTextField!
    @IBOutlet weak var static_groups_label_field: NSTextField!
    @IBOutlet weak var network_segments_label_field: NSTextField!
    @IBOutlet weak var packages_label_field: NSTextField!
    @IBOutlet weak var printers_label_field: NSTextField!
    @IBOutlet weak var policies_label_field: NSTextField!
    @IBOutlet weak var users_label_field: NSTextField!
    
    @IBOutlet weak var migrateOrRemove_label_field: NSTextField!
    
    // Source and destination fields
    @IBOutlet weak var source_jp_server_field: NSTextField!
    @IBOutlet weak var source_user_field: NSTextField!
    @IBOutlet weak var source_pwd_field: NSSecureTextField!
    @IBOutlet weak var dest_jp_server_field: NSTextField!
    @IBOutlet weak var dest_user_field: NSTextField!
    @IBOutlet weak var dest_pwd_field: NSSecureTextField!
    
    // selective migration - start
        // source / destination tables
        @IBOutlet weak var srcSrvTableView: NSTableView!
        @IBOutlet weak var desSrvTableView: NSTableView!
    
        // source / destination array / dictionary of items
        var sourceDataArray:[String] = []
        var targetDataArray:[String] = []
        var availableIDsToMigDict:[String:Int] = [:]   // something like xmlName, xmlID
        var availableObjsToMigDict:[Int:String] = [:]   // something like xmlID, xmlName
    
        // destination TextFieldCells
        @IBOutlet weak var destTextCell_TextFieldCell: NSTextFieldCell!
        @IBOutlet weak var dest_TableColumn: NSTableColumn!
    // selective migration - end
    
    var isDir: ObjCBool = false
    
    // command line switches
    var debug = false
    
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
    let safeCharSet = CharacterSet.alphanumerics
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
    
    var xmlName = ""
    var destEPs = [String:Int]()
    var currentEPs = [String:Int]()
    var currentEndpointID = 0
    var progressCountArray = [String:Int]() // track if post/put was successful
    
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
    
    // This order must match the drop down for selective migration
    var AllEndpointsArray: [String] = ["advancedcomputersearches", "buildings", "categories", "computergroups", "computers", "osxconfigurationprofiles", "departments", "computerextensionattributes", "distributionpoints", "ldapservers", "netbootservers", "networksegments", "packages", "policies", "printers", "scripts", "sites", "softwareupdateservers", "users"]
    
    var getEndpointInProgress: String = ""     // end point currently in the GET queue
    var endpointInProgress: String = ""     // end point currently in the POST queue
    var endpointName: String = ""
    var POSTsuccessCount: Int = 0
    var failedCount: Int = 0
    var postCount: Int = 1
    
    @IBOutlet weak var mySpinner_ImageView: NSImageView!
    var theImage:[NSImage] = [NSImage(named: "0.png")!, NSImage(named: "1.png")!, NSImage(named: "2.png")!, NSImage(named: "3.png")!, NSImage(named: "4.png")!, NSImage(named: "5.png")!, NSImage(named: "6.png")!, NSImage(named: "7.png")!, NSImage(named: "8.png")!, NSImage(named: "9.png")!, NSImage(named: "10.png")!, NSImage(named: "11.png")!]
    var showSpinner = false
    
    // group counters
    var smartCount = 0
    var staticCount = 0
    var ComputerGroupType = ""  // either smart or static
    //var groupCheckArray: [Bool] = []

    
    // define list of items to migrate
    var objectsToMigrate: [String] = []
    
    var wipe_data: Bool = false
    
    let fm = FileManager()
    var theOpQ = OperationQueue() // create operation queue for API calls
    var theCreateQ = OperationQueue() // create operation queue for API POST/PUT calls
    
    var authQ = DispatchQueue(label: "com.jamf.auth")
    var theModeQ = DispatchQueue(label: "com.jamf.addRemove")
    var theSpinnerQ = DispatchQueue(label: "com.jamf.spinner")
    var destEPQ = DispatchQueue(label: "com.jamf.destEPs")
    
    var migrateOrWipe: String = ""
    var httpStatusCode: Int = 0
    var URLisValid: Bool = true
    var processGroup = DispatchGroup()
    
    @IBAction func showHistoryFolder(_ sender: Any) {
        isDir = true
        if (self.fm.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/history", isDirectory: &isDir)) {
            NSWorkspace.shared().openFile(NSHomeDirectory() + "/Library/Application Support/jamf-migrator/history")
        } else {
            alert_dialog(header: "Alert", message: "There are currently no history files to display.")
        }
    }

    @IBAction func toggleAllNone(_ sender: NSButton) {
        self.allNone_button.state = (
            self.building_button.state == 1
            && self.advcompsearch_button.state == 1
            && self.categories_button.state == 1
            && self.computers_button.state == 1
            && self.dept_button.state == 1
            && self.fileshares_button.state == 1
            && self.sus_button.state == 1
            && self.ldapservers_button.state == 1
            && self.netboot_button.state == 1
            && self.osxconfigurationprofiles_button.state == 1
            && self.smart_comp_grps_button.state == 1
            && self.static_comp_grps_button.state == 1
            && self.ext_attribs_button.state == 1
            && self.sites_button.state == 1
            && self.scripts_button.state == 1
            && self.networks_button.state == 1
            && self.packages_button.state == 1
            && self.printers_button.state == 1
            && self.policies_button.state == 1
            && self.users_button.state == 1) ? 1 : 0;
    }
    
    @IBAction func allNone(_ sender: Any) {
        self.advcompsearch_button.state = self.allNone_button.state
        self.building_button.state = self.allNone_button.state
        self.categories_button.state = self.allNone_button.state
        self.computers_button.state = self.allNone_button.state
        self.dept_button.state = self.allNone_button.state
        self.fileshares_button.state = self.allNone_button.state
        self.sus_button.state = self.allNone_button.state
        self.ldapservers_button.state = self.allNone_button.state
        self.netboot_button.state = self.allNone_button.state
        self.osxconfigurationprofiles_button.state = self.allNone_button.state
        self.smart_comp_grps_button.state = self.allNone_button.state
        self.static_comp_grps_button.state = self.allNone_button.state
        self.ext_attribs_button.state = self.allNone_button.state
        self.sites_button.state = self.allNone_button.state
        self.scripts_button.state = self.allNone_button.state
        self.networks_button.state = self.allNone_button.state
        self.packages_button.state = self.allNone_button.state
        self.printers_button.state = self.allNone_button.state
        self.policies_button.state = self.allNone_button.state
        self.users_button.state = self.allNone_button.state
    }
    
    @IBAction func sectionToMigrate(_ sender: Any) {
        objectsToMigrate.removeAll()
        sourceDataArray.removeAll()
        srcSrvTableView.reloadData()
        targetDataArray.removeAll()
        desSrvTableView.reloadData()
        if sectionToMigrate_button.indexOfSelectedItem > 0 {
            objectsToMigrate.append(AllEndpointsArray[sectionToMigrate_button.indexOfSelectedItem-1])
            Go(sender: self)
            NSLog("Selectively migrating: \(objectsToMigrate)")
        }
    }
    
    @IBAction func Go(sender: AnyObject) {
        if debug { writeToHistory(stringOfText: "[- debug -] go sender tag: \(sender.tag)\n") }
        // determine if we got here from the Go button or selectToMigrate button
        if sender.tag != nil {
            self.goSender = "goButton"
        } else {
            self.goSender = "selectToMigrateButton"
        }
        if debug { writeToHistory(stringOfText: "[- debug -] Go button pressed from: \(goSender)\n") }
        
        // which tab are we on - start
        if bulk_tabViewItem.tabState.rawValue == 0 {
            migrationMode = "bulk"
        } else {
            migrationMode = "selective"
        }
        // which tab are we on - end

        //self.go_button.isEnabled = false
        goButtonEnabled(button_status: false)
        clearProcessingFields()
        currentEPs.removeAll()

        // credentials were entered check - start
        if source_user_field.stringValue == "" || source_pwd_field.stringValue == "" {
            alert_dialog(header: "Alert", message: "Must provide both a username and password for the source server.")
            //self.go_button.isEnabled = true
            goButtonEnabled(button_status: true)
            return
        }
        if dest_user_field.stringValue == "" || dest_pwd_field.stringValue == "" {
            alert_dialog(header: "Alert", message: "Must provide both a username and password for the destination server.")
            //self.go_button.isEnabled = true
            goButtonEnabled(button_status: true)
            return
        }
        // credentials check - end
        
        // set credentials / servers - start
        self.source_jp_server = source_jp_server_field.stringValue
        self.source_user = source_user_field.stringValue.addingPercentEncoding(withAllowedCharacters: safeCharSet)!
        self.source_pass = source_pwd_field.stringValue.addingPercentEncoding(withAllowedCharacters: safeCharSet)!
        
        self.dest_jp_server = dest_jp_server_field.stringValue
        self.dest_user = dest_user_field.stringValue.addingPercentEncoding(withAllowedCharacters: safeCharSet)!
        self.dest_pass = dest_pwd_field.stringValue.addingPercentEncoding(withAllowedCharacters: safeCharSet)!
        // set credentials / servers - end
        
        // server is reachable - start
        if !(checkURL(theUrl: self.source_jp_server) == 0) {
            self.alert_dialog(header: "Attention", message: "The source server, \(self.source_jp_server), URL could not be contacted.")
            //self.go_button.isEnabled = true
            goButtonEnabled(button_status: true)
            return
        }
        if !(checkURL(theUrl: self.dest_jp_server) == 0) {
            self.alert_dialog(header: "Attention", message: "The destination, \(self.dest_jp_server), server URL could not be contacted.")
            //self.go_button.isEnabled = true
            goButtonEnabled(button_status: true)
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
                                    NSLog("Destination server response: \(String(describing: response))")
                                    if(!self.theOpQ.isSuspended) {
                                        self.startMigrating()
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        //print("Destination server response: \(response)")
                                        NSLog("Destination server response: \(String(describing: response))")
                                        self.alert_dialog(header: "Attention", message: "The destination server URL could not be validated.")
                                    }
                                    
                                    NSLog("Failed to connect to destination server.")
                                    //self.go_button.isEnabled = true
                                    self.goButtonEnabled(button_status: true)
                                    return
                                }
                            }   // let task for destinationURL - end
                            
                            task_destinationURL.resume()
                            // verify source destination URL - end
                            
                        } else {
                            DispatchQueue.main.async {
                                self.alert_dialog(header: "Attention", message: "The source server URL could not be validated.")
                            }
                            NSLog("Failed to connect source server.")
                            //self.go_button.isEnabled = true
                            self.goButtonEnabled(button_status: true)
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

    }
    
//    @IBAction func SmartAndStaticGroups(sender: AnyObject) {
//        self.smart_comp_grps_button.state = self.all_groups_button.state
//        self.static_comp_grp_button.state = self.all_groups_button.state
//    }

    @IBAction func QuitNow(sender: AnyObject) {
        // check for file that sets mode to delete data from destination server, delete if found - start
        rmDELETE()
        // check for file that allows deleting data from destination server, delete if found - end
        //self.go_button.isEnabled = true
        self.goButtonEnabled(button_status: true)
        NSApplication.shared().terminate(self)
    }
    
//================================= migration functions =================================//
    
    func authCheck(f_sourceURL: String, f_credentials: String, completion: @escaping (Bool) -> Void) {
        var validCredentials:Bool = false
        if self.debug { self.writeToHistory(stringOfText: "[- debug -] --- checking authentication to: \(f_sourceURL)\n") }
        //theOpQ.maxConcurrentOperationCount = 1
        //let semaphore = DispatchSemaphore(value: 0)
        //print("operations in Auth que: \(theOpQ.operationCount)")
        //print("operations Auth que: \(theOpQ.operations)")
        
        authQ.sync {
            var myURL = "\(f_sourceURL)/JSSResource/buildings"
            myURL = myURL.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
            if self.debug { self.writeToHistory(stringOfText: "[- debug -] checking: \(myURL)\n") }

            let encodedURL = NSURL(string: myURL)
            let request = NSMutableURLRequest(url: encodedURL! as URL)
            //let request = NSMutableURLRequest(url: encodedURL as! URL, cachePolicy: NSURLRequest.CachePolicy(rawValue: 1)!, timeoutInterval: 10)
            request.httpMethod = "GET"
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(f_credentials)", "Content-Type" : "application/json", "Accept" : "application/json"]
            let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: request as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse {
                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(myURL) auth check httpResponse: \(httpResponse.statusCode)\n") }
                    
                    if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(myURL) auth httpResponse, between 199 and 299: \(httpResponse.statusCode)\n") }
                        validCredentials = true
                        completion(validCredentials)
                    } else {
                        if self.debug { self.writeToHistory(stringOfText: "\n\n[- debug -] ---------- status code ----------\n") }
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(httpResponse.statusCode)\n") }
                        self.httpStatusCode = httpResponse.statusCode
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] ---------- status code ----------\n") }
                        if self.debug { self.writeToHistory(stringOfText: "\n\n[- debug -] ---------- response ----------\n") }
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(httpResponse)\n") }
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] ---------- response ----------\n\n") }
                        self.theOpQ.cancelAllOperations()
                        switch self.httpStatusCode {
                        case 401:
                            self.alert_dialog(header: "Authentication Failure", message: "Please verify username and password for:\n\(f_sourceURL)")
                        default:
                            self.alert_dialog(header: "Error", message: "An unknown error occured trying to query the source server.")
                        }
                        //                        401 - wrong username and/or password
                        //                        409 - unable to create object; already exists or data missing or xml error
                        //self.go_button.isEnabled = true
                        self.goButtonEnabled(button_status: true)
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
        if self.debug { self.writeToHistory(stringOfText: "[- debug -] Start Migrating/Removal\n") }
        // check for file that allow deleting data from destination server - start
 //       var isDir: ObjCBool = false
        if (fm.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/DELETE", isDirectory: &isDir)) {
            if self.debug { self.writeToHistory(stringOfText: "[- debug -] Removing data from destination server - \(dest_jp_server_field.stringValue)\n") }
            wipe_data = true
            
            migrateOrWipe = "----------- Starting To Wipe Data -----------\n"
        } else {
            if self.debug { self.writeToHistory(stringOfText: "[- debug -] Migrating data from \(source_jp_server_field.stringValue) to \(dest_jp_server_field.stringValue).\n") }
            // verify source and destination are not the same - start
            if source_jp_server_field.stringValue == dest_jp_server_field.stringValue {
                alert_dialog(header: "Alert", message: "Source and destination servers cannot be the same.")
                //self.go_button.isEnabled = true
                self.goButtonEnabled(button_status: true)
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
        
        // list the items in the order they need to be migrated
        if migrationMode == "bulk" {
            // initialize list of items to migrate then add what we want - start
            objectsToMigrate.removeAll()
            //groupCheckArray.removeAll()
            if building_button.state == 1 {
                objectsToMigrate += ["buildings"]
            }
            
            if dept_button.state == 1 {
                objectsToMigrate += ["departments"]
            }
            
            if ldapservers_button.state == 1 {
                objectsToMigrate += ["ldapservers"]
            }
            
            if sites_button.state == 1 {
                objectsToMigrate += ["sites"]
            }
            
            if users_button.state == 1 {
                objectsToMigrate += ["users"]
            }
            
            if fileshares_button.state == 1 {
                objectsToMigrate += ["distributionpoints"]
            }
            
            if computers_button.state == 1 {
                objectsToMigrate += ["computers"]
            }
            
            if categories_button.state == 1 {
                objectsToMigrate += ["categories"]
            }
            
            if sus_button.state == 1 {
                objectsToMigrate += ["softwareupdateservers"]
            }
            
            if netboot_button.state == 1 {
                objectsToMigrate += ["netbootservers"]
            }
            
            if ext_attribs_button.state == 1 {
                objectsToMigrate += ["computerextensionattributes"]
            }
            
            if advcompsearch_button.state == 1 {
                objectsToMigrate += ["advancedcomputersearches"]
            }
            
            if scripts_button.state == 1 {
                objectsToMigrate += ["scripts"]
            }
            
            if smart_comp_grps_button.state == 1 || static_comp_grps_button.state == 1 {
                objectsToMigrate += ["computergroups"]
            }
            
            if osxconfigurationprofiles_button.state == 1 {
                objectsToMigrate += ["osxconfigurationprofiles"]
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
            // initialize list of items to migrate then add what we want - end
            
            
            if wipe_data {
                if objectsToMigrate.count > 0 {
                    // set server and credentials used for wipe
                    sourceBase64Creds = destBase64Creds
                    self.source_jp_server = dest_jp_server
                    // move sites to the end of the array
                    var siteIndex = objectsToMigrate.index(of: "users")
                    if siteIndex != nil {
                        let siteTmp = objectsToMigrate.remove(at: siteIndex!)
                        objectsToMigrate.insert(siteTmp, at: objectsToMigrate.count)
                    }
                    siteIndex = objectsToMigrate.index(of: "sites")
                    if siteIndex != nil {
                        let siteTmp = objectsToMigrate.remove(at: siteIndex!)
                        objectsToMigrate.insert(siteTmp, at: objectsToMigrate.count)
                    }

                } else {
                    //go_button.isEnabled = true
                    self.goButtonEnabled(button_status: true)
                    return
                }// end if objectsToMigrate - end
            }   // if wipe_data - end
        }
        
        if objectsToMigrate.count == 0 {
            if self.debug { self.writeToHistory(stringOfText: "[- debug -] nothing selected to migrate/remove.\n") }
            self.goButtonEnabled(button_status: true)
            return
        }
        
//        historyFile = getCurrentTime() + "_migration.txt"
//        isDir = false
//        if !(fm.fileExists(atPath: historyPath! + historyFile, isDirectory: &isDir)) {
//            _ = try? fm.createDirectory(atPath: historyPath!, withIntermediateDirectories: true, attributes: nil )
//        }
//        fm.createFile(atPath: historyPath! + historyFile, contents: nil, attributes: nil)
//        historyFileW = FileHandle(forUpdatingAtPath: (historyPath! + historyFile))
        
        writeToHistory(stringOfText: migrateOrWipe)
        //go_button.isEnabled = false
        self.goButtonEnabled(button_status: false)
        
        // make sure the labels can change color when we start
        changeColor = true
        
        // set all the labels to white - start
        DispatchQueue.main.async {
            for i in (0..<self.AllEndpointsArray.count) {
                self.labelColor(endpoint: self.AllEndpointsArray[i], theColor: self.whiteText)
            }
        }
        // set all the labels to white - end
        
        if self.debug { self.writeToHistory(stringOfText: "[- debug -] migrating/removing \(objectsToMigrate.count) sections\n") }
            // loop through process of migrating or removing - start
            for i in (0..<objectsToMigrate.count) {
                if self.debug { self.writeToHistory(stringOfText: "[- debug -] Starting to process \(objectsToMigrate[i])\n") }
                if (goSender == "goButton" && migrationMode == "bulk") || (goSender == "selectToMigrateButton") {
                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] getting endpoint: \(objectsToMigrate[i])\n") }
                    self.getEndpoints(endpoint: objectsToMigrate[i])  {
                        (result: String) in
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] getEndpoints result: \(result)\n") }
                    }
                } else {
                    self.existingEndpoints(destEndpoint: "\(objectsToMigrate[0])")  {
                        (result: String) in
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] Returned from existing endpoints: \(result)\n") }
                        var objToMigrateID = 0
                        for j in (0..<self.targetDataArray.count) {
                            objToMigrateID = self.availableIDsToMigDict[self.targetDataArray[j]]!
                            if !self.wipe_data  {
                                if self.debug { self.writeToHistory(stringOfText: "[- debug -] check for existing object: \(self.availableObjsToMigDict[objToMigrateID]!)\n") }
                                if self.currentEPs[self.availableObjsToMigDict[objToMigrateID]!] != nil {
                                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(self.availableObjsToMigDict[objToMigrateID]!) already exists\n") }
                                    //self.currentEndpointID = self.currentEPs[xmlName]!
                                    self.endPointByID(endpoint: self.objectsToMigrate[0], endpointID: objToMigrateID, endpointCurrent: (j+1), endpointCount: self.targetDataArray.count, action: "update", destEpId: self.currentEPs[self.availableObjsToMigDict[objToMigrateID]!]!)
                                } else {
                                    self.endPointByID(endpoint: self.objectsToMigrate[0], endpointID: objToMigrateID, endpointCurrent: (j+1), endpointCount: self.targetDataArray.count, action: "create", destEpId: 0)
                                }
                                
                                //self.endPointByID(endpoint: objectsToMigrate[0], endpointID: objToMigrateID, endpointCurrent: (j+1), endpointCount: targetDataArray.count, action: "create", destEpId: 0)
                                //self.endPointByID(endpoint: endpoint, endpointID: xmlID, endpointCurrent: (i+1), endpointCount: endpointCount)
                            } else {
                                if self.debug { self.writeToHistory(stringOfText: "[- debug -] selective removal not implemented - would need object ID from destination server rather than source server.\n") }
                            }   // if !self.wipe_data else - end
                        }   // for j in  - end
                }
                }   //for i in - else - end
            }   // loop through process of migrating or removing - end

    }   // func startMigrating - end

    
    func getEndpoints(endpoint: String, completion: (_ result: String) -> Void) {
        if self.debug { self.writeToHistory(stringOfText: "[- debug -] Getting \(endpoint)\n") }
        var endpointParent = ""
        switch endpoint {
        case "advancedcomputersearches":
            endpointParent = "advanced_computer_searches"
        case "computerextensionattributes":
            endpointParent = "computer_extension_attributes"
        case "computergroups":
            endpointParent = "computer_groups"
        case "distributionpoints":
            endpointParent = "distribution_points"
        case "ldapservers":
            endpointParent = "ldap_servers"
        case "netbootservers":
            endpointParent = "netboot_servers"
        case "networksegments":
            endpointParent = "network_segments"
        case "osxconfigurationprofiles":
            endpointParent = "os_x_configuration_profiles"
        case "softwareupdateservers":
            endpointParent = "software_update_servers"
        default:
            endpointParent = "\(endpoint)"
        }
        
        // initialize post/put success count
        if endpoint != "computergroups" {
            progressCountArray["\(endpoint)"] = 0
        } else {
            progressCountArray["smartcomputergroups"] = 0
            progressCountArray["staticcomputergroups"] = 0
        }
        
        
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
            let request = NSMutableURLRequest(url: encodedURL! as URL)
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
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] Getting all endpoints from: \(myURL)\n") }
                        let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                        if let endpointJSON = json as? [String: Any] {
                            //print("endpointJSON: \(endpointJSON))")
                            
                            switch endpoint {
                            case "advancedcomputersearches", "buildings", "categories", "computers", "computerextensionattributes", "departments", "distributionpoints", "ldapservers", "netbootservers", "networksegments", "osxconfigurationprofiles", "packages", "printers", "scripts", "sites", "softwareupdateservers", "users":
                                if let endpointInfo = endpointJSON[endpointParent] as? [Any] {
                                    let endpointCount: Int = endpointInfo.count
                                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] Initial count for \(endpoint) found: \(endpointCount)\n") }
                                    
                                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] Verify empty dictionary of objects - availableObjsToMigDict count: \(self.availableObjsToMigDict.count)\n") }
                                    
//                                    self.availableObjsToMigDict.removeAll()
//                                    self.availableObjsToMigDict = [:]
                                    
                                    if endpointCount > 0 {
                                        
                                        self.existingEndpoints(destEndpoint: "\(endpoint)")  {
                                            (result: String) in
                                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] Returned from existing \(endpoint): \(result)\n") }
                                            
                                            for i in (0..<endpointCount) {
                                                if i == 0 { self.availableObjsToMigDict.removeAll() }

                                                let record = endpointInfo[i] as! [String : AnyObject]
                                                //let xmlID: Int = (record["id"] as! Int)
//                                                if "\(endpoint)" != "computers" {
//                                                    self.xmlName = (record["name"] as! String)
//                                                } else {
//                                                    self.xmlName = (record["name"] as! String)
//                                                    // need to fix, identify duplicate computers by something other than name
//                                                    //                                                    xmlName = (record["udid"] as! String)
//                                                }
                                                self.availableObjsToMigDict[record["id"] as! Int] = record["name"] as! String?
                                                if self.debug { self.writeToHistory(stringOfText: "[- debug -] Current number of \(endpoint) to process: \(self.availableObjsToMigDict.count)\n") }
                                            }   // for i in (0..<endpointCount) end
                                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] Found total of \(self.availableObjsToMigDict.count) \(endpoint) to process\n") }
                                            
                                            var counter = 1
                                            if self.goSender == "goButton" {
                                                for (l_xmlID, l_xmlName) in self.availableObjsToMigDict {
                                                    if !self.wipe_data  {
                                                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] check for ID on \(l_xmlName): \(String(describing: self.currentEPs[l_xmlName]))\n") }
                                                        if self.currentEPs[l_xmlName] != nil {
                                                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(l_xmlName) already exists\n") }
                                                            //self.currentEndpointID = self.currentEPs[l_xmlName]!
                                                            self.endPointByID(endpoint: endpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count, action: "update", destEpId: self.currentEPs[l_xmlName]!)
                                                        } else {
                                                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(l_xmlName) - create\n") }
                                                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] function - endpoint: \(endpoint), endpointID: \(l_xmlID), endpointCurrent: \(counter), endpointCount: \(endpointCount), action: \"create\", destEpId: 0\n") }
                                                            self.endPointByID(endpoint: endpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count, action: "create", destEpId: 0)
                                                        }
                                                        //self.endPointByID(endpoint: endpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: endpointCount, action: "create", destEpId: 0)
                                                    } else {
                                                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] remove - endpoint: \(endpoint)\t endpointID: \(l_xmlID)\t endpointName: \(l_xmlName)\n") }
                                                        self.RemoveEndpoints(endpointType: endpoint, endPointID: l_xmlID, endpointName: l_xmlName, endpointCurrent: counter, endpointCount: self.availableObjsToMigDict.count)
                                                    }   // if !self.wipe_data else - end
                                                    counter+=1
                                                }   // for (l_xmlID, l_xmlName) in availableObjsToMigDict
                                            } else {
                                                // populate source server under the selective tab
                                                for (l_xmlID, l_xmlName) in self.availableObjsToMigDict {
                                                    DispatchQueue.main.async {
                                                        //print("adding \(l_xmlName) to array")
                                                        self.availableIDsToMigDict[l_xmlName] = l_xmlID
                                                        self.sourceDataArray.append(l_xmlName)
                                                        self.srcSrvTableView.reloadData()
                                                    }   // DispatchQueue.main.async - end
                                                    counter+=1
                                                }   // for (l_xmlID, l_xmlName) in availableObjsToMigDict
                                                DispatchQueue.main.async {
                                                    //self.sourceDataArray.sort()
                                                    self.sourceDataArray = self.sourceDataArray.sorted{$0.localizedCompare($1) == .orderedAscending}
                                                    self.srcSrvTableView.reloadData()
                                                }
                                            }   // if self.goSender else - end
//                                                counter += 1
//                                            }   // for (l_xmlID, l_xmlName) in computerPoliciesDict - end
//                                            }   // for i in - end
                                        }   // if endpointCount - end
                                    } // self.existingEndpoints(destEndpoint: "computers")
                                }   // end if let buildings, departments...
                                
                            case "computergroups":
                                if self.debug { self.writeToHistory(stringOfText: "[- debug -] processing computer groups\n") }
                                if let endpointInfo = endpointJSON["computer_groups"] as? [Any] {
                                    
                                    let endpointCount: Int = endpointInfo.count
                                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] groups found: \(endpointCount)\n") }
                                    //self.migrationStatus(endpoint: "computer groups", count: endpointCount)
                                    
                                    var smartGroupDict: [Int: String] = [:]
                                    var staticGroupDict: [Int: String] = [:]
                                    if endpointCount > 0 {
                                        // find number of groups
                                        self.smartCount = 0
                                        self.staticCount = 0
                                        var excludeCount = 0
                                        // split computergroups into smart and static - start
                                        for i in (0..<endpointCount) {
                                            let record = endpointInfo[i] as! [String : AnyObject]
 
                                            let smart: Bool = (record["is_smart"] as! Bool)
                                            if smart {
                                                //self.smartCount += 1
                                                smartGroupDict[record["id"] as! Int] = record["name"] as! String?
                                            } else {
                                                //self.staticCount += 1
                                                staticGroupDict[record["id"] as! Int] = record["name"] as! String?
                                            }
                                        }
                                        // split computergroups into smart and static - end
                                        if self.smart_comp_grps_button.state == 0 {
                                            excludeCount += smartGroupDict.count
                                        }
                                        if self.static_comp_grps_button.state == 0 {
                                            excludeCount += staticGroupDict.count
                                        }
                                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(smartGroupDict.count) smart groups\n") }
                                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(staticGroupDict.count) static groups\n") }
                                        var currentGroupDict: [Int: String] = [:]
                                        // verify we have some groups
                                        for g in (0...1) {
                                            currentGroupDict.removeAll()
                                            var groupCount = 0
                                            var localEndpoint = endpoint
                                            if (self.smart_comp_grps_button.state == 1) && (g == 0) {
                                                currentGroupDict = smartGroupDict
                                                groupCount = currentGroupDict.count
                                                self.ComputerGroupType = "smartcomputergroups"
                                                print("computergroups smart - ComputerGroupType: \(self.ComputerGroupType)")
                                                localEndpoint = "smartcomputergroups"
                                            }
                                            if (self.static_comp_grps_button.state == 1) && (g == 1) {
                                                currentGroupDict = staticGroupDict
                                                groupCount = currentGroupDict.count
                                                self.ComputerGroupType = "staticcomputergroups"
                                                print("computergroups static - ComputerGroupType: \(self.ComputerGroupType)")
                                                localEndpoint = "staticcomputergroups"
                                            }
                                            var counter = 1
                                            for (l_xmlID, l_xmlName) in currentGroupDict {
                                                if l_xmlName != "All Managed Clients" && l_xmlName != "All Managed Servers" {
                                                    if self.goSender == "goButton" {
                                                        if !self.wipe_data  {
                                                            self.endPointByID(endpoint: localEndpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: groupCount, action: "create", destEpId: 0)
                                                        } else {
                                                            self.RemoveEndpoints(endpointType: localEndpoint, endPointID: l_xmlID, endpointName: l_xmlName, endpointCurrent: counter, endpointCount: groupCount)
                                                        }   // if !self.wipe_data else - end
                                                    } else {
                                                        // populate source server under the selective tab
                                                        DispatchQueue.main.async {
                                                            //print("adding \(l_xmlName) to array")
                                                            self.availableIDsToMigDict[l_xmlName] = l_xmlID
                                                            self.sourceDataArray.append(l_xmlName)
                                                            self.srcSrvTableView.reloadData()
                                                        }   // DispatchQueue.main.async - end
                                                    }   // if self.goSender else - end
                                                } else if counter == groupCount {
                                                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] remove - endpoint: \(localEndpoint)\t endpointID: \(l_xmlID)\t endpointName: \(l_xmlName)\n") }
                                                    self.CreateEndpoints(endpointType: localEndpoint, endPointXML: "", endpointCurrent: counter, endpointCount: groupCount, action: "create", destEpId: 0)
                                                }   // if l_xmlName - end
                                                counter += 1
                                            }   // for (l_xmlID, l_xmlName) - end
                                        }   //for g in (0...1) - end
                                    }
                                }   // if let endpointInfo = endpointJSON["computer_groups"] - end

                            case "policies":
                                if self.debug { self.writeToHistory(stringOfText: "[- debug -] processing \(endpoint)\n") }
                                if let endpointInfo = endpointJSON[endpoint] as? [Any] {
                                    let endpointCount: Int = endpointInfo.count
                                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(endpoint) found: \(endpointCount)\n") }
                                    
                                    var computerPoliciesDict: [Int: String] = [:]
                                    if endpointCount > 0 {
                                        
                                        // create dictionary of existing policies
                                        self.existingEndpoints(destEndpoint: "policies")  {
                                            (result: String) in
                                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] Returned from existing endpoints: \(result)\n") }
                                            
                                            for _ in (0..<endpointCount) {
                                                //var nonRemotePolicies = 0
                                                // filter out policies created from casper remote - start
                                                for i in (0..<endpointCount) {
                                                    let record = endpointInfo[i] as! [String : AnyObject]
                                                    let nameCheck = record["name"] as! String
                                                    if nameCheck.range(of:"[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] at", options: .regularExpression) == nil && nameCheck != "Update Inventory" {
                                                        computerPoliciesDict[record["id"] as! Int] = nameCheck
                                                    }
                                                }
                                            }
                                            
                                            let nonRemotePolicies = computerPoliciesDict.count
                                            var counter = 1
                                            for (l_xmlID, l_xmlName) in computerPoliciesDict {
                                                if self.goSender == "goButton" {
                                                    if !self.wipe_data  {
                                                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] check for ID on \(l_xmlName): \(String(describing: self.currentEPs[l_xmlName]))\n") }
                                                        if self.currentEPs[l_xmlName] != nil {
                                                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(l_xmlName) already exists\n") }
                                                            //self.currentEndpointID = self.currentEPs[l_xmlName]!
                                                            self.endPointByID(endpoint: endpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: nonRemotePolicies, action: "update", destEpId: self.currentEPs[l_xmlName]!)
                                                        } else {
                                                            self.endPointByID(endpoint: endpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: nonRemotePolicies, action: "create", destEpId: 0)
                                                        }
                                                        //self.endPointByID(endpoint: endpoint, endpointID: l_xmlID, endpointCurrent: counter, endpointCount: nonRemotePolicies, action: "create", destEpId: 0)
                                                    } else {
                                                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] remove - endpoint: \(endpoint)\t endpointID: \(l_xmlID)\t endpointName: \(l_xmlName)\n") }
                                                        self.RemoveEndpoints(endpointType: endpoint, endPointID: l_xmlID, endpointName: l_xmlName, endpointCurrent: counter, endpointCount: nonRemotePolicies)
                                                    }   // if !self.wipe_data else - end
                                                } else {
                                                    // populate source server under the selective tab
                                                    DispatchQueue.main.async {
                                                        //print("adding \(l_xmlName) to array")
                                                        self.availableIDsToMigDict[l_xmlName] = l_xmlID
                                                        self.sourceDataArray.append(l_xmlName)
                                                        self.srcSrvTableView.reloadData()
                                                    }   // DispatchQueue.main.async - end
                                                }   // if self.goSender else - end
                                                counter += 1
                                            }   // for (l_xmlID, l_xmlName) in computerPoliciesDict - end
                                        }   // if endpointCount > 0
                                    } // self.existingEndpoints(destEndpoint: "advancedcomputersearches")
                                }   //if let endpointInfo = endpointJSON - end
                                
                            default:
                                break
                            }   // switch - end
                        }   // if let endpointJSON - end
                        
                    }

                }   // if let httpResponse as? HTTPURLResponse - end
                semaphore.signal()
                if error != nil {
                }
            })  // let task = session - end
            task.resume()
            semaphore.wait()
            if self.goSender == "selectToMigrateButton" {
                self.goButtonEnabled(button_status: true)
            }

        }   // theOpQ - end
        completion("Got endpoint - \(endpoint)")
    }
    
    func endPointByID(endpoint: String, endpointID: Int, endpointCurrent: Int, endpointCount: Int, action: String, destEpId: Int) {
        theOpQ.maxConcurrentOperationCount = 1
        let semaphore = DispatchSemaphore(value: 0)
        var localEndPointType = endpoint
        if endpoint == "smartcomputergroups" || endpoint == "staticcomputergroups" {
            localEndPointType = "computergroups"
        }
        theOpQ.addOperation {
            var myURL = "\(self.source_jp_server)/JSSResource/\(localEndPointType)/id/\(endpointID)"
            myURL = myURL.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
            let encodedURL = NSURL(string: myURL)
            let request = NSMutableURLRequest(url: encodedURL! as URL)
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
//                    let regexID = try! NSRegularExpression(pattern: "<id>+[0-9]+</id>", options:.caseInsensitive)
//                    PostXML = regexID.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "")

                    //PostXML = PostXML.replacingOccurrences(of: "(?:\\r|\\n)+", with: "", options: .regularExpression)
                    for xmlTag in ["id"] {
                        PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
                    }
 //                   print("\n\nRemoved id tag: \(XMLString)")

                    switch endpoint {
                    case "buildings", "departments", "sites", "categories", "distributionpoints", "netbootservers", "softwareupdateservers", "computerextensionattributes", "scripts", "printers", "osxconfigurationprofiles":
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] processing " + endpoint + " - verbose\n") }
                        //print("\nXML: \(PostXML)")
                        
                        DispatchQueue.main.async {
                            if self.getEndpointInProgress != endpoint {
                                self.endpointInProgress = endpoint
                                self.getStatusInit(endpoint: endpoint, count: endpointCount)
                                
                            }
                            self.get_completed_field.stringValue = "\(endpointCurrent)"
                            
                        }
                        self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId)
                        
                    case "ldapservers":
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] processing ldapservers - verbose\n") }
                        // remove computers that are a member of the smart group from XML
                        let regexComp = try! NSRegularExpression(pattern: "<password_sha256 since=\"9.23\">(.*?)</password_sha256>", options:.caseInsensitive)
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
                        
                        self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId)
                        
                    case "advancedcomputersearches":
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] processing advancedcomputersearches - verbose\n") }
                        // clean up some data from XML
                        for xmlTag in ["computers"] {
                            PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
                        }
                        
                        //print("\nXML: \(PostXML)")
                        
                        if self.getEndpointInProgress != endpoint {
                            self.endpointInProgress = endpoint
                            self.getStatusInit(endpoint: endpoint, count: endpointCount)
                        }
                        self.get_completed_field.stringValue = "\(endpointCurrent)"
                        
                        self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId)
                        
                    
                    case "computers":
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] processing computers - verbose\n") }
                        // clean up some data from XML
                        //for xmlTag in ["package", "mapped_printers", "extension_attributes", "plugins", "applications", "running_services", "certificates", "licensed_software", "computer_group_memberships", "configuration_profiles", "managed", "management_username"] {
                        for xmlTag in ["package", "mapped_printers", "plugins", "running_services", "licensed_software", "computer_group_memberships", "managed", "management_username"] {
                            PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
                        }

                        let regexComp = try! NSRegularExpression(pattern: "<management_password_sha256 since=\"9.23\">(.*?)</management_password_sha256>", options:.caseInsensitive)
                        PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "")
                        PostXML = PostXML.replacingOccurrences(of: "<xprotect_version/>", with: "")
                        //print("\nXML: \(PostXML)")
                        
                        if self.getEndpointInProgress != endpoint {
                            self.endpointInProgress = endpoint
                            self.getStatusInit(endpoint: endpoint, count: endpointCount)
                        }
                        self.get_completed_field.stringValue = "\(endpointCurrent)"
                        
                        self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId)
                        
                    case "networksegments":
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] processing network segments - verbose\n") }
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
                        
                    	self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId)
                    case "computergroups", "smartcomputergroups", "staticcomputergroups":
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] processing smart/static groups - verbose\n") }
                        // remove computers that are a member of a smart group
                        if endpoint == "smartcomputergroups" {
                            let regexComp = try! NSRegularExpression(pattern: "<computers>(.*?)</computers>", options:.caseInsensitive)
                            PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "")
                        }
                        //print("\n\(endpoint) XML: \(PostXML)\n")

                            if self.getEndpointInProgress != endpoint {
                                self.endpointInProgress = endpoint
                                self.getStatusInit(endpoint: endpoint, count: endpointCount)
                        }
                                self.get_completed_field.stringValue = "\(endpointCurrent)"
                        
                    	self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId)
                        
                    case "packages":
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] processing packages - verbose\n") }
                        // remove 'No category assigned' from XML
                        let regexComp = try! NSRegularExpression(pattern: "<category>No category assigned</category>", options:.caseInsensitive)
                        PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<category/>")
                        //print("\nXML: \(PostXML)")
                        
                        if self.getEndpointInProgress != endpoint {
                            self.endpointInProgress = endpoint
                            self.getStatusInit(endpoint: endpoint, count: endpointCount)
                        }
                        self.get_completed_field.stringValue = "\(endpointCurrent)"
                        
                        self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId)
                        
                    case "policies":
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] processing policies - verbose\n") }
                        // remove individual objects that are scoped to the policy from XML
                        for xmlTag in ["self_service_icon", "computers", "allow_users_to_defer", "allow_deferral_until_utc"] {
                            PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
                        }
                        let regexComp = try! NSRegularExpression(pattern: "<management_password_sha256 since=\"9.23\">(.*?)</management_password_sha256>", options:.caseInsensitive)
                        PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "")
                        //print("\nXML: \(PostXML)")
                        
                        if self.getEndpointInProgress != endpoint {
                            self.endpointInProgress = endpoint
                            self.getStatusInit(endpoint: endpoint, count: endpointCount)
                        }
                        self.get_completed_field.stringValue = "\(endpointCurrent)"
                        
                        self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId)
                        
                    case "users":
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] processing users - verbose\n") }
                        // remove individual objects that are scoped to the policy from XML
                        if self.computers_button.state != 1 {
                            let regexComp = try! NSRegularExpression(pattern: "<computers>(.*?)</computers>", options:.caseInsensitive)
                            PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<computers/>")
                        }
                        let regexComp = try! NSRegularExpression(pattern: "<self_service_icon>(.*?)</self_service_icon>", options:.caseInsensitive)
                        PostXML = regexComp.stringByReplacingMatches(in: PostXML, options: [], range: NSRange(0..<PostXML.utf16.count), withTemplate: "<self_service_icon/>")
                        // remove photo reference from XML
                        for xmlTag in ["enable_custom_photo_url", "custom_photo_url","links"] {
                            PostXML = self.rmXmlData(theXML: PostXML, theTag: xmlTag)
                        }
                        //print("\nXML: \(PostXML)")
                        
                        if self.getEndpointInProgress != endpoint {
                            self.endpointInProgress = endpoint
                            self.getStatusInit(endpoint: endpoint, count: endpointCount)
                        }
                        self.get_completed_field.stringValue = "\(endpointCurrent)"
                        
                        self.CreateEndpoints(endpointType: endpoint, endPointXML: PostXML, endpointCurrent: endpointCurrent, endpointCount: endpointCount, action: action, destEpId: destEpId)
                        
                    default:
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] Unknown endpoint: \(endpoint)\n") }
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
    
    func CreateEndpoints(endpointType: String, endPointXML: String, endpointCurrent: Int, endpointCount: Int, action: String, destEpId: Int) {
        // this is where we create the new endpoint
        var DestURL = ""
        let destinationEpId = destEpId
        //if self.debug { self.writeToHistory(stringOfText: "[- debug -] ----- Posting #\(endpointCurrent): \(endpointType) -----\n") }
        theOpQ.maxConcurrentOperationCount = 1
        let semaphore = DispatchSemaphore(value: 0)
        let encodedXML = endPointXML.data(using: String.Encoding.utf8)
        var localEndPointType = endpointType
        if endpointType == "smartcomputergroups" || endpointType == "staticcomputergroups" {
            localEndPointType = "computergroups"
        }
        
        theCreateQ.addOperation {

            DestURL = "\(self.dest_jp_server_field.stringValue)/JSSResource/" + localEndPointType + "/id/\(destinationEpId)"
            DestURL = DestURL.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
            if self.debug { self.writeToHistory(stringOfText: "[- debug -] Action: \(action)\t URL: \(DestURL)\t Object \(endpointCurrent) of \(endpointCount)\n") }
            if self.debug { self.writeToHistory(stringOfText: "[- debug -] Object XML: \(endPointXML)\n") }
            
            if endpointCurrent == 1 {
                self.postCount = 1
            } else {
                self.postCount += 1
                //print("destURL: \(DestURL)\n")
            }
            let encodedURL = NSURL(string: DestURL)
            let request = NSMutableURLRequest(url: encodedURL! as URL)
            if action == "create" {
                request.httpMethod = "POST"
            } else {
                request.httpMethod = "PUT"
            }
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
                        //self.migrationStatus(endpoint: endpointType, count: endpointCount)
                        self.migrationStatus(endpoint: endpointType, count: endpointCount)
                        //self.object_name_field.stringValue = endpointType
                        
                        self.objects_completed_field.stringValue = "\(self.postCount)"
//                        if endpointCount == endpointCurrent && self.changeColor {
//                            self.labelColor(endpoint: endpointType, theColor: self.greenText)
                        //                        }
                        //if self.objectsToMigrate.last == endpointType && endpointCount == endpointCurrent {
                        if self.objectsToMigrate.last == localEndPointType && endpointCount == endpointCurrent {
                            //self.go_button.isEnabled = true
                            self.rmDELETE()
                            self.goButtonEnabled(button_status: true)
                            print("Done")
                        }
                    }
                    // look to see if we are processing the next endpointType - start
                    if self.endpointInProgress != endpointType {
                        self.writeToHistory(stringOfText: "Migrating \(endpointType)\n")
                        self.endpointInProgress = endpointType
//                        self.changeColor = true
                        self.POSTsuccessCount = 0
//                        self.progressCountArray["\(endpointType)"] = 0
                    }   // look to see if we are processing the next localEndPointType - end
                    if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
                        self.writeToHistory(stringOfText: "\t\(self.getName(endpoint: endpointType, objectXML: endPointXML))\n")

                        self.POSTsuccessCount += 1
                        self.progressCountArray["\(endpointType)"] = self.progressCountArray["\(endpointType)"]!+1
                        if endpointCount == endpointCurrent && self.progressCountArray["\(endpointType)"] == endpointCount {
//                            if endpointCount == endpointCurrent && self.changeColor {
                            self.labelColor(endpoint: endpointType, theColor: self.greenText)
                        }
//                        print("\n\n---------- Success ----------")
//                        print("\(endPointXML)")
//                        print("---------- Success ----------")
                    } else {
                        // create failed
                        self.labelColor(endpoint: endpointType, theColor: self.yellowText)
//                        self.changeColor = false
                        self.writeToHistory(stringOfText: "**** \(self.getName(endpoint: endpointType, objectXML: endPointXML)) - Failed\n")
                        // Write xml for degugging - start
                        
                        self.writeToHistory(stringOfText: "\(endPointXML)\n")
                        self.writeToHistory(stringOfText: "HTTP status code: \(httpResponse.statusCode)\n")

                        // Write xml for degugging - end
                        
                        if self.progressCountArray["\(endpointType)"] == 0 && endpointCount == endpointCurrent {
//                        if self.POSTsuccessCount == 0 && endpointCount == endpointCurrent {
                            self.labelColor(endpoint: endpointType, theColor: self.redText)
                        }
                        if self.debug { self.writeToHistory(stringOfText: "\n\n[- debug -] ---------- xml of failed upload ----------\n") }
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(endPointXML)\n") }
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] ---------- status code ----------\n") }
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(httpResponse.statusCode)\n") }
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] ---------- response ----------\n") }
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(httpResponse)\n") }
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] ---------- response ----------\n\n") }
//                        401 - wrong username and/or password
//                        409 - unable to create object; already exists or data missing or xml error
                    }
                }
                if self.debug { self.writeToHistory(stringOfText: "[- debug -] POST or PUT Operation: \(request.httpMethod)\n") }
                
                if self.debug { self.writeToHistory(stringOfText: "[- debug -] endpoint: \(localEndPointType)-\(endpointCurrent)\t Total: \(endpointCount)\t Succeeded: \(self.POSTsuccessCount)\t No Failures: \(self.changeColor)\t SuccessArray \(String(describing: self.progressCountArray["\(localEndPointType)"]))") }
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
        theOpQ.maxConcurrentOperationCount = 3
        let semaphore = DispatchSemaphore(value: 0)
        var localEndPointType = endpointType
        if endpointType == "smartcomputergroups" || endpointType == "staticcomputergroups" {
            localEndPointType = "computergroups"
        }

        theOpQ.addOperation {
            var DestURL = "\(self.dest_jp_server_field.stringValue)/JSSResource/" + localEndPointType + "/id/\(endPointID)"
            DestURL = DestURL.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
            
            if self.debug { self.writeToHistory(stringOfText: "[- debug -] removing \(endpointType) with ID \(endPointID)  -  Object \(endpointCurrent) of \(endpointCount)\n") }
            if self.debug { self.writeToHistory(stringOfText: "\n[- debug -] removal URL: \(DestURL)\n") }
            
            let encodedURL = NSURL(string: DestURL)
            let request = NSMutableURLRequest(url: encodedURL! as URL)
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
                        if self.debug { self.writeToHistory(stringOfText: "\n\n[- debug -] ---------- endpoint info ----------\n") }
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] Type: \(endpointType)\t Name: \(endpointName)\t ID: \(endPointID)\n") }
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] ---------- status code ----------\n") }
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(httpResponse.statusCode)\n") }
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] ---------- response ----------\n") }
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] \(httpResponse)\n") }
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] ---------- response ----------\n\n") }
                    }
                    
                }
                if self.objectsToMigrate.last == localEndPointType && endpointCount == endpointCurrent {
                    // check for file that allows deleting data from destination server, delete if found - start
                    self.rmDELETE()
                    // check for file that allows deleting data from destination server, delete if found - end
                    //self.go_button.isEnabled = true
                    self.goButtonEnabled(button_status: true)
                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] Done\n") }
                }
                semaphore.signal()
                if error != nil {
                }
            })  // let task = session.dataTask -end
            task.resume()
            semaphore.wait()
        }   // theOpQ.addOperation - end
    }
    
    func existingEndpoints(destEndpoint: String, completion: @escaping (_ result: String) -> Void) {
        print("\nGetting existing endpoints: \(destEndpoint)\n")
        var endpointParent = ""
        switch destEndpoint {
        case "advancedcomputersearches":
            endpointParent = "advanced_computer_searches"
        case "computerextensionattributes":
            endpointParent = "computer_extension_attributes"
        case "computergroups":
            endpointParent = "computer_groups"
        case "distributionpoints":
            endpointParent = "distribution_points"
        case "ldapservers":
            endpointParent = "ldap_servers"
        case "netbootservers":
            endpointParent = "netboot_servers"
        case "networksegments":
            endpointParent = "network_segments"
        case "osxconfigurationprofiles":
            endpointParent = "os_x_configuration_profiles"
        case "softwareupdateservers":
            endpointParent = "software_update_servers"
        default:
            endpointParent = "\(destEndpoint)"
        }
        
        currentEPs.removeAll()
        
        //theOpQ.maxConcurrentOperationCount = 1
        let semaphore = DispatchSemaphore(value: 0)
        destEPQ.async {
            //print("Entered destEPQ")
            var destURL = "\(self.dest_jp_server)/JSSResource/\(destEndpoint)"
            destURL = destURL.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
            
            let destEncodedURL = NSURL(string: destURL)
            let destRequest = NSMutableURLRequest(url: destEncodedURL! as URL)
            destRequest.httpMethod = "GET"
            let destConf = URLSessionConfiguration.default
            destConf.httpAdditionalHeaders = ["Authorization" : "Basic \(self.destBase64Creds)", "Content-Type" : "application/json", "Accept" : "application/json"]
            let destSession = Foundation.URLSession(configuration: destConf, delegate: self, delegateQueue: OperationQueue.main)
            let task = destSession.dataTask(with: destRequest as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse {
                    //print("httpResponse: \(String(describing: response))")
                    do {
                        let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                        if let destEndpointJSON = json as? [String: Any] {
                            if self.debug { self.writeToHistory(stringOfText: "\n[- debug -] -------- Getting all \(destEndpoint) --------\n") }
                            if self.debug { self.writeToHistory(stringOfText: "[- debug -] existing destEndpointJSON: \(destEndpointJSON))\n") }
                             switch destEndpoint {
  
                            // need to revisit as name isn't the best indicatory on whether or not a computer exists
                            case "-computers":
                                if self.debug { self.writeToHistory(stringOfText: "[- debug -] getting current computers\n") }
                                if let destEndpointInfo = destEndpointJSON["computers"] as? [Any] {
                                    let destEndpointCount: Int = destEndpointInfo.count
                                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] esisting \(destEndpoint) found: \(destEndpointCount)\n") }
                                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] destEndpointInfo: \(destEndpointInfo)\n") }
                                    
                                    if destEndpointCount > 0 {
                                        for i in (0..<destEndpointCount) {
                                            let destRecord = destEndpointInfo[i] as! [String : AnyObject]
                                            let destXmlID: Int = (destRecord["id"] as! Int)
//                                            print("computer ID: \(destXmlID)")
                                            if let destEpGeneral = destEndpointJSON["computers/id/\(destXmlID)/subset/General"] as? [Any] {
                                                print("destEpGeneral: \(destEpGeneral)")
                                                let destRecordGeneral = destEpGeneral[0] as! [String : AnyObject]
                                                print("destRecordGeneral: \(destRecordGeneral)")
                                                let destXmlUdid: String = (destRecordGeneral["udid"] as! String)
                                                self.currentEPs[destXmlUdid] = destXmlID
                                            }
                                            //print("Dest endpoint name: \(destXmlName)")
                                        }
                                    }   // if destEndpointCount > 0
                            }   //if let destEndpointInfo = destEndpointJSON - end
                                
                            default:
                                if self.debug { self.writeToHistory(stringOfText: "[- debug -] getting current \(endpointParent) on destination server\n") }
                                if let destEndpointInfo = destEndpointJSON["\(endpointParent)"] as? [Any] {
                                    let destEndpointCount: Int = destEndpointInfo.count
                                    if self.debug { self.writeToHistory(stringOfText: "[- debug -] existing \(destEndpoint) found: \(destEndpointCount) on destination server\n") }
                                    
                                    if destEndpointCount > 0 {
                                        for i in (0..<destEndpointCount) {
                                            let destRecord = destEndpointInfo[i] as! [String : AnyObject]
                                            let destXmlID: Int = (destRecord["id"] as! Int)
                                            let destXmlName: String = (destRecord["name"] as! String)
                                            self.currentEPs[destXmlName] = destXmlID
                                        }   // for i in (0..<destEndpointCount) - end
                                    }   // if destEndpointCount > 0 - end
                                }   // if let destEndpointInfo - end
                            }   // switch - end
                        }   // if let destEndpointJSON - end
                        
                    } catch {
                        if self.debug { self.writeToHistory(stringOfText: "[- debug -] Existing endpoints: error serializing JSON: \(error)\n") }
                    }   // end do/catch
                    
                    if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
                        //print(httpResponse.statusCode)
                        
                        completion("\nCurrent endpoints - \(self.currentEPs)")
                    } else {
                        // something went wrong
                        completion("\ndestination count error")
                        
                    }   // if httpResponse/else - end
                }   // if let httpResponse - end
                semaphore.signal()
                if error != nil {
                }
            })  // let task = destSession - end
            //print("GET")
            task.resume()
            //semaphore.wait()
        }   // theOpQ - end
    }
    
//==================================== Utility functions ====================================
    
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
        var str = theUrl.lowercased().replacingOccurrences(of: "https://", with: "")
        str = str.lowercased().replacingOccurrences(of: "http://", with: "")
        
        var str_array = str.components(separatedBy: ":")
        
        var fqdn = str_array[0]
        
        if str_array.count > 1 {
            let port_array = str_array[1].components(separatedBy: "/")
            port = port_array[0]
        } else {
            port = "443"
            // for multi-context jamf server
            var fqdn_array = fqdn.components(separatedBy: "/")
            fqdn = fqdn_array[0]
        }
        
        task_telnet.launchPath = "/bin/bash"
        task_telnet.arguments = ["-c", "nc -z -G 10 \(fqdn) \(port)"]
        
        task_telnet.launch()
        task_telnet.waitUntilExit()
        let result = task_telnet.terminationStatus
        
        if self.debug { self.writeToHistory(stringOfText: "[- debug -] Connectivity test for: \(theUrl)\n") }
        if self.debug { self.writeToHistory(stringOfText: "[- debug -] result: \(Int8(result))\n") }
        
        return(Int8(result))
    }   // func checkURL - end

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
    
    func goButtonEnabled(button_status: Bool) {
        DispatchQueue.main.async {
//            self.mySpinner(spin: !button_status)
//            self.mySpinner_ImageView.isHidden = !button_status
            
            self.theSpinnerQ.async {
                var theImageNo = 0
                while !button_status {
                    DispatchQueue.main.async {
                        self.mySpinner_ImageView.image = self.theImage[theImageNo]
                        theImageNo += 1
                        if theImageNo > 11 {
                            theImageNo = 0
                        }
                    }
                    usleep(100000)  // sleep 0.1 seconds
                }
            }
            self.mySpinner_ImageView.isHidden = button_status
            self.go_button.isEnabled = button_status
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
//        var theEndpoint = endpoint
//        if theEndpoint == "computergroups" {
//            print("ComputerGroupType: \(self.ComputerGroupType)")
//            theEndpoint = self.ComputerGroupType
//        }
        switch endpoint {
        case "advancedcomputersearches":
            advcompsearch_label_field.textColor = theColor
        case "buildings":
            building_label_field.textColor = theColor
        case "categories":
            categories_label_field.textColor = theColor
        case "computers":
            computers_label_field.textColor = theColor
        case "departments":
            departments_label_field.textColor = theColor
        case "ldapservers":
            ldapservers_label_field.textColor = theColor
        case "sites":
            sites_label_field.textColor = theColor
        case "distributionpoints":
            file_shares_label_field.textColor = theColor
        case "softwareupdateservers":
            sus_label_field.textColor = theColor
        case "netbootservers":
            netboot_label_field.textColor = theColor
        case "osxconfigurationprofiles":
            osxconfigurationprofiles_label_field.textColor = theColor
        case "computerextensionattributes":
            extension_attributes_label_field.textColor = theColor
        case "scripts":
            scripts_label_field.textColor = theColor
        case "computergroups":
            smart_groups_label_field.textColor = theColor
            static_groups_label_field.textColor = theColor
        case "smartcomputergroups":
            smart_groups_label_field.textColor = theColor
        case "staticcomputergroups":
            static_groups_label_field.textColor = theColor
        case "networksegments":
            network_segments_label_field.textColor = theColor
        case "packages":
            packages_label_field.textColor = theColor
        case "printers":
            printers_label_field.textColor = theColor
        case "policies":
            policies_label_field.textColor = theColor
        case "users":
            users_label_field.textColor = theColor
        default:
            print("unknown label")
        }
    }
    
    func rmXmlData(theXML: String, theTag: String) -> String {
//        if theTag == "extension_attributes" {
//            print("************************************\norig: \(theXML)\n************************************")
//        }
        let f_regexComp = try! NSRegularExpression(pattern: "<\(theTag)>(.|\n)*?</\(theTag)>", options:.caseInsensitive)
        let newXML = f_regexComp.stringByReplacingMatches(in: theXML, options: [], range: NSRange(0..<theXML.utf16.count), withTemplate: "")
//        if theTag == "extension_attributes" {
//            print("************************************\nnew: \(theXML)\n************************************")
//        }
        return newXML
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
    
    func mySpinner(spin: Bool) {
        theSpinnerQ.async {
            var theImageNo = 0
            while spin {
                DispatchQueue.main.async {
                    self.mySpinner_ImageView.image = self.theImage[theImageNo]
                    theImageNo += 1
                    if theImageNo > 11 {
                        theImageNo = 0
                    }
                }
                usleep(100000)  // sleep 0.1 seconds
            }
        }
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
    
// selective migration functions - start
    func numberOfRows(in aTableView: NSTableView) -> Int
    {
        var numberOfRows:Int = 0;
        if (aTableView == srcSrvTableView)
        {
            numberOfRows = sourceDataArray.count
        }
        else if (aTableView == desSrvTableView)
        {
            numberOfRows = targetDataArray.count
        }
        return numberOfRows
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any?
    {
        //        print("tableView: \(tableView)\t\ttableColumn: \(tableColumn)\t\trow: \(row)")
        var newString:String = ""
        if (tableView == srcSrvTableView)
        {
            newString = sourceDataArray[row]
        }
        else if (tableView == desSrvTableView)
        {
            newString = targetDataArray[row]
        }
        return newString;
    }
    
    func tableView(_ aTableView: NSTableView,
                   writeRowsWith rowIndexes: IndexSet,
                   to pboard: NSPasteboard) -> Bool
    {
        if ((aTableView == srcSrvTableView) || (aTableView == desSrvTableView))
        {
            let data:Data = NSKeyedArchiver.archivedData(withRootObject: rowIndexes)
            let registeredTypes:[String] = [NSStringPboardType]
            pboard.declareTypes(registeredTypes, owner: self)
            pboard.setData(data, forType: NSStringPboardType)
            return true
            
        }
        else
        {
            return false
        }
    }
    
    func tableView(_ aTableView: NSTableView,
                   validateDrop info: NSDraggingInfo,
                   proposedRow row: Int,
                   proposedDropOperation operation: NSTableViewDropOperation) -> NSDragOperation
    {
        if operation == .above {
            return .move
        }
        return .all
        
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool
    {
        let data:Data = info.draggingPasteboard().data(forType: NSStringPboardType)!
        let rowIndexes:IndexSet = NSKeyedUnarchiver.unarchiveObject(with: data) as! IndexSet
        
        if ((info.draggingSource() as! NSTableView == desSrvTableView) && (tableView == desSrvTableView))
        {
            let value:String = targetDataArray[rowIndexes.first!]
            targetDataArray.remove(at: rowIndexes.first!)
            if (row > targetDataArray.count)
            {
                targetDataArray.insert(value, at: row-1)
            }
            else
            {
                targetDataArray.insert(value, at: row)
            }
            desSrvTableView.reloadData()
            return true
        }
        else if ((info.draggingSource() as! NSTableView == srcSrvTableView) && (tableView == desSrvTableView))
        {
            let value:String = sourceDataArray[rowIndexes.first!]
            sourceDataArray.remove(at: rowIndexes.first!)
            targetDataArray.append(value)
            srcSrvTableView.reloadData()
            desSrvTableView.reloadData()
            return true
        }
        else
        {
            return false
        }
        
    }
// selective migration functions - end

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        // Sellect all items to be migrated
        allNone_button.state = 1
        advcompsearch_button.state = 1
        building_button.state = 1
        categories_button.state = 1
        computers_button.state = 1
        dept_button.state = 1
        sites_button.state = 1
        ldapservers_button.state = 1
        netboot_button.state = 1
        osxconfigurationprofiles_button.state = 1
        sus_button.state = 1
        fileshares_button.state = 1
        ext_attribs_button.state = 1
        smart_comp_grps_button.state = 1
        static_comp_grps_button.state = 1
        scripts_button.state = 1
        networks_button.state = 1
        packages_button.state = 1
        printers_button.state = 1
        policies_button.state = 1
        users_button.state = 1

        source_jp_server_field.becomeFirstResponder()
        go_button.isEnabled = true
        
        // for selective migration - start
        let registeredTypes:[String] = [NSStringPboardType]
        srcSrvTableView.register(forDraggedTypes: registeredTypes)
        desSrvTableView.register(forDraggedTypes: registeredTypes)
        NSLog(srcSrvTableView.registeredDraggedTypes.description)
        // for selective migration - end
        
                // read commandline args
                var numberOfArgs = 0
        
                numberOfArgs = CommandLine.arguments.count - 2  // subtract 2 since we start counting at 0, another 1 for the app itself
                    if numberOfArgs >= 0 {
                        for i in stride(from: 1, through: numberOfArgs+1, by: 1) {
                            //print("i: \(i)\t argument: \(CommandLine.arguments[i])")
                            switch CommandLine.arguments[i]{
                            case "-s":
                                    // Add code to save xml to file
                                print("not yet implemented")
                            case "-debug":
                                debug = true
                            default:
                                print("unknown switch or no argument(s) passed: \(CommandLine.arguments[i])")
                        }
                    }
                }

        historyFile = getCurrentTime() + "_migration.txt"
        isDir = false
        if !(fm.fileExists(atPath: historyPath! + historyFile, isDirectory: &isDir)) {
            _ = try? fm.createDirectory(atPath: historyPath!, withIntermediateDirectories: true, attributes: nil )
        }
        fm.createFile(atPath: historyPath! + historyFile, contents: nil, attributes: nil)
        historyFileW = FileHandle(forUpdatingAtPath: (historyPath! + historyFile))
        sleep(1)
        if debug { writeToHistory(stringOfText: "----- Debug Mode -----\n") }
        
        theModeQ.async {
            var isDir: ObjCBool = false
            var isRed = false
            
            while true {
                if (self.fm.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/jamf-migrator/DELETE", isDirectory: &isDir)) {
                    DispatchQueue.main.async {
                        if isRed == false {
                        self.migrateOrRemove_label_field.stringValue = "--- Removing ---"
                        self.migrateOrRemove_label_field.textColor = self.redText
                            isRed = true
                        } else {
                            self.migrateOrRemove_label_field.textColor = self.yellowText
                            isRed = false
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        //self.mySpinner_ImageView.rotate(byDegrees: CGFloat(self.deg))
                        self.migrateOrRemove_label_field.stringValue = "Migrating"
                        self.migrateOrRemove_label_field.textColor = self.whiteText
                        isRed = false
                    }
                }
                sleep(1)
            }
        }
        
        NSApplication.shared().activate(ignoringOtherApps: true)
    }   //override func viewDidLoad() - end

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
    
}

