//
//  Mapper4.swift
//  NES_EMU
//
//  Created by mio on 2021/8/8.
//

import Foundation
class Mapper4: Mapper {
    
    override func postInitialize() {
        SetPrgBankIndex8k(cpuBankIndex: 3, cartBankIndex: NumPrgBanks8k() - 1)
        irqEnabled = false
        irqReloadPending = false
        irqPending = false
    }
    
    func UpdateBank(_ value: UInt8) {
        let chrBankMask1k = NumChrBanks1k() - 1
        let prgBankMask8k = NumPrgBanks8k() - 1
        let nextBankToUpdate = Int(nextBankToUpdate)
        switch nextBankToUpdate {
        case 0:
            SetChrBankIndex1k(ppuBankIndex: chrBankMode * 4 + 0, cartBankIndex: (value & 0xFE) & chrBankMask1k)
            SetChrBankIndex1k(ppuBankIndex: chrBankMode * 4 + 1, cartBankIndex: (value | 0x01) & chrBankMask1k)
            break
        case 1:
            SetChrBankIndex1k(ppuBankIndex: chrBankMode * 4 + 2, cartBankIndex: (value & 0xFE) & chrBankMask1k)
            SetChrBankIndex1k(ppuBankIndex: chrBankMode * 4 + 3, cartBankIndex: (value | 0x01) & chrBankMask1k)
            break
        case 2:
            SetChrBankIndex1k(ppuBankIndex: (1 - chrBankMode) * 4 + 0, cartBankIndex: value & chrBankMask1k)
            break
        case 3:
            SetChrBankIndex1k(ppuBankIndex: (1 - chrBankMode) * 4 + 1, cartBankIndex: value & chrBankMask1k)
            break
        case 4:
            SetChrBankIndex1k(ppuBankIndex: (1 - chrBankMode) * 4 + 2, cartBankIndex: value & chrBankMask1k)
            break
        case 5:
            SetChrBankIndex1k(ppuBankIndex: (1 - chrBankMode) * 4 + 3, cartBankIndex: value & chrBankMask1k)
            break
        case 6:
            SetPrgBankIndex8k(cpuBankIndex: prgBankMode * 2 + 0, cartBankIndex: value & prgBankMask8k)
            break
        case 7:
            SetPrgBankIndex8k(cpuBankIndex: 1, cartBankIndex: value & prgBankMask8k)
            break
        default:
            break
        }
    }
    
    func UpdateFixedBanks() {
        // Update the fixed second-to-last bank
        SetPrgBankIndex8k(cpuBankIndex: (1 - prgBankMode) * 2, cartBankIndex: NumPrgBanks8k() - 2)
    }
    
    override func OnCpuWrite(cpuAddress: UInt16, value: UInt8) {
        var memAddress = cpuAddress
        let mask = BITS16([15,14,13,0]) // Top 3 bits for register, low bit for high/low part of register
        memAddress &= mask
        switch memAddress
        {
        case 0x8000:
            chrBankMode = (value & BIT(7)) >> 7
            prgBankMode = (value & BIT(6)) >> 6
            nextBankToUpdate = value & BITS([0,1,2])
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
            irqReloadValue = value
            break
        case 0xC001:
            irqReloadPending = true
            break
        case 0xE000:
            irqEnabled = false
            irqPending = false
            break
        case 0xE001:
            irqEnabled = true
            break
        default:
            break
        }
    }
 
    func hackOnScanline() {
        if irqCounter == 0 || irqReloadPending {
            irqCounter = irqReloadValue
            irqReloadPending = false
        }
        else {
            irqCounter -= 1
            if irqCounter == 0 && irqEnabled {
                // Trigger IRQ - for now set the flag...
                irqPending = true
            }
        }
    }
    
    override func TestAndClearIrqPending() -> Bool {
        let result = irqPending
        irqPending = false
        return result
    }
    
    var chrBankMode: UInt8 = 0
    var prgBankMode: UInt8 = 0
    var irqReloadValue: UInt8 = 0
    var irqCounter: UInt8 = 0
}
