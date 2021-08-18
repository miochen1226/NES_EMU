//
//  Ppu.swift
//  NES_EMU
//
//  Created by mio on 2021/8/15.
//

import Foundation
class Ppu:PpuDef, IPpu{
    func HandleCpuRead(_ cpuAddress: uint16) -> uint8 {
        var result:UInt8 = 0

        switch (cpuAddress)
        {
        case CpuMemory.kPpuStatusReg: // $2002
            
            //@HACK: Some games like Bomberman and Burger Time poll $2002.7 (VBlank flag) expecting the
            // bit to be set before the NMI executes. On actual hardware, this results in a race condition
            // where sometimes the bit won't be set, or the NMI won't occur. See:
            // http://wiki.nesdev.com/w/index.php/NMI#Race_condition and
            // http://forums.nesdev.com/viewtopic.php?t=5005
            // In my emulator code, CPU and PPU execute sequentially, so this race condition does not occur;
            // instead, $2002.7 will normally never be set before NMI is processed, breaking games that
            // depend on it. To fix this, we assume the CPU instruction that executed this read will be at
            // least 3 CPU cycles long, and we check if we _will_ set the VBlank flag on the next PPU update;
            // if so, we set the flag right away and return it.
            let kSetVBlankCycle:UInt32 = YXtoPpuCycle(y: 241, x: 1)
            if (m_cycle < kSetVBlankCycle && (m_cycle + CpuToPpuCycles(3) >= kSetVBlankCycle))
            {
                SetVBlankFlag()
            }

            result = ReadPpuRegister(cpuAddress)

            m_ppuStatusReg.Clear(PpuStatus.InVBlank);
            WritePpuRegister(CpuMemory.kPpuVRamAddressReg1, value: 0)
            WritePpuRegister(CpuMemory.kPpuVRamAddressReg2, value: 0)
            m_vramAndScrollFirstWrite = true
            
            break

        case CpuMemory.kPpuVRamIoReg: // $2007
            
            //assert(m_vramAndScrollFirstWrite && "User code error: trying to read from $2007 when VRAM address not yet fully set via $2006");

            // Read from palette or return buffered value
            if (m_vramAddress >= PpuMemory.kPalettesBase)
            {
                result = m_palette.Read(MapPpuToPalette(ppuAddress: m_vramAddress))
            }
            else
            {
                result = m_vramBufferedValue;
            }

            // Write to register memory for debugging (not actually required)
            WritePpuRegister(cpuAddress, value: result)

            // Always update buffered value from current vram pointer before incrementing it.
            // Note that we don't buffer palette values, we read "under it", which mirrors the name table memory (VRAM/CIRAM).
            m_vramBufferedValue = m_ppuMemoryBus!.Read(m_vramAddress)
                
            // Advance vram pointer
            let advanceOffset:UInt16 = PpuControl1.GetPpuAddressIncrementSize( UInt16(m_ppuControlReg1.Value()) )
            m_vramAddress += advanceOffset;
            
            break;

        default:
            result = ReadPpuRegister(cpuAddress)
        }

        return result
    }
    
    func ReadPpuRegister(_ cpuAddress:UInt16)->UInt8
    {
        return m_ppuRegisters.Read(MapCpuToPpuRegister(cpuAddress))
    }
    
    func MapCpuToPpuRegister(_ cpuAddress:UInt16)->UInt16
    {
        let ppuRegAddress = (cpuAddress - CpuMemory.kPpuRegistersBase ) % CpuMemory.kPpuRegistersSize
        return ppuRegAddress
    }
    
    func WritePpuRegister(_ cpuAddress:UInt16,  value:UInt8)
    {
        //NSLog("WritePpuRegister")
        
        let address = MapCpuToPpuRegister(cpuAddress)
        m_ppuRegisters.Write(address: MapCpuToPpuRegister(cpuAddress), value: value)
    }
    
    func HandleCpuWrite(_ cpuAddress: UInt16, value: UInt8) {
        let registerAddress = MapCpuToPpuRegister(cpuAddress)
        //const uint8
        let oldValue = m_ppuRegisters.Read(registerAddress)

        // Update register value
        //Mio modify
        WritePpuRegister(cpuAddress, value: value)
        
        
        switch (cpuAddress)
        {
        case CpuMemory.kPpuControlReg1: // $2000
            //Mio test
            //printPpuControl1Status()
            SetVRamAddressNameTable(v: &m_tempVRamAddress, value: value & 0x3)

            let oldPpuControlReg1:Bitfield8 = Bitfield8.init()//reinterpret_cast< Bitfield8*>(&oldValue);
            oldPpuControlReg1.Set(oldValue)
            
            let test1 = oldPpuControlReg1.Test(PpuControl1.NmiOnVBlank)
            let test2 = m_ppuControlReg1.Test(PpuControl1.NmiOnVBlank)
            
            if(test2 == true)
            {
                //NSLog("NmiOnVBlank is true")
            }
            let enabledNmiOnVBlank = !oldPpuControlReg1.Test(PpuControl1.NmiOnVBlank) && m_ppuControlReg1.Test(PpuControl1.NmiOnVBlank)
            
            if ( enabledNmiOnVBlank && m_ppuStatusReg.Test(PpuStatus.InVBlank) ) // In vblank (and $2002 not read yet, which resets this bit)
            {
                m_nes!.SignalCpuNmi()
            }
            
            break
        case CpuMemory.kPpuStatusReg:// 0x2002
            
            break
        case CpuMemory.kPpuSprRamAddressReg:// 0x2003
            
            break
        
        case CpuMemory.kPpuSprRamIoReg: // $2004
            
            // Write value to sprite ram at address in $2003 (OAMADDR) and increment address
            var spriteRamAddress = ReadPpuRegister(CpuMemory.kPpuSprRamAddressReg)
            m_oam.Write(address: UInt16(spriteRamAddress), value: value)
            spriteRamAddress = spriteRamAddress &+ 1
            
            WritePpuRegister(CpuMemory.kPpuSprRamAddressReg, value: spriteRamAddress)
            break
        
        case CpuMemory.kPpuVRamAddressReg1: // $2005 (PPUSCROLL)
            
            if (m_vramAndScrollFirstWrite) // First write: X scroll values
            {
                m_fineX = value & 0x07
                SetVRamAddressCoarseX(v: &m_tempVRamAddress, value: (value & ~0x07) >> 3)
            }
            else // Second write: Y scroll values
            {
                SetVRamAddressFineY(v: &m_tempVRamAddress, value: value & 0x07)
                SetVRamAddressCoarseY(v: &m_tempVRamAddress, value: (value & ~0x07) >> 3)
            }

            m_vramAndScrollFirstWrite = !m_vramAndScrollFirstWrite;
            
            break

        case CpuMemory.kPpuVRamAddressReg2: // $2006 (PPUADDR)
            
            let halfAddress = TO16(value)
            if (m_vramAndScrollFirstWrite) // First write: high byte
            {
                // Write 6 bits to high byte - note that technically we shouldn't touch bit 15, but whatever
                m_tempVRamAddress = ((halfAddress & 0x3F) << 8) | (m_tempVRamAddress & 0x00FF);
            }
            else
            {
                m_tempVRamAddress = (m_tempVRamAddress & 0xFF00) | halfAddress;
                m_vramAddress = m_tempVRamAddress; // Update v from t on second write
            }

            m_vramAndScrollFirstWrite = !m_vramAndScrollFirstWrite;
            
            break;

        
        case CpuMemory.kPpuVRamIoReg: // $2007
            
            //assert(m_vramAndScrollFirstWrite && "User code error: trying to write to $2007 when VRAM address not yet fully set via $2006");

            // Write to palette or memory bus
            if (m_vramAddress >= PpuMemory.kPalettesBase)
            {
                m_palette.Write(address: MapPpuToPalette(ppuAddress: m_vramAddress), value: value)
            }
            else
            {
                m_ppuMemoryBus?.Write(m_vramAddress, value: value)
            }

            let advanceOffset = PpuControl1.GetPpuAddressIncrementSize( UInt16(m_ppuControlReg1.Value()) )
            m_vramAddress = m_vramAddress + advanceOffset;
            
            break
        default:
            break
        }
    }
    
    /*
 static let  kPpuStatusReg:uint16                = 0x2002 // (R)
 static let  kPpuSprRamAddressReg:uint16        = 0x2003 // (W) \_ OAMADDR
 static let  kPpuSprRamIoReg:uint16            = 0x2004 // (W) /  OAMDATA
 static let  kPpuVRamAddressReg1:uint16        = 0x2005 // (W2)
 static let  kPpuVRamAddressReg2:uint16        = 0x2006 // (W2) \_
 static let  kPpuVRamIoReg:uint16                = 0x2007 // (RW) /
     **/
    
    
    //var cacheMapVRamCache:[UInt16:UInt16] = [:]
    @inline(__always)
    func MapPpuToVRam(_ ppuAddress:UInt16)->UInt16
    {
        //assert(ppuAddress >= PpuMemory.kVRamBase); // Address may go into palettes (vram pointer)

        
        var virtualVRamAddress = (ppuAddress - PpuMemory.kVRamBase)
            
        if(virtualVRamAddress >= PpuMemory.kVRamSize)
        {
            virtualVRamAddress = virtualVRamAddress % PpuMemory.kVRamSize;
        }
        
        var physicalVRamAddress:UInt16 = 0
        switch (m_nes!.GetNameTableMirroring())
        {
        case RomHeader.NameTableMirroring.Vertical:
            // Vertical mirroring (horizontal scrolling)
            // A B
            // A B
            // Simplest case, just wrap >= 2K
            physicalVRamAddress = virtualVRamAddress % UInt16(NameTableMemory.kSize);
            break

        case RomHeader.NameTableMirroring.Horizontal:
            // Horizontal mirroring (vertical scrolling)
            // A A
            // B B
            if (virtualVRamAddress >= KB(3)) // 4th virtual page (B) maps to 2nd physical page
            {
                physicalVRamAddress = virtualVRamAddress - UInt16(KB(2))
            }
            else if (virtualVRamAddress >= KB(2)) // 3rd virtual page (B) maps to 2nd physical page (B)
            {
                physicalVRamAddress = virtualVRamAddress - UInt16(KB(1))
            }
            else if (virtualVRamAddress >= KB(1)) // 2nd virtual page (A) maps to 1st physical page (A)
            {
                physicalVRamAddress = virtualVRamAddress - UInt16(KB(1))
            }
            else // 1st virtual page (A) maps to 1st physical page (A)
            {
                physicalVRamAddress = virtualVRamAddress;
            }
            break;

        case RomHeader.NameTableMirroring.OneScreenUpper:
            // A A
            // A A
            physicalVRamAddress = virtualVRamAddress % UInt16((NameTableMemory.kSize / 2))
            break;

        case RomHeader.NameTableMirroring.OneScreenLower:
            // B B
            // B B
            physicalVRamAddress = (virtualVRamAddress % UInt16((NameTableMemory.kSize / 2))) + UInt16((NameTableMemory.kSize / 2))
            break;

        default:
            assert(false);
            break;
        }

        return physicalVRamAddress;
    }
    
    @inline(__always)
    func HandlePpuRead(_ ppuAddress: uint16) -> uint8 {
        return m_nameTables.Read(MapPpuToVRam(ppuAddress))
    }
    
    @inline(__always)
    func HandlePpuWrite(_ ppuAddress: UInt16, value: UInt8) {
        let address = MapPpuToVRam(ppuAddress)
        m_nameTables.Write(address: address, value: value);
    }
    
    var m_renderer:Renderer? = nil
    var m_ppuMemoryBus:PpuMemoryBus? = nil
    var m_nes:INes? = nil
    
    func Initialize(ppuMemoryBus:PpuMemoryBus,nes:INes,renderer:Renderer) {
        
        m_renderer = renderer
        m_palette.Initialize()
        m_ppuMemoryBus = ppuMemoryBus
        m_nes = nes
    }
    
    func KB(_ n:UInt)->UInt
    {
        return n*1024
    }
    
    let m_nameTables = NameTableMemory.init()
    
    
    
    
    //Debug
    var tPerformSpriteEvaluation = 0
    var tFetchBackgroundTileData = 0
    var tFetchBackgroundTileData1 = 0
    var tRenderPixel = 0
    var tFetchSpriteData = 0
    
    var m_ppuStatusReg:Bitfield8WithPpuRegister = Bitfield8WithPpuRegister.init()
    var m_ppuControlReg1:Bitfield8WithPpuRegister = Bitfield8WithPpuRegister.init()
    var m_ppuControlReg2:Bitfield8WithPpuRegister = Bitfield8WithPpuRegister.init()
    var m_ppuRegisters:PpuRegisterMemory = PpuRegisterMemory.init()
    var m_spriteFetchData:[SpriteFetchData] = []
    var m_vramAndScrollFirstWrite:Bool = false
    var m_vramAddress:UInt16 = 0
    var m_tempVRamAddress:UInt16 = 0
    var m_vramBufferedValue:UInt8 = 0
    var m_numSpritesToRender = 0
    var m_cycle:UInt32 = 0
    var m_evenFrame = true
    var m_vblankFlagSetThisFrame = false
    
    var m_oam = ObjectAttributeMemory.init()
    var m_oam2 = ObjectAttributeMemory2.init()
    
    var m_renderSprite0 = false
    var m_bgTileFetchDataPipeline0:BgTileFetchData = BgTileFetchData.init()
    var m_bgTileFetchDataPipeline1:BgTileFetchData = BgTileFetchData.init()
    var m_fineX:UInt8 = 0
    
    func Reset()
    {
        m_nameTables.initial(size: KB(2))
        InitPaletteColors()
        // See http://wiki.nesdev.com/w/index.php/PPU_power_up_state
        
        m_ppuStatusReg.initialize(ppuRegisterMemory: m_ppuRegisters,regAddress: CpuMemory.kPpuStatusReg)
        m_ppuControlReg1.initialize(ppuRegisterMemory: m_ppuRegisters,regAddress: CpuMemory.kPpuControlReg1)
        m_ppuControlReg2.initialize(ppuRegisterMemory: m_ppuRegisters,regAddress: CpuMemory.kPpuControlReg2)
        
        //WritePpuRegister(CpuMemory.kPpuControlReg1, value: 0)
        //WritePpuRegister(CpuMemory.kPpuControlReg2, value: 0)
        //WritePpuRegister(CpuMemory.kPpuVRamAddressReg1, value: 0)
        //WritePpuRegister(CpuMemory.kPpuVRamIoReg, value: 0)
        m_spriteFetchData.removeAll()
        for _ in 0...7
        {
            m_spriteFetchData.append(SpriteFetchData.init())
        }
        
        m_vramAndScrollFirstWrite = true

        // Not necessary but helps with debugging
        m_vramAddress = 0xDDDD
        m_tempVRamAddress = 0xDDDD
        m_vramBufferedValue = 0xDD

        m_numSpritesToRender = 0

        m_cycle = 0
        m_evenFrame = true
        m_vblankFlagSetThisFrame = false
    }
    
    @inline(__always)
    func CpuToPpuCycles(_ cpuCycles:UInt32)->UInt32
    {
        return cpuCycles * 3
    }
    
    func ClearOAM2() // OAM2 = $FF
    {
        m_oam2.ClearOAM2()
    }
    
    func Execute(_ cpuCycles:UInt32, completedFrame: inout Bool)
    {
        let ppuCycles = CpuToPpuCycles(cpuCycles)

        completedFrame = false

        let renderingEnabled = m_ppuControlReg2.Test(UInt8(PpuControl2.RenderBackground|PpuControl2.RenderSprites))
        
        for _ in 0 ... ppuCycles-1
        {
            let x:UInt32 = m_cycle % Ppu.kNumScanlineCycles // offset in current scanline
            let y:UInt32 = m_cycle / Ppu.kNumScanlineCycles // scanline

            if ( (y <= 239) || y == 261 ) // Visible and Pre-render scanlines
            {
                if (renderingEnabled) //@TODO: Not sure about this
                {
                    if (x == 64)
                    {
                        // Cycles 1-64: Clear secondary OAM to $FF
                        ClearOAM2();
                    }
                    else if (x == 256)
                    {
                        // Cycles 65-256: Sprite evaluation
                        //let tBegin = clock()
                        PerformSpriteEvaluation(x: x, y: y)
                        //let tDru = clock() - tBegin
                        //tPerformSpriteEvaluation += Int(tDru)
                    }
                    else if (x == 260)
                    {
                        //@TODO: This is a dirty hack for Mapper4 (MMC3) and the like to get around the fact that
                        // my PPU implementation doesn't perform Sprite fetches as expected (must fetch even if no
                        // sprites found on scanline, and fetch each sprite separately like I do for tiles). For now
                        // this mostly works.
                        
                        //TODO
                        m_nes!.HACK_OnScanline()
                    }
                }

                if (x >= 257 && x <= 320) // "HBlank" (idle cycles)
                {
                    if (renderingEnabled)
                    {
                        if (x == 257)
                        {
                            CopyVRamAddressHori(target: &m_vramAddress, source: &m_tempVRamAddress)
                        }
                        else if (y == 261 && x >= 280 && x <= 304)
                        {
                            //@TODO: could optimize by just doing this once on last cycle (x==304)
                            CopyVRamAddressVert(target: &m_vramAddress, source: &m_tempVRamAddress)
                        }
                        else if (x == 320)
                        {
                            // Cycles 257-320: sprite data fetch for next scanline
                            //let tBegin = clock()
                            FetchSpriteData(y)
                            //let tDru = clock() - tBegin
                            //tFetchSpriteData += Int(tDru)
                        }
                    }
                }
                else // Fetch and render cycles
                {
                    //assert(x <= 256 || (x >= 321 && x <= 340));
                    // Update VRAM address and fetch data
                    if (renderingEnabled)
                    {
                        // PPU fetches 4 bytes every 8 cycles for a given tile (NT, AT, LowBG, and HighBG).
                        // We want to know when we're on the last cycle of the HighBG tile byte (see Ntsc_timing.jpg)
                        let lastFetchCycle = (x >= 8) && (x % 8 == 0)

                        if (lastFetchCycle)
                        {
                            //let tBegin = clock()
                            FetchBackgroundTileData()
                            //let tDru = clock() - tBegin
                            //tFetchBackgroundTileData += Int(tDru)
                            

                            // Data for v was just fetched, so we can now increment it
                            if (x != 256)
                            {
                                IncHoriVRamAddress(&m_vramAddress)
                            }
                            else
                            {
                                IncVertVRamAddress(&m_vramAddress)
                            }
                        }
                    }

                    // Render pixel at x,y using pipelined fetch data. If rendering is disabled, will render background color.
                    if (x < Ppu.kScreenWidth && y < Ppu.kScreenHeight)
                    {
                        //let tBegin = clock()
                        RenderPixel(x: x, y: y)
                        //let tDru = clock() - tBegin
                        //tRenderPixel += Int(tDru)
                    }

                    // Clear flags on pre-render line at dot 1
                    if (y == 261 && x == 1)
                    {
                        m_ppuStatusReg.Clear(PpuStatus.InVBlank | PpuStatus.PpuHitSprite0 | PpuStatus.SpriteOverflow)
                    }

                    // Present on (second to) last cycle of last visible scanline
                    //@TODO: Do this on last frame of post-render line?
                    if (y == 239 && x == 339)
                    {
                        completedFrame = true
                        OnFrameComplete()
                    }
                }
            }
            else // Post-render and VBlank 240-260
            {
                assert(y >= 240 && y <= 260);

                if (y == 241 && x == 1)
                {
                    SetVBlankFlag()

                    if (m_ppuControlReg1.Test(PpuControl1.NmiOnVBlank))
                    {
                        m_nes?.SignalCpuNmi()
                    }
                }
            }
            // Update cycle
            m_cycle = (m_cycle + 1) % Ppu.kNumScreenCycles
        }
    }
    
    @inline(__always)
    func PerformSpriteEvaluation(x:UInt32, y:UInt32) // OAM -> OAM2
    {
        //NSLog("PerformSpriteEvaluation")
        // See http://wiki.nesdev.com/w/index.php/PPU_sprite_evaluation

        let isSprite8x16:Bool = m_ppuControlReg1.Test(PpuControl1.SpriteSize8x16)
        
        var spriteHeight:UInt8 = 8
        if(isSprite8x16)
        {
            spriteHeight = 16
        }
        
        // Reset sprite vars for current scanline
        m_numSpritesToRender = 0
        m_renderSprite0 = false

        var n:Int = 0; // Sprite [0-63] in OAM
        var n2 = m_numSpritesToRender // Sprite [0-7] in OAM2

        let oam:[SpriteData] = getOamArray(oamMemory:m_oam)
        //var oam2:[SpriteData] = getOam2Array(oamMemory:m_oam2)
        
        // Attempt to find up to 8 sprites on current scanline
        while (n2 < 8)
        {
            var oam2n2 = m_oam2.getSprite(n)
            
            let spriteY:UInt8 = oam[n].bmpLow;
            oam2n2.bmpLow = spriteY; // (1)

            if (IsSpriteInRangeY(y: y, spriteY: spriteY, spriteHeight: spriteHeight)) // (1a)
            {
                oam2n2.bmpHigh = oam[n].bmpHigh
                oam2n2.attributes = oam[n].attributes
                oam2n2.x = oam[n].x
                
                m_oam2.saveSprite(sprite:oam2n2,index: n2)

                if (n == 0) // If we're going to render sprite 0, set flag so we can detect sprite 0 hit when we render
                {
                    m_renderSprite0 = true
                }

                n2 = n2 + 1
            }

            n = n + 1
            if (n == 64) // (2a)
            {
                // We didn't find 8 sprites, OAM2 contains what we've found so far, so we can bail
                
                m_numSpritesToRender = n2
                //m_oam2.saveSprites(sprites: oam2)
                return
            }
        }

        // We found 8 sprites above. Let's see if there are any more so we can set sprite overflow flag.
        var m:UInt16 = 0; // Byte in sprite data [0-3]
        
        while (n < 64)
        {
            var spriteY:UInt8 = 0
            if(m == 0)
            {
                spriteY = oam[n].bmpHigh
            }
            if(m == 1)
            {
                spriteY = oam[n].bmpLow
            }
            if(m == 2)
            {
                spriteY = oam[n].attributes
            }
            if(m == 3)
            {
                spriteY = oam[n].x
            }
            
            //let spriteY:UInt8 = oam[n][m]; // (3) Evaluate OAM[n][m] as a Y-coordinate (it might not be)
            IncAndWrap(v: &m, size: 4)
            
            if (IsSpriteInRangeY(y: y, spriteY: spriteY, spriteHeight: spriteHeight)) // (3a)
            {
                m_ppuStatusReg.Set(PpuStatus.SpriteOverflow);

                // PPU reads next 3 bytes from OAM. Because of the hardware bug (below), m might not be 1 here, so
                // we carefully increment n when m overflows.
                for i in 0...2
                {
                    if (IncAndWrap(v: &m, size: 4))
                    {
                        n = n + 1
                    }
                }
            }
            else
            {
                // (3b) If the value is not in range, increment n and m (without carry). If n overflows to 0, go to 4; otherwise go to 3
                // The m increment is a hardware bug - if only n was incremented, the overflow flag would be set whenever more than 8
                // sprites were present on the same scanline, as expected.
                n = n + 1
                IncAndWrap(v: &m, size: 4) // This increment is a hardware bug
            }
        }
    }

    @inline(__always)
    func FetchSpriteData(_ y:UInt32) // OAM2 -> render (shift) registers
    {
        //NSLog("FetchSpriteData")
        // See http://wiki.nesdev.com/w/index.php/PPU_rendering#Cycles_257-320
        
        let oam2:[SpriteData] = getOam2Array(oamMemory:m_oam2)
        let isSprite8x16 = m_ppuControlReg1.Test(PpuControl1.SpriteSize8x16)

        if(m_numSpritesToRender == 0)
        {
            return
        }
        for n in 0...m_numSpritesToRender-1
        {
            let spriteY:UInt8 = oam2[n].bmpLow
            let byte1:UInt8 = oam2[n].bmpHigh
            let attribs:UInt8 = oam2[n].attributes
            let flipHorz:Bool = TestBits(target:attribs, value: BIT(6))
            let flipVert:Bool = TestBits(target:attribs, value: BIT(7))

            var patternTableAddress:UInt16 = 0
            var tileIndex:UInt8 = 0
            if ( !isSprite8x16 ) // 8x8 sprite, oam byte 1 is tile index
            {
                if(m_ppuControlReg1.Test(PpuControl1.SpritePatternTableAddress8x8))
                {
                    patternTableAddress = 0x1000
                }
                else
                {
                    patternTableAddress = 0x0000
                }
                tileIndex = byte1
            }
            else // 8x16 sprite, both address and tile index are stored in oam byte 1
            {
                if(TestBits(target: byte1, value: BIT(0)))
                {
                    patternTableAddress = 0x1000
                }
                else
                {
                    patternTableAddress = 0x0000
                }
                tileIndex = UInt8(ReadBits(target: byte1, value: ~BIT(0)))
            }

            var yOffset:UInt8 = UInt8(y) - spriteY
            
            if(isSprite8x16)
            {
                assert(yOffset < 16)
            }
            else
            {
                assert(yOffset < 8)
            }
            

            if (isSprite8x16)
            {
                // In 8x16 mode, first tile is at tileIndex, second tile (underneath) is at tileIndex + 1
                var nextTile:UInt8 = 0
                if (yOffset >= 8)
                {
                    nextTile = nextTile + 1
                    yOffset = yOffset - 8
                }

                // In 8x16 mode, vertical flip also flips the tile index order
                if (flipVert)
                {
                    nextTile = (nextTile + 1) % 2
                }

                tileIndex = tileIndex + nextTile
            }

            if (flipVert)
            {
                yOffset = 7 - yOffset
            }
            assert(yOffset < 8)
            
            let tileOffset:UInt16 = TO16(tileIndex) * 16
            let byte1Address:UInt16 = patternTableAddress + tileOffset + UInt16(yOffset)
            let byte2Address:UInt16 = byte1Address + 8

            //auto& data = m_spriteFetchData[n]
            m_spriteFetchData[n].bmpLow = m_ppuMemoryBus!.Read(byte1Address)
            m_spriteFetchData[n].bmpHigh = m_ppuMemoryBus!.Read(byte2Address)
            m_spriteFetchData[n].attributes = oam2[n].attributes
            m_spriteFetchData[n].x = oam2[n].x

            if (flipHorz)
            {
                m_spriteFetchData[n].bmpLow = FlipBits(m_spriteFetchData[n].bmpLow)
                m_spriteFetchData[n].bmpHigh = FlipBits(m_spriteFetchData[n].bmpHigh)
            }
        }
    }
    
    @inline(__always)
    func FetchBackgroundTileData()
    {
        //NSLog("FetchBackgroundTileData")
        // Load bg tile row data (2 bytes) at v into pipeline
        let v = m_vramAddress
        //let testValue = m_ppuControlReg1.Value()
        let patternTableAddress:UInt16 = PpuControl1.GetBackgroundPatternTableAddress(UInt16(m_ppuControlReg1.Value()))
        
        
        
        let tileIndexAddress:UInt16 = 0x2000 | (v & 0x0FFF)
        let attributeAddress:UInt16 = 0x23C0 | (v & 0x0C00) | ((v >> 4) & 0x38) | ((v >> 2) & 0x07)
        
        //assert(attributeAddress >= PpuMemory.kAttributeTable0 && attributeAddress < PpuMemory.kNameTablesEnd);
        let tileIndex = m_ppuMemoryBus!.Read(tileIndexAddress)
        
        let tileOffset:UInt16 = TO16(tileIndex) * 16
        let fineY:UInt8 = GetVRamAddressFineY(v)
        let byte1Address:UInt16 = patternTableAddress + tileOffset + UInt16(fineY)
        let byte2Address:UInt16 = byte1Address + 8

        // Load attribute byte then compute and store the high palette bits from it for this tile
        // The high palette bits are 2 consecutive bits in the attribute byte. We need to shift it right
        // by 0, 2, 4, or 6 and read the 2 low bits. The amount to shift by is can be computed from the
        // VRAM address as follows: [bit 6, bit 2, 0]
        let attribute:UInt8 = m_ppuMemoryBus!.Read(attributeAddress)
        let attributeShift:UInt8 = UInt8(((v & 0x40) >> 4) | (v & 0x2))
        //assert(attributeShift == 0 || attributeShift == 2 || attributeShift == 4 || attributeShift == 6);
        let paletteHighBits:UInt8 = (attribute >> attributeShift) & 0x3

        
        m_bgTileFetchDataPipeline0.bmpLow = m_bgTileFetchDataPipeline1.bmpLow // Shift pipelined data
        m_bgTileFetchDataPipeline0.bmpHigh = m_bgTileFetchDataPipeline1.bmpHigh
        m_bgTileFetchDataPipeline0.paletteHighBits = m_bgTileFetchDataPipeline1.paletteHighBits
        
        // Push results at top of pipeline
        m_bgTileFetchDataPipeline1.bmpLow = m_ppuMemoryBus!.Read(byte1Address)
        m_bgTileFetchDataPipeline1.bmpHigh = m_ppuMemoryBus!.Read(byte2Address)
        m_bgTileFetchDataPipeline1.paletteHighBits = paletteHighBits
    }
    
    @inline(__always)
    func RenderPixel(x:UInt32, y:UInt32)
    {
        //TODO
        //NSLog("RenderPixel")
        // See http://wiki.nesdev.com/w/index.php/PPU_rendering
        var bgRenderingEnabled = m_ppuControlReg2.Test(PpuControl2.RenderBackground)
        var spriteRenderingEnabled = m_ppuControlReg2.Test(PpuControl2.RenderSprites)
        
        
        // Consider bg/sprites as disabled (for this pixel) if we're not supposed to render it in the left-most 8 pixels
        if ( !m_ppuControlReg2.Test(PpuControl2.BackgroundShowLeft8) && x < 8 )
        {
            bgRenderingEnabled = false
        }

        if ( !m_ppuControlReg2.Test(PpuControl2.SpritesShowLeft8) && x < 8 )
        {
            spriteRenderingEnabled = false
        }
        
        
        // Get the background pixel
        var bgPaletteHighBits:UInt8 = 0
        var bgPaletteLowBits:UInt8 = 0
        if (bgRenderingEnabled)
        {
            // At this point, the data for the current and next tile are in m_bgTileFetchDataPipeline
            let currTile = m_bgTileFetchDataPipeline0
            let nextTile = m_bgTileFetchDataPipeline1

            // Mux uses fine X to select a bit from shift registers
            let muxMask:UInt8 = UInt8(1 << (7 - m_fineX))

            // Instead of actually shifting every cycle, we rebuild the shift register values
            // for the current cycle (using the x value)
            //@TODO: Optimize by storing 16 bit values for low and high bitmap bytes and shifting every cycle
            let xShift:UInt8 = UInt8(x % 8)
            let shiftRegLow:UInt8 = (currTile.bmpLow << xShift) | (nextTile.bmpLow >> (8 - xShift))
            let shiftRegHigh:UInt8 = (currTile.bmpHigh << xShift) | (nextTile.bmpHigh >> (8 - xShift));

            bgPaletteLowBits = (TestBits01(target: muxMask,value: shiftRegHigh) << 1) | (TestBits01(target: muxMask,value: shiftRegLow))

            // Technically, the mux would index 2 8-bit registers containing replicated values for the current
            // and next tile palette high bits (from attribute bytes), but this is faster.
            
            if(xShift + m_fineX < 8)
            {
                bgPaletteHighBits = currTile.paletteHighBits
            }
            else
            {
                bgPaletteHighBits = nextTile.paletteHighBits
            }
        }
        
        // Get the potential sprite pixel
        var foundSprite = false
        var spriteHasBgPriority = false
        var isSprite0 = false
        var sprPaletteHighBits:UInt8 = 0
        var sprPaletteLowBits:UInt8 = 0
        if (spriteRenderingEnabled)
        {
            //for (uint8 n = 0; n < m_numSpritesToRender; ++n)
            
            if(m_numSpritesToRender != 0)
            {
                for n in 0 ... m_numSpritesToRender-1
                {
                    if ( (x >= m_spriteFetchData[n].x) && (x < (m_spriteFetchData[n].x &+ 8)) )
                    {
                        if (!foundSprite)
                        {
                            // Compose "sprite color" (0-3) from high bit in bitmap bytes
                            sprPaletteLowBits = (TestBits01(target: m_spriteFetchData[n].bmpHigh, value: 0x80) << 1) | (TestBits01(target: m_spriteFetchData[n].bmpLow, value: 0x80))

                            // First non-transparent pixel moves on to multiplexer
                            if (sprPaletteLowBits != 0)
                            {
                                foundSprite = true
                                sprPaletteHighBits = ReadBits(target: m_spriteFetchData[n].attributes, value: 0x3)
                                //@TODO: cache this in spriteData
                                spriteHasBgPriority = TestBits(target: m_spriteFetchData[n].attributes, value: BIT(5))

                                if (m_renderSprite0 && (n == 0)) // Rendering pixel from sprite 0?
                                {
                                    isSprite0 = true
                                }
                            }
                        }

                        // Shift out high bits - do this for all (overlapping) sprites in range
                        m_spriteFetchData[n].bmpLow = m_spriteFetchData[n].bmpLow << 1
                        m_spriteFetchData[n].bmpHigh = m_spriteFetchData[n].bmpHigh << 1
                    }
                }
            }
            
        }

        
        // Multiplexer selects background or sprite pixel (see "Priority multiplexer decision table")
        //var color:Color4 = Color4.init()
        if (bgPaletteLowBits == 0)
        {
            if (!foundSprite || sprPaletteLowBits == 0)
            {
                // Background color 0
                GetBackgroundColor(&m_colorPixel)
            }
            else
            {
                // Sprite color
                GetPaletteColor(highBits: sprPaletteHighBits, lowBits: sprPaletteLowBits, paletteBaseAddress: PpuMemory.kSpritePalette, color: &m_colorPixel)
            }
        }
        else
        {
            if (foundSprite && !spriteHasBgPriority)
            {
                // Sprite color
                GetPaletteColor(highBits:sprPaletteHighBits, lowBits: sprPaletteLowBits, paletteBaseAddress:PpuMemory.kSpritePalette, color: &m_colorPixel)
            }
            else
            {
                // BG color
                GetPaletteColor(highBits: bgPaletteHighBits, lowBits: bgPaletteLowBits, paletteBaseAddress: PpuMemory.kImagePalette, color: &m_colorPixel)
            }

            if (isSprite0)
            {
                m_ppuStatusReg.Set(PpuStatus.PpuHitSprite0)
            }
        }

        //return
        
        backBuffer[Int(x), Int(y)] = m_colorPixel.argb
        //.RGBA()//RGBA.from(paletteColor: 0x01)//precomputedPalette[mirrored]
        //m_renderer?.DrawPixel(x: x, y: y, color: &m_colorPixel)
    }
    
    var frame = 0
    var m_colorPixel:Color4 = Color4()
    @inline(__always)
    func OnFrameComplete()
    {
        frame += 1
        swap(&frontBuffer, &backBuffer)
        
        let renderingEnabled = m_ppuControlReg2.Test(UInt8(PpuControl2.RenderBackground|PpuControl2.RenderSprites))
        
        // For odd frames, the cycle at the end of the scanline (340,239) is skipped
        if (!m_evenFrame && renderingEnabled)
        {
            m_cycle = m_cycle + 1
        }

        m_evenFrame = !m_evenFrame
        m_vblankFlagSetThisFrame = false
    }
    
    @inline(__always)
    func SetVBlankFlag()
    {
        if (!m_vblankFlagSetThisFrame)
        {
            m_ppuStatusReg.Set(PpuStatus.InVBlank)
            m_vblankFlagSetThisFrame = true
        }
    }
    
    @inline(__always)
    func getOamArray(oamMemory:ObjectAttributeMemory)->[SpriteData]
    {
        var array:[SpriteData] = []
        for i in 0...ObjectAttributeMemory.kMaxSprites-1
        {
            let spriteData = oamMemory.getSprite(i)
            array.append(spriteData)
        }
        return array
    }
    
    @inline(__always)
    func getOam2Array(oamMemory:ObjectAttributeMemory2)->[SpriteData]
    {
        var array:[SpriteData] = []
        for i in 0...ObjectAttributeMemory2.kMaxSprites-1
        {
            let spriteData = oamMemory.getSprite(i)
            array.append(spriteData)
        }
        return array
    }
    
    @inline(__always)
    func GetBackgroundColor(_ color:inout Color4)
    {
        color = g_paletteColors[Int(m_palette.Read(0))] // BG ($3F00)
    }
}
