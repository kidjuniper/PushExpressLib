//
//  File.swift
//  
//
//  Created by Nikita Stepanov on 13.06.2024.
//

import Foundation

public enum TransportType: String {
    case fcm
    case onesignal
    case apns
}

public enum Events: String {
    case clicked
    case delivered
}
