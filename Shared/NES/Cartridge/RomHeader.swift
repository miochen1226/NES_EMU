//
//  RomHeader.swift
//  NES_EMU
//
//  Created by mio on 2021/8/6.
//

import Foundation

enum NameTableMirroring: Codable {
    case Horizontal
    case Vertical
    case FourScreen
    case OneScreenUpper
    case OneScreenLower
    case Undefined
}

class RomHeader{
    
    func GetNumPrgRomBanks() -> UInt {
        return prgRomBanks
    }
    
    func GetNumChrRomBanks() -> UInt {
        return chrRomBanks
    }
    
    func GetNumPrgRamBanks() -> UInt {
        return prgRamBanks
    }
    
    func GetPrgRomSizeBytes() -> UInt {
        return prgRomBanks * KB(16)
    }
    
    func GetChrRomSizeBytes() -> UInt {
        return chrRomBanks * KB(8)
    }
    
    func GetPrgRamSizeBytes() -> UInt {
        return prgRamBanks * KB(8)
    }
    
    func GetMapperNumber() -> Int
    {
        return mapperNumber
    }
    
    func compareUintChar(uint:UInt8 ,char:Unicode.Scalar) -> Bool {
        let n = UInt8.init(ascii: char)
        if uint == n {
            return true
        }
        else {
            return false
        }
    }
    
    func HasSRAM() -> Bool {
        return hasSaveRam
    }
    
    func GetNameTableMirroring() -> NameTableMirroring {
        return mirroring
    }
    
    func Initialize(bytes: [UInt8]) -> RomHeader? {
        let char7 = bytes[7]
        let flags6 = bytes[6]
        let flags7 = bytes[7]
        
        if !compareUintChar(uint: bytes[0], char: "N")
            || !compareUintChar(uint: bytes[1], char: "E")
            || !compareUintChar(uint: bytes[2], char: "S") {
            NSLog("not NES rom")
            return nil
        }
        
        //"\x1A"
        if bytes[3] != 26 {
            NSLog("not NES rom")
            return nil
        }
        
        prgRomBanks = UInt.init(bytes[4])
        chrRomBanks = UInt.init(bytes[5])
        prgRamBanks = UInt.init(bytes[8])
        
        // Wiki: Value 0 infers 8 KB for compatibility
        if prgRamBanks == 0 {
            prgRamBanks = 1
        }
        
        if (flags6 & BIT(3)) != 0 {
            mirroring = NameTableMirroring.FourScreen
        }
        else {
            mirroring = ((flags6 & BIT(0)) != 0) ? NameTableMirroring.Vertical : NameTableMirroring.Horizontal
        }
        
        mapperNumber = Int((flags7 & 0xF0) | ((flags6 & 0xF0) >> 4))
        hasSaveRam = (flags6 & BIT(1)) != 0
        
        return self
    }
    
    var mirroring:NameTableMirroring = .Undefined
    var prgRomBanks:UInt = 0
    var chrRomBanks:UInt = 0
    var prgRamBanks:UInt = 0
    var hasSaveRam = false
    var mapperNumber = 0
}
