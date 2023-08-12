//
//  Bitfield8WithPpuRegister.swift
//  NES_EMU
//
//  Created by mio on 2021/8/12.
//

import Foundation

class Bitfield8WithPpuRegister {
    
    func MapCpuToPpuRegister(_ cpuAddress: UInt16) -> UInt16 {
        let ppuRegAddress = (cpuAddress - CpuMemory.kPpuRegistersBase ) % CpuMemory.kPpuRegistersSize
        return ppuRegAddress
    }
    
    func reload() {
        field = ppuRegisters?.RawRef(address: regAddressSelf) ?? 0
    }
    
    func initialize(ppuRegisterMemory: PpuRegisterMemory, regAddress: UInt16) {
        ppuRegisters = ppuRegisterMemory
        //load default value
        regAddressSelf = Int(MapCpuToPpuRegister(regAddress))
        field = ppuRegisters?.RawRef(address: regAddressSelf) ?? 0
    }
    
    func Value() -> UInt8 {
        return field
    }
    
    func Read(_ bits:UInt8) -> UInt8 {
        return field & bits
    }
    
    func Test(_ bits:UInt8) -> Bool {
        let ret = Read(bits)
        
        if ret == 0 {
            return false
        }
        else {
            return true
        }
    }
    
    func Test01(_ bits: UInt8) -> UInt8 {
        if Read(bits) != 0 {
            return 1
        }
        else {
            return 0
        }
    }
    
    func Set(_ bits: UInt8) {
        field |= bits
        writeValueToMemory()
    }
    
    func SetValue(_ value: UInt8) -> UInt8 {
        field = value
        writeValueToMemory()
        return field
    }
    
    func Set(bits:UInt8, enabled: UInt8) {
        if ((enabled) != 0)
        {
            Set(bits)
        }
        else {
            Clear(bits)
        }
        
        writeValueToMemory()
    }
    
    func Clear(_ bits:UInt8)
    {
        field &= ~bits
        writeValueToMemory()
    }
    
    func writeValueToMemory()
    {
        ppuRegisters?.putValue(address: regAddressSelf, value: field)
    }

    func ClearAll() {
        field = 0
        writeValueToMemory()
    }
    
    var field: UInt8 = 0
    var ppuRegisters:PpuRegisterMemory? = nil
    var regAddressSelf:Int = 0
}
