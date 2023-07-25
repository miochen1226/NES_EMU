//
//  CpuRegDef.swift
//  NES_EMU
//
//  Created by mio on 2021/8/14.
//

import Foundation

class CpuRegDef:NSObject
{
    enum StatusFlag:UInt8
    {
        case Carry              = 0b00000001//(1<<0)
        case Zero               = 0b00000010//(1<<1)
        case IrqDisabled        = 0b00000100// Interrupt (IRQ) disabled
        case Decimal            = 0b00001000 // *NOTE: Present in P, but Decimal mode not supported by NES CPU
        case BrkExecuted        = 0b00010000 // BRK executed (IRQ/software interupt) *NOTE: Not actually a bit in P, only set on stack for s/w interrupts
        case Unused             = 0b00100000 // *NOTE: Never set in P, but always set on stack
        case Overflow           = 0b01000000 // 'V'
        case Negative           = 0b10000000 // aka Sign flag
    }
    
    let Carry = StatusFlag.Carry.rawValue
    let Zero = StatusFlag.Zero.rawValue
    let IrqDisabled = StatusFlag.IrqDisabled.rawValue
    let Decimal = StatusFlag.Decimal.rawValue
    let BrkExecuted = StatusFlag.BrkExecuted.rawValue
    let Unused = StatusFlag.Unused.rawValue
    let Overflow = StatusFlag.Overflow.rawValue
    let Negative = StatusFlag.Negative.rawValue
}
