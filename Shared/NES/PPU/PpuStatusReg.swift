//
//  PpuStatusReg.swift
//  NES_EMU
//
//  Created by mio on 2021/8/12.
//

import Foundation


//CpuMemory.kPpuStatusReg kPpuControlReg1 kPpuControlReg2
class Bitfield8WithPpuRegister
{
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
    
    private var m_pField:UInt8 = 0
    var m_field:UInt8
    {
        get{
            m_pField = loadValueFromMemory()
            return m_pField
        }
        set
        {
            m_pField = newValue
            writeValueToMemory()
        }
    }
    
    var mappedAddress = 0
    func initialize(ppuRegisterMemory:PpuRegisterMemory,regAddress:UInt16)
    {
        m_regAddress = regAddress
        m_ppuRegisters = ppuRegisterMemory
        mappedAddress = Int(MapCpuToPpuRegister(m_regAddress))
    }
    
    func loadValueFromMemory()->UInt8
    {
        return m_ppuRegisters!.rawMemory[mappedAddress]
    }
    
    
    func writeValueToMemory()
    {
        m_ppuRegisters!.rawMemory[mappedAddress] = m_pField
    }

    func Value()->UInt8
    {
        return m_field
    }
    
    func SetValue(_ value:UInt8)
    {
        m_field = value
    }

    func  ClearAll() { m_field = 0 }
    
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
    }
    
    func Set(_ bits:UInt8)
    {
        m_field |= bits
    }
    
    func Clear(_ bits:UInt8)
    {
        m_field &= ~bits
    }
    
    func Read(_ bits:UInt8)->UInt8
    {
        return m_field & bits
    }
    
    func Test(_ bits:UInt8)->Bool
    {
        let ret = Read(bits)
        
        if(ret == 0)
        {
            return false
        }
        else
        {
            return true
        }
        //return Read(bits) != 0
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

    // Bit position functions
    func SetPos(bitPos:UInt8, enabled:UInt8)
    {
        if (enabled != 0)
        {
            SetPos(bitPos)
        }
        else
        {
            ClearPos(bitPos)
        }
    }
    
    func SetPos(_ bitPos:UInt8)
    {
        Set(1 << bitPos)
    }
    
    func ClearPos(_ bitPos:UInt8)
    {
        Clear(1 << bitPos)
    }
    
    func ReadPos(_ bitPos:UInt8)->UInt8
    {
        return Read(1 << bitPos)
    }
        
    func TestPos(bitPos:UInt8)->Bool
    {
        return Read(1 << bitPos) != 0
    }
        
    func TestPos01(_ bitPos:UInt8)->UInt8
    {
        if(Read(1 << bitPos) != 0)
        {
            return 1
        }
        else
        {
            return 0
        }
    }
}
