//
//  SpeechMgr.swift
//  BluetoothRCcar
//
//  Created by Diii workstation on 06/12/2017.
//  Copyright © 2017 Diii workstation. All rights reserved.
//

import Foundation
import Speech

enum VoiceControlStatus:Int {
    case Stop = 0
    case Forward = 1
    case Backward = 2
    case TurnLeft = 3
    case TurnRight = 4
    case Rotate = 5
}

@available(iOS 10.0, *)
class SpeechManager: NSObject, SFSpeechRecognizerDelegate, SFSpeechRecognitionTaskDelegate{
    
    static var instance:SpeechManager!
    //MARK: - Member
    var audioEngine:AVAudioEngine!
    var speechRecognizer:SFSpeechRecognizer!
    var recognitionRequest:SFSpeechAudioBufferRecognitionRequest!
    var recognitionTask:SFSpeechRecognitionTask!
    var state:VoiceControlStatus = .Stop
    var voiceEnable:Bool = false
    var isRecording:Bool = false
    
    //MARK: - Init
    static func getInstance() -> SpeechManager {
        
        if instance == nil {
            instance = SpeechManager()
        }
        return instance!
    }
    
    override init() {
        super.init()
        
        SFSpeechRecognizer.requestAuthorization { (SFSpeechRecognizerAuthorizationStatus) in }
        AVAudioSession.sharedInstance().requestRecordPermission { (Bool) in }
        
        audioEngine = AVAudioEngine()
        speechRecognizer = SFSpeechRecognizer()
        speechRecognizer.delegate = self
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer:AVAudioPCMBuffer, AVAudioTime) in
            
            let bufferData = buffer.floatChannelData?[0]
            var volume:Float = 0.0
            for i:Int in 0..<Int(buffer.frameLength) {
                volume += fabsf((bufferData?[i])!)
            }
            
            if volume > 100 {
                self.isRecording = true
                self.recognitionRequest.append(buffer)
            }
            else {
                if self.isRecording {
                    self.stopSpeech()
                }
                self.isRecording = false
            }
        }
    }
    
    //MARK: - Function
    func startSpeech() {
        if !audioEngine.isRunning {
            audioEngine.prepare()
            do {
                try audioEngine.start()
                recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
                recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, delegate: self)
            } catch let error as NSError {
                print(error)
            }
        }
    }
    
    func stopSpeech() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest.endAudio()
            recognitionTask.finish()
        }
    }
    
    //MARK: - SFSpeechRecognitionTaskDelegate
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition recognitionResult: SFSpeechRecognitionResult) {
        let resultString:String = recognitionResult.bestTranscription.formattedString
        print(resultString)
        if resultString.contains("stop") { // Stop
            state = .Stop
        }
        else if resultString.contains("go") { // Forward
            state = .Forward
        }
        else if resultString.contains("back") { // Backward
            state = .Backward
        }
        else if resultString.contains("left") { // TurnLeft
            state = .TurnLeft
        }
        else if resultString.contains("right") { // TurnRight
            state = .TurnRight
        }
        else if resultString.contains("rotate") { // Rotate
            state = .Rotate
        }
    }
    
    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
        if voiceEnable {
            print(successfully)
            self.startSpeech()
        }
    }
}
