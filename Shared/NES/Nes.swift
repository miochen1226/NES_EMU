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
    let m_ppuMemoryBus = PpuMemoryBus.init()
    let m_cpuInternalRam = CpuInternalRam.init()
    let m_renderer = Renderer.init()
    init() {
        m_renderer.Initialize()
        m_cpu.Initialize(cpuMemoryBus:m_cpuMemoryBus)
        m_ppu.Initialize(ppuMemoryBus: m_ppuMemoryBus, nes: self,renderer:m_renderer)
        m_cpuMemoryBus.Initialize(cpu:m_cpu, ppu:m_ppu, cartridge:m_cartridge,cpuInternalRam: m_cpuInternalRam)
        m_ppuMemoryBus.Initialize(ppu: m_ppu, cartridge: m_cartridge)
    }
    
    func loadRom()
    {
        m_cartridge.loadFile()
        m_cpu.Reset()
        m_ppu.Reset()
    }
    
    func step()
    {
        ExecuteCpuAndPpuFrame()
    }
    
    func GetNameTableMirroring()->RomHeader.NameTableMirroring
    {
        return m_cartridge.GetNameTableMirroring()
    }
    
    func ExecuteCpuAndPpuFrame()
    {
        var completedFrame = false
        m_cpuMemoryBus.readCount = 0
        
        var t = clock()
        while (!completedFrame)
        {
            // Update CPU, get number of cycles elapsed
            var cpuCycles:UInt32 = 0
            m_cpu.Execute(&cpuCycles)
            m_ppu.Execute(cpuCycles, completedFrame: &completedFrame)
            //m_apu.Execute(cpuCycles);
        }
        
        t = clock() - t
        print("The function takes \(t) ticks, which is \(Double(t) / Double(CLOCKS_PER_SEC)) seconds of CPU time")
    }
    
    func SignalCpuNmi()
    {
        m_cpu.Nmi()
    }
    
    func SignalCpuIrq()
    {
        m_cpu.Irq()
    }
}
