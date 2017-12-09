//
//  BluetoothMgr.swift
//  BluetoothRCcar
//
//  Created by Diii workstation on 05/12/2017.
//  Copyright © 2017 Diii workstation. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

enum WheelStatus:Int {
    case Stop = 2
    case Forward = 1
    case Backward = 0
}

let YOUR_PI_BULETOOTH = "andyPi"
let SEND_TIME_INTERVAL = 0.1

class BluetoothMgr : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDataSource, UITableViewDelegate {
    
    static var instance:BluetoothMgr!
    //MARK: - Member
    var centralManager:CBCentralManager!
    var connectPeripheral:CBPeripheral!
    var tableView:UITableView!
    
    var readCharacteristic:CBCharacteristic?
    var writeCharacteristic:CBCharacteristic?
    var connected:Bool = false
    
    var devicesArray:NSMutableArray = NSMutableArray()
    
    //Initalize bluetooth manager
    static func getInstance() -> BluetoothMgr {
        
        if instance == nil {
            instance = BluetoothMgr()
        }
        return instance!
    }
    
    override init() {
        super.init()
        
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue(label: "Bluetooth"))
        
        tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 300, height:250))
        tableView.dataSource = self
        tableView.delegate = self
        tableView.layer.masksToBounds = true
        tableView.layer.borderWidth = 1
        tableView.layer.borderColor = UIColor.lightGray.cgColor
        tableView.layer.cornerRadius = 5
    }
    
    //Player's RC car controlling orders
    func sendMoveCommand(_ leftWheelStatus:WheelStatus,_ rightWheelStatus:WheelStatus) {
        // 2 byte 0:Left-wheel 1:right-wheel
        
        var bytes:[UInt8] = []
        bytes.append(self.statusChangeToUInt8(leftWheelStatus));
        bytes.append(self.statusChangeToUInt8(rightWheelStatus));
        let data:Data = Data(bytes: bytes, count: bytes.count)
        
        if writeCharacteristic != nil {
            connectPeripheral.writeValue(data, for: writeCharacteristic!, type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    func statusChangeToUInt8(_ status:WheelStatus) -> UInt8 {
        switch status {
        case .Stop:
            return 0xFF
        case .Forward:
            return 0x0F
        case .Backward:
            return 0x00
        }
    }
    
    func setConnectStatus(_ isConnected:Bool) {
        
        if isConnected {
            DispatchQueue.main.async {
                self.tableView.isHidden = true
            }
            centralManager.stopScan()
            devicesArray.removeAllObjects()
            connected = true
        }
        else {
            DispatchQueue.main.async {
                self.tableView.isHidden = false
            }
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            connected = false
        }
    }
    
    // Bluetooth peripherals scanner
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        DispatchQueue.main.async {
            // for UI
            if !(self.devicesArray.contains(peripheral)) {
                self.devicesArray.add(peripheral)
                self.tableView.reloadData()
            }
        }
        
        if peripheral.name == YOUR_PI_BULETOOTH {
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        connectPeripheral = peripheral
        connectPeripheral.delegate = self
        self.setConnectStatus(true)
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        self.setConnectStatus(false);
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        self.setConnectStatus(false);
    }
    
    // MARK: - CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        for  service:CBService in peripheral.services!  {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        for characteristic:CBCharacteristic in service.characteristics! {
            if (characteristic.properties.rawValue & CBCharacteristicProperties.read.rawValue) == CBCharacteristicProperties.read.rawValue {
                readCharacteristic = characteristic;
            }
            if (characteristic.properties.rawValue & CBCharacteristicProperties.notify.rawValue) == CBCharacteristicProperties.notify.rawValue {
                peripheral .setNotifyValue(true, for: characteristic)
            }
            if (characteristic.properties.rawValue & CBCharacteristicProperties.write.rawValue) == CBCharacteristicProperties.write.rawValue {
                writeCharacteristic = characteristic;
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        let ip = String(data: characteristic.value!, encoding: String.Encoding.ascii)!
        StreamManager.getInstance().socketStart(ip)
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (devicesArray.count)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell=UITableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: "mycell")
        let peripheral:CBPeripheral = devicesArray.object(at: indexPath.row) as! CBPeripheral
        
        if peripheral.name != nil {
            cell.textLabel?.text = peripheral.name
        }
        else {
            cell.textLabel?.text = "no name"
        }
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let peripheral:CBPeripheral = devicesArray.object(at: indexPath.row) as! CBPeripheral
        centralManager.connect(peripheral, options: nil)
    }
}
