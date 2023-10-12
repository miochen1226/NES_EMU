//
//  Bitfield8WithPpuRegister.swift
//  NES_EMU
//
//  Created by mio on 2021/8/12.
//

import Foundation

class Bitfield8WithPpuRegister {
    /*var field: UInt8 = 0
     var ppuRegisters:PpuRegisterMemory? = nil
     var regAddressSelf:Int = 0
     */
    func MapCpuToPpuRegister(_ cpuAddress: UInt16) -> UInt16 {
        let ppuRegAddress = (cpuAddress - CpuMemory.kPpuRegistersBase ) % CpuMemory.kPpuRegistersSize
        return ppuRegAddress
    }
    
    func reload() {
        field = ppuRegisters?.rawRef(address: regAddressSelf) ?? 0
    }
    
    func initialize(ppuRegisterMemory: PpuRegisterMemory, regAddress: UInt16) {
        ppuRegisters = ppuRegisterMemory
        //load default value
        regAddressSelf = Int(MapCpuToPpuRegister(regAddress))
        field = ppuRegisters?.rawRef(address: regAddressSelf) ?? 0
    }
    
    func value() -> UInt8 {
        return field
    }
    
    func read(_ bits:UInt8) -> UInt8 {
        return field & bits
    }
    
    func test(_ bits:UInt8) -> Bool {
        let ret = read(bits)
        
        if ret == 0 {
            return false
        }
        else {
            return true
        }
    }
    
    func test01(_ bits: UInt8) -> UInt8 {
        if read(bits) != 0 {
            return 1
        }
        else {
            return 0
        }
    }
    
    func set(_ bits: UInt8) {
        field |= bits
        writeValueToMemory()
    }
    
    func setValue(_ value: UInt8) -> UInt8 {
        field = value
        writeValueToMemory()
        return field
    }
    
    func set(bits:UInt8, enabled: UInt8) {
        if ((enabled) != 0)
        {
            set(bits)
        }
        else {
            clear(bits)
        }
        
        writeValueToMemory()
    }
    
    func clear(_ bits:UInt8)
    {
        field &= ~bits
        writeValueToMemory()
    }
    
    func writeValueToMemory()
    {
        ppuRegisters?.putValue(address: regAddressSelf, value: field)
    }

    func clearAll() {
        field = 0
        writeValueToMemory()
    }
    
    var field: UInt8 = 0
    var ppuRegisters:PpuRegisterMemory? = nil
    var regAddressSelf:Int = 0
}
