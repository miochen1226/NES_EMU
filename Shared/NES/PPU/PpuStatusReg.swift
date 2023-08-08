//
//  PpuStatusReg.swift
//  NES_EMU
//
//  Created by mio on 2021/8/12.
//

import Foundation


//CpuMemory.kPpuStatusReg kPpuControlReg1 kPpuControlReg2
class Bitfield8WithPpuRegister//:Bitfield8
{
    var m_field:UInt8 = 0
    var m_ppuRegisters:PpuRegisterMemory? = nil
    var m_regAddress:UInt16 = 0
    
    func MapCpuToPpuRegister(_ cpuAddress:UInt16)->UInt16
    {
        if(cpuAddress < CpuMemory.kPpuRegistersBase || cpuAddress >= CpuMemory.kPpuRegistersEnd)
        {
            NSLog("ERROR")
        }
        let ppuRegAddress = (cpuAddress - CpuMemory.kPpuRegistersBase ) % CpuMemory.kPpuRegistersSize
        return ppuRegAddress
    }
    
    func reload()
    {
        let address = Int(MapCpuToPpuRegister(m_regAddress))
        m_field = m_ppuRegisters?.Read(UInt16(address)) ?? 0
    }
    
    func initialize(ppuRegisterMemory:PpuRegisterMemory,regAddress:UInt16)
    {
        m_regAddress = regAddress
        m_ppuRegisters = ppuRegisterMemory
        
        //load default value
        let address = Int(MapCpuToPpuRegister(m_regAddress))
        m_field = m_ppuRegisters?.Read(UInt16(address)) ?? 0
    }
    
    func Value()->UInt8
    {
        reload()
        return m_field
    }
    
    func Read(_ bits:UInt8)->UInt8
    {
        reload()
        return m_field & bits
    }
    
    func Test(_ bits:UInt8)->Bool
    {
        reload()
        let ret = Read(bits)
        
        if(ret == 0)
        {
            return false
        }
        else
        {
            return true
        }
    }
    
    func Test01(_ bits:UInt8)->UInt8
    {
        if(Read(bits) != 0)
        {
            return 1
        }
        else
        {
            return 0
        }
    }
    
    func Set(_ bits:UInt8)
    {
        m_field |= bits
        writeValueToMemory()
    }
    
    func SetValue(_ value:UInt8)->UInt8
    {
        m_field = value
        writeValueToMemory()
        return m_field
    }
    
    func Set(bits:UInt8, enabled:UInt8)
    {
        if ((enabled) != 0)
        {
            Set(bits)
        }
        else
        {
            Clear(bits)
        }
        
        writeValueToMemory()
    }
    
    func Clear(_ bits:UInt8)
    {
        m_field &= ~bits
        writeValueToMemory()
    }
    
    func writeValueToMemory()
    {
        let address = Int(MapCpuToPpuRegister(m_regAddress))
        m_ppuRegisters?.putValue(address: address, value: m_field)
    }

    func ClearAll()
    {
        m_field = 0
        writeValueToMemory()
    }
}
