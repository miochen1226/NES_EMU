//
//  Nes.swift
//  NES_EMU
//
//  Created by mio on 2021/8/8.
//

import Foundation
import SpriteKit

class SpriteObj{
    var width:Int = 8
    var height:Int = 8
    var isTransParent = false
    var x = 0
    var y = 0
    var rawColors:[Color4] = []
    
    func getPixel(pos:Int)->[UInt8]
    {
        let y = pos/8
        let x = pos%8
        let dataPix:Color4 = rawColors[x + (7-y)*8]
        return [dataPix.d_r,dataPix.d_g,dataPix.d_b,dataPix.d_a]
        //return [UInt8(0),UInt8(255),UInt8(0),UInt8(255)]
    }
    
    func getTexture()->SKTexture
    {
        let bytes = stride(from: 0, to: (8 * 8), by: 1).flatMap {
            pos in
            return getPixel(pos: pos)
        }
        let data = Data.init(bytes)
        let bgTexture = SKTexture.init(data: data, size: CGSize(width: 8, height: 8))
        return bgTexture
    }
}

class Nes{
    static let sharedInstance = Nes()
    
    let m_cartridge = Cartridge.init()
    
    let m_ppu = Ppu.init()
    let m_apu = Apu.init()
    let m_cpu = Cpu.init()
    let m_controllerPorts = ControllerPorts.init()
    let m_cpuMemoryBus = CpuMemoryBus.init()
    let m_ppuMemoryBus = PpuMemoryBus.init()
    let m_cpuInternalRam = CpuInternalRam.init()
    let m_renderer = Renderer.shared
    init() {
        
        m_cpu.setApu(apu: m_apu)
        m_cpu.setControllerPorts(controllerPorts: m_controllerPorts)
        
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
    
    func getSpriteObjs()->[SpriteObj]
    {
        var spriteObjs:[SpriteObj] = []
        
        let oam1:[SpriteData] = m_ppu.getOamArray(oamMemory:m_ppu.m_oam)
        
        var sprPaletteHighBits:UInt8 = 0
        var sprPaletteLowBits:UInt8 = 0
        for spriteData in oam1
        {
            if(spriteData.bmpLow == 255)
            {
                continue
            }
            
            if(spriteData.x == 0)
            {
                continue
            }
            let spriteObj = SpriteObj()
            spriteObj.x = Int(spriteData.x)
            spriteObj.y = 239 - Int(spriteData.bmpLow)
            
            let attribs:UInt8 = spriteData.attributes
            let flipHorz:Bool = TestBits(target:UInt16(attribs), value: BIT(6))
            //let flipVert:Bool = m_ppu.TestBits(target:UInt16(attribs), value:m_ppu.BIT(7))
            //let spriteHasBgPriority:Bool = m_ppu.TestBits(target: UInt16(attribs), value: m_ppu.BIT(5))
           
            let tileIndex:UInt8 = spriteData.bmpHigh
            let tileOffset:UInt16 = TO16(tileIndex) * 16
            
            let patternTableAddress:UInt16 = 0x0000
            
            var spriteFetchData = SpriteFetchData()
            
            for spY in 0...7
            {
                let byte1Address:UInt16 = patternTableAddress + tileOffset + UInt16(spY)
                let byte2Address:UInt16 = byte1Address + 8
                spriteFetchData.bmpLow = m_ppu.m_ppuMemoryBus!.Read(byte1Address)
                spriteFetchData.bmpHigh = m_ppu.m_ppuMemoryBus!.Read(byte2Address)
                
                
                if (flipHorz)
                {
                    spriteFetchData.bmpLow = m_ppu.FlipBits(spriteFetchData.bmpLow)
                    spriteFetchData.bmpHigh = m_ppu.FlipBits(spriteFetchData.bmpHigh)
                }
                
                for _ in 0...7
                {
                    sprPaletteLowBits = (TestBits01(target: UInt16(spriteFetchData.bmpHigh), value: 0x80) << 1) | (TestBits01(target: UInt16(spriteFetchData.bmpLow), value: 0x80))
                    
                    if (sprPaletteLowBits != 0)
                    {
                        sprPaletteHighBits = UInt8(ReadBits(target: UInt16(spriteData.attributes), value: UInt8(0x3)))

                    }
                          
                    var color:Color4 = Color4.init()
                    m_ppu.GetPaletteColor(highBits: sprPaletteHighBits, lowBits: sprPaletteLowBits, paletteBaseAddress: PpuMemory.kSpritePalette, color: &color)
                    
                    spriteFetchData.bmpLow = spriteFetchData.bmpLow << 1
                    spriteFetchData.bmpHigh = spriteFetchData.bmpHigh << 1
                    
                    if(color.d_b == 0 && color.d_r == 0 && color.d_g == 0)
                    {
                        color.d_a = 0
                    }
                    
                    //Transparent pixel
                    if(sprPaletteLowBits == 0)
                    {
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
    
    func GetNameTableMirroring()->RomHeader.NameTableMirroring
    {
        return m_cartridge.GetNameTableMirroring()
    }
    
    let serialQueue = DispatchQueue(label: "SerialQueue")
    var iRenderScreen:IRenderScreen?
    
    var m_wantQuit = false
   
    func stop()
    {
        m_wantQuit = true
        //m_apu.m_audioDriver?.stop()
    }
    
    func startRun(iRenderScreen:IRenderScreen)
    {
        self.iRenderScreen = iRenderScreen
        serialQueue.async {
            while self.m_wantQuit == false
            {
                var half = false
                //let dateLast = Date()
                //for _ in 0...59
                //{
                    self.ExecuteCpuAndPpuFrame()
                    half = !half
                    //half = false
                    if(half)
                    {
                        DispatchQueue.main.async {
                            self.iRenderScreen?.renderScreen()
                        }
                    }
                //}
                //DispatchQueue.main.async {
                //    self.iRenderScreen?.renderScreen()
                //}
                /*
                while dateLast.timeIntervalSinceNow > -1
                {
                }*/
            }
            print("QUIT")
        }
    }
    
    func getFpsInfo()->String
    {
        //let strFps = String(totalFrame)
        totalFrame = 0
        
        let strFps = String(totalCitcle/30000)
        totalCitcle = 0
        let fpsInfo = "FPS: " + strFps
        return fpsInfo
    }
    var totalFrame = 0
    var totalCitcle:UInt32 = 0
    
    func ExecuteCpuAndPpuFrame()
    {
        var completedFrame = false
        m_cpuMemoryBus.readCount = 0
        var clockCount:UInt32 = 0
        while (!completedFrame)
        //while (clockCount<30000)
        {
            // Update CPU, get number of cycles elapsed
            var cpuCycles:UInt32 = 0
            m_cpu.Execute(&cpuCycles)
            m_ppu.Execute(cpuCycles, completedFrame: &completedFrame)
            m_apu.Execute(cpuCycles)
            
            totalCitcle += cpuCycles
            clockCount += cpuCycles
        }
        self.m_renderer.pushFrame()
        
        //print("Circle->"+String(totalCitcle))
        totalFrame += 1
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
