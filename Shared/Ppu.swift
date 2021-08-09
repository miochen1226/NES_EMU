//
//  Ppu.swift
//  NES_EMU
//
//  Created by mio on 2021/8/8.
//

import Foundation
class Ppu:HandleCpuReadProtocol{
    func HandleCpuRead(_ cpuAddress: uint16) -> uint8 {
        return 0
    }
    
    func HandleCpuWrite(cpuAddress:UInt16, value:UInt8)
    {
        //TODO
    }
    
}
