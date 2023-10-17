//
//  PpuMemoryBus.swift
//  NES_EMU
//
//  Created by mio on 2021/8/10.
//

import Foundation

class PpuMemoryBus {
    var ppu:IPpu?
    var cartridge:ICartridge?
    
    func initialize(ppu: IPpu, cartridge: ICartridge) {
        self.ppu = ppu
        self.cartridge = cartridge
    }

    func read(_ ppuAddressIn: UInt16) -> UInt8 {
        var ppuAddress = ppuAddressIn
        ppuAddress = ppuAddress % PpuMemory.kPpuMemorySize // Handle mirroring above 16K to 64K

        if ppuAddress >= PpuMemory.kVRamBase {
            return ppu!.handlePpuRead(ppuAddress)
        }
        return cartridge!.handlePpuRead(ppuAddress)
    }

    func readCard(_ ppuAddressIn: UInt16) -> UInt8 {
        var ppuAddress = ppuAddressIn
        ppuAddress = ppuAddress % PpuMemory.kPpuMemorySize // Handle mirroring above 16K to 64K
        if ppuAddress >= PpuMemory.kVRamBase {
            return ppu!.handlePpuRead(ppuAddress)
        }
        return cartridge!.handlePpuRead(ppuAddress)
    }
    
    func write(_ ppuAddressIn: UInt16, value: UInt8) {
        var ppuAddress = ppuAddressIn
        ppuAddress = ppuAddress % PpuMemory.kPpuMemorySize // Handle mirroring above 16K to 64K

        if ppuAddress >= PpuMemory.kVRamBase {
            return ppu!.handlePpuWrite(ppuAddress, value: value)
        }
        return cartridge!.handlePpuWrite(ppuAddress, value: value)
    }
}
