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
    
    
    var m_irqEnabled = false
    var m_irqReloadPending = false
    var m_irqPending = false
    
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
    
    var m_numPrgBanks:UInt8 = 0
    var m_numChrBanks:UInt8 = 0
    var m_numSavBanks:UInt8 = 0
    var m_canWritePrgMemory = false
    var m_canWriteChrMemory = false
    var m_canWriteSavMemory = false
    var m_nextBankToUpdate:UInt8 = 0
    func CanWriteChrMemory()->Bool
    {
        return m_canWriteChrMemory
    }
    func OnCpuWrite(cpuAddress:UInt16, value:UInt8)
    {
        // Nothing to do
    }
    
    func GetMappedSavBankIndex(cpuBankIndex:Int)->UInt8
    {
        return m_savBankIndices[cpuBankIndex]!
    }
    
    func GetMappedChrBankIndex(ppuBankIndex:Int)->UInt8
    {
        return m_chrBankIndices[ppuBankIndex]!
    }
    
    
    func CanWritePrgMemory()->Bool
    {
        return m_canWritePrgMemory
    }
    
    func CanWriteSavMemory()->Bool
    {
        return m_canWriteSavMemory
    }
    
    func Initialize(numPrgBanks:UInt8,numChrBanks:UInt8,numSavBanks:UInt8)
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
            m_canWriteChrMemory = true
        }

        
        // Default init banks to most common mapping
        SetPrgBankIndex32k(cpuBankIndexIn:0, cartBankIndexIn:0)
        SetChrBankIndex8k(ppuBankIndexIn:0, cartBankIndexIn:0)
        SetSavBankIndex8k(cpuBankIndexIn:0, cartBankIndexIn:0)
        PostInitialize()
    }
    
    func PostInitialize()
    {
        
    }
    
    func HACK_OnScanline()
    {
        
    }
    
    func TestAndClearIrqPending()->Bool
    {
        return false
    }
    
    func SetCanWritePrgMemory(_ enabled:Bool)
    {
        m_canWritePrgMemory = enabled
    }
    
    func SetCanWriteChrMemory(_ enabled:Bool)
    {
        m_canWriteChrMemory = enabled
    }
    
    func SetCanWriteSavMemory(_ enabled:Bool)
    {
        m_canWriteSavMemory = enabled
    }
    
    var m_nametableMirroring = NameTableMirroring.Vertical
    func SetNameTableMirroring(_ value:NameTableMirroring )
    {
        m_nametableMirroring = value
    }
    
    func SetPrgBankIndex16k(cpuBankIndexIn:Int, cartBankIndexIn:UInt8)
    {
        let cpuBankIndex = cpuBankIndexIn * 4
        let cartBankIndex = cartBankIndexIn * 4
        m_prgBankIndices[cpuBankIndex] = cartBankIndex
        m_prgBankIndices[cpuBankIndex + 1] = cartBankIndex + 1
        m_prgBankIndices[cpuBankIndex + 2] = cartBankIndex + 2
        m_prgBankIndices[cpuBankIndex + 3] = cartBankIndex + 3
    }
    
    func SetPrgBankIndex32k(cpuBankIndexIn:Int, cartBankIndexIn:UInt8)
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
    
    func SetChrBankIndex8k(ppuBankIndexIn:Int, cartBankIndexIn:UInt8)
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
    
    func SetSavBankIndex8k(cpuBankIndexIn:Int, cartBankIndexIn:UInt8)
    {
        m_savBankIndices[cpuBankIndexIn] = cartBankIndexIn
    }
    
    
    var m_prgBankIndices:[Int:UInt8] = [:]
    var m_chrBankIndices:[Int:UInt8] = [:]
    var m_savBankIndices:[Int:UInt8] = [:]
    
    func GetMappedPrgBankIndex(_ cpuBankIndex:Int)->Int
    {
        return Int(m_prgBankIndices[cpuBankIndex]!)
    }
    
    
    func NumPrgBanks4k()->UInt8
    {
        return m_numPrgBanks / 2
    }
    
    func NumPrgBanks8k()->UInt8
    {
        return m_numPrgBanks / 2
    }
    
    func NumPrgBanks16k()->UInt8
    {
        return m_numPrgBanks / 4
    }
    
    func NumPrgBanks32k()->UInt8
    {
        return m_numPrgBanks / 8
    }
    
    
    
    func NumChrBanks1k()->UInt8
    {
        return m_numChrBanks
    }
    
    func NumChrBanks4k()->UInt8
    {
        return m_numChrBanks / 4
    }
    
    func NumChrBanks8k()->UInt8
    {
        return m_numChrBanks / 8
    }
    
    func NumSavBanks8k()->UInt8
    {
        return m_numSavBanks
    }
    
    
    func SetPrgBankIndex4k(cpuBankIndex:UInt8, cartBankIndex:UInt8)
    {
        m_prgBankIndices[Int(cpuBankIndex)] = cartBankIndex
    }
    
    func SetPrgBankIndex8k(cpuBankIndex:UInt8, cartBankIndex:UInt8)
    {
        var cpuBankIndex_ = Int(cpuBankIndex)
        var cartBankIndex_ = cartBankIndex
        cpuBankIndex_ *= 2
        cartBankIndex_ *= 2
        m_prgBankIndices[cpuBankIndex_] = cartBankIndex_
        m_prgBankIndices[cpuBankIndex_ + 1] = cartBankIndex_ + 1
    }
    
    func SetPrgBankIndex16k(cpuBankIndex:UInt8, cartBankIndex:UInt8)
    {
        var cpuBankIndex_ = Int(cpuBankIndex)
        var cartBankIndex_ = cartBankIndex
        cpuBankIndex_ *= 4
        cartBankIndex_ *= 4
        m_prgBankIndices[cpuBankIndex_] = cartBankIndex_
        m_prgBankIndices[cpuBankIndex_ + 1] = cartBankIndex_ + 1
        m_prgBankIndices[cpuBankIndex_ + 2] = cartBankIndex_ + 2
        m_prgBankIndices[cpuBankIndex_ + 3] = cartBankIndex_ + 3
    }
    
    func SetPrgBankIndex32k(cpuBankIndex:UInt8, cartBankIndex:UInt8)
    {
        var cpuBankIndex_ = cpuBankIndex
        var cartBankIndex_ = cartBankIndex
        
        cpuBankIndex_ *= 8
        cartBankIndex_ *= 8
        m_prgBankIndices[Int(cpuBankIndex_)] = cartBankIndex_
        m_prgBankIndices[Int(cpuBankIndex_) + 1] = (cartBankIndex_) + 1
        m_prgBankIndices[Int(cpuBankIndex_) + 2] = (cartBankIndex_) + 2
        m_prgBankIndices[Int(cpuBankIndex_) + 3] = (cartBankIndex_) + 3
        m_prgBankIndices[Int(cpuBankIndex_) + 4] = (cartBankIndex_) + 4
        m_prgBankIndices[Int(cpuBankIndex_) + 5] = (cartBankIndex_) + 5
        m_prgBankIndices[Int(cpuBankIndex_) + 6] = (cartBankIndex_) + 6
        m_prgBankIndices[Int(cpuBankIndex_) + 7] = (cartBankIndex_) + 7
    }

    func SetChrBankIndex1k(ppuBankIndex:UInt8, cartBankIndex:UInt8)
    {
        m_chrBankIndices[Int(ppuBankIndex)] = cartBankIndex
    }
    
    func SetChrBankIndex4k(ppuBankIndex:UInt8, cartBankIndex:UInt8)
    {
        var ppuBankIndex_ = Int(ppuBankIndex)
        var cartBankIndex_ = cartBankIndex
        
        ppuBankIndex_ *= 4
        cartBankIndex_ *= 4
        
        m_chrBankIndices[ppuBankIndex_] = cartBankIndex_
        m_chrBankIndices[ppuBankIndex_ + 1] = cartBankIndex_ + 1
        m_chrBankIndices[ppuBankIndex_ + 2] = cartBankIndex_ + 2
        m_chrBankIndices[ppuBankIndex_ + 3] = cartBankIndex_ + 3
    }
    
    func SetChrBankIndex8k(ppuBankIndex:UInt, cartBankIndex:UInt8)
    {
        var ppuBankIndex_ = Int(ppuBankIndex)
        var cartBankIndex_ = cartBankIndex
        
        ppuBankIndex_ *= 8
        cartBankIndex_ *= 8
        m_chrBankIndices[ppuBankIndex_] = cartBankIndex_
        m_chrBankIndices[ppuBankIndex_ + 1] = cartBankIndex_ + 1;
        m_chrBankIndices[ppuBankIndex_ + 2] = cartBankIndex_ + 2;
        m_chrBankIndices[ppuBankIndex_ + 3] = cartBankIndex_ + 3;
        m_chrBankIndices[ppuBankIndex_ + 4] = cartBankIndex_ + 4;
        m_chrBankIndices[ppuBankIndex_ + 5] = cartBankIndex_ + 5;
        m_chrBankIndices[ppuBankIndex_ + 6] = cartBankIndex_ + 6;
        m_chrBankIndices[ppuBankIndex_ + 7] = cartBankIndex_ + 7;
    }
}
