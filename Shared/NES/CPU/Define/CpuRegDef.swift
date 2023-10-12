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
    
    static let Carry = StatusFlag.Carry.rawValue
    static let Zero = StatusFlag.Zero.rawValue
    static let IrqDisabled = StatusFlag.IrqDisabled.rawValue
    static let Decimal = StatusFlag.Decimal.rawValue
    static let BrkExecuted = StatusFlag.BrkExecuted.rawValue
    static let Unused = StatusFlag.Unused.rawValue
    static let Overflow = StatusFlag.Overflow.rawValue
    static let Negative = StatusFlag.Negative.rawValue
}
