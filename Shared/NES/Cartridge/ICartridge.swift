//
//  ICartridge.swift
//  NES_EMU
//
//  Created by mio on 2021/8/14.
//

import Foundation

protocol ICartridge:HandleCpuReadWriteProtocol,HandlePpuReadWriteProtocol {
    func hackOnScanline(nes:Nes)
}
