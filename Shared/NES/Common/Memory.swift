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
    //var rawMemory:[UInt8] = Array<UInt8>()
    func initial(size:UInt)
    {
        memorySize = size
        
        rawBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(size))
        /*
        for _ in 0..<size
        {
            rawMemory.append(0)
        }*/
    }
    
    func putValue(address:Int,value:UInt8)
    {
        rawBuffer[address] = value
    }
    
    func RawRef(address:Int)->UInt8
    {
        return rawBuffer[address]
    }
    
    func Read(_ address:UInt16)->UInt8
    {
        return rawBuffer[Int(address)]
    }

    func Write( address:UInt16,  value:UInt8)
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
    
    func Initialize()
    {
        
    }
}

class ObjectAttributeMemory:Memory
{
    func getSprite(_ index:Int)->SpriteData
    {
        let addressBegin = index*4
        var spriteData = SpriteData.init()
        spriteData.bmpLow = rawBuffer[addressBegin]
        spriteData.bmpHigh = rawBuffer[addressBegin+1]
        spriteData.attributes = rawBuffer[addressBegin+2]
        spriteData.x = rawBuffer[addressBegin+3]
        
        return spriteData
    }
    
    
    static let kMaxSprites = 64
    static let kSpriteDataSize = 4
    static let kSpriteMemorySize = kMaxSprites * kSpriteDataSize
    
    override init() {
        super.init()
        memorySize = UInt(ObjectAttributeMemory.kSpriteMemorySize)
        initial(size: UInt(ObjectAttributeMemory.kSpriteMemorySize))
    }
    
    func Initialize()
    {
        
    }
}

class ObjectAttributeMemory2:Memory
{
    func getSprite(_ index:Int)->SpriteData
    {
        let addressBegin = index*4
        var spriteData = SpriteData.init()
        spriteData.bmpLow = rawBuffer[addressBegin]
        spriteData.bmpHigh = rawBuffer[addressBegin+1]
        spriteData.attributes = rawBuffer[addressBegin+2]
        spriteData.x = rawBuffer[addressBegin+3]
        
        return spriteData
    }
    static let kMaxSprites = 64
    static let kSpriteDataSize = 4
    static let kSpriteMemorySize = kMaxSprites * kSpriteDataSize * 8
    
    override init() {
        super.init()
        memorySize = UInt(ObjectAttributeMemory2.kSpriteMemorySize)
        initial(size: UInt(ObjectAttributeMemory2.kSpriteMemorySize))
    }
    
    func ClearOAM2()
    {
        /*
        for index in 0..<memorySize
        {
            let mIndex = Int(index)
            rawMemory[mIndex] = 0xFF
        }
        */
    }
    
    func saveSprites(sprites:[SpriteData])
    {
        var index:Int = 0
        for sprite in sprites
        {
            rawBuffer[index*4] = sprite.bmpLow
            rawBuffer[index*4+1] = sprite.bmpHigh
            rawBuffer[index*4+2] = sprite.attributes
            rawBuffer[index*4+3] = sprite.x
            index = index + 1
        }
    }
    
    func Initialize()
    {
        
    }
}

class CpuInternalMemory:Memory
{
    override init() {
        super.init()
        
    }
    
    func Initialize(initSize:UInt)->CpuInternalMemory
    {
        memorySize = initSize
        initial(size: initSize)
        return self
    }
}

class NameTableMemory:Memory
{
    static var kSize = 2048
    override init() {
        super.init()
        
    }
    
    init(initSize:UInt)
    {
        super.init()
        memorySize = initSize
        initial(size: initSize)
    }
    
    override func Read(_ address:UInt16)->UInt8
    {
        assert(address < 2048)
        return rawBuffer[Int(address)]
    }
    
    override func Write( address:UInt16,  value:UInt8)
    {
        assert(address < 2048)
        rawBuffer[Int(address)] = value
    }
}

