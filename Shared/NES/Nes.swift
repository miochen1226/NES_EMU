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
        
        /*
        for _ in 0...60
        {
            ExecuteCpuAndPpuFrame()
        }
        */
    }
    
    func step()
    {
        //for _ in 0...
        //{
            ExecuteCpuAndPpuFrame()
        //}
    }
    
    func GetNameTableMirroring()->RomHeader.NameTableMirroring
    {
        return m_cartridge.GetNameTableMirroring()
    }
    
    func ExecuteCpuAndPpuFrame()
    {
        //var cpuCycles:uint32 = 0
        
        //m_cpu.Execute(&cpuCycles)
        NSLog("ExecuteCpuAndPpuFrame")
        var completedFrame = false
        var totalCpuCycles:UInt32 = 0
        while (!completedFrame)
        {
            // Update CPU, get number of cycles elapsed
            var cpuCycles:UInt32 = 0
            m_cpu.Execute(&cpuCycles)

            // Update PPU with that many cycles
            m_ppu.Execute(cpuCycles, completedFrame: &completedFrame)

            totalCpuCycles += cpuCycles//*4
         //   m_apu.Execute(cpuCycles);
        }
        NSLog("ExecuteCpuAndPpuFrame end %d",totalCpuCycles)
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
    
    func SignalCpuNmi()
    {
        m_cpu.Nmi()
    }
    func SignalCpuIrq()
    {
        m_cpu.Irq()
    }
}
