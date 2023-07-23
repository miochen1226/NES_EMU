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

class CpuMemoryBus{
    var m_cpu:ICpu?
    var m_ppu:IPpu?
    var m_cartridge:ICartridge?
    var m_cpuInternalRam:CpuInternalRam?
    var readCount = 0
    func Initialize(cpu:ICpu,ppu:IPpu,cartridge:ICartridge,cpuInternalRam:CpuInternalRam)
    {
        m_cpu = cpu
        m_ppu = ppu
        m_cartridge = cartridge
        m_cpuInternalRam = cpuInternalRam
    }
    
    
    //func HandleCpuReadEx(_ cpuAddress: uint16,readValue:inout UInt8)
    
    func ReadEx(_ cpuAddress:UInt16,readValue:inout UInt8)
    {
        if (cpuAddress >= CpuMemory.kExpansionRomBase)
        {
            m_cartridge!.HandleCpuReadEx(cpuAddress,readValue:&readValue)
        }
        else if (cpuAddress >= CpuMemory.kCpuRegistersBase)
        {
            //return m_cpu!.HandleCpuRead(cpuAddress)
        }
        else if (cpuAddress >= CpuMemory.kPpuRegistersBase)
        {
            //Mio mark for test.
            //return 0//m_ppu!.HandleCpuRead(cpuAddress)
        }

        //return m_cpuInternalRam!.HandleCpuRead(cpuAddress)
    }
    
    func Read(_ cpuAddress:UInt16)->UInt8
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
            m_cartridge!.HandleCpuWrite(cpuAddress, value: value)
            return
        }
        else if (cpuAddress >= CpuMemory.kCpuRegistersBase)
        {
            m_cpu!.HandleCpuWrite(cpuAddress, value: value)
            return
        }
        else if (cpuAddress >= CpuMemory.kPpuRegistersBase)
        {
            m_ppu!.HandleCpuWrite(cpuAddress, value: value)
            return
        }

        m_cpuInternalRam!.HandleCpuWrite(cpuAddress, value: value)
    }
    
}
