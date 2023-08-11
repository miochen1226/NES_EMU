//
//  Ppu.swift
//  NES_EMU
//
//  Created by mio on 2021/8/8.
//

import Foundation

class Ppu:IPpu{
   
    var m_ppuStatusReg:Bitfield8WithPpuRegister = Bitfield8WithPpuRegister.init()
    var m_ppuControlReg1:Bitfield8WithPpuRegister = Bitfield8WithPpuRegister.init()
    var m_ppuControlReg2:Bitfield8WithPpuRegister = Bitfield8WithPpuRegister.init()
    
    func Reset()
    {
        InitPaletteColors()
        // See http://wiki.nesdev.com/w/index.php/PPU_power_up_state
        
        m_ppuStatusReg.initialize(ppuRegisterMemory: m_ppuRegisters,regAddress: CpuMemory.kPpuStatusReg)
        m_ppuControlReg1.initialize(ppuRegisterMemory: m_ppuRegisters,regAddress: CpuMemory.kPpuControlReg1)
        m_ppuControlReg2.initialize(ppuRegisterMemory: m_ppuRegisters,regAddress: CpuMemory.kPpuControlReg2)
        
        WritePpuRegister(CpuMemory.kPpuControlReg1, value: 0)
        WritePpuRegister(CpuMemory.kPpuControlReg2, value: 0)
        WritePpuRegister(CpuMemory.kPpuVRamAddressReg1, value: 0)
        WritePpuRegister(CpuMemory.kPpuVRamIoReg, value: 0)
        
        m_spriteFetchData.removeAll()
        for _ in 0...64
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
    
    var m_numSpritesToRender = 0
    func Initialize(ppuMemoryBus:PpuMemoryBus,nes:Nes,renderer:Renderer) {
        
        m_renderer = renderer
        m_palette.Initialize()
        m_ppuMemoryBus = ppuMemoryBus
        m_nes = nes
    }
    
    var m_palette = PaletteMemory.init()
    
    
    
    
    
    
    var m_vramAndScrollFirstWrite:Bool = false
    var m_ppuRegisters:PpuRegisterMemory = PpuRegisterMemory.init()
    var m_tempVRamAddress:UInt16 = 0
    
    var m_vramAddress:UInt16 = 0
    
    var m_fineX:UInt8 = 0                    // Fine x scroll (3 bits), "Loopy x"
    var m_vramBufferedValue:UInt8 = 0
    
    var m_cycle:UInt32 = 0
    var m_evenFrame:Bool = false
    var m_vblankFlagSetThisFrame:Bool = false
    
    
    var m_nes:Nes? = nil
    var m_ppuMemoryBus:PpuMemoryBus? = nil
    
    
    func YXtoPpuCycle(y:UInt32, x:UInt32)->UInt32
    {
        return y * 341 + x;
    }

    func CpuToPpuCycles(_ cpuCycles:UInt32)->UInt32
    {
        return cpuCycles * 3
    }
    
    func SetVBlankFlag()
    {
        if (!m_vblankFlagSetThisFrame)
        {
            m_ppuStatusReg.Set(PpuStatus.InVBlank)
            m_vblankFlagSetThisFrame = true
        }
    }
    
    
    func MapPpuToPalette(ppuAddress:UInt16)->UInt16
    {
        //assert(ppuAddress >= PpuMemory::kPalettesBase && ppuAddress < PpuMemory::kPalettesEnd);

        if(ppuAddress < PpuMemory.kPalettesBase || ppuAddress >= PpuMemory.kPalettesEnd)
        {
            NSLog("ERROR")
            return 0
        }
        
        var paletteAddress = (ppuAddress - PpuMemory.kPalettesBase) % PpuMemory.kPalettesSize;

        // Addresses $3F10/$3F14/$3F18/$3F1C are mirrors of $3F00/$3F04/$3F08/$3F0C
        // If least 2 bits are unset, it's one of the 8 mirrored addresses, so clear bit 4 to mirror
        if ( !TestBits(target: paletteAddress, value: (BIT(1)|BIT(0))) )
        {
            ClearBits(target: &paletteAddress, value: BIT(4))
        }
        return paletteAddress
    }
    
    func ReadPpuRegister(_ cpuAddress:UInt16)->UInt8
    {
        return m_ppuRegisters.Read(MapCpuToPpuRegister(cpuAddress))
    }

    func WritePpuRegister(_ cpuAddress:UInt16,  value:UInt8)
    {
        m_ppuRegisters.Write(address: MapCpuToPpuRegister(cpuAddress), value: value)
        m_ppuStatusReg.reload()
        m_ppuControlReg1.reload()
        m_ppuControlReg2.reload()
    }
    
    
    func HandleCpuRead(_ cpuAddress: UInt16) -> UInt8 {
        assert(cpuAddress >= CpuMemory.kPpuRegistersBase && cpuAddress < CpuMemory.kPpuRegistersEnd)
        
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
            m_ppuStatusReg.Clear(PpuStatus.InVBlank)
            WritePpuRegister(CpuMemory.kPpuVRamAddressReg1, value: 0)
            WritePpuRegister(CpuMemory.kPpuVRamAddressReg2, value: 0)
            m_vramAndScrollFirstWrite = true
            
            break

        case CpuMemory.kPpuVRamIoReg: // $2007
            
            assert(m_vramAndScrollFirstWrite)// && "User code error: trying to read from $2007 when VRAM address not yet fully set via $2006");

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
            //WritePpuRegister(cpuAddress, value: result)

            // Always update buffered value from current vram pointer before incrementing it.
            // Note that we don't buffer palette values, we read "under it", which mirrors the name table memory (VRAM/CIRAM).
            m_vramBufferedValue = m_ppuMemoryBus!.Read(m_vramAddress)
                
            // Advance vram pointer
            let advanceOffset:UInt16 = PpuControl1.GetPpuAddressIncrementSize( m_ppuControlReg1.Value())
            m_vramAddress += advanceOffset
            
            break

        default:
            result = ReadPpuRegister(cpuAddress)
        }

        return result
    }
    
    //var m_oam = ObjectAttributeMemory.init()
    //var m_oam2 = ObjectAttributeMemory2.init()
    
    func HandleCpuWrite(_ cpuAddress:UInt16, value:UInt8)
    {
        let registerAddress = MapCpuToPpuRegister(cpuAddress)
        //const uint8
        let oldValue = m_ppuRegisters.Read(registerAddress)

        // Update register value
        //Mio modify
        WritePpuRegister(cpuAddress, value: value)
        
        
        switch (cpuAddress)
        {
        case CpuMemory.kPpuControlReg1: // $2000
            
            SetVRamAddressNameTable(v: &m_tempVRamAddress, value: value & 0x3)


            let oldPpuControlReg1:Bitfield8 = Bitfield8.init()
            oldPpuControlReg1.Set(oldValue)
            
            let enabledNmiOnVBlank = !oldPpuControlReg1.Test(PpuControl1.NmiOnVBlank) && m_ppuControlReg1.Test(PpuControl1.NmiOnVBlank)
            
            if ( enabledNmiOnVBlank && m_ppuStatusReg.Test(PpuStatus.InVBlank) ) // In vblank (and $2002 not read yet, which resets this bit)
            {
                m_nes!.SignalCpuNmi()
            }
            
            break
        case CpuMemory.kPpuControlReg2: //$2001
            
            
            break
        case CpuMemory.kPpuSprRamIoReg: // $2004
            // Write value to sprite ram at address in $2003 (OAMADDR) and increment address
            
            //kPpuSprRamAddressReg only use in here
            let spriteRamAddress = ReadPpuRegister(CpuMemory.kPpuSprRamAddressReg)
            m_oam.Write(address: UInt16(spriteRamAddress), value: value)
            
            let newAddr = (UInt16(spriteRamAddress)+1)%256
            //Mio new code
            WritePpuRegister(CpuMemory.kPpuSprRamAddressReg, value: UInt8(newAddr))
            
            break
        
        case CpuMemory.kPpuVRamAddressReg1: // $2005 (PPUSCROLL)
            
            if (m_vramAndScrollFirstWrite) // First write: X scroll values
            {
                m_fineX = value & 0x07
                SetVRamAddressCoarseX(v: &m_tempVRamAddress, value: (value & ~0x07) >> 3)
            }
            else // Second write: Y scroll values
            {
                //print("SetVRamAddressFineY->" + String(value))
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
                m_tempVRamAddress = (m_tempVRamAddress & 0xFF00) | halfAddress
                m_vramAddress = m_tempVRamAddress; // Update v from t on second write
            }
            
            m_vramAndScrollFirstWrite = !m_vramAndScrollFirstWrite;
            break
        case CpuMemory.kPpuVRamIoReg: // $2007
            assert(m_vramAndScrollFirstWrite)// && "User code error: trying to write to $2007 when VRAM address not yet fully set via $2006");

            // Write to palette or memory bus
            if (m_vramAddress >= PpuMemory.kPalettesBase)
            {
                m_palette.Write(address: MapPpuToPalette(ppuAddress: m_vramAddress), value: value)
            }
            else
            {
                m_ppuMemoryBus?.Write(m_vramAddress, value: value)
            }

            let advanceOffset = PpuControl1.GetPpuAddressIncrementSize( m_ppuControlReg1.Value())
            m_vramAddress = m_vramAddress + advanceOffset;
            break
 
        default:
            break
        }
    }
    
    func SetVRamAddressFineY(v:inout UInt16, value:UInt8)
    {
        v = (v & ~0x7000) | (TO16(value) << 12)
    }
    
    func SetVRamAddressCoarseX(v:inout UInt16,  value:UInt8)
    {
        v = (v & ~0x001F) | (TO16(value) & 0x001F)
    }
    
    func SetVRamAddressCoarseY(v:inout UInt16, value:UInt8)
    {
        v = (v & ~0x03E0) | (TO16(value) << 5)
    }
    
    let kScreenWidth:UInt32 = 256
    let kScreenHeight:UInt32 = 240
    
    func ClearOAM2() // OAM2 = $FF
    {
        //@NOTE: We don't actually need this step as we track number of sprites to render per scanline
        m_oam2.Clear()
    }
    
    func IsSpriteInRangeY( y:UInt32,  spriteY:UInt8,  spriteHeight:UInt8) -> Bool
    {
        return (y >= spriteY && (y < UInt32(spriteY) + UInt32(spriteHeight)) && spriteY < kScreenHeight)
    }
    
    var m_renderSprite0 = false
    
    func IncAndWrap(v:inout UInt16, size:Int)->Bool
    {
        v = v + 1
        if (v == size)
        {
            v = 0
            return true
        }
        return false
    }
    
    var m_oam = OAM()
    var m_oam2 = OAM()
    
    func PerformSpriteEvaluation(x:UInt32, y:UInt32) // OAM -> OAM2
    {
        //NSLog("PerformSpriteEvaluation")
        // See http://wiki.nesdev.com/w/index.php/PPU_sprite_evaluation

        //miotest
        
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

        //let oam:[SpriteData] = getOamArray(oamMemory:m_oam)
        //var oam2:[SpriteData] = getOam2Array(oamMemory:m_oam2)
        while (n2 < 64)
        {
            let sprite = m_oam.getSprite(n)
            let spriteY:UInt8 = sprite.bmpLow
            
            var sprite2 = SpriteData()
            
            sprite2.bmpLow = spriteY // (1)

            if (IsSpriteInRangeY(y: y, spriteY: spriteY, spriteHeight: spriteHeight)) // (1a)
            {
                sprite2.bmpHigh = sprite.bmpHigh
                sprite2.attributes = sprite.attributes
                sprite2.x = sprite.x
                m_oam2.setSprite(n2, spriteData: sprite2)
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
                return
            }
        }
        
        // We found 8 sprites above. Let's see if there are any more so we can set sprite overflow flag.
        var m:UInt16 = 0; // Byte in sprite data [0-3]
        
        while (n < 64)
        {
            let sprite = m_oam.getSprite(n)
            var spriteY:UInt8 = 0
            if(m == 0)
            {
                spriteY = sprite.bmpHigh
            }
            if(m == 1)
            {
                spriteY = sprite.bmpLow
            }
            if(m == 2)
            {
                spriteY = sprite.attributes
            }
            if(m == 3)
            {
                spriteY = sprite.x
            }
            
            //let spriteY:UInt8 = oam[n][m]; // (3) Evaluate OAM[n][m] as a Y-coordinate (it might not be)
            _ = IncAndWrap(v: &m, size: 4)
            
            if (IsSpriteInRangeY(y: y, spriteY: spriteY, spriteHeight: spriteHeight)) // (3a)
            {
                m_ppuStatusReg.Set(PpuStatus.SpriteOverflow)

                // PPU reads next 3 bytes from OAM. Because of the hardware bug (below), m might not be 1 here, so
                // we carefully increment n when m overflows.
                for _ in 0...2
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
                _ = IncAndWrap(v: &m, size: 4) // This increment is a hardware bug
            }
        }
        
        return
        // Attempt to find up to 8 sprites on current scanline
        /*
        while (n2 < 8)
        {
            let sprite = m_oam.getSprite(n)
            let spriteY:UInt8 = oam[n].bmpLow
            oam2[n2].bmpLow = spriteY // (1)

            if (IsSpriteInRangeY(y: y, spriteY: spriteY, spriteHeight: spriteHeight)) // (1a)
            {
                oam2[n2].bmpHigh = oam[n].bmpHigh
                oam2[n2].attributes = oam[n].attributes
                oam2[n2].x = oam[n].x

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
                m_oam2.saveSprites(sprites: oam2)
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
            _ = IncAndWrap(v: &m, size: 4)
            
            if (IsSpriteInRangeY(y: y, spriteY: spriteY, spriteHeight: spriteHeight)) // (3a)
            {
                m_ppuStatusReg.Set(PpuStatus.SpriteOverflow);

                // PPU reads next 3 bytes from OAM. Because of the hardware bug (below), m might not be 1 here, so
                // we carefully increment n when m overflows.
                for _ in 0...2
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
                _ = IncAndWrap(v: &m, size: 4) // This increment is a hardware bug
            }
        }*/
    }
    
    func FlipBits(_ v:UInt8) -> UInt8
    {
        /*
        let b0 = ((v & Ppu.BIT(0)) << 7)
        let b1 = ((v & BIT(1)) << 5)
        let b2 = ((v & BIT(1)) << 5)
        let b3 = ((v & BIT(1)) << 5)
        let b4 = ((v & BIT(1)) << 5)
        let b5 = ((v & BIT(1)) << 5)
        let b6 = ((v & BIT(1)) << 5)
        let b7 = ((v & BIT(1)) << 5)*/
        return
              ((v & BIT(0)) << 7) | ((v & BIT(1)) << 5) | ((v & BIT(2)) << 3) | ((v & BIT(3)) << 1) | ((v & BIT(4)) >> 1) | ((v & BIT(5)) >> 3) | ((v & BIT(6)) >> 5) | ((v & BIT(7)) >> 7)
    }
    
    func getOamArray(oamMemory:OAM)->[SpriteData]
    {
        var array:[SpriteData] = []
        for i in 0..<ObjectAttributeMemory.kMaxSprites
        {
            let spriteData = oamMemory.getSprite(i)
            array.append(spriteData)
        }
        return array
    }
    
    func getOam2Array(oamMemory:ObjectAttributeMemory2)->[SpriteData]
    {
        var array:[SpriteData] = []
        for i in 0..<ObjectAttributeMemory2.kMaxSprites
        {
            let spriteData = oamMemory.getSprite(i)
            array.append(spriteData)
        }
        return array
    }
    
    func FetchSpriteData(_ y:UInt32) // OAM2 -> render (shift) registers
    {
        //NSLog("FetchSpriteData")
        // See http://wiki.nesdev.com/w/index.php/PPU_rendering#Cycles_257-320
        //miotest
        let isSprite8x16 = m_ppuControlReg1.Test(PpuControl1.SpriteSize8x16)

        if(m_numSpritesToRender == 0)
        {
            return
        }
        for n in 0..<m_numSpritesToRender
        {
            let sprite = m_oam2.getSprite(n)
            let spriteY:UInt8 = sprite.bmpLow
            let byte1:UInt8 = sprite.bmpHigh
            let attribs:UInt8 = sprite.attributes
            let flipHorz:Bool = TestBits(target:UInt16(attribs), value: BIT(6))
            let flipVert:Bool = TestBits(target:UInt16(attribs), value:BIT(7))

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
                if(TestBits(target: UInt16(byte1), value: BIT(0)))
                {
                    patternTableAddress = 0x1000
                }
                else
                {
                    patternTableAddress = 0x0000
                }
                tileIndex = UInt8(ReadBits(target: UInt16(byte1), value: ~BIT(0)))
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
                if(yOffset>7)
                {
                    //Bug
                    print("Err->"+String(yOffset))
                    yOffset = yOffset%8
                    print("Err->->"+String(yOffset))
                }
                yOffset = 7 - yOffset
            }
            assert(yOffset < 8)
            
            let tileOffset:UInt16 = TO16(tileIndex) * 16
            let byte1Address:UInt16 = patternTableAddress + tileOffset + UInt16(yOffset)
            let byte2Address:UInt16 = byte1Address + 8
            m_spriteFetchData[n].bmpLow = m_ppuMemoryBus!.Read(byte1Address)
            m_spriteFetchData[n].bmpHigh = m_ppuMemoryBus!.Read(byte2Address)
            m_spriteFetchData[n].attributes = sprite.attributes
            m_spriteFetchData[n].x = sprite.x
            
            if (flipHorz)
            {
                m_spriteFetchData[n].bmpLow = FlipBits(m_spriteFetchData[n].bmpLow)
                m_spriteFetchData[n].bmpHigh = FlipBits(m_spriteFetchData[n].bmpHigh)
            }
        }
        /*
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
            let flipHorz:Bool = TestBits(target:UInt16(attribs), value: BIT(6))
            let flipVert:Bool = TestBits(target:UInt16(attribs), value:BIT(7))

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
                if(TestBits(target: UInt16(byte1), value: BIT(0)))
                {
                    patternTableAddress = 0x1000
                }
                else
                {
                    patternTableAddress = 0x0000
                }
                tileIndex = UInt8(ReadBits(target: UInt16(byte1), value: ~BIT(0)))
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
            /*
            var spriteFetchData = SpriteFetchData()
            spriteFetchData.bmpLow = m_ppuMemoryBus!.Read(byte1Address)
            spriteFetchData.bmpHigh = m_ppuMemoryBus!.Read(byte2Address)
            spriteFetchData.attributes = oam2[n].attributes
            spriteFetchData.x = oam2[n].x
            
            m_spriteFetchData[n] = spriteFetchData
            //m_spriteFetchData[n].bmpLow = m_ppuMemoryBus!.Read(byte1Address)
            //m_spriteFetchData[n].bmpHigh = m_ppuMemoryBus!.Read(byte2Address)
            //m_spriteFetchData[n].attributes = oam2[n].attributes
            //m_spriteFetchData[n].x = oam2[n].x
             */
            
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
        
        */
    }
    
    var m_spriteFetchData:[SpriteFetchData] = []
    
    func GetVRamAddressFineY(_ v:UInt16)->UInt8
    {
        return TO8((v & 0x7000) >> 12)
    }
    
    var mapColorUse:[UInt8:Bool] = [:]
    func FetchBackgroundTileData()
    {
        // Load bg tile row data (2 bytes) at v into pipeline
        let v = m_vramAddress
        let patternTableAddress:UInt16 = PpuControl1.GetBackgroundPatternTableAddress(m_ppuControlReg1.Value())
        let tileIndexAddress:UInt16 = 0x2000 | (v & 0x0FFF)
        let attributeAddress:UInt16 = 0x23C0 | (v & 0x0C00) | ((v >> 4) & 0x38) | ((v >> 2) & 0x07)
        
        
        assert(attributeAddress >= PpuMemory.kAttributeTable0 && attributeAddress < PpuMemory.kNameTablesEnd)
        
        let tileIndex:UInt8 = m_ppuMemoryBus!.Read(tileIndexAddress)
        
        let tileOffset:UInt16 = TO16(tileIndex) * 16
        let fineY:UInt8 = GetVRamAddressFineY(v)
        let byte1Address:UInt16 = patternTableAddress + tileOffset + UInt16(fineY)
        let byte2Address:UInt16 = byte1Address + 8

        
        // Load attribute byte then compute and store the high palette bits from it for this tile
        // The high palette bits are 2 consecutive bits in the attribute byte. We need to shift it right
        // by 0, 2, 4, or 6 and read the 2 low bits. The amount to shift by is can be computed from the
        // VRAM address as follows: [bit 6, bit 2, 0]
        let attribute:UInt8 = m_ppuMemoryBus!.Read(attributeAddress)
        
        //let bmps:[UInt8] = m_ppuMemoryBus!.Read2(byte1Address)
        //let bmpLow:UInt8 = bmps[0]
        //let bmpHigh:UInt8 = bmps[1]
        
        
        let bmpLow = m_ppuMemoryBus!.Read(byte1Address)
        let bmpHigh = m_ppuMemoryBus!.Read(byte2Address)
        
        let attributeShift:UInt8 = UInt8(((v & 0x40) >> 4) | (v & 0x2))
        let paletteHighBits:UInt8 = (attribute >> attributeShift) & 0x3

        
        m_bgTileFetchDataPipeline_0.bmpLow = m_bgTileFetchDataPipeline_1.bmpLow
        m_bgTileFetchDataPipeline_0.bmpHigh = m_bgTileFetchDataPipeline_1.bmpHigh
        m_bgTileFetchDataPipeline_0.paletteHighBits = m_bgTileFetchDataPipeline_1.paletteHighBits
        
        m_bgTileFetchDataPipeline_1.bmpLow = bmpLow
        m_bgTileFetchDataPipeline_1.bmpHigh = bmpHigh
        m_bgTileFetchDataPipeline_1.paletteHighBits = paletteHighBits
        return
        /*
        m_bgTileFetchDataPipeline[0].bmpLow = m_bgTileFetchDataPipeline[1].bmpLow // Shift pipelined data
        m_bgTileFetchDataPipeline[0].bmpHigh = m_bgTileFetchDataPipeline[1].bmpHigh
        m_bgTileFetchDataPipeline[0].paletteHighBits = m_bgTileFetchDataPipeline[1].paletteHighBits
        
        // Push results at top of pipeline
        m_bgTileFetchDataPipeline[1].bmpLow = m_ppuMemoryBus!.Read(byte1Address)
        //m_bgTileFetchDataPipeline[1].bmpHigh = m_ppuMemoryBus!.Read(byte2Address)
        m_bgTileFetchDataPipeline[1].paletteHighBits = paletteHighBits
         */
    }
    
    let kNumPaletteColors:UInt = 64
    var g_paletteColors:UnsafeMutablePointer<PixelColor>!//[Color4] = []
    
    
    func InitPaletteColors()
    {
        struct RGB {
            var r:UInt8 = 0
            var g:UInt8 = 0
            var b:UInt8 = 0
        }

        //#if USE_PALETTE == 1
        // This palette seems more "accurate"
        // 2C03 and 2C05 palettes (http://wiki.nesdev.com/w/index.php/PPU_palettes#2C03_and_2C05)
        let dac3Palette:[[UInt8]] =
        [
            [3,3,3],[0,1,4],[0,0,6],[3,2,6],[4,0,3],[5,0,3],[5,1,0],[4,2,0],[3,2,0],[1,2,0],[0,3,1],[0,4,0],[0,2,2],[0,0,0],[0,0,0],[0,0,0],
            [5,5,5],[0,3,6],[0,2,7],[4,0,7],[5,0,7],[7,0,4],[7,0,0],[6,3,0],[4,3,0],[1,4,0],[0,4,0],[0,5,3],[0,4,4],[0,0,0],[0,0,0],[0,0,0],
            [7,7,7],[3,5,7],[4,4,7],[6,3,7],[7,0,7],[7,3,7],[7,4,0],[7,5,0],[6,6,0],[3,6,0],[0,7,0],[2,7,6],[0,7,7],[0,0,0],[0,0,0],[0,0,0],
            [7,7,7],[5,6,7],[6,5,7],[7,5,7],[7,4,7],[7,5,5],[7,6,4],[7,7,2],[7,7,3],[5,7,2],[4,7,3],[2,7,6],[4,6,7],[0,0,0],[0,0,0],[0,0,0]
        ]
        
        /*
        let palette:[Int] = [430,326,044,660,000,755,014,630,555,310,070,003,764,770,040,572,
                             737,200,027,747,000,222,510,740,653,053,447,140,403,000,473,357,
                             503,031,420,006,407,507,333,704,022,666,036,020,111,773,444,707,
                          757,777,320,700,760,276,777,467,000,750,637,567,360,657,077,120]
        */
        
        /*
        let palette:[[Int]] =
        [
            [0x80,0x80,0x80], [0x00,0x3D,0xA6], [0x00,0x12,0xB0], [0x44,0x00,0x96],
            [0xA1,0x00,0x5E], [0xC7,0x00,0x28], [0xBA,0x06,0x00], [0x8C,0x17,0x00],
            [0x5C,0x2F,0x00], [0x10,0x45,0x00], [0x05,0x4A,0x00], [0x00,0x47,0x2E],
            [0x00,0x41,0x66], [0x00,0x00,0x00], [0x05,0x05,0x05], [0x05,0x05,0x05],
            [0xC7,0xC7,0xC7], [0x00,0x77,0xFF], [0x21,0x55,0xFF], [0x82,0x37,0xFA],
            [0xEB,0x2F,0xB5], [0xFF,0x29,0x50], [0xFF,0x22,0x00], [0xD6,0x32,0x00],
            [0xC4,0x62,0x00], [0x35,0x80,0x00], [0x05,0x8F,0x00], [0x00,0x8A,0x55],
            [0x00,0x99,0xCC], [0x21,0x21,0x21], [0x09,0x09,0x09], [0x09,0x09,0x09],
            [0xFF,0xFF,0xFF], [0x0F,0xD7,0xFF], [0x69,0xA2,0xFF], [0xD4,0x80,0xFF],
            [0xFF,0x45,0xF3], [0xFF,0x61,0x8B], [0xFF,0x88,0x33], [0xFF,0x9C,0x12],
            [0xFA,0xBC,0x20], [0x9F,0xE3,0x0E], [0x2B,0xF0,0x35], [0x0C,0xF0,0xA4],
            [0x05,0xFB,0xFF], [0x5E,0x5E,0x5E], [0x0D,0x0D,0x0D], [0x0D,0x0D,0x0D],
            [0xFF,0xFF,0xFF], [0xA6,0xFC,0xFF], [0xB3,0xEC,0xFF], [0xDA,0xAB,0xEB],
            [0xFF,0xA8,0xF9], [0xFF,0xAB,0xB3], [0xFF,0xD2,0xB0], [0xFF,0xEF,0xA6],
            [0xFF,0xF7,0x9C], [0xD7,0xE8,0x95], [0xA6,0xED,0xAF], [0xA2,0xF2,0xDA],
            [0x99,0xFF,0xFC], [0xDD,0xDD,0xDD], [0x11,0x11,0x11], [0x11,0x11,0x11]
        ]
         */
        
        g_paletteColors = UnsafeMutablePointer<PixelColor>.allocate(capacity: Int(kNumPaletteColors))
        let rawBuffer = UnsafeMutableRawPointer(g_paletteColors)
        for i:Int in 0..<Int(kNumPaletteColors)
        {
            let colorItem = dac3Palette[Int(i)]
            
            let iR:UInt8 = colorItem[0]
            let iG:UInt8 = colorItem[1]
            let iB:UInt8 = colorItem[2]
            let fr = Float(iR)
            let fg = Float(iG)
            let fb = Float(iB)
            
            
            let R = UInt8(fr/7*255)
            let G = (UInt8(fg/7*255))
            let B = (UInt8(fb/7*255))
            let A = 0xFF
            
            var pixelColor = PixelColor()
            pixelColor.d_r = R
            pixelColor.d_g = G
            pixelColor.d_b = B
            pixelColor.d_a = UInt8(A)
            
            memcpy(rawBuffer?.advanced(by: Int(i*MemoryLayout<PixelColor>.stride)), &pixelColor, MemoryLayout<PixelColor>.stride)
            //g_paletteColors[i] = pixelColor
            
            /*
            let fr = Float(iR)
            let fg = Float(iG)
            let fb = Float(iB)
            
            
            let R = UInt8(fr/7*255)
            let G = (UInt8(fg/7*255))
            let B = (UInt8(fb/7*255))
            let A = 0xFF
            */
            /*
            let colorItem = palette[Int(i)]
            
            let fR = Float(colorItem/100)
            let fG = Float((colorItem-Int(fR)*100)/10)
            let fB = Float(colorItem - Int(fR)*100 - Int(fG)*10)
            
            let R = UInt8(fR/7*255)
            let G = (UInt8(fG/7*255))
            let B = (UInt8(fB/7*255))
            let A = 0xFF
            */
            /*
            let R = iR
            let G = iG
            let B = iB
            let A = 0xFF
            */
            //let rgbItem = Color4.init()
            //rgbItem.SetRGBA(r: R, g: G, b: B, a: UInt8(A))
            //rgbItem.SetRGBA(r: UInt8(R), g: UInt8(G), b: UInt8(B), a: UInt8(A))
            
            //g_paletteColors.append(rgbItem)
        }
    }
    
    struct BgTileFetchData
    {
        var bmpLow:UInt8 = 0
        var bmpHigh:UInt8 = 0
        var paletteHighBits:UInt8 = 0
    }
    var m_bgTileFetchDataPipeline:[BgTileFetchData] = [BgTileFetchData.init(),BgTileFetchData.init()]
    var m_bgTileFetchDataPipeline_0 = BgTileFetchData.init()
    var m_bgTileFetchDataPipeline_1 = BgTileFetchData.init()
    
    func isHitSprite(x:UInt32,spriteData:SpriteFetchData)->Bool
    {
        let left = spriteData.x
        let right:Int = Int(spriteData.x) + 8
        if(x >= left && x <= right)
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    func RenderPixel(x:UInt32, y:UInt32)
    {
        //miotest
        //return
        //NSLog("RenderPixel")
        // See http://wiki.nesdev.com/w/index.php/PPU_rendering
        var bgRenderingEnabled = m_ppuControlReg2.Test(UInt8(PpuControl2.RenderBackground))
        var spriteRenderingEnabled = m_ppuControlReg2.Test(UInt8(PpuControl2.RenderSprites))
        
        // Consider bg/sprites as disabled (for this pixel) if we're not supposed to render it in the left-most 8 pixels
        if ( !m_ppuControlReg2.Test(UInt8(PpuControl2.BackgroundShowLeft8)) && x < 8 )
        {
            bgRenderingEnabled = false
        }

        if ( !m_ppuControlReg2.Test(UInt8(PpuControl2.SpritesShowLeft8)) && x < 8 )
        {
            spriteRenderingEnabled = false
        }
        
        
        // Get the background pixel
        var bgPaletteHighBits:UInt8 = 0
        var bgPaletteLowBits:UInt8 = 0
        
        if (bgRenderingEnabled)
        {
            // At this point, the data for the current and next tile are in m_bgTileFetchDataPipeline
            let currTile = m_bgTileFetchDataPipeline_0
            let nextTile = m_bgTileFetchDataPipeline_1

            // Mux uses fine X to select a bit from shift registers
            
            let muxMask:UInt16 = UInt16(1 << (7 - m_fineX))

            // Instead of actually shifting every cycle, we rebuild the shift register values
            // for the current cycle (using the x value)
            //@TODO: Optimize by storing 16 bit values for low and high bitmap bytes and shifting every cycle
            let xShift:UInt8 = UInt8(x % 8)
            let shiftRegLow:UInt8 = (currTile.bmpLow << xShift) | (nextTile.bmpLow >> (8 - xShift))
            let shiftRegHigh:UInt8 = (currTile.bmpHigh << xShift) | (nextTile.bmpHigh >> (8 - xShift));

            bgPaletteLowBits = (TestBits01(target: muxMask,value: shiftRegHigh) << 1) | (TestBits01(target: muxMask,value: shiftRegLow))

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
            if(m_numSpritesToRender != 0)
            {
                for n in 0 ... m_numSpritesToRender-1
                {
                    var spriteData = m_spriteFetchData[n]
                    
                    if isHitSprite(x:x,spriteData: spriteData)
                    {
                        if (!foundSprite)
                        {
                            // Compose "sprite color" (0-3) from high bit in bitmap bytes
                            sprPaletteLowBits = (TestBits01(target: UInt16(spriteData.bmpHigh), value: 0x80) << 1) | (TestBits01(target: UInt16(spriteData.bmpLow), value: 0x80))
                            
                            // First non-transparent pixel moves on to multiplexer
                            
                            if (sprPaletteLowBits != 0)
                            {
                                foundSprite = true
                                sprPaletteHighBits = UInt8(ReadBits(target: UInt16(spriteData.attributes), value: UInt8(0x3))) //@TODO: cache this in spriteData
                                spriteHasBgPriority = TestBits(target: UInt16(spriteData.attributes), value: BIT(5))
                                
                                
                                if (m_renderSprite0 && (n == 0)) // Rendering pixel from sprite 0?
                                {
                                    isSprite0 = true
                                }
                            }
                        }

                        // Shift out high bits - do this for all (overlapping) sprites in range
                        spriteData.bmpLow = spriteData.bmpLow << 1
                        spriteData.bmpHigh = spriteData.bmpHigh << 1
                        
                        m_spriteFetchData[n] = spriteData
                    }
                }
            }
        }
        //var color:Color4 = Color4.init()
        //var color = PixelColor()
        //return
        // Multiplexer selects background or sprite pixel (see "Priority multiplexer decision table")
        
        if (bgPaletteLowBits == 0)
        {
            if (!foundSprite || sprPaletteLowBits == 0)
            {
                // Background color 0
                //GetBackgroundColor(&color)
                let pixelColor = GetBackgroundPixelColor()
                m_renderer?.DrawPixelColor(x: x, y: y, pixelColor: pixelColor)
            }
            else
            {
                // Sprite color
                let pixelColor = GetPaletteColor(highBits: sprPaletteHighBits, lowBits: sprPaletteLowBits, paletteBaseAddress: PpuMemory.kSpritePalette)
                m_renderer?.DrawPixelColor(x: x, y: y, pixelColor: pixelColor)
            }
        }
        else
        {
            if (foundSprite && !spriteHasBgPriority)
            {
                // Sprite color
                let pixelColor = GetPaletteColor(highBits:sprPaletteHighBits, lowBits: sprPaletteLowBits, paletteBaseAddress:PpuMemory.kSpritePalette)
                m_renderer?.DrawPixelColor(x: x, y: y, pixelColor: pixelColor)
                //GetPaletteColor(highBits:sprPaletteHighBits, lowBits: sprPaletteLowBits, paletteBaseAddress:PpuMemory.kSpritePalette, color: &color)
            }
            else
            {
                // BG color
                let pixelColor = GetPaletteColor(highBits: bgPaletteHighBits, lowBits: bgPaletteLowBits, paletteBaseAddress: PpuMemory.kImagePalette)
                //GetPaletteColor(highBits: bgPaletteHighBits, lowBits: bgPaletteLowBits, paletteBaseAddress: PpuMemory.kImagePalette, color: &color)
                m_renderer?.DrawPixelColor(x: x, y: y, pixelColor: pixelColor)
            }

            if (isSprite0)
            {
                m_ppuStatusReg.Set(PpuStatus.PpuHitSprite0)
            }
        }

        
    }
    
    var m_renderer:Renderer? = nil
    func GetPaletteColor(highBits:UInt8,lowBits:UInt8,paletteBaseAddress:UInt16,color:inout Color4)
    {
        
        assert(lowBits != 0)
        let paletteOffset:UInt8 = (highBits << 2) | (lowBits & 0x3)
        //@NOTE: lowBits is never 0, so we don't have to worry about mapping every 4th byte to 0 (bg color) here.
        // That case is handled specially in the multiplexer code.
        let paletteIndex:Int = Int(m_palette.Read( MapPpuToPalette(ppuAddress: paletteBaseAddress + UInt16(paletteOffset))))
        color.d_r = g_paletteColors[paletteIndex].d_r
        color.d_g = g_paletteColors[paletteIndex].d_g
        color.d_b = g_paletteColors[paletteIndex].d_b
        color.d_a = g_paletteColors[paletteIndex].d_a
        
    }
    
    func GetBackgroundPixelColor()->PixelColor
    {
        let paletteIndex = Int(m_palette.Read(0))
        return g_paletteColors[paletteIndex]
    }
    
    func GetPaletteColor(highBits:UInt8,lowBits:UInt8,paletteBaseAddress:UInt16)->PixelColor
    {
        assert(lowBits != 0)
        let paletteOffset:UInt8 = (highBits << 2) | (lowBits & 0x3)
        let paletteIndex:Int = Int(m_palette.Read( MapPpuToPalette(ppuAddress: paletteBaseAddress + UInt16(paletteOffset))))
        return g_paletteColors[paletteIndex]
    }
    
    func OnFrameComplete()
    {
        let renderingEnabled = m_ppuControlReg2.Test(UInt8(PpuControl2.RenderBackground|PpuControl2.RenderSprites))
        
        // For odd frames, the cycle at the end of the scanline (340,239) is skipped
        if (!m_evenFrame && renderingEnabled)
        {
            m_cycle = m_cycle + 1
        }

        m_evenFrame = !m_evenFrame
        m_vblankFlagSetThisFrame = false
    }
    
    func IncHoriVRamAddress(_ v:inout UInt16)
        {
            if ((v & 0x001F) == 31) // if coarse X == 31
            {
                v &= ~0x001F // coarse X = 0
                v ^= 0x0400 // switch horizontal nametable
            }
            else
        {
            v += 1 // increment coarse X
        }
    }

    func IncVertVRamAddress(_ v:inout UInt16)
    {
        if ((v & 0x7000) != 0x7000) // if fine Y < 7
        {
            v += 0x1000 // increment fine Y
        }
        else
        {
            v &= ~0x7000; // fine Y = 0
            var y = (v & 0x03E0) >> 5 // let y = coarse Y
            if (y == 29)
            {
                y = 0 // coarse Y = 0
                v ^= 0x0800; // switch vertical nametable
            }
            else if (y == 31)
            {
                y = 0 // coarse Y = 0, nametable not switched
            }
            else
            {
                y += 1 // increment coarse Y
            }
            v = (v & ~0x03E0) | (y << 5) // put coarse Y back into v
        }
    }
    
    
    func CopyVRamAddressHori(target:inout UInt16, source:inout UInt16)
    {
        // Copy coarse X (5 bits) and low nametable bit
        target = (target & ~0x041F) | ((source & 0x041F))
    }

    func CopyVRamAddressVert(target:inout UInt16, source:inout UInt16)
    {
        // Copy coarse Y (5 bits), fine Y (3 bits), and high nametable bit
        target = (target & 0x041F) | ((source & ~0x041F))
    }
    var passRenderTime = 30
    var alowRendBg = false
    func Execute(_ cpuCycles:UInt32, completedFrame: inout Bool)
    {
        let kNumTotalScanlines:UInt32 = 262
        let kNumHBlankAndBorderCycles:UInt32 = 85
        let kNumScanlineCycles = UInt32(kScreenWidth + kNumHBlankAndBorderCycles) // 256 + 85 = 341
        let kNumScreenCycles = UInt32(kNumScanlineCycles * kNumTotalScanlines) // 89342 cycles per screen

        let ppuCycles = CpuToPpuCycles(cpuCycles)

        completedFrame = false
        
        if(passRenderTime<=0)
        {
            //alowRendBg = !alowRendBg
        }
        else
        {
            passRenderTime = passRenderTime-1
        }
        let renderingEnabled = m_ppuControlReg2.Test(UInt8(PpuControl2.RenderBackground|PpuControl2.RenderSprites))
        
        if(renderingEnabled)
        {
            //NSLog("renderingEnabled->TRUE")
        }
        for _ in 0..<ppuCycles
        {
            let x = m_cycle % kNumScanlineCycles // offset in current scanline
            let y = m_cycle / kNumScanlineCycles // scanline

            if ( (y <= 239) || y == 261 ) // Visible and Pre-render scanlines
            {
                if (renderingEnabled) //@TODO: Not sure about this
                {
                    if (x == 64)
                    {
                        // Cycles 1-64: Clear secondary OAM to $FF
                        ClearOAM2()
                    }
                    else if (x == 256)
                    {
                        // Cycles 65-256: Sprite evaluation
                        PerformSpriteEvaluation(x: x, y: y)
                    }
                    else if (x == 260)
                    {
                        //@TODO: This is a dirty hack for Mapper4 (MMC3) and the like to get around the fact that
                        // my PPU implementation doesn't perform Sprite fetches as expected (must fetch even if no
                        // sprites found on scanline, and fetch each sprite separately like I do for tiles). For now
                        // this mostly works.
                        
                        //TODO
                        m_nes?.HACK_OnScanline()
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
                            FetchSpriteData(y)
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
                            FetchBackgroundTileData()
                            
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
                    if (x < kScreenWidth && y < kScreenHeight)
                    {
                        RenderPixel(x: x, y: y)
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
                assert(y >= 240 && y <= 260)

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
            m_cycle = (m_cycle + 1) % kNumScreenCycles;
        }
    }
    
    
    func MapCpuToPpuRegister(_ cpuAddress:UInt16)->UInt16
    {
        if(cpuAddress < CpuMemory.kPpuRegistersBase || cpuAddress >= CpuMemory.kPpuRegistersEnd)
        {
            NSLog("ERROR")
        }
        assert(cpuAddress >= CpuMemory.kPpuRegistersBase && cpuAddress < CpuMemory.kPpuRegistersEnd)
        
        let ppuRegAddress = (cpuAddress - CpuMemory.kPpuRegistersBase ) % CpuMemory.kPpuRegistersSize
        return ppuRegAddress
    }
    
    func SetVRamAddressNameTable(v:inout UInt16,  value:UInt8)
    {
        v = (v & ~0x0C00) | (TO16(value) << 10)
    }
    
    func HandlePpuRead(_ ppuAddress:UInt16)->UInt8
    {
        //@NOTE: The palette can only be accessed directly by the PPU (no address lines go out to Cartridge)
        return m_nameTables.Read(MapPpuToVRam(ppuAddress))
    }
    
    let m_nameTables = NameTableMemory.init(initSize: KB(2))
    
    static func KB(_ n:UInt)->UInt
    {
        return n*1024
    }
    
    func KB(_ n:UInt)->UInt
    {
        return n*1024
    }
    
    func HandlePpuWrite(_ ppuAddress:UInt16,  value:UInt8)
    {
        let address = MapPpuToVRam(ppuAddress)
        m_nameTables.Write(address: address, value: value);
    }
    
    func MapPpuToVRam(_ ppuAddress:UInt16)->UInt16
    {
        assert(ppuAddress >= PpuMemory.kVRamBase)
        // Address may go into palettes (vram pointer)

        let virtualVRamAddress = (ppuAddress - PpuMemory.kVRamBase) % PpuMemory.kVRamSize
        
        var physicalVRamAddress:UInt16 = 0
        switch (m_nes!.GetNameTableMirroring())
        {
        case NameTableMirroring.Vertical:
            // Vertical mirroring (horizontal scrolling)
            // A B
            // A B
            // Simplest case, just wrap >= 2K
            physicalVRamAddress = virtualVRamAddress % UInt16(NameTableMemory.kSize)
            break

        case NameTableMirroring.Horizontal:
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
            break

        case NameTableMirroring.OneScreenUpper:
            // A A
            // A A
            physicalVRamAddress = virtualVRamAddress % UInt16((NameTableMemory.kSize / 2))
            break

        case NameTableMirroring.OneScreenLower:
            // B B
            // B B
            physicalVRamAddress = (virtualVRamAddress % UInt16((NameTableMemory.kSize / 2))) + UInt16((NameTableMemory.kSize / 2))
            break

        default:
            assert(false)
            break
        }

        return physicalVRamAddress
    }
}
