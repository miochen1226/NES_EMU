//
//  ControllerPorts.swift
//  NES_EMU (iOS)
//
//  Created by mio on 2023/7/27.
//

import Foundation

class ControllerPorts: NSObject {
    
    var readIndex_1 = 0
    
    var readIndex_2 = 0
    
    func pressL(_ isDown:Bool = true)
    {
        keyPressStatus[6] = isDown
    }
    
    func pressR(_ isDown:Bool = true)
    {
        keyPressStatus[7] = isDown
    }
    
    func pressU(_ isDown:Bool = true)
    {
        keyPressStatus[4] = isDown
    }
    
    func pressD(_ isDown:Bool = true)
    {
        keyPressStatus[5] = isDown
    }
    
    func pressA(_ isDown:Bool = true)
    {
        keyPressStatus[0] = isDown
    }
    
    func pressB(_ isDown:Bool = true)
    {
        keyPressStatus[1] = isDown
    }
    
    func pressStart(_ isDown:Bool = true)
    {
        keyPressStatus[3] = isDown
    }
    
    func pressSelect(_ isDown:Bool = true)
    {
        keyPressStatus[2] = isDown
    }
    
    func MapCpuToPorts(_ cpuAddress:UInt16)->Int
    {
        if (cpuAddress == CpuMemory.kControllerPort1)
        {
            return 0
        }
        else if (cpuAddress == CpuMemory.kControllerPort2)
        {
            return 1
        }

        return 0
    }
    
    var keyPressStatus:[Int:Bool] = [:]
    var isPressStart = false
    func ReadInputDown(controllerIndex:Int, btnIndex:Int)->Bool
    {
        //print("ReadInputDown" + String(controllerIndex) + "-" + String(btnIndex))
        var isDown = false
        
        
        if(controllerIndex == 0)
        {
            if(keyPressStatus[btnIndex] == true)
            {
                isDown = true
                
                //keyPressStatus[btnIndex] = false
            }
        }
        
        return isDown
    }
    
    func HandleCpuRead( cpuAddress:UInt16)->UInt8
    {
        var result:UInt8 = 0x40
        let controllerIndex = MapCpuToPorts(cpuAddress)
        
        if(controllerIndex == 0)
        {
            let btnIndex:Int = m_readIndex[controllerIndex]
            let isButtonDown = ReadInputDown(controllerIndex: controllerIndex, btnIndex: btnIndex)
            
            lastIsButtonDown[btnIndex] = isButtonDown
            
            if(isButtonDown)
            {
                result = result | 1
            }
        }
        else
        {
            //result = 0
            /*
            result = getButtonStatus(readIndex:readIndex_2,controllerIndex:Int(controllerIndex))
            readIndex_2 += 1
            if(readIndex_2>7)
            {
                readIndex_2 = 0
            }*/
        }
        
        if (!m_strobe)
        {
            m_readIndex[Int(controllerIndex)] += 1
            if(m_readIndex[Int(controllerIndex)]>7)
            {
                m_readIndex[Int(controllerIndex)] = 0
            }
        }
        
        return result
    }
    
    var start_status:Bool = false
    var pushTime = 0
    
    
    var lastIsButtonDown:[Bool] = [false,false,false,false,false,false,false,false]
    var isPress = false
    
    var isReady = false
    var m_strobe = false
    var lastStrobe = false
    func HandleCpuWrite(cpuAddress:UInt16, value:UInt8)
    {
        let controllerIndex = MapCpuToPorts(cpuAddress)
        
        if(controllerIndex == 0)
        {
            lastStrobe = m_strobe
            if(value == 1)
            {
                //print("push up 1")
                m_strobe = true
            }
            else
            {
                //print("push up 0")
                m_strobe = false
            }
            
            if (m_strobe || lastStrobe)
            {
                //print("reset control")
                m_readIndex[0] = 0
                m_readIndex[1] = 0
            }
        }
        
    }
    
    var m_readIndex:[Int] = [0,0]
}
