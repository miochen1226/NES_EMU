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
    }
    
    func getTexture()->SKTexture
    {
        let bytes = stride(from: 0, to: (8 * 8), by: 1).flatMap {
            pos in
            return getPixel(pos: pos)
        }
        let data = Data(bytes: bytes)
        let bgTexture = SKTexture.init(data: data, size: CGSize(width: 8, height: 8))
        return bgTexture
    }
}

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
    
    func getSpriteObjs()->[SpriteObj]
    {
        //return []
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
            let spriteObj = SpriteObj()
            spriteObj.x = Int(spriteData.x)
            spriteObj.y = 239 - Int(spriteData.bmpLow)
            
            let attribs:UInt8 = spriteData.attributes
            let flipHorz:Bool = m_ppu.TestBits(target:UInt16(attribs), value: m_ppu.BIT(6))
            let flipVert:Bool = m_ppu.TestBits(target:UInt16(attribs), value:m_ppu.BIT(7))
            
            let spriteHasBgPriority:Bool = m_ppu.TestBits(target: UInt16(attribs), value: m_ppu.BIT(5))
            
            /*
            if(spriteHasBgPriority)
            {
                print("spriteHasBgPriority")
            }*/
            /*
            for x in 0...7
            {
                for y in 0...7
                {
                    spriteObj.rawColors.append(Color4())
                }
            }*/
            
            var tileIndex:UInt8 = spriteData.bmpHigh
            let tileOffset:UInt16 = m_ppu.TO16(tileIndex) * 16
            
            let v = m_ppu.m_vramAddress;
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
                
                //auto& data = m_spriteFetchData[n]
                
                for spX in 0...7
                {
                    sprPaletteLowBits = (m_ppu.TestBits01(target: UInt16(spriteFetchData.bmpHigh), value: 0x80) << 1) | (m_ppu.TestBits01(target: UInt16(spriteFetchData.bmpLow), value: 0x80))
                    
                    if (sprPaletteLowBits != 0)
                    {
                        sprPaletteHighBits = UInt8(m_ppu.ReadBits(target: UInt16(spriteData.attributes), value: 0x3))

                    }
                          
                    var color:Color4 = Color4.init()
                    m_ppu.GetPaletteColor(highBits: sprPaletteHighBits, lowBits: sprPaletteLowBits, paletteBaseAddress: PpuMemory.kSpritePalette, color: &color)
                    
                    
                    spriteFetchData.bmpLow = spriteFetchData.bmpLow << 1
                    spriteFetchData.bmpHigh = spriteFetchData.bmpHigh << 1
                    
                    //if(spriteHasBgPriority)
                    /*{
                        color.d_a = 0
                    }
                    else
                    */
                    if(color.d_b == 0 && color.d_r == 0 && color.d_g == 0)
                    {
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
    func startRun(iRenderScreen:IRenderScreen)
    {
        self.iRenderScreen = iRenderScreen
        serialQueue.async {
            while true
            {
                self.ExecuteCpuAndPpuFrame()
                
                DispatchQueue.main.async {
                    self.iRenderScreen?.renderScreen()
                }
            }
            
        }
    }
    
    var totalFrame = 0
    func ExecuteCpuAndPpuFrame()
    {
        var completedFrame = false
        m_cpuMemoryBus.readCount = 0
        
        //var t = clock()
        //var ticks = 0
        while (!completedFrame)
        {
            // Update CPU, get number of cycles elapsed
            var cpuCycles:UInt32 = 0
            m_cpu.Execute(&cpuCycles)
            
            //if(totalFrame > 360)
            //{
                m_ppu.Execute(cpuCycles, completedFrame: &completedFrame)
            //}
            /*
            else
            {
                ticks += 1
                if(ticks == 3)
                {
                    completedFrame = true
                }
            }
             */
            //m_apu.Execute(cpuCycles);
        }
        
        //totalFrame += 1
        //print(totalFrame/60)
        //t = clock() - t
        //print("The function takes \(t) ticks, which is \(Double(t) / Double(CLOCKS_PER_SEC)) seconds of CPU time")
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
