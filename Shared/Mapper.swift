//
//  Mapper.swift
//  NES_EMU
//
//  Created by mio on 2021/8/8.
//

import Foundation
class Mapper{
    static func KB(_ n:UInt)->UInt
    {
        return n*1024
    }
    
    static func MB(_ n:UInt)->UInt
    {
        return n*1024*1024
    }
    static var kPrgBankCount:UInt = 8
    static var kPrgBankSize:UInt = KB(4)

    static var kChrBankCount:UInt = 8
    static var kChrBankSize:UInt = KB(1)

    static var kSavBankCount:UInt = 1
    static var kSavBankSize:UInt = KB(8)
    
    /*
     void Initialize(size_t numPrgBanks, size_t numChrBanks, size_t numSavBanks)
         {
             m_nametableMirroring = NameTableMirroring::Undefined;
             m_numPrgBanks = numPrgBanks;
             m_numChrBanks = numChrBanks;
             m_numSavBanks = numSavBanks;
             m_canWritePrgMemory = false;
             m_canWriteChrMemory = false;
             m_canWriteSavMemory = true;

             if (m_numChrBanks == 0)
             {
                 m_numChrBanks = 8; // 8K of CHR-RAM
                 m_canWriteChrMemory = true;
             }

             // Default init banks to most common mapping
             SetPrgBankIndex32k(0, 0);
             SetChrBankIndex8k(0, 0);
             SetSavBankIndex8k(0, 0);

             PostInitialize();
         }
     **/
    
    var m_numPrgBanks:UInt = 0
    var m_numChrBanks:UInt = 0
    var m_numSavBanks:UInt = 0
    var m_canWritePrgMemory = false
    var m_canWriteChrMemory = false
    var m_canWriteSavMemory = false
    func Initialize(numPrgBanks:UInt,numChrBanks:UInt,numSavBanks:UInt)
    {
        m_numPrgBanks = numPrgBanks
        m_numChrBanks = numChrBanks
        m_numSavBanks = numSavBanks
    
        m_canWritePrgMemory = false
        m_canWriteChrMemory = false
        m_canWriteSavMemory = true

        if (m_numChrBanks == 0)
        {
            m_numChrBanks = 8; // 8K of CHR-RAM
            m_canWriteChrMemory = true;
        }

        // Default init banks to most common mapping
        SetPrgBankIndex32k(cpuBankIndexIn:0, cartBankIndexIn:0)
        SetChrBankIndex8k(ppuBankIndexIn:0, cartBankIndexIn:0)
        SetSavBankIndex8k(cpuBankIndexIn:0, cartBankIndexIn:0)
    }
    
    func SetPrgBankIndex32k(cpuBankIndexIn:Int, cartBankIndexIn:Int)
    {
        var cpuBankIndex = cpuBankIndexIn
        var cartBankIndex = cartBankIndexIn
        
        cpuBankIndex *= 8
        cartBankIndex *= 8
        m_prgBankIndices[cpuBankIndex] = cartBankIndex
        m_prgBankIndices[cpuBankIndex + 1] = cartBankIndex + 1
        m_prgBankIndices[cpuBankIndex + 2] = cartBankIndex + 2
        m_prgBankIndices[cpuBankIndex + 3] = cartBankIndex + 3
        m_prgBankIndices[cpuBankIndex + 4] = cartBankIndex + 4
        m_prgBankIndices[cpuBankIndex + 5] = cartBankIndex + 5
        m_prgBankIndices[cpuBankIndex + 6] = cartBankIndex + 6
        m_prgBankIndices[cpuBankIndex + 7] = cartBankIndex + 7
    }
    
    func SetChrBankIndex8k(ppuBankIndexIn:Int, cartBankIndexIn:Int)
    {
        var ppuBankIndex = ppuBankIndexIn
        var cartBankIndex = cartBankIndexIn
        ppuBankIndex *= 8
        cartBankIndex *= 8
        m_chrBankIndices[ppuBankIndex] = cartBankIndex
        m_chrBankIndices[ppuBankIndex + 1] = cartBankIndex + 1
        m_chrBankIndices[ppuBankIndex + 2] = cartBankIndex + 2
        m_chrBankIndices[ppuBankIndex + 3] = cartBankIndex + 3
        m_chrBankIndices[ppuBankIndex + 4] = cartBankIndex + 4
        m_chrBankIndices[ppuBankIndex + 5] = cartBankIndex + 5
        m_chrBankIndices[ppuBankIndex + 6] = cartBankIndex + 6
        m_chrBankIndices[ppuBankIndex + 7] = cartBankIndex + 7
    }
    
    func SetSavBankIndex8k(cpuBankIndexIn:Int, cartBankIndexIn:Int)
    {
        m_savBankIndices[cpuBankIndexIn] = cartBankIndexIn;
    }
    
    
    var m_prgBankIndices:[Int:Int] = [:]
    var m_chrBankIndices:[Int:Int] = [:]
    var m_savBankIndices:[Int:Int] = [:]
    
    func GetMappedPrgBankIndex(_ cpuBankIndex:Int)->Int
    {
        return Int(m_prgBankIndices[cpuBankIndex]!)
    }
    
    func SetPrgBankIndex4k(cpuBankIndex:Int, cartBankIndex:Int)
    {
        m_prgBankIndices[cpuBankIndex] = cartBankIndex;
    }
    
    /*
    func SetPrgBankIndex8k(cpuBankIndex:UInt, cartBankIndex:UInt)
    {
        cpuBankIndex *= 2
        cartBankIndex *= 2
        m_prgBankIndices[cpuBankIndex] = cartBankIndex;
        m_prgBankIndices[cpuBankIndex + 1] = cartBankIndex + 1;
    }
    */
    
    
    
}
