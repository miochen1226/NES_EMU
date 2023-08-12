//
//  CpuInternalRam.swift
//  NES_EMU
//
//  Created by mio on 2021/8/8.
//

import Foundation
class CpuInternalRam: HandleCpuReadProtocol {
    
    func HandleCpuRead(_ cpuAddress: UInt16) -> UInt8 {
        return memory.Read(MapCpuToInternalRam(cpuAddress: cpuAddress))
    }
    
    func HandleCpuWrite(_ cpuAddress: UInt16, value: UInt8) {
        memory.Write(address: MapCpuToInternalRam(cpuAddress: cpuAddress), value: value)
    }
    
    func MapCpuToInternalRam( cpuAddress: UInt16) -> UInt16 {
        assert(cpuAddress < CpuMemory.kInternalRamEnd);
        return cpuAddress % CpuMemory.kInternalRamSize;
    }
    let memory = CpuInternalMemory.init().Initialize(initSize:KB(2))
}
