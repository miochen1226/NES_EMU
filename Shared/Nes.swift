//
//  Nes.swift
//  NES_EMU
//
//  Created by mio on 2021/8/8.
//

import Foundation
class Nes{
    
    let m_cartridge = Cartridge.init()
    let m_cpu = Cpu.init()
    let m_ppu = Ppu.init()
    let m_cpuMemoryBus = CpuMemoryBus.init()
    let m_cpuInternalRam = CpuInternalRam.init()
    init() {
        m_cpu.Initialize(cpuMemoryBus:m_cpuMemoryBus)
        m_cpuMemoryBus.Initialize(cpu:m_cpu, ppu:m_ppu, cartridge:m_cartridge,cpuInternalRam: m_cpuInternalRam)
    }
    
    func loadRom()
    {
        m_cartridge.loadFile()
        m_cpu.Reset()
        
        for _ in 0...99999
        {
            ExecuteCpuAndPpuFrame()
        }
    }
    
    func ExecuteCpuAndPpuFrame()
    {
        var cpuCycles:uint32 = 0
        
        m_cpu.Execute(&cpuCycles)
        
        //bool completedFrame = false;
        /*
        while (!completedFrame)
        {
            // Update CPU, get number of cycles elapsed
            uint32 cpuCycles;
            m_cpu.Execute(cpuCycles);

            // Update PPU with that many cycles
            m_ppu.Execute(cpuCycles, completedFrame);

            m_apu.Execute(cpuCycles);
        }*/
    }
    
}
