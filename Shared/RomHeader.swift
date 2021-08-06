//
//  RomHeader.swift
//  NES_EMU
//
//  Created by mio on 2021/8/6.
//

import Foundation
class RomHeader{
    
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
    
    var m_prgRomBanks:UInt8 = 0
    var m_chrRomBanks:UInt8 = 0
    var m_prgRamBanks:UInt8 = 0

    
    func Initialize(bytes: [UInt8])->RomHeader?
    {
        let char7 = bytes[7]
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
            NSLog("NES1")
        }
        
        m_prgRomBanks = bytes[4]
        m_chrRomBanks = bytes[5]
        
        m_prgRamBanks = bytes[8];
        
        // Wiki: Value 0 infers 8 KB for compatibility
        if (m_prgRamBanks == 0)
        {
            m_prgRamBanks = 1
        }
        
        NSLog("m_prgRomBanks->%d",m_prgRomBanks)
        NSLog("m_chrRomBanks->%d",m_chrRomBanks)
        NSLog("m_prgRamBanks->%d",m_chrRomBanks)
        return self
    }
}
