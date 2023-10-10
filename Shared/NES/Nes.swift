//
//  Nes.swift
//  NES_EMU
//
//  Created by mio on 2021/8/8.
//

import Foundation
import SpriteKit

class SpriteObj {
    func getPixel(pos:Int) -> [UInt8] {
        let y = pos/8
        let x = pos%8
        let dataPix:Color4 = rawColors[x + (7-y)*8]
        return [dataPix.d_r,dataPix.d_g,dataPix.d_b,dataPix.d_a]
    }
    
    func getTexture() -> SKTexture {
        let bytes = stride(from: 0, to: (8 * 8), by: 1).flatMap {
            pos in
            return getPixel(pos: pos)
        }
        let data = Data.init(bytes)
        let bgTexture = SKTexture.init(data: data, size: CGSize(width: 8, height: 8))
        return bgTexture
    }
    
    var width:Int = 8
    var height:Int = 8
    var isTransParent = false
    var x = 0
    var y = 0
    var rawColors:[Color4] = []
}

class Nes{
    
    init() {
        cpu.setApu(apu: apu)
        cpu.setControllerPorts(controllerPorts: controllerPorts)
        
        renderer.initialize()
        cpu.initialize(cpuMemoryBus: cpuMemoryBus)
        ppu.initialize(ppuMemoryBus: ppuMemoryBus, nes: self,renderer: renderer)
        apu.initialize(nes: self)
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
    
    func getSpriteObjs() -> [SpriteObj] {
        var spriteObjs:[SpriteObj] = []
        var spriteDatas:[SpriteData] = []
        for i in 0 ..< 64 {
            spriteDatas.append(ppu.oam.getSprite(i))
        }
        
        var sprPaletteHighBits:UInt8 = 0
        var sprPaletteLowBits:UInt8 = 0
        for spriteData in spriteDatas {
            if spriteData.bmpLow == 255 {
                continue
            }
            
            if spriteData.x == 0 {
                continue
            }
            
            let spriteObj = SpriteObj()
            spriteObj.x = Int(spriteData.x)
            spriteObj.y = 239 - Int(spriteData.bmpLow)
            
            let attribs:UInt8 = spriteData.attributes
            let flipHorz:Bool = testBits(target:UInt16(attribs), value: BIT(6))
            let tileIndex:UInt8 = spriteData.bmpHigh
            let tileOffset:UInt16 = tO16(tileIndex) * 16
            
            let patternTableAddress:UInt16 = 0x0000
            
            var spriteFetchData = SpriteFetchData()
            
            for spY in 0 ..< 8 {
                let byte1Address:UInt16 = patternTableAddress + tileOffset + UInt16(spY)
                let byte2Address:UInt16 = byte1Address + 8
                spriteFetchData.bmpLow = ppu.ppuMemoryBus!.read(byte1Address)
                spriteFetchData.bmpHigh = ppu.ppuMemoryBus!.read(byte2Address)
                if flipHorz {
                    spriteFetchData.bmpLow = ppu.flipBits(spriteFetchData.bmpLow)
                    spriteFetchData.bmpHigh = ppu.flipBits(spriteFetchData.bmpHigh)
                }
                
                for _ in 0 ..< 8 {
                    sprPaletteLowBits = (testBits01(target: UInt16(spriteFetchData.bmpHigh), value: 0x80) << 1) | (testBits01(target: UInt16(spriteFetchData.bmpLow), value: 0x80))
                    
                    if sprPaletteLowBits != 0 {
                        sprPaletteHighBits = UInt8(readBits(target: UInt16(spriteData.attributes), value: UInt8(0x3)))
                    }
                          
                    var color:Color4 = Color4.init()
                    ppu.GetPaletteColor(highBits: sprPaletteHighBits, lowBits: sprPaletteLowBits, paletteBaseAddress: PpuMemory.kSpritePalette, color: &color)
                    
                    spriteFetchData.bmpLow = spriteFetchData.bmpLow << 1
                    spriteFetchData.bmpHigh = spriteFetchData.bmpHigh << 1
                    
                    if color.d_b == 0 && color.d_r == 0 && color.d_g == 0 {
                        color.d_a = 0
                    }
                    
                    //Transparent pixel
                    if sprPaletteLowBits == 0 {
                        color.d_r = 0
                        color.d_g = 0
                        color.d_b = 0
                        color.d_a = 0
                    }
                    
                    spriteObj.rawColors.append(color)
                }
            }
            
            spriteObjs.append(spriteObj)
        }
        return spriteObjs
    }
    
    func hackOnScanline() {
        cartridge.hackOnScanline(nes:self)
    }
    
    func getNameTableMirroring() -> NameTableMirroring {
        return cartridge.getNameTableMirroring()
    }
    
    func stop() {
        apu.audioDriver?.audioUnitPlayer.stop()
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
        
        apu.audioDriver?.audioUnitPlayer.start()
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
        while (!completedFrame)
        {
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
    
    func pressL(_ isDown: Bool = true) {
        controllerPorts.pressL(isDown)
    }
    
    func pressR(_ isDown: Bool = true)
    {
        controllerPorts.pressR(isDown)
    }
    
    func pressU(_ isDown: Bool = true)
    {
        controllerPorts.pressU(isDown)
    }
    
    func pressD(_ isDown: Bool = true)
    {
        controllerPorts.pressD(isDown)
    }
    
    func pressA(_ isDown: Bool = true) {
        controllerPorts.pressA(isDown)
    }
    
    func pressB(_ isDown: Bool = true) {
        controllerPorts.pressB(isDown)
    }
    
    func pressStart(_ isDown: Bool = true) {
        controllerPorts.pressStart(isDown)
    }
    
    func pressSelect(_ isDown:Bool = true) {
        controllerPorts.pressSelect(isDown)
    }
    
    
    static let sharedInstance = Nes()
    
    let cartridge = Cartridge.init()
    let ppu = Ppu.init()
    let apu = Apu.init()
    let cpu = Cpu.init()
    private let controllerPorts = ControllerPorts.init()
    let cpuMemoryBus = CpuMemoryBus.init()
    let ppuMemoryBus = PpuMemoryBus.init()
    let cpuInternalRam = CpuInternalRam.init()
    let renderer = Renderer.shared
    var wantQuit = false
    var isRunning = false
    var totalFrame = 0
    let serialQueue = DispatchQueue(label: "SerialQueue")
    var iRenderScreen:IRenderScreen?
    let frameLimitTime:Double = 1/60
    
}
