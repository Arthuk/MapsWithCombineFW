//
//  ConnectionManager.swift
//  MapsWithCombineFW
//
//  Created by arturs on 24/08/2022.
//

import Foundation
import Combine

final class ConnectionManager {
    
    //MARK: - Properties
    private var service: ConnectionProviding
    private var subscribers = Set<AnyCancellable>()
    
    var connectionStatusPublisher: CurrentValueSubject<Bool, Never> = .init(false)
    
    //MARK: - Init
    init(service: ConnectionProviding = TCPCommunicator(url: URL(string: "127.0.0.1")!, port: 65535)) {
        self.service = service
    }

    //MARK: - API
    func connect() {
        service.connect()
            .removeDuplicates()
            .sink { [weak self] receivedNotification in
                self?.connectionStatusPublisher.send(true)
            }
            .store(in: &subscribers)
    }
    
    func disconnect() {
        service.disconnect()
            .removeDuplicates()
            .sink { [weak self] receivedNotification in
                self?.connectionStatusPublisher.send(false)
            }
            .store(in: &subscribers)
    }
    
    func authorize(byEmail: String) {
        service.send(message: "AUTHORIZE " + byEmail + "\n")
    }
    
    func userListPublisher() -> PassthroughSubject<String, Never> {
        service.userListPublisher
    }
    
    func userLocationUpdatesPublisher() -> PassthroughSubject<String, Never> {
        service.updatePublisher
    }
    
    #if DEBUG
    //MARK: - Testing API
    func simulateUserListEmit() {
        service.userListPublisher.send(testUserList)
    }
    
    func simulateLocationUpdateEmit() {
        let delayPublisher = Timer.publish(every: 3, on: .main, in: .default).autoconnect()
        let delayedValuesPublisher = Publishers.Zip(testUpdates.publisher, delayPublisher)
        
        delayedValuesPublisher
            .map { [weak self] (update, delay) -> () in
                self?.service.updatePublisher.send(update)
            }
            .sink { _ in
                print("fire test update")
            }
            .store(in: &subscribers)
    }
    #endif
}
