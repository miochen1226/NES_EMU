//
//  Ppu_.swift
//  NES_EMU
//
//  Created by mio on 2021/8/14.
//

import Foundation

protocol IPpu:HandleCpuReadWriteProtocol,HandlePpuReadWriteProtocol {
    func initialize(ppuMemoryBus:PpuMemoryBus,nes:Nes,renderer:IRenderer)
    func execute(_ cpuCycles:UInt32, completedFrame: inout Bool)
    func reset()
}
