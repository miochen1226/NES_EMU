//
//  ICpu.swift
//  NES_EMU
//
//  Created by mio on 2021/8/14.
//

import Foundation

protocol ICpu:HandleCpuReadWriteProtocol {
    func initialize(cpuMemoryBus: CpuMemoryBus)
    func reset()
    func setApu(apu: IApu)
    func setControllerPorts(controllerPorts: ControllerPorts)
    
    func execute(_ cpuCyclesElapsed: inout UInt32)
    func Nmi()
    func Irq()
}
