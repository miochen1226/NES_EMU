//
//  File.swift
//  NES_EMU
//
//  Created by mio on 2021/8/8.
//

import Foundation
class CpuInternalRam: HandleCpuReadProtocol {
    func HandleCpuRead(_ cpuAddress: uint16) -> uint8 {
        return 0
    }
}
