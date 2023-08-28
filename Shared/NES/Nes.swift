//
//  Nes.swift
//  NES_EMU
//
//  Created by mio on 2021/8/8.
//

import Foundation
import SpriteKit

class PixelRGB {
    var r:UInt8 = 0
    var g:UInt8 = 0
    var b:UInt8 = 0
    var a:UInt8 = 0
}

class Sprite8x8: NSObject {
    var arrayPixelRgb:[UInt8] = []
    override init() {
        super.init()
        rawColors = UnsafeMutablePointer<[UInt8]>.allocate(capacity: 64*4)
        
        for _ in 0..<64 {
            arrayPixelRgb.append(255)
            arrayPixelRgb.append(0)
            arrayPixelRgb.append(0)
            arrayPixelRgb.append(255)
        }
        
        rawColors.initialize(to: arrayPixelRgb)
    }
    /*
    func getPixel(pos:Int) -> [UInt8] {
        let dataPix:Color4 = rawColors.pointee[pos]
        return [dataPix.d_r,dataPix.d_g,dataPix.d_b,dataPix.d_a]
    }
    */
    func getTexture() -> SKTexture {
        let data = Data.init(arrayPixelRgb)
        let bgTexture = SKTexture.init(data: data, size: CGSize(width: 8, height: height))
        return bgTexture
    }
    
    var width:Int = 8
    var height:Int = 8
    var isTransParent = false
    var x = 0
    var y = 0
    //var rawColors:[Color4] = []
    var haveData = false
    
    func rand() {
        for i in 0 ..< 64 {
            let randValue:UInt8 = UInt8(Int.random(in: 0...255))
            /*
            rawColors.pointee[i].d_r = randValue
            rawColors.pointee[i].d_g = randValue
            rawColors.pointee[i].d_b = randValue
            rawColors.pointee[i].d_a = 255
             */
        }
    }
    
    var rawColors:UnsafeMutablePointer<[UInt8]>!
}


struct SpriteObj{
    func getPixel(pos:Int) -> [UInt8] {
        let y = pos/8
        let x = pos%8
        //(height-y-1)*8
        let dataPix:Color4 = rawColors[x + (height-y-1)*8]
        return [dataPix.d_r,dataPix.d_g,dataPix.d_b,dataPix.d_a]
    }
    
    func getTexture() -> SKTexture {
        let bytes = stride(from: 0, to: (8 * height), by: 1).flatMap {
            pos in
            return getPixel(pos: pos)
        }
        let data = Data.init(bytes)
        let bgTexture = SKTexture.init(data: data, size: CGSize(width: 8, height: height))
        return bgTexture
    }
    
    var width:Int = 8
    var height:Int = 8
    var isTransParent = false
    var x = 0
    var y = 0
    var rawColors:[Color4] = []
    
    var haveData = false
    var oamIndex = 0
    
}

class Nes{
    
    init() {
        cpu.setApu(apu: apu)
        cpu.setControllerPorts(controllerPorts: controllerPorts)
        
        renderer.initialize()
        cpu.initialize(cpuMemoryBus: cpuMemoryBus)
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
    
    func getBgSprite8x8s(index: Int) -> Sprite8x8 {
        return ppu.getBgSprite8x8s(index:index)
    }
    
    func getBGSpriteObjs() -> [SpriteObj] {
        var spriteObjs:[SpriteObj] = []
        //var bgSpriteDatas:[BGSpriteData] = []
        
        let tileFetchDataDisplay = ppu.getTileFetchDataDisplay()
        /*for index in 0 ..< 32*30*8 {
            let bgSpriteData = tileFetchDataDisplay[index]
            bgSpriteDatas.append(bgSpriteData)
        }*/
        
        for y8 in 0 ..< 30 {
            for tileX in 0 ..< 32 {
                var spriteObj = SpriteObj()
                spriteObj.x = tileX*8
                spriteObj.y = y8*8//bgSpriteData.y
                //var baseY = (y8*8)*32+tileX
                for y in 0 ..< 8 {
                    let index = (y8*8+(7-y))*32+tileX
                    //(y8*8+(7-y))*32+tileX
                    //print(String("index") + "->" + String(index))
                    let bgSpriteData = tileFetchDataDisplay[index]
                    
                    var bgSpriteDataNext = bgSpriteData
                    if(index < 7678)
                    {
                        bgSpriteDataNext = tileFetchDataDisplay[index+1]
                    }
                    var bgPaletteHighBits:UInt8 = 0
                    var bgPaletteLowBits:UInt8 = 0
                    let currTile = bgSpriteData
                    let nextTile = bgSpriteData
                    
                    if bgSpriteData.isValid {
                        //var spriteObj = SpriteObj()
                        var bgPaletteHighBits:UInt8 = 0
                        var bgPaletteLowBits:UInt8 = 0
                        let currTile = bgSpriteData
                        let nextTile = bgSpriteDataNext
                        
                        for x in 0 ..< 8 {
                            let fineX:UInt8 = 0// scroll , later implement
                            let muxMask:UInt16 = UInt16(1 << (7 - fineX))

                            let xShift:UInt8 = UInt8(x % 8)
                            let shiftRegLow:UInt8 = (currTile.bmpLow << xShift) | (nextTile.bmpLow >> (8 - xShift))
                            let shiftRegHigh:UInt8 = (currTile.bmpHigh << xShift) | (nextTile.bmpHigh >> (8 - xShift));

                            bgPaletteLowBits = (testBits01(target: muxMask,value: shiftRegHigh) << 1) | (testBits01(target: muxMask,value: shiftRegLow))

                            if xShift + fineX < 8 {
                                bgPaletteHighBits = currTile.paletteHighBits
                            }
                            else {
                                bgPaletteHighBits = nextTile.paletteHighBits
                            }
                            
                            if bgPaletteLowBits == 0 {
                                let pixelColor = ppu.getBackgroundPixelColor()
                                
                                spriteObj.width = 8
                                spriteObj.height = 8
                                
                                let color4 = Color4.init(pixelColor: pixelColor)
                                spriteObj.rawColors.append(color4)
                            }
                            else {
                                let pixelColor = ppu.getPaletteColor(highBits: bgPaletteHighBits, lowBits: bgPaletteLowBits, paletteBaseAddress: PpuMemory.kImagePalette)
                                
                                
                                spriteObj.width = 8
                                spriteObj.height = 8
                                
                                let color4 = Color4.init(pixelColor: pixelColor)
                                spriteObj.rawColors.append(color4)
                            }
                        }
                        
                    }
                    else{
                        for x in 0 ..< 8 {
                            let pixelColor = ppu.getBackgroundPixelColor()
                            
                            spriteObj.width = 8
                            spriteObj.height = 8
                            
                            let color4 = Color4.init(pixelColor: pixelColor)
                            spriteObj.rawColors.append(color4)
                        }
                    }
                    
                }
                spriteObjs.append(spriteObj)
            }
        }
        return spriteObjs
    }
    
    
    func saveSprites()
    {
        tempSpriteObjs = getSpriteObjs()
        ppu.cleanAllSprite()
    }
    var tempSpriteObjs:[SpriteObj] = []
    
    
    
    func getSpriteObjs() -> [SpriteObj] {
        
        return ppu.getSpriteObjsEx()
    }
    
    func hackOnScanline() {
        cartridge.hackOnScanline(nes:self)
    }
    
    func getNameTableMirroring() -> NameTableMirroring {
        return cartridge.getNameTableMirroring()
    }
    
    func stop() {
        //apu.audioDriver?.audioUnitPlayer.stop()
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
        
        //apu.audioDriver?.audioUnitPlayer.start()
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
    
    func executeCpuAndPpuFrame()
    {
        var completedFrame = false
        cpuMemoryBus.readCount = 0
        var clockCount:UInt32 = 0
        while (!completedFrame)
        {
            // Update CPU, get number of cycles elapsed
            var cpuCycles:UInt32 = 0
            cpu.execute(&cpuCycles)
            ppu.execute(cpuCycles, completedFrame: &completedFrame)
            
            //apu.execute(cpuCycles)
            clockCount += cpuCycles
        }
        saveSprites()
        //print("-")
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
