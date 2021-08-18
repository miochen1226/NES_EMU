//
//  Nes.swift
//  NES_EMU
//
//  Created by mio on 2021/8/8.
//

import Foundation

typealias uint8 = UInt8
typealias uint16 = UInt16
typealias uint32 = UInt32

class Nes:INes{
    
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
    
    public static let frequency = 1789773.0

    var totalCycles = 0
    var completedFrame = false
    
    public var frames: Int {
        m_ppu.frame
    }

    public var screenData: Data {
        Data(bytesNoCopy: m_ppu.frontBuffer.pixels.baseAddress!, count: m_ppu.frontBuffer.pixels.count, deallocator: .none)
    }
    
    public func step(time: TimeInterval) {
        let target = totalCycles + Int(time * Nes.frequency)

        while totalCycles < target {
            step()
        }
    }
    
    func step()
    {
        var cpuCycles:UInt32 = 0
        m_cpu.Execute(&cpuCycles)
        m_ppu.Execute(cpuCycles, completedFrame: &completedFrame)
        totalCycles += Int(cpuCycles)
    }
    
    func GetNameTableMirroring()->RomHeader.NameTableMirroring
    {
        return m_cartridge.GetNameTableMirroring()
    }
    let enableSpeedDev = true
    var totalFrame = 0
    func ExecuteCpuAndPpuFrameForDev()
    {
        var completedFrame = false
        var totleCycle:UInt32 = 0
        m_cpuMemoryBus.readCount = 0
        
        var t = clock()
        
        var tCpuDurTotal = 0
        var tGpuDurTotal = 0
        
        m_ppuMemoryBus.tReadTotal1 = 0
        m_ppuMemoryBus.tReadTotal2 = 0
        m_ppuMemoryBus.tWriteTotal = 0
        
        m_ppu.tPerformSpriteEvaluation = 0
        m_ppu.tFetchBackgroundTileData1 = 0
        m_ppu.tFetchBackgroundTileData = 0
        m_ppu.tRenderPixel = 0
        m_ppu.tFetchSpriteData = 0
        
        //m_ppu.getOrmTime = 0
        
        
        var frameCompute = 0
        self.m_renderer.enableDraw = true
        let tCpu = clock()
        while(true)
        {
            completedFrame = false
            while (!completedFrame)
            {
                // Update CPU, get number of cycles elapsed
                var cpuCycles:UInt32 = 0
                //let tCpu = clock()
                m_cpu.Execute(&cpuCycles)
                //let tCpuDur = clock() - tCpu
                //tCpuDurTotal += Int(tCpuDur)
                
                //let tGpu = clock()
                m_ppu.Execute(cpuCycles, completedFrame: &completedFrame)
                //let tGpuDur = clock() - tGpu
                //tGpuDurTotal += Int(tGpuDur)
                
                
                //totleCycle += cpuCycles
                
                //if(totleCycle > 29780)
                //{
                //    break
                //}
            }
            totalFrame += 1
            
            frameCompute += 1
            if(frameCompute>118)
            {
                //self.m_renderer.enableDraw = true
            }
            if(frameCompute>119)
            {
                break
            }
        }
        
        let tCpuDur = clock() - tCpu
        
        print("The Frame \(Int(frameCompute)) is \(Double(tCpuDur) / Double(CLOCKS_PER_SEC)) seconds")
        //print("The CPU is \(Double(tCpuDurTotal) / Double(CLOCKS_PER_SEC)) seconds")
        //print("The GPU is \(Double(tGpuDurTotal) / Double(CLOCKS_PER_SEC)) seconds")
        
        let printGpuDebug = false
        
        if(printGpuDebug)
        {
            print("The PPM read 1 is \(Double(m_ppuMemoryBus.tReadTotal1) / Double(CLOCKS_PER_SEC)) seconds of CPU time")
            print("The PPM read 2 is \(Double(m_ppuMemoryBus.tReadTotal2) / Double(CLOCKS_PER_SEC)) seconds of CPU time")
            print("The PPM write is \(Double(m_ppuMemoryBus.tWriteTotal) / Double(CLOCKS_PER_SEC)) seconds of CPU time")
            
            print("The tPerformSpriteEvaluation is \(Double(m_ppu.tPerformSpriteEvaluation) / Double(CLOCKS_PER_SEC)) seconds of CPU time")
            print("The tFetchBackgroundTileData is \(Double(m_ppu.tFetchBackgroundTileData) / Double(CLOCKS_PER_SEC)) seconds of CPU time")
            
            print("The tFetchBackgroundTileData1 is \(Double(m_ppu.tFetchBackgroundTileData1) / Double(CLOCKS_PER_SEC)) seconds of CPU time")
            
            
            print("The tRenderPixel is \(Double(m_ppu.tRenderPixel) / Double(CLOCKS_PER_SEC)) seconds of CPU time")
            print("The tFetchSpriteData is \(Double(m_ppu.tFetchSpriteData) / Double(CLOCKS_PER_SEC)) seconds of CPU time")
        }
        //print("The function takes \(t) ticks, which is \(Double(t) / Double(CLOCKS_PER_SEC)) seconds of CPU time")
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
    
    func HACK_OnScanline() { m_cartridge.HACK_OnScanline() }
    
}
