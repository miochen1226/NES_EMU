//
//  CpuRegDef.swift
//  NES_EMU
//
//  Created by mio on 2021/8/14.
//

import Foundation

class CpuStatusFlag
{
    static func BIT(_ n:UInt8)->UInt8
    {
         return (1<<n)
    }
    
    static let Carry = BIT(0)
    static let Zero = BIT(1)
    static let IrqDisabled = BIT(2)
    static let Decimal = BIT(3)
    static let BrkExecuted = BIT(4)
    static let Unused = BIT(5)
    static let Overflow = BIT(6)
    static let Negative = BIT(7)
    
    let Carry = CpuStatusFlag.Carry
    let Zero = CpuStatusFlag.Zero
    let IrqDisabled = CpuStatusFlag.IrqDisabled
    let Decimal = CpuStatusFlag.Decimal
    let BrkExecuted = CpuStatusFlag.BrkExecuted
    let Unused = CpuStatusFlag.Unused
    let Overflow = CpuStatusFlag.Overflow
    let Negative = CpuStatusFlag.Negative
}

class CpuRegDef
{
    

    
}
