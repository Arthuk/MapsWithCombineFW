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
}
