//
//  Mapper0.swift
//  NES_EMU
//
//  Created by mio on 2021/8/11.
//

import Foundation
class Mapper0:Mapper
{
    override func PostInitialize()
    {
        if(NumPrgBanks16k() == 1 || NumPrgBanks16k() == 2)
        {
            
        }
        
        if(NumChrBanks8k() == 1)
        {
            
        }
        
        SetPrgBankIndex16k(cpuBankIndexIn: 0, cartBankIndexIn: 0)

        if (NumPrgBanks16k() == 1)
        {
            SetPrgBankIndex16k(cpuBankIndexIn: 1, cartBankIndexIn: 0) // Both low and high 16k banks are the same
        }
        else
        {
            SetPrgBankIndex16k(cpuBankIndexIn: 1, cartBankIndexIn: 1)
        }

        SetChrBankIndex8k(ppuBankIndexIn: 0, cartBankIndexIn: 0)
    }
    
    override func OnCpuWrite(cpuAddress:UInt16, value:UInt8)
    {
        // Nothing to do
    }
    
}
