//
//  Ppu.swift
//  NES_EMU
//
//  Created by mio on 2021/8/8.
//

import Foundation

struct BgTileFetchData {
    var bmpLow:UInt8 = 0
    var bmpHigh:UInt8 = 0
    var paletteHighBits:UInt8 = 0
}

class PpuBase : Codable {
    enum CodingKeys: String, CodingKey {
        case ppuRegisters
        case kNumPaletteColors
        case nameTables
        case ppuControlReg1
        case ppuControlReg2
        case numSpritesToRender
        case vramAndScrollFirstWrite
        case kScreenWidth
        case kScreenHeight
        case renderSprite0
        case oam
        case oam2
        case palette
    }
    
    init() {
    }
    
    func initPaletteColors() {
        struct RGB {
            var r:UInt8 = 0
            var g:UInt8 = 0
            var b:UInt8 = 0
        }

        // This palette seems more "accurate"
        // 2C03 and 2C05 palettes (http://wiki.nesdev.com/w/index.php/PPU_palettes#2C03_and_2C05)
        let dac3Palette:[[UInt8]] =
        [
            [3,3,3],[0,1,4],[0,0,6],[3,2,6],[4,0,3],[5,0,3],[5,1,0],[4,2,0],[3,2,0],[1,2,0],[0,3,1],[0,4,0],[0,2,2],[0,0,0],[0,0,0],[0,0,0],
            [5,5,5],[0,3,6],[0,2,7],[4,0,7],[5,0,7],[7,0,4],[7,0,0],[6,3,0],[4,3,0],[1,4,0],[0,4,0],[0,5,3],[0,4,4],[0,0,0],[0,0,0],[0,0,0],
            [7,7,7],[3,5,7],[4,4,7],[6,3,7],[7,0,7],[7,3,7],[7,4,0],[7,5,0],[6,6,0],[3,6,0],[0,7,0],[2,7,6],[0,7,7],[0,0,0],[0,0,0],[0,0,0],
            [7,7,7],[5,6,7],[6,5,7],[7,5,7],[7,4,7],[7,5,5],[7,6,4],[7,7,2],[7,7,3],[5,7,2],[4,7,3],[2,7,6],[4,6,7],[0,0,0],[0,0,0],[0,0,0]
        ]
        
        paletteColors = UnsafeMutablePointer<PixelColor>.allocate(capacity: Int(kNumPaletteColors))
        let rawBuffer = UnsafeMutableRawPointer(paletteColors)
        for i:Int in 0 ..< Int(kNumPaletteColors)
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
        }
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        ppuRegisters = try values.decode(PpuRegisterMemory.self, forKey: .ppuRegisters)
        kNumPaletteColors = try values.decode(UInt.self, forKey: .kNumPaletteColors)
        nameTables = try values.decode(NameTableMemory.self, forKey: .nameTables)
        numSpritesToRender = try values.decode(Int.self, forKey: .numSpritesToRender)
        vramAndScrollFirstWrite = try values.decode(Bool.self, forKey: .vramAndScrollFirstWrite)
        kScreenWidth = try values.decode(UInt32.self, forKey: .kScreenWidth)
        kScreenHeight = try values.decode(UInt32.self, forKey: .kScreenHeight)
        renderSprite0 = try values.decode(Bool.self, forKey: .renderSprite0)
        oam = try values.decode(OAM.self, forKey: .oam)
        oam2 = try values.decode(OAM.self, forKey: .oam2)
        palette = try values.decode(PaletteMemory.self, forKey: .palette)
        
        ppuStatusReg.initialize(ppuRegisterMemory: ppuRegisters,regAddress: CpuMemory.kPpuStatusReg)
        ppuControlReg1.initialize(ppuRegisterMemory: ppuRegisters,regAddress: CpuMemory.kPpuControlReg1)
        ppuControlReg2.initialize(ppuRegisterMemory: ppuRegisters,regAddress: CpuMemory.kPpuControlReg2)
        
        initPaletteColors()
        
        spriteFetchData.removeAll()
        for _ in 0 ..< 64 {
            spriteFetchData.append(SpriteFetchData.init())
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ppuRegisters, forKey: .ppuRegisters)
        try container.encode(kNumPaletteColors, forKey: .kNumPaletteColors)
        try container.encode(nameTables, forKey: .nameTables)
        try container.encode(numSpritesToRender, forKey: .numSpritesToRender)
        try container.encode(vramAndScrollFirstWrite, forKey: .vramAndScrollFirstWrite)
        try container.encode(kScreenWidth, forKey: .kScreenWidth)
        try container.encode(kScreenHeight, forKey: .kScreenHeight)
        try container.encode(renderSprite0, forKey: .renderSprite0)
        try container.encode(oam, forKey: .oam)
        try container.encode(oam2, forKey: .oam2)
        try container.encode(palette, forKey: .palette)
    }
    
    var palette = PaletteMemory.init()
    var renderer: Renderer? = nil
    var ppuStatusReg: Bitfield8WithPpuRegister = Bitfield8WithPpuRegister.init()
    var ppuControlReg1: Bitfield8WithPpuRegister = Bitfield8WithPpuRegister.init()
    var ppuControlReg2: Bitfield8WithPpuRegister = Bitfield8WithPpuRegister.init()
    var numSpritesToRender:Int = 0
    var vramAndScrollFirstWrite: Bool = false
    var ppuRegisters: PpuRegisterMemory = PpuRegisterMemory.init()
    var tempVRamAddress: UInt16 = 0
    var vramAddress: UInt16 = 0
    var fineX: UInt8 = 0                    // Fine x scroll (3 bits), "Loopy x"
    var vramBufferedValue: UInt8 = 0
    var cycle: UInt32 = 0
    var evenFrame: Bool = false
    var vblankFlagSetThisFrame: Bool = false
    var nes:Nes? = nil
    var ppuMemoryBus: PpuMemoryBus? = nil
    var spriteFetchData: [SpriteFetchData] = []
    var nameTables = NameTableMemory.init(initSize: KB(2))
    var kScreenWidth:UInt32 = 256
    var kScreenHeight:UInt32 = 240
    var renderSprite0 = false
    var oam = OAM()
    var oam2 = OAM()
    var kNumPaletteColors:UInt = 64
    var paletteColors:UnsafeMutablePointer<PixelColor>!
    var bgTileFetchDataPipeline_0 = BgTileFetchData.init()
    var bgTileFetchDataPipeline_1 = BgTileFetchData.init()
    private var paletteColorsData:[PixelColor] = []
}

class Ppu: PpuBase,IPpu {
   
    func initialize(ppuMemoryBus:PpuMemoryBus,nes:Nes,renderer:Renderer) {
        self.renderer = renderer
        self.ppuMemoryBus = ppuMemoryBus
        self.nes = nes
    }
    
    func reset() {
        initPaletteColors()
        // See http://wiki.nesdev.com/w/index.php/PPU_power_up_state
        
        ppuStatusReg.initialize(ppuRegisterMemory: ppuRegisters,regAddress: CpuMemory.kPpuStatusReg)
        ppuControlReg1.initialize(ppuRegisterMemory: ppuRegisters,regAddress: CpuMemory.kPpuControlReg1)
        ppuControlReg2.initialize(ppuRegisterMemory: ppuRegisters,regAddress: CpuMemory.kPpuControlReg2)
        
        writePpuRegister(CpuMemory.kPpuControlReg1, value: 0)
        writePpuRegister(CpuMemory.kPpuControlReg2, value: 0)
        writePpuRegister(CpuMemory.kPpuVRamAddressReg1, value: 0)
        writePpuRegister(CpuMemory.kPpuVRamIoReg, value: 0)
        
        spriteFetchData.removeAll()
        for _ in 0 ..< 64 {
            spriteFetchData.append(SpriteFetchData.init())
        }
        
        vramAndScrollFirstWrite = true

        // Not necessary but helps with debugging
        vramAddress = 0xDDDD
        tempVRamAddress = 0xDDDD
        vramBufferedValue = 0xDD
        numSpritesToRender = 0

        cycle = 0
        evenFrame = true
        vblankFlagSetThisFrame = false
    }
    
    func yXtoPpuCycle(y: UInt32, x: UInt32) -> UInt32 {
        return y * 341 + x
    }

    func cpuToPpuCycles(_ cpuCycles: UInt32) -> UInt32 {
        return cpuCycles * 3
    }
    
    func setVBlankFlag() {
        if !vblankFlagSetThisFrame {
            ppuStatusReg.set(PpuStatus.InVBlank)
            vblankFlagSetThisFrame = true
        }
    }
    
    func mapPpuToPalette(ppuAddress: UInt16) -> UInt16 {
        var paletteAddress = (ppuAddress - PpuMemory.kPalettesBase) % PpuMemory.kPalettesSize;
        // Addresses $3F10/$3F14/$3F18/$3F1C are mirrors of $3F00/$3F04/$3F08/$3F0C
        // If least 2 bits are unset, it's one of the 8 mirrored addresses, so clear bit 4 to mirror
        if !testBits(target: paletteAddress, value: (BIT(1)|BIT(0))) {
            clearBits(target: &paletteAddress, value: BIT(4))
        }
        return paletteAddress
    }
    
    func readPpuRegister(_ cpuAddress: UInt16) -> UInt8 {
        return ppuRegisters.read(mapCpuToPpuRegister(cpuAddress))
    }

    func writePpuRegister(_ cpuAddress:UInt16, value: UInt8) {
        ppuRegisters.write(address: mapCpuToPpuRegister(cpuAddress), value: value)
        ppuStatusReg.reload()
        ppuControlReg1.reload()
        ppuControlReg2.reload()
    }
    
    func handleCpuRead(_ cpuAddress: UInt16) -> UInt8 {
        assert(cpuAddress >= CpuMemory.kPpuRegistersBase && cpuAddress < CpuMemory.kPpuRegistersEnd)
        var result:UInt8 = 0
        switch cpuAddress {
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
            let kSetVBlankCycle:UInt32 = yXtoPpuCycle(y: 241, x: 1)
            if (cycle < kSetVBlankCycle && (cycle + cpuToPpuCycles(3) >= kSetVBlankCycle))
            {
                setVBlankFlag()
            }

            result = readPpuRegister(cpuAddress)
            ppuStatusReg.clear(PpuStatus.InVBlank)
            writePpuRegister(CpuMemory.kPpuVRamAddressReg1, value: 0)
            writePpuRegister(CpuMemory.kPpuVRamAddressReg2, value: 0)
            vramAndScrollFirstWrite = true
            break
        case CpuMemory.kPpuVRamIoReg: // $2007
            // && "User code error: trying to read from $2007 when VRAM address not yet fully set via $2006");
            assert(vramAndScrollFirstWrite)

            // Read from palette or return buffered value
            if vramAddress >= PpuMemory.kPalettesBase {
                result = palette.read(mapPpuToPalette(ppuAddress: vramAddress))
            }
            else {
                result = vramBufferedValue
            }

            // Write to register memory for debugging (not actually required)
            //WritePpuRegister(cpuAddress, value: result)

            // Always update buffered value from current vram pointer before incrementing it.
            // Note that we don't buffer palette values, we read "under it", which mirrors the name table memory (VRAM/CIRAM).
            vramBufferedValue = ppuMemoryBus!.read(vramAddress)
                
            // Advance vram pointer
            let advanceOffset:UInt16 = PpuControl1.getPpuAddressIncrementSize(ppuControlReg1.value())
            vramAddress += advanceOffset
            break
        default:
            result = readPpuRegister(cpuAddress)
        }

        return result
    }
    
    func handleCpuWrite(_ cpuAddress:UInt16, value: UInt8) {
        let registerAddress = mapCpuToPpuRegister(cpuAddress)
        //const uint8
        let oldValue = ppuRegisters.read(registerAddress)

        // Update register value
        writePpuRegister(cpuAddress, value: value)
        
        switch (cpuAddress)
        {
        case CpuMemory.kPpuControlReg1: // $2000
            
            setVRamAddressNameTable(v: &tempVRamAddress, value: value & 0x3)

            let oldPpuControlReg1:Bitfield8 = Bitfield8.init()
            oldPpuControlReg1.set(oldValue)
            
            let enabledNmiOnVBlank = !oldPpuControlReg1.test(PpuControl1.NmiOnVBlank) && ppuControlReg1.test(PpuControl1.NmiOnVBlank)
            
            if  enabledNmiOnVBlank && ppuStatusReg.test(PpuStatus.InVBlank) {
                // In vblank (and $2002 not read yet, which resets this bit)
                nes!.SignalCpuNmi()
            }
            break
        case CpuMemory.kPpuControlReg2: //$2001
            break
        case CpuMemory.kPpuSprRamIoReg: // $2004
            // Write value to sprite ram at address in $2003 (OAMADDR) and increment address
            let spriteRamAddress = readPpuRegister(CpuMemory.kPpuSprRamAddressReg)
            oam.write(address: UInt16(spriteRamAddress), value: value)
            let newAddr = (UInt16(spriteRamAddress)+1)%256
            writePpuRegister(CpuMemory.kPpuSprRamAddressReg, value: UInt8(newAddr))
            break
        
        case CpuMemory.kPpuVRamAddressReg1: // $2005 (PPUSCROLL)
            if vramAndScrollFirstWrite {
                // First write: X scroll values
                fineX = value & 0x07
                setVRamAddressCoarseX(v: &tempVRamAddress, value: (value & ~0x07) >> 3)
            }
            else {
                // Second write: Y scroll values
                setVRamAddressFineY(v: &tempVRamAddress, value: value & 0x07)
                setVRamAddressCoarseY(v: &tempVRamAddress, value: (value & ~0x07) >> 3)
            }
            vramAndScrollFirstWrite = !vramAndScrollFirstWrite;
            break
        case CpuMemory.kPpuVRamAddressReg2: // $2006 (PPUADDR)
            let halfAddress = tO16(value)
            if vramAndScrollFirstWrite {
                //First write: high byte
                // Write 6 bits to high byte - note that technically we shouldn't touch bit 15, but whatever
                tempVRamAddress = ((halfAddress & 0x3F) << 8) | (tempVRamAddress & 0x00FF);
            }
            else {
                tempVRamAddress = (tempVRamAddress & 0xFF00) | halfAddress
                vramAddress = tempVRamAddress // Update v from t on second write
            }
            
            vramAndScrollFirstWrite = !vramAndScrollFirstWrite;
            break
        case CpuMemory.kPpuVRamIoReg: // $2007
            assert(vramAndScrollFirstWrite)// && "User code error: trying to write to $2007 when VRAM address not yet fully set via $2006");
            // Write to palette or memory bus
            if vramAddress >= PpuMemory.kPalettesBase {
                palette.write(address: mapPpuToPalette(ppuAddress: vramAddress), value: value)
            }
            else
            {
                ppuMemoryBus?.write(vramAddress, value: value)
            }

            let advanceOffset = PpuControl1.getPpuAddressIncrementSize(ppuControlReg1.value())
            vramAddress = vramAddress + advanceOffset;
            break
        default:
            break
        }
    }
    
    func setVRamAddressFineY(v:inout UInt16, value: UInt8) {
        v = (v & ~0x7000) | (tO16(value) << 12)
    }
    
    func setVRamAddressCoarseX(v:inout UInt16,  value: UInt8) {
        v = (v & ~0x001F) | (tO16(value) & 0x001F)
    }
    
    func setVRamAddressCoarseY(v:inout UInt16, value: UInt8) {
        v = (v & ~0x03E0) | (tO16(value) << 5)
    }
    
    
    func clearOAM2()
    {
        oam2.clear()
    }
    
    func isSpriteInRangeY( y:UInt32,  spriteY:UInt8,  spriteHeight:UInt8) -> Bool
    {
        return (y >= spriteY && (y < UInt32(spriteY) + UInt32(spriteHeight)) && spriteY < kScreenHeight)
    }
    
    func incAndWrap(v:inout UInt16, size: Int) -> Bool {
        v = v + 1
        if v == size {
            v = 0
            return true
        }
        return false
    }
    
    func performSpriteEvaluation(x:UInt32, y: UInt32) {
        // See http://wiki.nesdev.com/w/index.php/PPU_sprite_evaluation
        let isSprite8x16:Bool = ppuControlReg1.test(PpuControl1.SpriteSize8x16)
        
        var spriteHeight: UInt8 = 8
        if isSprite8x16 {
            spriteHeight = 16
        }
        
        // Reset sprite vars for current scanline
        numSpritesToRender = 0
        renderSprite0 = false

        var n:Int = 0; // Sprite [0-63] in OAM
        var n2 = numSpritesToRender // Sprite [0-7] in OAM2

        while n2 < 64 {
            let sprite = oam.getSprite(n)
            let spriteY: UInt8 = sprite.bmpLow
            var sprite2 = SpriteData()
            sprite2.bmpLow = spriteY // (1)
            if isSpriteInRangeY(y: y, spriteY: spriteY, spriteHeight: spriteHeight) {
                sprite2.bmpHigh = sprite.bmpHigh
                sprite2.attributes = sprite.attributes
                sprite2.x = sprite.x
                oam2.setSprite(n2, spriteData: sprite2)
                if n == 0 {
                    renderSprite0 = true
                }

                n2 = n2 + 1
            }
            n = n + 1
            
            if n == 64 {
                // We didn't find 8 sprites, OAM2 contains what we've found so far, so we can bail
                numSpritesToRender = n2
                return
            }
        }
        
        // We found 8 sprites above. Let's see if there are any more so we can set sprite overflow flag.
        var m:UInt16 = 0; // Byte in sprite data [0-3]
        
        while n < 64 {
            let sprite = oam.getSprite(n)
            var spriteY:UInt8 = 0
            if m == 0 {
                spriteY = sprite.bmpHigh
            }
            if m == 1 {
                spriteY = sprite.bmpLow
            }
            if m == 2 {
                spriteY = sprite.attributes
            }
            if m == 3 {
                spriteY = sprite.x
            }
            
            //let spriteY:UInt8 = oam[n][m]; // (3) Evaluate OAM[n][m] as a Y-coordinate (it might not be)
            _ = incAndWrap(v: &m, size: 4)
            
            if isSpriteInRangeY(y: y, spriteY: spriteY, spriteHeight: spriteHeight) {
                ppuStatusReg.set(PpuStatus.SpriteOverflow)

                // PPU reads next 3 bytes from OAM. Because of the hardware bug (below), m might not be 1 here, so
                // we carefully increment n when m overflows.
                for _ in 0...2 {
                    if incAndWrap(v: &m, size: 4) {
                        n = n + 1
                    }
                }
            }
            else {
                // (3b) If the value is not in range, increment n and m (without carry). If n overflows to 0, go to 4; otherwise go to 3
                // The m increment is a hardware bug - if only n was incremented, the overflow flag would be set whenever more than 8
                // sprites were present on the same scanline, as expected.
                n = n + 1
                _ = incAndWrap(v: &m, size: 4) // This increment is a hardware bug
            }
        }
    }
    
    func flipBits(_ v:UInt8) -> UInt8
    {
        return
              ((v & BIT(0)) << 7) | ((v & BIT(1)) << 5) | ((v & BIT(2)) << 3) | ((v & BIT(3)) << 1) | ((v & BIT(4)) >> 1) | ((v & BIT(5)) >> 3) | ((v & BIT(6)) >> 5) | ((v & BIT(7)) >> 7)
    }
    
    func fetchSpriteData(_ y:UInt32) // OAM2 -> render (shift) registers
    {
        // See http://wiki.nesdev.com/w/index.php/PPU_rendering#Cycles_257-320
        
        let isSprite8x16 = ppuControlReg1.test(PpuControl1.SpriteSize8x16)

        if numSpritesToRender == 0 {
            return
        }
        
        for n in 0 ..< numSpritesToRender {
            let sprite = oam2.getSprite(n)
            let spriteY:UInt8 = sprite.bmpLow
            let byte1:UInt8 = sprite.bmpHigh
            let attribs:UInt8 = sprite.attributes
            let flipHorz:Bool = testBits(target: UInt16(attribs), value: BIT(6))
            let flipVert:Bool = testBits(target: UInt16(attribs), value: BIT(7))

            var patternTableAddress:UInt16 = 0
            var tileIndex:UInt8 = 0
            if ( !isSprite8x16 ) // 8x8 sprite, oam byte 1 is tile index
            {
                if(ppuControlReg1.test(PpuControl1.SpritePatternTableAddress8x8))
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
                if(testBits(target: UInt16(byte1), value: BIT(0)))
                {
                    patternTableAddress = 0x1000
                }
                else
                {
                    patternTableAddress = 0x0000
                }
                tileIndex = UInt8(readBits(target: UInt16(byte1), value: ~BIT(0)))
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
            
            let tileOffset:UInt16 = tO16(tileIndex) * 16
            let byte1Address:UInt16 = patternTableAddress + tileOffset + UInt16(yOffset)
            let byte2Address:UInt16 = byte1Address + 8
            spriteFetchData[n].bmpLow = ppuMemoryBus!.read(byte1Address)
            spriteFetchData[n].bmpHigh = ppuMemoryBus!.read(byte2Address)
            spriteFetchData[n].attributes = sprite.attributes
            spriteFetchData[n].x = sprite.x
            
            if (flipHorz)
            {
                spriteFetchData[n].bmpLow = flipBits(spriteFetchData[n].bmpLow)
                spriteFetchData[n].bmpHigh = flipBits(spriteFetchData[n].bmpHigh)
            }
        }
    }
    
    
    
    func GetVRamAddressFineY(_ v: UInt16) -> UInt8 {
        return tO8((v & 0x7000) >> 12)
    }
    
    var mapColorUse:[UInt8:Bool] = [:]
    func FetchBackgroundTileData() {
        if skipRender {
            return
        }
        // Load bg tile row data (2 bytes) at v into pipeline
        let v = vramAddress
        let patternTableAddress:UInt16 = PpuControl1.getBackgroundPatternTableAddress(ppuControlReg1.value())
        let tileIndexAddress:UInt16 = 0x2000 | (v & 0x0FFF)
        let attributeAddress:UInt16 = 0x23C0 | (v & 0x0C00) | ((v >> 4) & 0x38) | ((v >> 2) & 0x07)
        
        
        assert(attributeAddress >= PpuMemory.kAttributeTable0 && attributeAddress < PpuMemory.kNameTablesEnd)
        
        let tileIndex:UInt8 = ppuMemoryBus!.read(tileIndexAddress)
        
        let tileOffset:UInt16 = tO16(tileIndex) * 16
        let fineY:UInt8 = GetVRamAddressFineY(v)
        let byte1Address:UInt16 = patternTableAddress + tileOffset + UInt16(fineY)
        let byte2Address:UInt16 = byte1Address + 8

        
        // Load attribute byte then compute and store the high palette bits from it for this tile
        // The high palette bits are 2 consecutive bits in the attribute byte. We need to shift it right
        // by 0, 2, 4, or 6 and read the 2 low bits. The amount to shift by is can be computed from the
        // VRAM address as follows: [bit 6, bit 2, 0]
        let attribute:UInt8 = ppuMemoryBus!.read(attributeAddress)
        
        let bmpLow = ppuMemoryBus!.read(byte1Address)
        let bmpHigh = ppuMemoryBus!.read(byte2Address)
        
        let attributeShift:UInt8 = UInt8(((v & 0x40) >> 4) | (v & 0x2))
        let paletteHighBits:UInt8 = (attribute >> attributeShift) & 0x3

        bgTileFetchDataPipeline_0.bmpLow = bgTileFetchDataPipeline_1.bmpLow
        bgTileFetchDataPipeline_0.bmpHigh = bgTileFetchDataPipeline_1.bmpHigh
        bgTileFetchDataPipeline_0.paletteHighBits = bgTileFetchDataPipeline_1.paletteHighBits
        
        bgTileFetchDataPipeline_1.bmpLow = bmpLow
        bgTileFetchDataPipeline_1.bmpHigh = bmpHigh
        bgTileFetchDataPipeline_1.paletteHighBits = paletteHighBits
    }
    
    func isHitSprite(x: UInt32, spriteData: SpriteFetchData) -> Bool {
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
    var skipRender = false
    func renderPixel(x:UInt32, y: UInt32) {
        if skipRender {
            return
        }
        // See http://wiki.nesdev.com/w/index.php/PPU_rendering
        var bgRenderingEnabled = ppuControlReg2.test(UInt8(PpuControl2.RenderBackground))
        var spriteRenderingEnabled = ppuControlReg2.test(UInt8(PpuControl2.RenderSprites))
        
        // Consider bg/sprites as disabled (for this pixel) if we're not supposed to render it in the left-most 8 pixels
        if !ppuControlReg2.test(UInt8(PpuControl2.BackgroundShowLeft8)) && x < 8 {
            bgRenderingEnabled = false
        }

        if !ppuControlReg2.test(UInt8(PpuControl2.SpritesShowLeft8)) && x < 8 {
            spriteRenderingEnabled = false
        }
        
        
        // Get the background pixel
        var bgPaletteHighBits:UInt8 = 0
        var bgPaletteLowBits:UInt8 = 0
        
        if (bgRenderingEnabled)
        {
            let currTile = bgTileFetchDataPipeline_0
            let nextTile = bgTileFetchDataPipeline_1

            // Mux uses fine X to select a bit from shift registers
            let muxMask:UInt16 = UInt16(1 << (7 - fineX))

            // Instead of actually shifting every cycle, we rebuild the shift register values
            // for the current cycle (using the x value)
            //@TODO: Optimize by storing 16 bit values for low and high bitmap bytes and shifting every cycle
            let xShift:UInt8 = UInt8(x % 8)
            let shiftRegLow:UInt8 = (currTile.bmpLow << xShift) | (nextTile.bmpLow >> (8 - xShift))
            let shiftRegHigh:UInt8 = (currTile.bmpHigh << xShift) | (nextTile.bmpHigh >> (8 - xShift));

            bgPaletteLowBits = (testBits01(target: muxMask,value: shiftRegHigh) << 1) | (testBits01(target: muxMask,value: shiftRegLow))

            if xShift + fineX < 8 {
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
            if numSpritesToRender != 0 {
                for n in 0 ..< numSpritesToRender {
                    var spriteData = spriteFetchData[n]
                    if isHitSprite(x:x,spriteData: spriteData) {
                        if !foundSprite {
                            // Compose "sprite color" (0-3) from high bit in bitmap bytes
                            sprPaletteLowBits = (testBits01(target: UInt16(spriteData.bmpHigh), value: 0x80) << 1) | (testBits01(target: UInt16(spriteData.bmpLow), value: 0x80))
                            
                            // First non-transparent pixel moves on to multiplexer
                            
                            if sprPaletteLowBits != 0 {
                                foundSprite = true
                                sprPaletteHighBits = UInt8(readBits(target: UInt16(spriteData.attributes), value: UInt8(0x3))) //@TODO: cache this in spriteData
                                spriteHasBgPriority = testBits(target: UInt16(spriteData.attributes), value: BIT(5))
                                
                                
                                if renderSprite0 && n == 0 {
                                    isSprite0 = true
                                }
                            }
                        }

                        // Shift out high bits - do this for all (overlapping) sprites in range
                        spriteData.bmpLow = spriteData.bmpLow << 1
                        spriteData.bmpHigh = spriteData.bmpHigh << 1
                        
                        spriteFetchData[n] = spriteData
                    }
                }
            }
        }
        
        if (bgPaletteLowBits == 0)
        {
            if (!foundSprite || sprPaletteLowBits == 0)
            {
                // Background color 0
                let pixelColor = getBackgroundPixelColor()
                renderer?.drawPixelColor(x: x, y: y, pixelColor: pixelColor)
            }
            else
            {
                // Sprite color
                let pixelColor = getPaletteColor(highBits: sprPaletteHighBits, lowBits: sprPaletteLowBits, paletteBaseAddress: PpuMemory.kSpritePalette)
                renderer?.drawPixelColor(x: x, y: y, pixelColor: pixelColor)
            }
        }
        else
        {
            if (foundSprite && !spriteHasBgPriority)
            {
                // Sprite color
                let pixelColor = getPaletteColor(highBits:sprPaletteHighBits, lowBits: sprPaletteLowBits, paletteBaseAddress:PpuMemory.kSpritePalette)
                renderer?.drawPixelColor(x: x, y: y, pixelColor: pixelColor)
            }
            else
            {
                // BG color
                let pixelColor = getPaletteColor(highBits: bgPaletteHighBits, lowBits: bgPaletteLowBits, paletteBaseAddress: PpuMemory.kImagePalette)
                renderer?.drawPixelColor(x: x, y: y, pixelColor: pixelColor)
            }

            if (isSprite0)
            {
                ppuStatusReg.set(PpuStatus.PpuHitSprite0)
            }
        }
    }
    
    func GetPaletteColor(highBits: UInt8, lowBits: UInt8, paletteBaseAddress: UInt16, color: inout Color4) {
        assert(lowBits != 0)
        let paletteOffset:UInt8 = (highBits << 2) | (lowBits & 0x3)
        //@NOTE: lowBits is never 0, so we don't have to worry about mapping every 4th byte to 0 (bg color) here.
        // That case is handled specially in the multiplexer code.
        let paletteIndex:Int = Int(palette.read( mapPpuToPalette(ppuAddress: paletteBaseAddress + UInt16(paletteOffset))))
        color.d_r = paletteColors[paletteIndex].d_r
        color.d_g = paletteColors[paletteIndex].d_g
        color.d_b = paletteColors[paletteIndex].d_b
        color.d_a = paletteColors[paletteIndex].d_a
    }
    
    func getBackgroundPixelColor() -> PixelColor {
        let paletteIndex = Int(palette.read(0))
        return paletteColors[paletteIndex]
    }
    
    func getPaletteColor(highBits: UInt8, lowBits: UInt8, paletteBaseAddress: UInt16) -> PixelColor {
        assert(lowBits != 0)
        let paletteOffset:UInt8 = (highBits << 2) | (lowBits & 0x3)
        let paletteIndex:Int = Int(palette.read( mapPpuToPalette(ppuAddress: paletteBaseAddress + UInt16(paletteOffset))))
        return paletteColors[paletteIndex]
    }
    
    func onFrameComplete() {
        let renderingEnabled = ppuControlReg2.test(UInt8(PpuControl2.RenderBackground|PpuControl2.RenderSprites))
        // For odd frames, the cycle at the end of the scanline (340,239) is skipped
        if !evenFrame && renderingEnabled {
            cycle = cycle + 1
        }

        evenFrame = !evenFrame
        vblankFlagSetThisFrame = false
    }
    
    func incHoriVRamAddress(_ v:inout UInt16) {
        if (v & 0x001F) == 31 {
            // if coarse X == 31
            v &= ~0x001F // coarse X = 0
            v ^= 0x0400 // switch horizontal nametable
        }
        else {
            v += 1 // increment coarse X
        }
    }

    func incVertVRamAddress(_ v: inout UInt16) {
        if (v & 0x7000) != 0x7000 {
            // if fine Y < 7
            v += 0x1000 // increment fine Y
        }
        else {
            v &= ~0x7000; // fine Y = 0
            var y = (v & 0x03E0) >> 5 // let y = coarse Y
            if y == 29 {
                y = 0 // coarse Y = 0
                v ^= 0x0800; // switch vertical nametable
            }
            else if y == 31 {
                y = 0 // coarse Y = 0, nametable not switched
            }
            else {
                y += 1 // increment coarse Y
            }
            v = (v & ~0x03E0) | (y << 5) // put coarse Y back into v
        }
    }
    
    
    func copyVRamAddressHori(target:inout UInt16, source: inout UInt16) {
        // Copy coarse X (5 bits) and low nametable bit
        target = (target & ~0x041F) | ((source & 0x041F))
    }

    func copyVRamAddressVert(target:inout UInt16, source: inout UInt16) {
        // Copy coarse Y (5 bits), fine Y (3 bits), and high nametable bit
        target = (target & 0x041F) | ((source & ~0x041F))
    }
    
    func execute(_ cpuCycles:UInt32, completedFrame: inout Bool) {
        let kNumTotalScanlines:UInt32 = 262
        let kNumHBlankAndBorderCycles:UInt32 = 85
        let kNumScanlineCycles = UInt32(kScreenWidth + kNumHBlankAndBorderCycles) // 256 + 85 = 341
        let kNumScreenCycles = UInt32(kNumScanlineCycles * kNumTotalScanlines) // 89342 cycles per screen

        let ppuCycles = cpuToPpuCycles(cpuCycles)
        completedFrame = false
        
        let renderingEnabled = ppuControlReg2.test(UInt8(PpuControl2.RenderBackground|PpuControl2.RenderSprites))
        
        for _ in 0 ..< ppuCycles
        {
            let x = cycle % kNumScanlineCycles // offset in current scanline
            let y = cycle / kNumScanlineCycles // scanline

            if ( (y <= 239) || y == 261 ) // Visible and Pre-render scanlines
            {
                if renderingEnabled {
                    if x == 64 {
                        // Cycles 1-64: Clear secondary OAM to $FF
                        clearOAM2()
                    }
                    else if x == 256 {
                        // Cycles 65-256: Sprite evaluation
                        performSpriteEvaluation(x: x, y: y)
                    }
                    else if (x == 260)
                    {
                        //@TODO: This is a dirty hack for Mapper4 (MMC3) and the like to get around the fact that
                        // my PPU implementation doesn't perform Sprite fetches as expected (must fetch even if no
                        // sprites found on scanline, and fetch each sprite separately like I do for tiles). For now
                        // this mostly works.
                        
                        nes?.hackOnScanline()
                    }
                }

                if x >= 257 && x <= 320 {
                    // "HBlank" (idle cycles)
                    if renderingEnabled {
                        if x == 257 {
                            copyVRamAddressHori(target: &vramAddress, source: &tempVRamAddress)
                        }
                        else if y == 261 && x >= 280 && x <= 304 {
                            copyVRamAddressVert(target: &vramAddress, source: &tempVRamAddress)
                        }
                        else if x == 320 {
                            // Cycles 257-320: sprite data fetch for next scanline
                            fetchSpriteData(y)
                        }
                    }
                }
                else {
                    // Fetch and render cycles
                    // Update VRAM address and fetch data
                    if renderingEnabled {
                        // PPU fetches 4 bytes every 8 cycles for a given tile (NT, AT, LowBG, and HighBG).
                        // We want to know when we're on the last cycle of the HighBG tile byte (see Ntsc_timing.jpg)
                        let lastFetchCycle = (x >= 8) && (x % 8 == 0)

                        if lastFetchCycle {
                            FetchBackgroundTileData()
                            
                            // Data for v was just fetched, so we can now increment it
                            if x != 256 {
                                incHoriVRamAddress(&vramAddress)
                            }
                            else {
                                incVertVRamAddress(&vramAddress)
                            }
                        }
                    }

                    // Render pixel at x,y using pipelined fetch data. If rendering is disabled, will render background color.
                    if x < kScreenWidth && y < kScreenHeight {
                        renderPixel(x: x, y: y)
                    }

                    // Clear flags on pre-render line at dot 1
                    if y == 261 && x == 1 {
                        ppuStatusReg.clear(PpuStatus.InVBlank | PpuStatus.PpuHitSprite0 | PpuStatus.SpriteOverflow)
                    }

                    // Present on (second to) last cycle of last visible scanline
                    //@TODO: Do this on last frame of post-render line?
                    if y == 239 && x == 339 {
                        completedFrame = true
                        onFrameComplete()
                    }
                }
            }
            else {
                // Post-render and VBlank 240-260
                assert(y >= 240 && y <= 260)

                if y == 241 && x == 1 {
                    setVBlankFlag()
                    if ppuControlReg1.test(PpuControl1.NmiOnVBlank) {
                        nes?.SignalCpuNmi()
                    }
                }
            }

            // Update cycle
            cycle = (cycle + 1) % kNumScreenCycles;
        }
    }
    
    func mapCpuToPpuRegister(_ cpuAddress: UInt16) -> UInt16 {
        assert(cpuAddress >= CpuMemory.kPpuRegistersBase && cpuAddress < CpuMemory.kPpuRegistersEnd)
        let ppuRegAddress = (cpuAddress - CpuMemory.kPpuRegistersBase ) % CpuMemory.kPpuRegistersSize
        return ppuRegAddress
    }
    
    func setVRamAddressNameTable(v:inout UInt16, value: UInt8) {
        v = (v & ~0x0C00) | (tO16(value) << 10)
    }
    
    func handlePpuRead(_ ppuAddress: UInt16) -> UInt8 {
        //@NOTE: The palette can only be accessed directly by the PPU (no address lines go out to Cartridge)
        return nameTables.read(mapPpuToVRam(ppuAddress))
    }
    
    func handlePpuWrite(_ ppuAddress:UInt16, value: UInt8) {
        let address = mapPpuToVRam(ppuAddress)
        nameTables.write(address: address, value: value);
    }
    
    func mapPpuToVRam(_ ppuAddress: UInt16) -> UInt16 {
        assert(ppuAddress >= PpuMemory.kVRamBase)
        // Address may go into palettes (vram pointer)

        let virtualVRamAddress = (ppuAddress - PpuMemory.kVRamBase) % PpuMemory.kVRamSize
        var physicalVRamAddress:UInt16 = 0
        switch nes!.getNameTableMirroring() {
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
