//
//  ViewController.swift
//  BluetoothRCcar
//
//  Created by Diii workstation on 05/12/2017.
//  Copyright © 2017 Diii workstation. All rights reserved.
//

import UIKit

let BETA = false

class ViewController: UIViewController, StreamManagerDelegate {

    //MARK: - member
    @IBOutlet var photoView:UIView!
    @IBOutlet var photoButton:UIButton!
    @IBOutlet var imageView:UIImageView!
    @IBOutlet var LForward:UIButton!
    @IBOutlet var RForward:UIButton!
    @IBOutlet var LBackward:UIButton!
    @IBOutlet var RBackward:UIButton!
    
    var bluetoothManager:BluetoothMgr!
    var streamManager:StreamManager!
    
    var leftWheelStatus:WheelStatus = .Stop
    var rightWheelStatus:WheelStatus = .Stop
    
    var checkPhoto:UIImage!
    var timer:Timer!
    var checkImageCountDown:Int = 0
    var voiceEnable = false
    
    //MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
        photoView.layer.borderColor = UIColor.white.cgColor
        
        photoButton.addTarget(self, action: #selector(self.photoButtonClicked(_:)), for: UIControlEvents.touchUpInside)
        LForward.addTarget(self, action: #selector(self.LButtonDown(_:)), for: UIControlEvents.touchDown)
        LForward.addTarget(self, action: #selector(self.LButtonUp(_:)), for: UIControlEvents.touchUpInside)
        LForward.addTarget(self, action: #selector(self.LButtonUp(_:)), for: UIControlEvents.touchUpOutside)
        LBackward.addTarget(self, action: #selector(self.LButtonDown(_:)), for: UIControlEvents.touchDown)
        LBackward.addTarget(self, action: #selector(self.LButtonUp(_:)), for: UIControlEvents.touchUpInside)
        LBackward.addTarget(self, action: #selector(self.LButtonUp(_:)), for: UIControlEvents.touchUpOutside)
        RForward.addTarget(self, action: #selector(self.RButtonDown(_:)), for: UIControlEvents.touchDown)
        RForward.addTarget(self, action: #selector(self.RButtonUp(_:)), for: UIControlEvents.touchUpInside)
        RForward.addTarget(self, action: #selector(self.RButtonUp(_:)), for: UIControlEvents.touchUpOutside)
        RBackward.addTarget(self, action: #selector(self.RButtonDown(_:)), for: UIControlEvents.touchDown)
        RBackward.addTarget(self, action: #selector(self.RButtonUp(_:)), for: UIControlEvents.touchUpInside)
        RBackward.addTarget(self, action: #selector(self.RButtonUp(_:)), for: UIControlEvents.touchUpOutside)
        
        bluetoothManager = BluetoothMgr.getInstance()
        bluetoothManager.tableView.center = self.view.center
        self.view.addSubview(bluetoothManager.tableView)
        streamManager = StreamManager.getInstance()
        streamManager.delegate = self
        timer = Timer.scheduledTimer(timeInterval: SEND_TIME_INTERVAL, target: self, selector: #selector(self.updateStatus), userInfo: nil, repeats: true)
        
        if #available(iOS 10.0, *), BETA {
            _ = SpeechManager.getInstance()
            
            let switchView:UISwitch = UISwitch()
            switchView.frame.origin.x = self.view.frame.size.width - switchView.frame.size.width
            switchView.frame.origin.y = self.view.frame.size.height - switchView.frame.size.height
            self.view.addSubview(switchView)
            switchView.addTarget(self, action: #selector(self.switchValueChange(_:)), for: .valueChanged)
            
            let recordButton:UIButton = UIButton(frame:CGRect(x: 0, y: self.view.frame.size.height - 40, width: 80, height: 40))
            recordButton.setTitle("Voice", for: .normal)
            recordButton.setTitleColor(UIColor.white, for: .normal)
            recordButton.setTitleColor(UIColor.lightGray, for: .highlighted)
            recordButton.layer.cornerRadius = 5.0
            recordButton.layer.borderWidth = 1.0
            recordButton.layer.borderColor = UIColor.white.cgColor
            self.view.addSubview(recordButton)
            recordButton.addTarget(self, action: #selector(self.recordButtonDown(_:)), for: .touchDown)
            recordButton.addTarget(self, action: #selector(self.recordButtonUp(_:)), for: .touchUpInside)
        }
    }
    
    //MARK: - Button Click
    @objc func photoButtonClicked(_ sender:UIButton) {
        if streamManager.connected {
            photoButton.setTitle("", for: .normal)
            streamManager.requestPhoto()
        }
    }
    
    @objc func LButtonDown(_ sender:UIButton) {
        if LForward.state.rawValue == LBackward.state.rawValue {
            leftWheelStatus = .Stop
        }
        else {
            leftWheelStatus = WheelStatus(rawValue: sender.tag)!
        }
    }
    
    @objc func LButtonUp(_ sender:UIButton) {
        leftWheelStatus = .Stop
    }
    
    @objc func RButtonDown(_ sender:UIButton) {
        if RForward.state.rawValue == RBackward.state.rawValue {
            rightWheelStatus = .Stop
        }
        else {
            rightWheelStatus = WheelStatus(rawValue: sender.tag)!
        }
    }
    
    @objc func RButtonUp(_ sender:UIButton) {
        rightWheelStatus = .Stop
    }
    
    //MARK: - iOS 10 Support
    @objc func switchValueChange(_ sender:UISwitch) {
        
        if #available(iOS 10.0, *) {
            voiceEnable = sender.isOn
            
            LForward.isEnabled = !voiceEnable
            RForward.isEnabled = !voiceEnable
            LBackward.isEnabled = !voiceEnable
            RBackward.isEnabled = !voiceEnable
            
            SpeechManager.getInstance().voiceEnable = voiceEnable
            voiceEnable ? SpeechManager.getInstance().startSpeech() : SpeechManager.getInstance().stopSpeech()
            
            SpeechManager.getInstance().state = .Stop
            leftWheelStatus = .Stop
            rightWheelStatus = .Stop
        }
    }
    
    @objc func recordButtonDown(_ sender:UIButton) {
        if #available(iOS 10.0, *), voiceEnable {
            sender.layer.borderColor = UIColor.lightGray.cgColor
            SpeechManager.getInstance().startSpeech()
        }
    }
    
    @objc func recordButtonUp(_ sender:UIButton) {
        if #available(iOS 10.0, *), voiceEnable {
            sender.layer.borderColor = UIColor.white.cgColor
            SpeechManager.getInstance().stopSpeech()
        }
    }
    
    //MARK: - Timer Function
    @objc func updateStatus() {
        
        if #available(iOS 10.0, *), voiceEnable {
            switch SpeechManager.getInstance().state {
            case .Stop:
                leftWheelStatus = .Stop
                rightWheelStatus = .Stop
                break
            case .Forward:
                leftWheelStatus = .Forward
                rightWheelStatus = .Forward
                break
            case .Backward:
                leftWheelStatus = .Backward
                rightWheelStatus = .Backward
                break
            case .TurnLeft:
                leftWheelStatus = .Forward
                rightWheelStatus = .Stop
                break
            case .TurnRight:
                leftWheelStatus = .Stop
                rightWheelStatus = .Forward
                break
            case .Rotate:
                leftWheelStatus = .Forward
                rightWheelStatus = .Backward
                break
            }
        }
        
        bluetoothManager.sendMoveCommand(leftWheelStatus, rightWheelStatus)
        
        if checkImageCountDown >= 10 {  // checkImageCountDown * SEND_TIME_INTERVAL = TimeInterval
            
            if( streamManager.firstGetImage && imageView.image == checkPhoto) {
                imageView.image = nil
                streamManager.sending = false
                photoButton.setTitle("Click To Get Photo", for: .normal)
            }
            else {
                checkPhoto = imageView.image
            }
            checkImageCountDown=0
        }
        checkImageCountDown+=1
    }
    
    //MARK: - StreamManagerDelegate
    func updatePhoto(_ image:UIImage) {
        imageView.image = image
    }
}

