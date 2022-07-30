//
//  AppDelegate.swift
//  jamf-migrator
//
//  Created by Leslie N. Helou on 12/9/16.
//  Copyright © 2016 jamf. All rights reserved.
//

import ApplicationServices
import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let vc = ViewController()
    
    var prefWindowController: NSWindowController?

    // allow access to previously selected folder - start
    var folderPath: URL? {
        didSet {
            do {
                let bookmark = try folderPath?.bookmarkData(options: .securityScopeAllowOnlyReadAccess, includingResourceValuesForKeys: nil, relativeTo: nil)
                UserDefaults.standard.set(bookmark, forKey: "bookmark")
            } catch let error as NSError {
                WriteToLog().message(stringOfText: "[AppDelegate] Set Bookmark Fails: \(error.description)\n")
            }
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
       if let bookmarkData = UserDefaults.standard.object(forKey: "bookmark") as? Data {
           do {
               var bookmarkIsStale = false
               let url = try URL.init(resolvingBookmarkData: bookmarkData as Data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &bookmarkIsStale)
               let _ = url.startAccessingSecurityScopedResource()
           } catch let error as NSError {
            WriteToLog().message(stringOfText: "Bookmark Access Fails: \(error.description)\n")
           }
       }
        
        // read command line arguments - start
        var numberOfArgs = 0
        var startPos     = 1
        // read commandline args
        numberOfArgs = CommandLine.arguments.count
//        print("all arguments: \(CommandLine.arguments)")
        if CommandLine.arguments.contains("-debug") {
            numberOfArgs -= 1
            startPos+=1
            LogLevel.debug = true
        }
        var index = 0
        while index < numberOfArgs {
                print("index: \(index)\t argument: \(CommandLine.arguments[index])")
                switch CommandLine.arguments[index].lowercased() {
                case "-saverawxml":
                    export.saveRawXml = true
                case "-savetrimmedxml":
                    export.saveTrimmedXml = true
                case "-export.saveonly":
                    export.saveOnly = true
                case "-forceldapid":
                    index += 1
//                    forceLdapId = Bool(CommandLine.arguments[index]) ?? false
                case "-ldapid":
                    index += 1
//                    ldapId = Int(CommandLine.arguments[index]) ?? -1
//                    if ldapId > 0 {
//                        hardSetLdapId = true
//                    }
                case "-sourceurl":
                    index += 1
                    JamfProServer.source = "\(CommandLine.arguments[index])"
                    if JamfProServer.source.prefix(4) != "http" {
                        JamfProServer.source = "https://\(JamfProServer.source)"
                    }
                case "-desturl":
                    index += 1
                    JamfProServer.destination = "\(CommandLine.arguments[index])"
                    if JamfProServer.destination.prefix(4) != "http" {
                        JamfProServer.destination = "https://\(JamfProServer.destination)"
                    }
                case "-backup":
                    index += 1
                    export.backupMode = Bool(CommandLine.arguments[index]) ?? false
                    setting.fullGUI = false
                case "-silent":
                    setting.fullGUI = false
//                case "-nsdocumentrevisionsdebugmode","YES":
//                    continue
                default:
                    print("unknown switch passed: \(CommandLine.arguments[index])")
                }
            index += 1
        }
        // read command line arguments - end
        print("done reading command line args - index: \(index)")
        
        
        if setting.fullGUI {
            NSApp.setActivationPolicy(.regular)
            let storyboard = NSStoryboard(name: "Main", bundle: nil)
            let mainWindowController = storyboard.instantiateController(withIdentifier: "Main") as! NSWindowController
            mainWindowController.window?.hidesOnDeactivate = false
            mainWindowController.showWindow(self)
        }
        else {
            print("running silently")
            
            ViewController().initVars()
        }
    }

    @IBAction func checkForUpdates(_ sender: AnyObject) {
        let verCheck = VersionCheck()
        
        let appInfo = Bundle.main.infoDictionary!
        let version = appInfo["CFBundleShortVersionString"] as! String
        
        verCheck.versionCheck() {
            (result: Bool) in
            if result {
                self.alert_dialog(header: "A new versions is available.", message: "Running Jamf Migrator: \(version)", updateAvail: result)
            } else {
                self.alert_dialog(header: "Running Jamf Migrator: \(version)", message: "No updates are currently available.", updateAvail: result)
            }
        }
    }
    
    func alert_dialog(header: String, message: String, updateAvail: Bool) {
        
        let dialog: NSAlert = NSAlert()
        dialog.messageText = header
        dialog.informativeText = message
        dialog.alertStyle = NSAlert.Style.informational
        if updateAvail {
            dialog.addButton(withTitle: "View")
            dialog.addButton(withTitle: "Ignore")
        } else {
            dialog.addButton(withTitle: "OK")
        }
        
        let clicked:NSApplication.ModalResponse = dialog.runModal()

        if clicked.rawValue == 1000 && updateAvail {
            if let url = URL(string: "https://github.com/jamf/JamfMigrator/releases") {
                    NSWorkspace.shared.open(url)
            }
        }

        //return true
    }   // func alert_dialog - end
    
    @IBAction func showPreferences(_ sender: Any) {
        PrefsWindowController().show()
    }
    
    // quit the app if the window is closed
    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool {
        return true
    }
    
}

