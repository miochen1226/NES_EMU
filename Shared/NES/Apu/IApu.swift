//
//  IApu.swift
//  NES_EMU
//
//  Created by mio on 2023/10/13.
//

import Foundation

protocol IApu: HandleCpuReadWriteProtocol {
    func execute(_ cpuCycles: UInt32)
    func startPlayer()
    func stopPlayer()
}
