//
//  PpuMemoryBus.swift
//  NES_EMU
//
//  Created by mio on 2021/8/10.
//

import Foundation
class PpuMemoryBus
{
    var m_ppu:IPpu?
    var m_cartridge:ICartridge?
    
    var tReadTotal1 = 0
    var tReadTotal2 = 0
    var tWriteTotal = 0
        

    func Initialize(ppu:IPpu, cartridge:ICartridge)
    {
        m_ppu = ppu
        m_cartridge = cartridge
    }

    @inline(__always)
    func Read(_ ppuAddressIn:UInt16)->UInt8
    {
        //let tBegin = clock()
        
        var ppuAddress = ppuAddressIn
        
        if(ppuAddress>=PpuMemory.kPpuMemorySize)
        {
            ppuAddress = ppuAddress % PpuMemory.kPpuMemorySize // Handle mirroring above 16K to 64K
        }
        
        if (ppuAddress >= PpuMemory.kVRamBase)
        {
            let result = m_ppu!.HandlePpuRead(ppuAddress)
            
            //let tDru = clock() - tBegin
            //tReadTotal1 += Int(tDru)
            return result
        }

        let result = m_cartridge!.HandlePpuRead(ppuAddress)
        
        //let tDru = clock() - tBegin
        //tReadTotal2 += Int(tDru)
        return result
    }

    @inline(__always)
    func Write(_ ppuAddressIn:UInt16,  value:UInt8)
    {
        //let tBegin = clock()
        var ppuAddress = ppuAddressIn
        ppuAddress = ppuAddress % PpuMemory.kPpuMemorySize; // Handle mirroring above 16K to 64K

        if (ppuAddress >= PpuMemory.kVRamBase)
        {
            m_ppu!.HandlePpuWrite(ppuAddress, value: value)
            //let tDru = clock() - tBegin
            //tWriteTotal += Int(tDru)
        }

        m_cartridge!.HandlePpuWrite(ppuAddress, value: value)
        //let tDru = clock() - tBegin
        //tWriteTotal += Int(tDru)
    }
}
