//
//  Mapper1.swift
//  NES_EMU
//
//  Created by mio on 2021/8/8.
//

import Foundation

class LoadRegister {
    
    init() {
        Reset()
    }
    
    func Reset() {
        m_value.clearAll()
        m_bitsWritten = 0
    }
    
    func SetBit(bit:UInt8) {
        
        //"All bits already written, must Reset"
        assert(m_bitsWritten < 5)
        
        var enable:UInt8 = 0
        if (bit & 0x01) != 0 {
            enable = 1
        }
        
        m_value.setPos(bitPos: m_bitsWritten, enabled: enable)
        m_bitsWritten += 1
    }
    
    func AllBitsSet() -> Bool {
        return m_bitsWritten == 5
    }
    
    func Value() -> UInt8 {
        return m_value.value()
    }
    
    var m_bitsWritten:UInt8 = 0
    var m_value:Bitfield8 = Bitfield8()
}

class Mapper1: Mapper {
    
    override func OnCpuWrite(cpuAddress:UInt16, value:UInt8) {
        if (cpuAddress < 0x8000) {
            return
        }
        
        let reset:Bool = (value & BIT(7)) != 0

        if reset {
            m_loadReg.Reset()
            m_controlReg.set(BITS([2,3]))
        }
        else {
            let dataBit:UInt8 = value & BIT(0)
            m_loadReg.SetBit(bit: dataBit)
            
            if m_loadReg.AllBitsSet() {
                switch (cpuAddress & 0xE000) {
                    case 0x8000:
                        m_controlReg.setValue(m_loadReg.Value())
                        UpdatePrgBanks()
                        UpdateChrBanks()
                        UpdateMirroring()
                        break

                    case 0xA000:
                        m_chrReg0.setValue(m_loadReg.Value())
                        
                        // Hijacks CHR reg bit 4 to select PRG 256k bank
                        if (m_boardType == BoardType.SUROM) {
                            UpdatePrgBanks()
                        }
                    
                        UpdateChrBanks()
                        break

                    case 0xC000:
                        m_chrReg1.setValue(m_loadReg.Value())
                        UpdateChrBanks()
                        break;

                    case 0xE000:
                        m_prgReg.setValue(m_loadReg.Value())
                        UpdatePrgBanks()
                        break

                    default:
                        assert(false)
                        break
                }

                m_loadReg.Reset()
            }
        }
    }

    var m_controlReg:Bitfield8 = Bitfield8()
    var m_chrReg0:Bitfield8 = Bitfield8()
    var m_chrReg1:Bitfield8 = Bitfield8()
    var m_prgReg:Bitfield8 = Bitfield8()
    
    enum BoardType :UInt8{
        case DEFAULT
        case SUROM
    }
    var m_boardType:BoardType  = BoardType.DEFAULT
    
    var m_loadReg:LoadRegister = LoadRegister()
    override func postInitialize() {
        m_boardType = BoardType.DEFAULT
        
        if (PrgMemorySize() == KB(512)) {
            m_boardType = BoardType.SUROM
        }
            
        m_loadReg.Reset()

        m_controlReg.setValue(BITS([2,3]))
        m_chrReg0.clearAll()
        m_chrReg1.clearAll()
        m_prgReg.clearAll()

        UpdatePrgBanks()
        UpdateChrBanks()
        UpdateMirroring()
    }
    
    func UpdatePrgBanks() {
        let bankMode = m_controlReg.read(BITS([2,3])) >> 2

        // 32k mode
        if (bankMode <= 1) {
            let mask = NumPrgBanks32k() - 1
            let cartBankIndex = (m_prgReg.read(BITS([0,1,2,3])) >> 1) & mask
            
            SetPrgBankIndex32k(cpuBankIndexIn: 0, cartBankIndexIn: cartBankIndex)
        }
        // 16k mode
        else {
            var mask:UInt8 = NumPrgBanks16k() - 1
            if mask > 16 {
                mask = 16
                assert(true)
            }
            var cartBankIndex = m_prgReg.read(BITS([0,1,2,3])) & mask
            var firstBankIndex:UInt8 = 0
            var lastBankIndex = (NumPrgBanks16k() - 1) & mask

            if m_boardType == BoardType.SUROM {
                let prgBankSelect256k = m_chrReg0.read(BIT(4))
                cartBankIndex |= prgBankSelect256k
                firstBankIndex |= prgBankSelect256k
                lastBankIndex |= prgBankSelect256k
            }

            if bankMode == 2 {
                SetPrgBankIndex16k(cpuBankIndexIn: 0, cartBankIndexIn: firstBankIndex)
                SetPrgBankIndex16k(cpuBankIndexIn: 1, cartBankIndexIn: cartBankIndex)
            }
            else {
                SetPrgBankIndex16k(cpuBankIndexIn: 0, cartBankIndexIn: cartBankIndex)
                SetPrgBankIndex16k(cpuBankIndexIn: 1, cartBankIndexIn: lastBankIndex)
            }
        }

        let bSavRamChipEnabled = m_prgReg.readPos(4) == 0
        SetCanWriteSavMemory(bSavRamChipEnabled)
    }
    
    func UpdateChrBanks() {
        let mode8k:Bool = m_controlReg.readPos(4) == 0
        
        if mode8k {
            let mask = NumChrBanks8k() - 1
            
            let value = (m_chrReg0.value() >> 1) & mask
            SetChrBankIndex8k(ppuBankIndexIn: 0, cartBankIndexIn: value)
        }
        else {
            let mask = NumChrBanks4k() - 1
            let value_0 = m_chrReg0.value() & mask
            let value_1 = m_chrReg1.value() & mask
            SetChrBankIndex4k(ppuBankIndex: 0, cartBankIndex: value_0)
            SetChrBankIndex4k(ppuBankIndex: 1, cartBankIndex: value_1)
        }
    }

    func UpdateMirroring() {
        let table:[NameTableMirroring] =
        [
            NameTableMirroring.OneScreenLower,
            NameTableMirroring.OneScreenUpper,
            NameTableMirroring.Vertical,
            NameTableMirroring.Horizontal,
        ]

        let mirroringType = m_controlReg.read(BITS([0,1]))
        SetNameTableMirroring(table[Int(mirroringType)])
    }
}
