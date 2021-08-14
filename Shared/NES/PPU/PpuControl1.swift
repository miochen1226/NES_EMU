//
//  PpuControl1.swift
//  NES_EMU
//
//  Created by mio on 2021/8/10.
//

import Foundation



class PpuStatus
{
    static func BIT(_ n:Int)->UInt8
    {
        return (1<<n)
    }
    static let VRAMWritesIgnored:UInt8     = BIT(4)
    static let SpriteOverflow:UInt8        = BIT(5)
    static let PpuHitSprite0:UInt8         = BIT(6)
    static let InVBlank:UInt8              = BIT(7)
}

class PpuControl1 {
    static func BIT(_ n:Int)->UInt8
    {
        return (1<<n)
    }
    static let NameTableAddressMask            = BIT(0)|BIT(1)//PpuControl1Type.NameTableAddressMask.rawValue
    static let PpuAddressIncrement             = BIT(2)//PpuControl1Type.PpuAddressIncrement.rawValue
    static let SpritePatternTableAddress8x8    = BIT(3)//PpuControl1Type.SpritePatternTableAddress8x8.rawValue
    static let BackgroundPatternTableAddress   = BIT(4)//PpuControl1Type.BackgroundPatternTableAddress.rawValue
    static let SpriteSize8x16                  = BIT(5)//PpuControl1Type.SpriteSize8x16.rawValue
    static let PpuMasterSlaveSelect            = BIT(6)//PpuControl1Type.PpuMasterSlaveSelect.rawValue
    static let NmiOnVBlank                     = BIT(7)//PpuControl1Type.NmiOnVBlank.rawValue
    
    static func GetNameTableAddress(_ ppuControl1:UInt16)->UInt16
    {
        return PpuMemory.kNameTable0 + ((uint16)(ppuControl1 & UInt16(NameTableAddressMask))) * PpuMemory.kNameAttributeTableSize
    }

    static func GetAttributeTableAddress(_ ppuControl1:UInt16)->UInt16
    {
        return GetNameTableAddress(ppuControl1) + PpuMemory.kNameTableSize // Follows name table
    }

    static func GetBackgroundPatternTableAddress(_ ppuControl1:UInt16)->UInt16
    {
        if(((ppuControl1 & UInt16(BackgroundPatternTableAddress))) != 0)
        {
            return 0x1000
        }
        else
        {
            return 0x0000
        }
    }

    static func GetPpuAddressIncrementSize(_ ppuControl1:UInt16)->UInt16
    {
        if(((ppuControl1 & UInt16(PpuAddressIncrement))) != 0)
        {
            return 32
        }
        else
        {
            return 1
        }
    }
}

class PpuControl2 {
    static func BIT(_ n:Int)->UInt8
    {
        return (1<<n)
    }
    static let DisplayType                 = BIT(0) // 0 = Color, 1 = Monochrome
    static let BackgroundShowLeft8         = BIT(1) // 0 = BG invisible in left 8-pixel column, 1 = No clipping
    static let SpritesShowLeft8            = BIT(2) // 0 = Sprites invisible in left 8-pixel column, 1 = No clipping
    static let RenderBackground            = BIT(3) // 0 = Background not displayed, 1 = Background visible
    static let RenderSprites               = BIT(4) // 0 = Sprites not displayed, 1 = Sprites visible
    static let ColorIntensityMask          = BIT(5)|BIT(6)|BIT(7) // High 3 bits if DisplayType == 0
    static let FullBackgroundColorMask     = BIT(5)|BIT(6)|BIT(7) // High 3 bits if DisplayType == 1
}
