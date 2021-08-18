//
//  File.swift
//  NES_EMU
//
//  Created by mio on 2021/8/8.
//

import Foundation
class CpuInternalRam: HandleCpuReadProtocol {
    
    static func KB(_ n:UInt)->UInt
    {
        return n*1024
    }
    
    let m_memory = CpuInternalMemory.init().Initialize(initSize:KB(2))
    
    func HandleCpuRead(_ cpuAddress: uint16) -> uint8 {
        return m_memory.Read(MapCpuToInternalRam(cpuAddress: cpuAddress))
    }
    
    func HandleCpuWrite(_ cpuAddress:UInt16, value:UInt8)
    {
        m_memory.Write(address: MapCpuToInternalRam(cpuAddress: cpuAddress), value: value)
    }
    
    func MapCpuToInternalRam( cpuAddress:UInt16)->UInt16
    {
        assert(cpuAddress < CpuMemory.kInternalRamEnd);
        return cpuAddress % CpuMemory.kInternalRamSize;
    }
}
