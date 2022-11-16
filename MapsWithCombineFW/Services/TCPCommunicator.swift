import Foundation
import Combine

protocol ConnectionProviding {
    var userListPublisher: PassthroughSubject<String, Never> { get }
    var updatePublisher: PassthroughSubject<String, Never> { get }
    
    func connect() -> NotificationCenter.Publisher
    func disconnect() -> NotificationCenter.Publisher
    func receiveFromStream(_ output: String)
    func send(message: String)
}

final class TCPCommunicator: NSObject, ConnectionProviding {
    
    private var readStream: Unmanaged<CFReadStream>?
    private var writeStream: Unmanaged<CFWriteStream>?
    private var inputStream: InputStream?
    private var outputStream: OutputStream?
    private var url: URL
    private var port: UInt32
        
    var userListPublisher = PassthroughSubject<String, Never>()
    var updatePublisher = PassthroughSubject<String, Never>()
    
    init(url: URL, port: UInt32) {
        self.url = url
        self.port = port
    }
    
    func connect() -> NotificationCenter.Publisher {
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (url.absoluteString as CFString), port, &readStream, &writeStream)
        outputStream = writeStream?.takeRetainedValue()
        inputStream = readStream?.takeRetainedValue()
        outputStream?.delegate = self
        inputStream?.delegate = self
        outputStream?.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)
        inputStream?.schedule(in: RunLoop.current, forMode: RunLoop.Mode.default)
        outputStream?.open()
        inputStream?.open()
        
        return NotificationCenter.default.publisher(for: .didConnect)
    }
    
    func disconnect() -> NotificationCenter.Publisher {
        inputStream?.close()
        outputStream?.close()
        inputStream?.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
        outputStream?.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
        inputStream?.delegate = nil
        outputStream?.delegate = nil
        inputStream = nil
        outputStream = nil
        
        return NotificationCenter.default.publisher(for: .didDisconnect)
    }
    
    func receiveFromStream(_ output: String) {
        if output.contains("USERLIST") {
            userListPublisher.send(output)
        }
        
        if output.contains("UPDATE") {
            updatePublisher.send(output)
        }
    }
    
    func send(message: String) {
        let response = "\(message)"
        let buff = [UInt8](message.utf8)
        if let _ = response.data(using: .ascii) {
            outputStream?.write(buff, maxLength: buff.count)
        }
    }
}

extension TCPCommunicator: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            NotificationCenter.default.post(name: .didConnect, object: nil)
        case .hasBytesAvailable:
            if aStream == inputStream {
                var dataBuffer = Array<UInt8>(repeating: 0, count: 1024)
                var len: Int
                while (inputStream?.hasBytesAvailable)! {
                    len = (inputStream?.read(&dataBuffer, maxLength: 1024))!
                    if len > 0 {
                        let output = String(bytes: dataBuffer, encoding: .utf8)
                        if let output = output {
                            receiveFromStream(output)
                        }
                    }
                }
            }
        case .hasSpaceAvailable:
            print("Stream has space available now")
        case .errorOccurred:
            print("\(aStream.streamError?.localizedDescription ?? "")")
        case .endEncountered:
            aStream.close()
            aStream.remove(from: RunLoop.current, forMode: RunLoop.Mode.default)
            
            NotificationCenter.default.post(name: .didDisconnect, object: nil)
        default:
            print("Unknown event")
        }
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
