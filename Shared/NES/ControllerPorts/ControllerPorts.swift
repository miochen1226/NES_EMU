//
//  ControllerPorts.swift
//  NES_EMU (iOS)
//
//  Created by mio on 2023/7/27.
//

import Foundation

extension ControllerPorts: IControllerPorts {
    func handleCpuRead( _ cpuAddress: UInt16) -> UInt8 {
        var result:UInt8 = 0x40
        let controllerIndex = MapCpuToPorts(cpuAddress)
        
        if controllerIndex == 0 {
            let btnIndex:Int = readIndex[controllerIndex]
            let isButtonDown = readInputDown(controllerIndex: controllerIndex, btnIndex: btnIndex)
            lastIsButtonDown[btnIndex] = isButtonDown
            if isButtonDown {
                result = result | 1
            }
        }
        
        if !strobe {
            readIndex[Int(controllerIndex)] += 1
            if readIndex[Int(controllerIndex)]>7 {
                readIndex[Int(controllerIndex)] = 0
            }
        }
        
        return result
    }
    
    func handleCpuWrite(_ cpuAddress:UInt16, value: UInt8) {
        let controllerIndex = MapCpuToPorts(cpuAddress)
        if controllerIndex == 0 {
            lastStrobe = strobe
            if value == 1 {
                strobe = true
            }
            else {
                strobe = false
            }
            
            if strobe || lastStrobe {
                readIndex[0] = 0
                readIndex[1] = 0
            }
        }
    }
}

class ControllerPorts: NSObject {
    
    func pressL(_ isDown: Bool = true) {
        setKeyPressStatus(6, isPress: isDown)
    }
    
    func pressR(_ isDown: Bool = true) {
        setKeyPressStatus(7, isPress: isDown)
    }
    
    func pressU(_ isDown: Bool = true) {
        setKeyPressStatus(4, isPress: isDown)
    }
    
    func pressD(_ isDown: Bool = true) {
        setKeyPressStatus(5, isPress: isDown)
    }
    
    func pressA(_ isDown: Bool = true) {
        setKeyPressStatus(0, isPress: isDown)
    }
    
    func pressB(_ isDown: Bool = true) {
        setKeyPressStatus(1, isPress: isDown)
    }
    
    func pressStart(_ isDown: Bool = true) {
        setKeyPressStatus(3, isPress: isDown)
    }
    
    func pressSelect(_ isDown:Bool = true) {
        setKeyPressStatus(2, isPress: isDown)
    }
    
    func MapCpuToPorts(_ cpuAddress: UInt16) -> Int {
        if cpuAddress == CpuMemory.kControllerPort1 {
            return 0
        }
        else if cpuAddress == CpuMemory.kControllerPort2 {
            return 1
        }
        return 0
    }
    
    func setKeyPressStatus(_ index: Int, isPress: Bool) {
        lock.lock()
        keyPressStatus[index] = isPress
        lock.unlock()
    }
    
    func getKeyPressStatus(_ index: Int) -> Bool {
        var isPress = false
        lock.lock()
        isPress = keyPressStatus[index] ?? false
        lock.unlock()
        return isPress
    }
    
    func readInputDown(controllerIndex: Int, btnIndex: Int) -> Bool {
        var isDown = false
        if controllerIndex == 0 {
            if getKeyPressStatus(btnIndex) {
                isDown = true
            }
        }
        return isDown
    }
    
    var readIndex:[Int] = [0,0]
    var start_status:Bool = false
    var pushTime = 0
    var lastIsButtonDown:[Bool] = [false,false,false,false,false,false,false,false]
    var isPress = false
    var isReady = false
    var strobe = false
    var lastStrobe = false
    
    var keyPressStatus:[Int:Bool] = [0:false,1:false,2:false,3:false,4:false,5:false,6:false,7:false]
    var isPressStart = false
    
    private let lock = NSLock()
    var readIndex_1 = 0
    var readIndex_2 = 0
}
