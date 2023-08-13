//
//  Memory.swift
//  NES_EMU
//
//  Created by mio on 2021/8/7.
//

import Foundation
class Memory:NSObject
{
    var memorySize:UInt = 0
    var rawBuffer:UnsafeMutablePointer<UInt8>! = nil
    
    deinit
    {
        rawBuffer.deallocate()
    }
    
    func initial(size:UInt)
    {
        memorySize = size
        rawBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(size))
    }
    
    func putValue(address:Int,value:UInt8)
    {
        rawBuffer[address] = value
    }
    
    func rawRef(address:Int)->UInt8
    {
        return rawBuffer[address]
    }
    
    func read(_ address: UInt16) -> UInt8 {
        return rawBuffer[Int(address)]
    }

    func write(address: UInt16, value: UInt8)
    {
        rawBuffer[Int(address)] = value
    }
}

class PpuRegisterMemory:Memory
{
    override init() {
        super.init()
        memorySize = 8
        initial(size: 8)
    }
}

class PaletteMemory:Memory
{
    override init() {
        super.init()
        memorySize = 32
        initial(size: 32)
    }
}

class CpuInternalMemory: Memory {
    override init() {
        super.init()
    }
    
    func initialize(initSize:UInt) -> CpuInternalMemory {
        memorySize = initSize
        initial(size: initSize)
        return self
    }
}

class NameTableMemory: Memory {
    static var kSize = 2048
    override init() {
        super.init()
    }
    
    init(initSize: UInt) {
        super.init()
        memorySize = initSize
        initial(size: initSize)
    }
    
    override func read(_ address: UInt16) -> UInt8 {
        assert(address < 2048)
        return rawBuffer[Int(address)]
    }
    
    override func write( address: UInt16, value: UInt8) {
        assert(address < 2048)
        rawBuffer[Int(address)] = value
    }
}

