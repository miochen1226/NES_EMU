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
    

    func Initialize(ppu:IPpu, cartridge:ICartridge)
    {
        m_ppu = ppu
        m_cartridge = cartridge
    }

    func Read(_ ppuAddressIn:UInt16)->UInt8
    {
        var ppuAddress = ppuAddressIn
        ppuAddress = ppuAddress % PpuMemory.kPpuMemorySize // Handle mirroring above 16K to 64K

        if (ppuAddress >= PpuMemory.kVRamBase)
        {
            return m_ppu!.HandlePpuRead(ppuAddress)
        }

        return m_cartridge!.HandlePpuRead(ppuAddress)
    }

    func ReadCard(_ ppuAddressIn:UInt16)->UInt8
    {
        var ppuAddress = ppuAddressIn
        ppuAddress = ppuAddress % PpuMemory.kPpuMemorySize // Handle mirroring above 16K to 64K
        if (ppuAddress >= PpuMemory.kVRamBase)
        {
            return m_ppu!.HandlePpuRead(ppuAddress)
        }
        return m_cartridge!.HandlePpuRead(ppuAddress)
    }
    
    func Write(_ ppuAddressIn:UInt16,  value:UInt8)
    {
        var ppuAddress = ppuAddressIn
        ppuAddress = ppuAddress % PpuMemory.kPpuMemorySize // Handle mirroring above 16K to 64K

        if (ppuAddress >= PpuMemory.kVRamBase)
        {
            return m_ppu!.HandlePpuWrite(ppuAddress, value: value)
        }

        return m_cartridge!.HandlePpuWrite(ppuAddress, value: value)
    }
}
