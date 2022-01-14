//
//  WriteToLog.swift
//  jamf-migrator
//
//  Created by Leslie Helou on 2/21/19.
//  Copyright © 2019 jamf. All rights reserved.
//

import Foundation
class WriteToLog {
    
    var logFileW: FileHandle? = FileHandle(forUpdatingAtPath: "")
    var writeToLogQ = DispatchQueue(label: "com.jamf.writeToLogQ", qos: DispatchQoS.background)

    func message(stringOfText: String) {
        let logString = (LogLevel.debug) ? "\(TimeDelegate().getCurrent()) [- debug -] \(stringOfText)":"\(TimeDelegate().getCurrent()) \(stringOfText)"

        self.logFileW = FileHandle(forUpdatingAtPath: (History.logPath! + History.logFile))

        self.logFileW?.seekToEndOfFile()
        let historyText = (logString as NSString).data(using: String.Encoding.utf8.rawValue)
        self.logFileW?.write(historyText!)
    }
}
