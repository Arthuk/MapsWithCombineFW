//
//  MapViewModel.swift
//  MapsWithCombineFW
//
//  Created by arturs on 18/08/2022.
//

import CoreLocation
import UIKit
import Combine

final class MapViewModel: NSObject {
    
    //MARK: - Properties
    private var manager: ConnectionManager
    private var subscriptions = Set<AnyCancellable>()
    private var users: Set<User?> = []
    
    var usersPublisher = PassthroughSubject<Set<User?>, Never>()
    
    //MARK: - Init
    init(manager: ConnectionManager) {
        self.manager = manager
        
        super.init()
        self.subscribeForServerUpdates()
    }

    //MARK: - Private methods
    private func subscribeForServerUpdates() {
        manager.userListPublisher()
            // Receive userList, parse into a [User] and repost down the pipeline
            .map({ [unowned self] userList -> [User?] in
                self.parseUsers(rawData: userList)
            })
            // Download user image and repost users down the pipeline
            .flatMap({ [unowned self] userList -> AnyPublisher<[User], Never> in
                self.updateWithProfileImage(userCollection: userList.compactMap { $0 })
            })
            // Check address with geocoder and repost users down the pipeline
            .flatMap({ [unowned self] userList -> AnyPublisher<[User], Never> in
                self.updateWithLocationDescription(userCollection: userList.compactMap { $0 })
            })
            // Finally store users and publish for subscribers (if any)
            .sink(receiveValue: { [unowned self] users in
                self.users = Set(users)
                self.usersPublisher.send(Set(users))
            })
            .store(in: &subscriptions)
        
        manager.userLocationUpdatesPublisher()
            // Receive updates, update coordinates in [User] and repost down the pipeline
            .map({ [unowned self] updates -> [User] in
                return self.updateUserLocation(rawData: updates)
            })
            // Update address with geocoder in [User] and repost users down the pipeline
            .flatMap({ [unowned self] userList -> AnyPublisher<[User], Never> in
                return self.updateWithLocationDescription(userCollection: userList.compactMap { $0 })
            })
            // Finally store updated users and publish for subscribers (if any)
            .sink { [unowned self] users in
                self.users = Set(users)
                self.usersPublisher.send(Set(users))
            }
            .store(in: &subscriptions)
    }
    
    private func updateWithLocationDescription(userCollection: [User]) -> AnyPublisher<[User], Never> {
        userCollection.publisher
            .map(\.location)
            .flatMap({ [unowned self] (latitude, longitude) -> AnyPublisher<String, Never> in
                return self.getLocationDescription(location: CLLocation(latitude: latitude,
                                                                        longitude: longitude))
            })
            .zip(userCollection.publisher)
            .map({ (address, user) in
                var mutableUser = user
                mutableUser.address = address
                return mutableUser
            })
            .collect()
            .eraseToAnyPublisher()
    }
    
    private func getLocationDescription(location: CLLocation) -> AnyPublisher<String, Never> {
        Deferred {
            Future() { promise in
                let geocoder = CLGeocoder()
                
                geocoder.reverseGeocodeLocation(location) { placemarks, error in
                    if error != nil {
                        print(error as Any)
                    }
                    if let placemarks = placemarks {
                        let pm = placemarks[0]
                        var addressString: String = ""
                        
                        if pm.thoroughfare != nil {
                            addressString = addressString + pm.thoroughfare! + ", "
                        }
                        if pm.locality != nil {
                            addressString = addressString + pm.locality!
                        }
                        promise(.success(addressString))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func updateWithProfileImage(userCollection: [User]) -> AnyPublisher<[User], Never> {
        userCollection.publisher
            .map(\.profilePicture)
            .flatMap { url in
                URLSession.shared.dataTaskPublisher(for: URL(string: url)!)
                    .map(\.data)
                    .replaceError(with: Data()) // add no photo image
            }
            .zip(userCollection.publisher)
            .map { (imageData, user) -> User in
                var mutableUser = user
                if let image = UIImage(data: imageData) {
                    mutableUser.image = image
                }
                return mutableUser
            }
            .collect()
            .eraseToAnyPublisher()
    }
    
    private func parseUsers(rawData: String) -> [User?] {
        var users: [User?] = []
        
        guard let startIndex = rawData.range(of: "USERLIST ")?.upperBound else {
            return users
        }
        let suffixed = rawData.suffix(from: startIndex)
        let endIndex = rawData.endIndex
        let prefixed = suffixed.prefix(upTo: endIndex)
        
        if prefixed.contains(";") {
            let splittedIntoArray = suffixed.components(separatedBy: ";").dropLast()
            let usersList = splittedIntoArray.map { User(string: $0) }
            users = usersList
        }
        return users
    }
    
    private func updateUserLocation(rawData: String) -> [User] {
        var noNilUsersArray = users.compactMap { $0 }
        
        guard let startIndex = rawData.range(of: "UPDATE")?.lowerBound else {
            return noNilUsersArray
        }
        let suffixed = rawData.suffix(from: startIndex)
        let splittedIntoArray = suffixed.components(separatedBy: "\n").dropLast()
        let coordinateUpdates = splittedIntoArray.map { str -> String in
            if let startIndex = str.range(of: "UPDATE ")?.upperBound {
                return String(str.suffix(from: startIndex))
            }
            return str
        }
        
        coordinateUpdates.forEach({ update in
            let data = Array(update.components(separatedBy: ","))
            
            guard let id = Int(data[0]) else { return }
            
            let hasMatch = noNilUsersArray.first { $0.id == id }
            if var userToUpdate = hasMatch {
                noNilUsersArray.removeAll { $0.id == id }
                
                userToUpdate.updateUserLocation(withArray: data)
                noNilUsersArray.append(userToUpdate)
            }
        })
        return noNilUsersArray
    }
    
    //MARK: - API
    func connect() {
        manager.connect()
    }
    
    func authorize(byEmail: String) {
        manager.authorize(byEmail: byEmail)
    }
    
    func connectionPublisher() -> CurrentValueSubject<Bool, Never> {
        manager.connectionStatusPublisher
    }
}


