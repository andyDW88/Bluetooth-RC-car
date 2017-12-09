//
//  StreamMgr.swift
//  BluetoothRCcar
//
//  Created by Diii workstation on 06/12/2017.
//  Copyright © 2017 Diii workstation. All rights reserved.
//

import Foundation
import UIKit

let SocketServerPort = 9487
let bufferSizeNumber = 100000

protocol StreamManagerDelegate {
    func updatePhoto(_ image:UIImage)
}

class StreamManager : NSObject, StreamDelegate {
    
    static var instance:StreamManager!
    //MARK: - Member
    var delegate:StreamManagerDelegate!
    
    var iStream:InputStream?
    var oStream:OutputStream?
    var imageBuffer:String = String()
    var connected:Bool = false
    var sending:Bool = false
    var firstGetImage:Bool = false
    
    //MARK: - Init
    static func getInstance() -> StreamManager {
        
        if instance == nil {
            instance = StreamManager()
        }
        return instance!
    }
    
    //MARK: - Function
    func socketStart(_ ip:String) {
        DispatchQueue(label: "Stream").async {
            
            Stream.getStreamsToHost(withName: ip, port: SocketServerPort, inputStream: &self.iStream, outputStream: &self.oStream)
            
            if (self.iStream != nil) && (self.oStream != nil) {
                CFReadStreamSetProperty(self.iStream, CFStreamPropertyKey(rawValue: kCFStreamPropertyShouldCloseNativeSocket), kCFBooleanTrue)
                CFWriteStreamSetProperty(self.oStream, CFStreamPropertyKey(rawValue: kCFStreamPropertyShouldCloseNativeSocket), kCFBooleanTrue)
                
                self.iStream?.delegate = self
                self.iStream?.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
                self.iStream?.open()
                
                self.oStream?.delegate = self
                self.oStream?.schedule(in: RunLoop.current, forMode: RunLoopMode.defaultRunLoopMode)
                self.oStream?.open()
                
                RunLoop.current.run()
            }
        }
    }
    
    func requestPhoto() {
        DispatchQueue(label: "Stream").async{
            if !self.sending {
                self.imageBuffer = ""
                var buffer:[UInt8] = [UInt8](repeating: 1, count: 1)
                //                NSLog("Transfer Begin")
                self.sending = true
                self.oStream?.write(&buffer, maxLength: buffer.count)
            }
        }
    }
    
    //MARK: - StreamDelegate
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        
        if (eventCode == .hasBytesAvailable) {
            
            var buffer = [UInt8](repeating: 0, count: bufferSizeNumber)
            let length = iStream?.read(&buffer, maxLength: buffer.count)
            if length! < 0 {
                return
            }
            let str = String(bytesNoCopy: &buffer, length: length!, encoding: String.Encoding.utf8, freeWhenDone: false)!
            if str == "connected"{
                self.connected = true
            }
            else {
                imageBuffer = imageBuffer.appending(str)
                if str.hasSuffix("S:DONE") {
                    imageBuffer = imageBuffer.replacingOccurrences(of: "S:DONE", with: "")
                    imageBuffer = imageBuffer.components(separatedBy: "base64,").last!
                    let imageData = Data(base64Encoded: imageBuffer, options: Data.Base64DecodingOptions.ignoreUnknownCharacters)
                    let image = UIImage(data: imageData!)
                    DispatchQueue.main.async {
                        if (self.delegate != nil) {
                            self.delegate.updatePhoto(image!)
                            self.firstGetImage = true
                        }
                    }
                    //                    NSLog("Transfer End")
                    self.sending = false
                    self.requestPhoto()
                }
            }
            
        }
    }
}
