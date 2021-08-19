//
//  Apu.swift
//  APU (iOS)
//
//  Created by mio on 2021/8/19.
//

import Foundation
class Apu
{
    func Initialize()
    {
        Apu_Initialize()
    }
    
    func Execute(cpuCycles:UInt32)
    {
        Apu_Execute(cpuCycles)
    }
    
    func HandleCpuWrite(cpuAddress:UInt16, value:UInt8)
    {
        Apu_HandleCpuWrite(cpuAddress,value)
    }
    func HandleCpuRead(cpuAddress:UInt16)->UInt8
    {
        return Apu_HandleCpuRead(cpuAddress)
    }
    
}
