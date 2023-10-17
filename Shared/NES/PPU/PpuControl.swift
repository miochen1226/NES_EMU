//
//  PpuControl1.swift
//  NES_EMU
//
//  Created by mio on 2021/8/10.
//

import Foundation

struct PpuStatus {
    static let VRAMWritesIgnored:UInt8     = BIT(4)
    static let SpriteOverflow:UInt8        = BIT(5)
    static let PpuHitSprite0:UInt8         = BIT(6)
    static let InVBlank:UInt8              = BIT(7)
}

class PpuControl {
    static let NameTableAddressMask            = BIT(0)|BIT(1)//PpuControl1Type.NameTableAddressMask.rawValue
    static let PpuAddressIncrement             = BIT(2)//PpuControl1Type.PpuAddressIncrement.rawValue
    static let SpritePatternTableAddress8x8    = BIT(3)//PpuControl1Type.SpritePatternTableAddress8x8.rawValue
    static let BackgroundPatternTableAddress   = BIT(4)//PpuControl1Type.BackgroundPatternTableAddress.rawValue
    static let SpriteSize8x16                  = BIT(5)//PpuControl1Type.SpriteSize8x16.rawValue
    static let PpuMasterSlaveSelect            = BIT(6)//PpuControl1Type.PpuMasterSlaveSelect.rawValue
    static let NmiOnVBlank                     = BIT(7)//PpuControl1Type.NmiOnVBlank.rawValue
    
    static func getNameTableAddress(_ ppuControl: UInt16) -> UInt16 {
        return PpuMemory.kNameTable0 + ((UInt16)(ppuControl & UInt16(NameTableAddressMask))) * PpuMemory.kNameAttributeTableSize
    }

    static func getAttributeTableAddress(_ ppuControl: UInt16) -> UInt16 {
        return getNameTableAddress(ppuControl) + PpuMemory.kNameTableSize
    }

    static func getBackgroundPatternTableAddress(_ ppuControl: UInt8) -> UInt16 {
        if ((ppuControl & BackgroundPatternTableAddress)) != 0 {
            return 0x1000
        }
        else {
            return 0x0000
        }
    }

    static func getPpuAddressIncrementSize(_ ppuControl: UInt8) -> UInt16 {
        if((ppuControl & PpuAddressIncrement)) != 0 {
            return 32
        }
        else {
            return 1
        }
    }
}
