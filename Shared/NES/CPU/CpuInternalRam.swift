//
//  CpuInternalRam.swift
//  NES_EMU
//
//  Created by mio on 2021/8/8.
//

import Foundation
class CpuInternalRam: HandleCpuReadWriteProtocol, Codable {
    
    enum CodingKeys: String, CodingKey {
        case memory
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        memory = try values.decode(CpuInternalMemory.self, forKey: .memory)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(memory, forKey: .memory)
    }
    init() {
        memory = CpuInternalMemory.init().initialize(initSize:KB(2))
    }
    
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
    
    var memory:CpuInternalMemory! = nil
}
