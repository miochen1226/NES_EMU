//
//  CpuMemoryBus.swift
//  NES_EMU
//
//  Created by mio on 2021/8/8.
//

import Foundation

struct CpuMemory {
    
    static let kInternalRamBase:UInt16            = 0x0000
    static let kInternalRamSize:UInt16            = UInt16(KB(2))
    static let kInternalRamEnd:UInt16            = kInternalRamBase + kInternalRamSize * 4 // Mirrored

    static let kPpuRegistersBase:UInt16            = 0x2000
    static let kPpuRegistersSize:UInt16            = 8
    static let kPpuRegistersEnd:UInt16            = kPpuRegistersBase + kPpuRegistersSize * 1024 // Mirrored

    static let kCpuRegistersBase:UInt16            = 0x4000
    static let kCpuRegistersSize:UInt16            = 32
    static let kCpuRegistersEnd:UInt16            = kCpuRegistersBase + kCpuRegistersSize

    static let kExpansionRomBase:UInt16            = 0x4020
    static let kExpansionRomSize:UInt16            = UInt16(KB(8)) - kCpuRegistersSize
    static let kExpansionRomEnd:UInt16            = kExpansionRomBase + kExpansionRomSize

    static let  kSaveRamBase:UInt16                = 0x6000
    static let  kSaveRamSize:UInt16                = UInt16(KB(8))
    static let  kSaveRamEnd:UInt16                = kSaveRamBase + kSaveRamSize

    static let  kPrgRomBase:UInt16                = 0x8000
    static let  kPrgRomSize:UInt16                = UInt16(KB(32))
    static let  kProRomEnd:UInt32                    = UInt32(kPrgRomBase + kPrgRomSize) // Note 32 bits
    
    static let  kStackBase:UInt16                    = 0x0100 // Range [$0100,$01FF] (page 1)

        // PPU memory-mapped registers
    static let  kPpuControlReg1:UInt16            = 0x2000 // (W)
    static let  kPpuControlReg2:UInt16            = 0x2001 // (W)
    static let  kPpuStatusReg:UInt16                = 0x2002 // (R)
    static let  kPpuSprRamAddressReg:UInt16        = 0x2003 // (W) \_ OAMADDR
    static let  kPpuSprRamIoReg:UInt16            = 0x2004 // (W) /  OAMDATA
    static let  kPpuVRamAddressReg1:UInt16        = 0x2005 // (W2)
    static let  kPpuVRamAddressReg2:UInt16        = 0x2006 // (W2) \_
    static let  kPpuVRamIoReg:UInt16                = 0x2007 // (RW) /

    static let  kSpriteDmaReg:UInt16                = 0x4014 // (W) OAMDMA
    static let  kControllerPort1:UInt16            = 0x4016 // (RW) Strobe for both controllers (bit 0), and controller 1 output
    static let  kControllerPort2:UInt16            = 0x4017 // (R) Controller 2 output

    static let kNmiVector:UInt16                   = 0xFFFA // and 0xFFFB
    static let  kResetVector:UInt16                = 0xFFFC // and 0xFFFD
    static let  kIrqVector:UInt16                    = 0xFFFE // and 0xFFFF
    
}

class CpuMemoryBus {
    
    func initialize(cpu: ICpu, ppu: IPpu, cartridge: ICartridge, cpuInternalRam: CpuInternalRam) {
        self.cpu = cpu
        self.ppu = ppu
        self.cartridge = cartridge
        self.cpuInternalRam = cpuInternalRam
    }
    
    func Read(_ cpuAddress: UInt16) -> UInt8 {
        if cpuAddress >= CpuMemory.kExpansionRomBase {
            return cartridge!.HandleCpuRead(cpuAddress)
        }
        else if cpuAddress >= CpuMemory.kCpuRegistersBase {
            return cpu!.HandleCpuRead(cpuAddress)
        }
        else if cpuAddress >= CpuMemory.kPpuRegistersBase {
            return ppu!.HandleCpuRead(cpuAddress)
        }

        return cpuInternalRam!.HandleCpuRead(cpuAddress)
    }
    
    func Write(cpuAddress: UInt16, value: UInt8) {
        if cpuAddress >= CpuMemory.kExpansionRomBase {
            cartridge!.HandleCpuWrite(cpuAddress, value: value)
            return
        }
        else if cpuAddress >= CpuMemory.kCpuRegistersBase {
            cpu!.HandleCpuWrite(cpuAddress, value: value)
            return
        }
        else if cpuAddress >= CpuMemory.kPpuRegistersBase {
            ppu!.HandleCpuWrite(cpuAddress, value: value)
            return
        }

        cpuInternalRam!.HandleCpuWrite(cpuAddress, value: value)
    }
    
    var cpu:ICpu?
    var ppu:IPpu?
    var cartridge:ICartridge?
    var cpuInternalRam:CpuInternalRam?
    var readCount = 0
    
}
