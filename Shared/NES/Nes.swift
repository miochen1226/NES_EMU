//
//  Nes.swift
//  NES_EMU
//
//  Created by mio on 2021/8/8.
//

import Foundation


class Nes {
    init() {
        cpu.initialize(cpuMemoryBus: cpuMemoryBus,apu: apu, controllerPorts: controllerPorts)
        ppu.initialize(ppuMemoryBus: ppuMemoryBus, nes: self,renderer: renderer)
        cpuMemoryBus.initialize(cpu: cpu, ppu: ppu, cartridge: cartridge,cpuInternalRam: cpuInternalRam)
        ppuMemoryBus.initialize(ppu: ppu, cartridge: cartridge)
    }
    
    deinit {
        self.stop()
    }
    
    func loadRom() {
        cartridge.loadFile()
        cpu.reset()
        ppu.reset()
    }
    
    func step() {
        executeCpuAndPpuFrame()
    }
    
    func hackOnScanline() {
        cartridge.hackOnScanline(nes:self)
    }
    
    func getNameTableMirroring() -> NameTableMirroring {
        return cartridge.getNameTableMirroring()
    }
    
    func stop() {
        apu.stopPlayer()
        wantQuit = true
        while isRunning {
            usleep(1000)
        }
        wantQuit = false
    }
    
    func setRenderScreen(iRenderScreen: IRenderScreen) {
        self.iRenderScreen = iRenderScreen
    }
    
    func start() {
        stop()
        apu.startPlayer()
        serialQueue.async {
            self.isRunning = true
            while self.wantQuit == false {
                let beginDate = Date().timeIntervalSince1970
                self.executeCpuAndPpuFrame()
                self.renderer.pushFrame()
                
                DispatchQueue.main.async {
                    self.iRenderScreen?.renderScreen()
                }
                
                let endDate = Date().timeIntervalSince1970
                let dateDiff = endDate - beginDate
                if dateDiff < self.frameLimitTime {
                    let needSleep:Double = self.frameLimitTime - dateDiff
                    let needSleepMilisec = UInt32(needSleep*1000000)
                    usleep(needSleepMilisec)
                }
            }
            self.isRunning = false
            self.wantQuit = false
        }
    }
    
    func getFpsInfo() -> String {
        let strFps = String(totalFrame)
        totalFrame = 0
        let fpsInfo = "FPS: " + strFps
        return fpsInfo
    }
    
    func executeCpuAndPpuFrame() {
        var completedFrame = false
        cpuMemoryBus.readCount = 0
        var clockCount:UInt32 = 0
        while (!completedFrame) {
            // Update CPU, get number of cycles elapsed
            var cpuCycles:UInt32 = 0
            cpu.execute(&cpuCycles)
            ppu.execute(cpuCycles, completedFrame: &completedFrame)
            apu.execute(cpuCycles)
            clockCount += cpuCycles
        }
        
        totalFrame += 1
    }
    
    func SignalCpuNmi() {
        cpu.Nmi()
    }
    
    func SignalCpuIrq() {
        cpu.Irq()
    }
    
    static let sharedInstance = Nes()
    
    let cartridge = Cartridge.init()
    var ppu:IPpu = Ppu()
    let apu:IApu = Apu()
    var cpu:ICpu = Cpu()
    let controllerPorts = ControllerPorts()
    let cpuMemoryBus = CpuMemoryBus()
    let ppuMemoryBus = PpuMemoryBus()
    var cpuInternalRam = CpuInternalRam()
    let renderer:IRenderer = Renderer.shared
    var wantQuit = false
    var isRunning = false
    var totalFrame = 0
    let serialQueue = DispatchQueue(label: "SerialQueue")
    var iRenderScreen:IRenderScreen?
    let frameLimitTime:Double = 1/60
}


