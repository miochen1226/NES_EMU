//
//  ICartridge.swift
//  NES_EMU
//
//  Created by mio on 2021/8/14.
//

import Foundation
protocol ICartridge:HandleCpuReadProtocol,HandlePpuReadProtocol {
    func HandleCpuReadEx(_ cpuAddress: UInt16,readValue:inout UInt8)
}
