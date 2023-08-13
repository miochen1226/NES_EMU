//
//  CpuInternalRam.swift
//  NES_EMU
//
//  Created by mio on 2021/8/8.
//

import Foundation
class CpuInternalRam: HandleCpuReadProtocol {
    
    func handleCpuRead(_ cpuAddress: UInt16) -> UInt8 {
        return memory.read(mapCpuToInternalRam(cpuAddress: cpuAddress))
    }
    
    func handleCpuWrite(_ cpuAddress: UInt16, value: UInt8) {
        memory.write(address: mapCpuToInternalRam(cpuAddress: cpuAddress), value: value)
    }
    
    func mapCpuToInternalRam( cpuAddress: UInt16) -> UInt16 {
        assert(cpuAddress < CpuMemory.kInternalRamEnd)
        return cpuAddress % CpuMemory.kInternalRamSize
    }
    
    let memory = CpuInternalMemory.init().initialize(initSize:KB(2))
}
