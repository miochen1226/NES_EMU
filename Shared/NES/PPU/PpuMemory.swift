//
//  PpuMemory.swift
//  NES_EMU
//
//  Created by mio on 2021/8/10.
//

import Foundation

class PpuMemory {
    
    // Addressible PPU is only 16K (14 bits)
    static let kPpuMemorySize:UInt16              = UInt16(KB(16))

    // CHR-ROM stores pattern tables
    static let kChrRomBase:UInt16                 = 0x0000
    static let kChrRomSize:UInt16                 = UInt16(KB(8))
    
    static let kChrRomEnd:UInt16                  = kChrRomBase + kChrRomSize

    // VRAM (aka CIRAM) stores name tables
    static let kVRamBase:UInt16                   = 0x2000
    static let kVRamSize:UInt16                   = UInt16(KB(4))
    static let kVRamEnd:UInt16                    = UInt16(kVRamBase + UInt16(KB(8)) - 256) // Mirrored

    static let kPalettesBase:UInt16               = 0x3F00
    static let kPalettesSize:UInt16               = 32
    static let kPalettesEnd:UInt16                = kPalettesBase + kPalettesSize * 8 // Mirrored

    static let kNumPatternTables:UInt16           = 2
    static let kPatternTableSize:UInt16           = UInt16(KB(4))
    static let kPatternTable0:UInt16              = 0x0000
    static let kPatternTable1:UInt16              = 0x1000

    // There are up to 4 Name/Attribute tables, each pair is 1 KB.
    // In fact, NES only has 2 KB total for name tables; the other 2 KB are mirrored off the first
    // two, either horizontally or vertically, or the cart supplies and extra 2 KB memory for 4 screen.
    // Also, a "name table" includes the attribute table, which are in the last 64 bytes.
    static let kNameTableSize:UInt16              = 960
    static let  kAttributeTableSize:UInt16        = 64
    static let  kNameAttributeTableSize:UInt16    = kNameTableSize + kAttributeTableSize

    static let  kNumMaxNameTables:UInt16            = 4
    static let  kNameTable0:UInt16                = 0x2000
    static let  kNameTable1:UInt16                = kNameTable0 + kNameAttributeTableSize
    static let  kNameTablesEnd:UInt16             = kNameTable0 + kNameAttributeTableSize * 4

    static let  kNumMaxAttributeTables:UInt16     = 4
    static let  kAttributeTable0:UInt16           = kNameTable0 + kNameTableSize

    // This is not actually the palette, but the palette lookup table (indices into actual palette)
    static let  kSinglePaletteSize:UInt16         = kPalettesSize / 2
    static let  kImagePalette:UInt16              = 0x3F00
    static let  kSpritePalette:UInt16             = 0x3F10

    static func GetPatternTableAddress(index: Int) -> UInt16 {
        assert(index < kNumPatternTables)
        return UInt16(kPatternTable0 + kPatternTableSize * UInt16(index))
    }

    static func GetNameTableAddress(index: Int) -> UInt16 {
        assert(index < kNumMaxNameTables)
        return kNameTable0 + (kNameAttributeTableSize * UInt16(index))
    }

    static func GetAttributeTableAddress(index: Int) -> UInt16 {
        assert(index < kNumMaxAttributeTables)
        return kAttributeTable0 + (kNameAttributeTableSize * UInt16(index))
    }
}
