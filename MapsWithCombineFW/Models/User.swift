//
//  User.swift
//  
//
//  Created by arturs on 18/08/2022.
//

import Foundation
import UIKit

struct User: Identifiable, Hashable {
    var id: Int
    var fullName: String
    var profilePicture: String
    var latitude: Double
    var longitude: Double
    
    var location: (latitude: Double, longitude: Double) {
        return (latitude: latitude, longitude: longitude)
    }
    
    var address: String?
    var image: UIImage?
}
          
extension User {
    init?(string: String) {
        let dataArray = string.components(separatedBy: ",")
        
        guard dataArray.count == 5,
                let id = Int(dataArray[0]),
                let lat = Double(dataArray[3]),
                let lon = Double(dataArray[4]) else { return nil }
        
        self.id = id
        self.fullName = dataArray[1]
        self.profilePicture = dataArray[2]
        self.latitude = lat
        self.longitude = lon
    }
    
    mutating func updateUserLocation(withArray data: [String]) {
        guard data.count == 3,
                let id = Int(data[0]),
                let lat = Double(data[1]),
                let lon = Double(data[2]),
                self.id == id else { return }
        
        self.latitude = lat
        self.longitude = lon
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}
