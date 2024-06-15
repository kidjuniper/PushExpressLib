//
//  File.swift
//  
//
//  Created by Nikita Stepanov on 15.06.2024.
//

import Foundation
import UserNotifications

extension URLSession {
    public class func downloadImage(atURL url: URL, withCompletionHandler completionHandler: @escaping (UNNotificationAttachment?, NSError?) -> Void) {
        let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completionHandler(nil, error as NSError)
                return
            }
            
            guard let data = data else {
                let noDataError = NSError(domain: "com.yourApp.error", code: 1001, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                completionHandler(nil, noDataError)
                return
            }
            
            let tempDirectory = FileManager.default.temporaryDirectory
            let uniqueDirectoryName = ProcessInfo.processInfo.globallyUniqueString
            let tempDirectoryURL = tempDirectory.appendingPathComponent(uniqueDirectoryName, isDirectory: true)
            
            do {
                try FileManager.default.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                
                let fileURL = tempDirectoryURL.appendingPathComponent("image.jpg")
                try data.write(to: fileURL)
                
                let attachment = try UNNotificationAttachment(identifier: "image", url: fileURL, options: nil)
                
                completionHandler(attachment, nil)
            } catch let error as NSError {
                completionHandler(nil, error)
            }
        }
        dataTask.resume()
    }
}
