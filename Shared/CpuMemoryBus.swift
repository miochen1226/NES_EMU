//
//  CpuMemoryBus.swift
//  NES_EMU
//
//  Created by mio on 2021/8/8.
//

import Foundation

struct CpuMemory
{
    static func KB(_ n:UInt)->UInt
    {
        return n*1024
    }
    
    static func MB(_ n:UInt)->UInt
    {
        return n*1024*1024
    }
    
    static let kInternalRamBase:uint16            = 0x0000
    static let kInternalRamSize:uint16            = uint16(KB(2))
    static let kInternalRamEnd:uint16            = kInternalRamBase + kInternalRamSize * 4 // Mirrored

    static let kPpuRegistersBase:uint16            = 0x2000
    static let kPpuRegistersSize:uint16            = 8
    static let kPpuRegistersEnd:uint16            = kPpuRegistersBase + kPpuRegistersSize * 1024 // Mirrored

    static let kCpuRegistersBase:uint16            = 0x4000
    static let kCpuRegistersSize:uint16            = 32
    static let kCpuRegistersEnd:uint16            = kCpuRegistersBase + kCpuRegistersSize

    static let kExpansionRomBase:uint16            = 0x4020
    static let kExpansionRomSize:uint16            = UInt16(KB(8)) - kCpuRegistersSize
    static let kExpansionRomEnd:uint16            = kExpansionRomBase + kExpansionRomSize

    static let  kSaveRamBase:uint16                = 0x6000
    static let  kSaveRamSize:uint16                = uint16(KB(8))
    static let  kSaveRamEnd:uint16                = kSaveRamBase + kSaveRamSize

    static let  kPrgRomBase:uint16                = 0x8000
    static let  kPrgRomSize:uint16                = uint16(KB(32))
    static let  kProRomEnd:uint32                    = uint32(kPrgRomBase + kPrgRomSize) // Note 32 bits
    
    static let  kStackBase:uint16                    = 0x0100 // Range [$0100,$01FF] (page 1)

        // PPU memory-mapped registers
    static let  kPpuControlReg1:uint16            = 0x2000 // (W)
    static let  kPpuControlReg2:uint16            = 0x2001 // (W)
    static let  kPpuStatusReg:uint16                = 0x2002 // (R)
    static let  kPpuSprRamAddressReg:uint16        = 0x2003 // (W) \_ OAMADDR
    static let  kPpuSprRamIoReg:uint16            = 0x2004 // (W) /  OAMDATA
    static let  kPpuVRamAddressReg1:uint16        = 0x2005 // (W2)
    static let  kPpuVRamAddressReg2:uint16        = 0x2006 // (W2) \_
    static let  kPpuVRamIoReg:uint16                = 0x2007 // (RW) /

    static let  kSpriteDmaReg:uint16                = 0x4014 // (W) OAMDMA
    static let  kControllerPort1:uint16            = 0x4016 // (RW) Strobe for both controllers (bit 0), and controller 1 output
    static let  kControllerPort2:uint16            = 0x4017 // (R) Controller 2 output

    static let kNmiVector:uint16                   = 0xFFFA // and 0xFFFB
    static let  kResetVector:uint16                = 0xFFFC // and 0xFFFD
    static let  kIrqVector:uint16                    = 0xFFFE // and 0xFFFF
    
}

class CpuMemoryBus{
    var m_cpu:Cpu?
    var m_ppu:Ppu?
    var m_cartridge:Cartridge?
    var m_cpuInternalRam:CpuInternalRam?
    func Initialize(cpu:Cpu,ppu:Ppu,cartridge:Cartridge,cpuInternalRam:CpuInternalRam)
    {
        m_cpu = cpu
        m_ppu = ppu
        m_cartridge = cartridge
        m_cpuInternalRam = cpuInternalRam
    }
    
    func Read(_ cpuAddress:uint16)->uint8
    {
        if (cpuAddress >= CpuMemory.kExpansionRomBase)
        {
            return m_cartridge!.HandleCpuRead(cpuAddress)
        }
        else if (cpuAddress >= CpuMemory.kCpuRegistersBase)
        {
            return m_cpu!.HandleCpuRead(cpuAddress)
        }
        else if (cpuAddress >= CpuMemory.kPpuRegistersBase)
        {
            return m_ppu!.HandleCpuRead(cpuAddress)
        }

        return m_cpuInternalRam!.HandleCpuRead(cpuAddress)
    }
    
    func Write(cpuAddress:UInt16, value:UInt8)
    {
        if (cpuAddress >= CpuMemory.kExpansionRomBase)
        {
            m_cartridge!.HandleCpuWrite(cpuAddress: cpuAddress, value: value)
            return
        }
        else if (cpuAddress >= CpuMemory.kCpuRegistersBase)
        {
            m_cpu!.HandleCpuWrite(cpuAddress: cpuAddress, value: value)
            return
        }
        else if (cpuAddress >= CpuMemory.kPpuRegistersBase)
        {
            m_ppu!.HandleCpuWrite(cpuAddress: cpuAddress, value: value)
            return
        }

        m_cpuInternalRam!.HandleCpuWrite(cpuAddress: cpuAddress, value: value)
    }
    
}
