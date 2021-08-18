//
//  PPUDef.swift
//  NES_EMU
//
//  Created by mio on 2021/8/15.
//

import Foundation
class PpuDef{
    
    var frontBuffer: ScreenBuffer = ScreenBuffer()
    var backBuffer: ScreenBuffer = ScreenBuffer()
    
    
    static let kScreenWidth:UInt32 = 256
    static let kScreenHeight:UInt32 = 240
    static let kNumTotalScanlines:UInt32 = 262
    static let kNumHBlankAndBorderCycles:UInt32 = 85
    static let kNumPaletteColors:UInt = 64
    static let kNumScanlineCycles:UInt32 = UInt32(kScreenWidth + kNumHBlankAndBorderCycles) // 256 + 85 = 341
    static let kNumScreenCycles:UInt32 = UInt32(kNumScanlineCycles * kNumTotalScanlines) // 89342 cycles per screen
    var g_paletteColors:[Color4] = []
    var m_palette = PaletteMemory.init()
    
    @inline(__always)
    func TO8(_ v16:uint16)->uint8
    {
        let v8:UInt8 = UInt8(v16 & 0x00FF)
        return v8
    }
    
    @inline(__always)
    func TO16(_ v8:UInt8)->UInt16
    {
        return UInt16(v8)
    }
    
    @inline(__always)
    func BIT(_ n:Int)->UInt8
    {
        return (1<<n)
    }
    
    @inline(__always)
    func FlipBits(_ v:UInt8) -> uint8
    {
        func BIT(_ n:Int)->UInt8
        {
            return (1<<n)
        }
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
    
    @inline(__always)
    func CopyVRamAddressHori(target:inout UInt16, source:inout UInt16)
    {
        // Copy coarse X (5 bits) and low nametable bit
        target = (target & ~0x041F) | ((source & 0x041F))
    }

    @inline(__always)
    func CopyVRamAddressVert(target:inout UInt16, source:inout UInt16)
    {
        // Copy coarse Y (5 bits), fine Y (3 bits), and high nametable bit
        target = (target & 0x041F) | ((source & ~0x041F))
    }
    
    @inline(__always)
    func GetVRamAddressFineY(_ v:UInt16)->UInt8
    {
        return TO8((v & 0x7000) >> 12)
    }
    
    @inline(__always)
    func MapPpuToPalette(ppuAddress:UInt16)->UInt16
    {
        if(ppuAddress < PpuMemory.kPalettesBase || ppuAddress >= PpuMemory.kPalettesEnd)
        {
            NSLog("ERROR")
            return 0
        }
        
        var paletteAddress = (ppuAddress - PpuMemory.kPalettesBase) % PpuMemory.kPalettesSize
        if ( !TestBits(target: UInt8(paletteAddress), value: (BIT(1)|BIT(0))) )
        {
            ClearBits(target: &paletteAddress, value: BIT(4))
        }

        return paletteAddress
    }
    
    @inline(__always)
    func GetPaletteColor(highBits:UInt8,lowBits:UInt8,paletteBaseAddress:UInt16,color:inout Color4)
    {
        let paletteOffset:UInt8 = (highBits << 2) | (lowBits & 0x3)

        //@NOTE: lowBits is never 0, so we don't have to worry about mapping every 4th byte to 0 (bg color) here.
        // That case is handled specially in the multiplexer code.
        let paletteIndex:UInt8 = m_palette.Read( MapPpuToPalette(ppuAddress: paletteBaseAddress + UInt16(paletteOffset)) )
        color = g_paletteColors[Int(paletteIndex & (UInt8(PpuDef.kNumPaletteColors)-1))]
    }
    
    @inline(__always)
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
    
    @inline(__always)
    func ClearBits(target:inout UInt16, value:UInt8)
    {
        target = (target & ~UInt16(value))
    }
    
    @inline(__always)
    func TestBits(target:UInt8,  value:UInt8)->Bool
    {
        return ReadBits(target: target, value: value) != 0
    }
    
    @inline(__always)
    func ReadBits(target:UInt8,  value:UInt8)->UInt8
    {
        return target & value
    }
    
    @inline(__always)
    func TestBits01(target:UInt8,value:UInt8)->UInt8
    {
        if(ReadBits(target: target, value: value) != 0)
        {
            return 1
        }
        else
        {
            return 0
        }
        //return ReadBits(target, value) != 0? 1 : 0;
    }
    
    @inline(__always)
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

    @inline(__always)
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
    
    @inline(__always)
    func IsSpriteInRangeY( y:UInt32,  spriteY:UInt8,  spriteHeight:UInt8) -> Bool
    {
        return (y >= spriteY && y < UInt32(spriteY) + UInt32(spriteHeight) && spriteY < Ppu.kScreenHeight)
    }
    
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
        let dac3Palette:[[Int]] =
        [
            [3,3,3],[0,1,4],[0,0,6],[3,2,6],[4,0,3],[5,0,3],[5,1,0],[4,2,0],[3,2,0],[1,2,0],[0,3,1],[0,4,0],[0,2,2],[0,0,0],[0,0,0],[0,0,0],
            [5,5,5],[0,3,6],[0,2,7],[4,0,7],[5,0,7],[7,0,4],[7,0,0],[6,3,0],[4,3,0],[1,4,0],[0,4,0],[0,5,3],[0,4,4],[0,0,0],[0,0,0],[0,0,0],
            [7,7,7],[3,5,7],[4,4,7],[6,3,7],[7,0,7],[7,3,7],[7,4,0],[7,5,0],[6,6,0],[3,6,0],[0,7,0],[2,7,6],[0,7,7],[0,0,0],[0,0,0],[0,0,0],
            [7,7,7],[5,6,7],[6,5,7],[7,5,7],[7,4,7],[7,5,5],[7,6,4],[7,7,2],[7,7,3],[5,7,2],[4,7,3],[2,7,6],[4,6,7],[0,0,0],[0,0,0],[0,0,0]
        ]
        
        for i:UInt in 0 ... PpuDef.kNumPaletteColors-1
        {
            let colorItem = dac3Palette[Int(i)]
            
            let iR:Int = colorItem[0]
            let iG:Int = colorItem[1]
            let iB:Int = colorItem[2]
            let fr = Float(iR)*255/7
            var fg = Float(iG)*255/7
            let fb = Float(iB)*255/7
            
            let R = UInt8(fr)
            let G = UInt8(fg)
            let B = UInt8(fb)
            let A = 0xFF

            let rgbItem = Color4.init()
            rgbItem.SetRGBA(r: R, g: G, b: B, a: UInt8(A))
            
            g_paletteColors.append(rgbItem)
        }
    }
    
    @inline(__always)
    func SetVRamAddressNameTable(v:inout UInt16,  value:UInt8)
    {
        v = (v & ~0x0C00) | (TO16(value) << 10)
    }
    
    @inline(__always)
    func SetVRamAddressCoarseX(v:inout UInt16,  value:UInt8)
    {
        v = (v & ~0x001F) | (TO16(value) & 0x001F)
    }
    
    @inline(__always)
    func SetVRamAddressCoarseY(v:inout UInt16, value:UInt8)
    {
        v = (v & ~0x03E0) | (TO16(value) << 5)
    }
    
    @inline(__always)
    func SetVRamAddressFineY(v:inout UInt16, value:UInt8)
    {
        v = (v & ~0x7000) | (TO16(value) << 12)
    }
    
    @inline(__always)
    func YXtoPpuCycle(y:UInt32, x:UInt32)->UInt32
    {
        return y * 341 + x;
    }
}
