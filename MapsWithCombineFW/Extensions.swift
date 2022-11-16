//
//  Extensions.swift
//  MapsWithCombineFW
//
//  Created by arturs on 23/08/2022.
//

import Foundation

extension Notification.Name {
    static var didConnect: Notification.Name {
        return Notification.Name(rawValue: "didConnect")
    }
    
    static var didDisconnect: Notification.Name {
        return Notification.Name(rawValue: "didDisconnect")
    }
}
