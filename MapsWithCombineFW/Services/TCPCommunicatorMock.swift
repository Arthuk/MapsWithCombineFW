//
//  TCPCommunicatorMock.swift
//  MapsWithCombineFW
//
//  Created by arturs on 18/12/2022.
//

import Foundation
import Combine

final class TCPCommunicatorMock: NSObject, ConnectionProviding {
    
    var userListPublisher = PassthroughSubject<String, Never>()
    var updatePublisher = PassthroughSubject<String, Never>()
    
    private var userTimer: Timer?
    private var updateTimer: Timer?
    private var index = 0
    
    override init() {
        super.init()
        
        launchSimulation()
    }
    
    func connect() -> NotificationCenter.Publisher {
        executeWithDelay(delay: 1) {
            NotificationCenter.default.post(name: .didConnect, object: nil)
        }
        
        return NotificationCenter.default.publisher(for: .didConnect)
    }
    
    func disconnect() -> NotificationCenter.Publisher {
        executeWithDelay(delay: 1) {
            NotificationCenter.default.post(name: .didDisconnect, object: nil)
        }
        return NotificationCenter.default.publisher(for: .didDisconnect)
    }
    
    func receiveFromStream(_ output: String) {
        if output.contains("USERLIST") {
            userListPublisher.send(output)
        } else if output.contains("UPDATE") {
            updatePublisher.send(output)
        }
    }
    
    func send(message: String) {
        return
    }
    
    private func launchSimulation() {
        userTimer = Timer.scheduledTimer(withTimeInterval: 0, repeats: false, block: { [weak self] timer in
            self?.receiveFromStream(testUserList)
        })
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true, block: { [weak self] timer in
            guard let index = self?.index else { return }
            
            self?.receiveFromStream(testUpdates[index])
            if index + 1 == testUpdates.count - 1 {
                self?.index = 0
            } else {
                self?.index += 1
            }
        })
    }
}

func executeWithDelay(delay: TimeInterval = 3, block: @escaping () -> Void) {
    DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
        block()
    }
}

let testUserList = """
USERLIST 101,Steve Jobs,https://image.cnbcfm.com/api/v1/image/104556423-steve-jobs-iphone-10-years.jpg,56.9495677035,24.1064071655;102,Elon  Mask,https://upload.wikimedia.org/wikipedia/commons/3/34/Elon_Musk_Royal_Society_%28crop2%29.jpg,56.9503693176,24.1084241867;\n
"""

let testUpdates: [String] = ["UPDATE 101,56.9495677035,24.1064071655\nUPDATE 102,56.95043368,24.1116642952\n",
                             "UPDATE 101,56.9495677035,24.1064071655\nUPDATE 102,56.9499831407,24.111020565\n",
                             "UPDATE 101,56.9495677035,24.1064071655\nUPDATE 102,56.9504453823,24.1101408005\n",
                             "UPDATE 101,56.9495677035,24.1064071655\nUPDATE 102,56.9502698482,24.1093039513\n",
                             "UPDATE 101,56.9495677035,24.1064071655\nUPDATE 102,56.9503634665,24.1084134579\n",
                             "UPDATE 101,56.9495677035,24.1064071655\nUPDATE 102,56.9503693176,24.1084241867\n",
                             "UPDATE 101,56.9495677035,24.1064071655\nUPDATE 102,56.9507203841,24.1086924076\n",
                             "UPDATE 101,56.9495677035,24.1064071655\nUPDATE 102,56.9509602776,24.1089177132\n",
                             "UPDATE 101,56.9495677035,24.1064071655\nUPDATE 102,56.9511299574,24.108928442\n",
                             "UPDATE 101,56.9495677035,24.1064071655\nUPDATE 102,56.9513288914,24.1093254089\n"]
