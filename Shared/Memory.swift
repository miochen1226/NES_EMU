//
//  Memory.swift
//  NES_EMU
//
//  Created by mio on 2021/8/7.
//

import Foundation
class Memory
{
    var memorySize:UInt = 0
    var rawMemory:[UInt8] = Array<UInt8>()
    func initial(size:UInt)->Memory
    {
        memorySize = size
        
        for _ in 0...size-1
        {
            rawMemory.append(0)
        }
        return self
    }
    
    func putValue(address:Int,value:UInt8)
    {
        rawMemory[address] = value
    }
    
}
