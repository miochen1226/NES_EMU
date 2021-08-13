//
//  PpuStatusReg.swift
//  NES_EMU
//
//  Created by mio on 2021/8/12.
//

import Foundation


//CpuMemory.kPpuStatusReg kPpuControlReg1 kPpuControlReg2
class Bitfield8WithPpuRegister:Bitfield8
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
    
    override func Set(_ bits:UInt8)
    {
        m_field |= bits
        writeValueToMemory()
    }
    
    override func SetValue(_ value:UInt8)->UInt8
    {
        m_field = value
        writeValueToMemory()
        return m_field
    }
    
    override func Set(bits:UInt8, enabled:UInt8)
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
    
    func writeValueToMemory()
    {
        let address = Int(MapCpuToPpuRegister(m_regAddress))
        m_ppuRegisters?.putValue(address: address, value: m_field)
    }

    override func  ClearAll()
    {
        let address = Int(MapCpuToPpuRegister(m_regAddress))
        m_field = 0
        m_ppuRegisters?.putValue(address: address, value: m_field)
    }
}
