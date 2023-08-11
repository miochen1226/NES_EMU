//
//  Mapper4.swift
//  NES_EMU
//
//  Created by mio on 2021/8/8.
//

import Foundation
class Mapper4: Mapper {
    
    var m_chrBankMode:UInt8 = 0
    var m_prgBankMode:UInt8 = 0
    var m_irqReloadValue:UInt8 = 0
    var m_irqCounter:UInt8 = 0
    
    override func PostInitialize()
    {
        SetPrgBankIndex8k(cpuBankIndex: 3, cartBankIndex: NumPrgBanks8k() - 1)
        m_irqEnabled = false
        m_irqReloadPending = false
        m_irqPending = false
    }
    
    func UpdateBank(_ value:UInt8)
    {
        let chrBankMask1k = NumChrBanks1k() - 1
        let prgBankMask8k = NumPrgBanks8k() - 1

        let nextBankToUpdate = Int(m_nextBankToUpdate)
        switch (nextBankToUpdate)
        {
            // value is 1K CHR bank
        case 0:
            SetChrBankIndex1k(ppuBankIndex: m_chrBankMode * 4 + 0, cartBankIndex: (value & 0xFE) & chrBankMask1k)
            SetChrBankIndex1k(ppuBankIndex: m_chrBankMode * 4 + 1, cartBankIndex: (value | 0x01) & chrBankMask1k)
            
            //SetChrBankIndex1k(m_chrBankMode * 4 + 0, (value & 0xFE) & chrBankMask1k);
            //SetChrBankIndex1k(m_chrBankMode * 4 + 1, (value | 0x01) & chrBankMask1k);
            break
        case 1:
            SetChrBankIndex1k(ppuBankIndex: m_chrBankMode * 4 + 2, cartBankIndex: (value & 0xFE) & chrBankMask1k)
            SetChrBankIndex1k(ppuBankIndex: m_chrBankMode * 4 + 3, cartBankIndex: (value | 0x01) & chrBankMask1k)
            
            //SetChrBankIndex1k(m_chrBankMode * 4 + 2, (value & 0xFE) & chrBankMask1k);
            //SetChrBankIndex1k(m_chrBankMode * 4 + 3, (value | 0x01) & chrBankMask1k);
            break
        case 2:
            SetChrBankIndex1k(ppuBankIndex: (1 - m_chrBankMode) * 4 + 0, cartBankIndex: value & chrBankMask1k)
            //SetChrBankIndex1k((1 - m_chrBankMode) * 4 + 0, value & chrBankMask1k);
            break
        case 3:
            SetChrBankIndex1k(ppuBankIndex: (1 - m_chrBankMode) * 4 + 1, cartBankIndex: value & chrBankMask1k)
            //SetChrBankIndex1k((1 - m_chrBankMode) * 4 + 1, value & chrBankMask1k)
            break
        case 4:
            SetChrBankIndex1k(ppuBankIndex: (1 - m_chrBankMode) * 4 + 2, cartBankIndex: value & chrBankMask1k)
            
            //SetChrBankIndex1k((1 - m_chrBankMode) * 4 + 2, value & chrBankMask1k)
            break
        case 5:
            SetChrBankIndex1k(ppuBankIndex: (1 - m_chrBankMode) * 4 + 3, cartBankIndex: value & chrBankMask1k)
            
            //SetChrBankIndex1k((1 - m_chrBankMode) * 4 + 3, value & chrBankMask1k)
            break

        case 6:
            SetPrgBankIndex8k(cpuBankIndex: m_prgBankMode * 2 + 0, cartBankIndex: value & prgBankMask8k)
            //SetPrgBankIndex8k(m_prgBankMode * 2 + 0, value & prgBankMask8k)
            break
        case 7:
            SetPrgBankIndex8k(cpuBankIndex: 1, cartBankIndex: value & prgBankMask8k)
            //SetPrgBankIndex8k(1, value & prgBankMask8k)
            break
        default:
            break
        }
    }
    
    func UpdateFixedBanks()
    {
        // Update the fixed second-to-last bank
        SetPrgBankIndex8k(cpuBankIndex: (1 - m_prgBankMode) * 2, cartBankIndex: NumPrgBanks8k() - 2)
    }
    
    override func OnCpuWrite(cpuAddress:UInt16, value:UInt8)
    {
        var cpuAddress_ = cpuAddress
        let mask = BITS16([15,14,13,0]) // Top 3 bits for register, low bit for high/low part of register

        cpuAddress_ &= mask

        switch (cpuAddress_)
        {
        case 0x8000:
            m_chrBankMode = (value & BIT(7)) >> 7
            m_prgBankMode = (value & BIT(6)) >> 6
            m_nextBankToUpdate = value & BITS([0,1,2])
            UpdateFixedBanks()
            break

        case 0x8001:
            UpdateBank(value)
            break

        case 0xA000:
            if((value & BIT(0)) == 0)
            {
                SetNameTableMirroring(NameTableMirroring.Vertical)
            }
            else
            {
                SetNameTableMirroring(NameTableMirroring.Horizontal)
            }
            //SetNameTableMirroring((value & BIT(0)) == 0? NameTableMirroring.Vertical : NameTableMirroring.Horizontal)
            break

        case 0xA001:
            
            // [EW.. ....]
            // E = Enable WRAM (0=disabled, 1=enabled)
            // W = WRAM write protect (0=writable, 1=not writable)
            // As long as WRAM is enabled and non write-protected, we can write to it
            let canWriteSavRam = ((value & BITS([7,6])) == BIT(7))
            SetCanWriteSavMemory(canWriteSavRam)
            
            break

        case 0xC000:
            // Value copied to counter when counter == 0 OR reload is pending
            // (at next rising edge)
            m_irqReloadValue = value
            break

        case 0xC001:
            m_irqReloadPending = true
            break

        case 0xE000:
            m_irqEnabled = false
            m_irqPending = false
            break

        case 0xE001:
            m_irqEnabled = true
            break
        default:
            break
        }
    }
 
    
    override func HACK_OnScanline()
    {
        if (m_irqCounter == 0 || m_irqReloadPending)
        {
            m_irqCounter = m_irqReloadValue
            m_irqReloadPending = false
        }
        else
        {
            m_irqCounter -= 1
            if (m_irqCounter == 0 && m_irqEnabled)
            {
                // Trigger IRQ - for now set the flag...
                m_irqPending = true
            }
        }
    }
    
    override func TestAndClearIrqPending()->Bool
    {
        let result = m_irqPending
        m_irqPending = false
        return result
    }
}
