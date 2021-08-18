//
//  RomHeader.swift
//  NES_EMU
//
//  Created by mio on 2021/8/6.
//

import Foundation
class RomHeader{
    
    func BIT(_ n:UInt8)->UInt8
    {
         return (1<<n)
    }
    
    func KB(_ n:UInt)->UInt
    {
        return n*1024
    }
    
    func MB(_ n:UInt)->UInt
    {
        return n*1024*1024
    }
    
    func GetNumPrgRomBanks()->UInt
    {
        return m_prgRomBanks
    }
    
    func GetNumChrRomBanks()->UInt
    {
        return m_chrRomBanks
    }
    
    func GetNumPrgRamBanks()->UInt
    {
        return m_prgRamBanks
    }
    
    func GetPrgRomSizeBytes()->UInt
    {
        return m_prgRomBanks * KB(16)
    }
    
    func GetChrRomSizeBytes()->UInt
    {
        return m_chrRomBanks * KB(8)
    }
    
    func GetPrgRamSizeBytes()->UInt
    {
        return m_prgRamBanks * KB(8)
    }
    var m_mapperNumber = 0
    
    //uint8 GetMapperNumber() const { return m_mapperNumber; }
    func GetMapperNumber()->Int
    {
        return m_mapperNumber
    }
    
    func compareUintChar(uint:UInt8 ,char:Unicode.Scalar)->Bool
    {
        let n = UInt8.init(ascii: char)
        if (uint == n)
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    var m_prgRomBanks:UInt = 0
    var m_chrRomBanks:UInt = 0
    var m_prgRamBanks:UInt = 0
    var m_hasSaveRam = false
    
    func HasSRAM()->Bool
    {
        return m_hasSaveRam
    }
    
    enum NameTableMirroring
    {
        case Horizontal
        case Vertical
        case FourScreen
        case OneScreenUpper
        case OneScreenLower

        case Undefined
    }
    //NameTableMirroring GetNameTableMirroring() const { return m_mirroring; }
    
    var m_mirroring:NameTableMirroring = .Undefined
    func GetNameTableMirroring()->NameTableMirroring
    {
        return m_mirroring
    }
    
    
    func Initialize(bytes: [UInt8])->RomHeader?
    {
        let char7 = bytes[7]
        
        let flags6 = bytes[6]
        let flags7 = bytes[7]
        
        if(!compareUintChar(uint: bytes[0], char: "N")
            || !compareUintChar(uint: bytes[1], char: "E")
            || !compareUintChar(uint: bytes[2], char: "S")
        )
        {
            NSLog("not NES rom")
            return nil
        }
        
        if(bytes[3] != 26) //"\x1A"
        {
            NSLog("not NES rom")
            return nil
        }
        
        if(char7 == 0 && bytes[12] == 0)
        {
            //Type = NES1
            
        }
        
        m_prgRomBanks = UInt.init(bytes[4])
        m_chrRomBanks = UInt.init(bytes[5])
        m_prgRamBanks = UInt.init(bytes[8])
        
        // Wiki: Value 0 infers 8 KB for compatibility
        if (m_prgRamBanks == 0)
        {
            m_prgRamBanks = 1
        }
        
        if ((flags6 & BIT(3)) != 0)
        {
            m_mirroring = NameTableMirroring.FourScreen
        }
        else
        {
            m_mirroring = ((flags6 & BIT(0)) != 0) ? NameTableMirroring.Vertical : NameTableMirroring.Horizontal
        }
        
        m_mapperNumber = Int((flags7 & 0xF0) | ((flags6 & 0xF0) >> 4))
    
        m_hasSaveRam = (flags6 & BIT(1)) != 0
        
        //NSLog("m_prgRomBanks->%d",m_prgRomBanks)
        //NSLog("m_chrRomBanks->%d",m_chrRomBanks)
        //NSLog("m_prgRamBanks->%d",m_chrRomBanks)
        return self
    }
}
