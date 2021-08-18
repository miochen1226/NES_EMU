//
//  Memory.swift
//  NES_EMU
//
//  Created by mio on 2021/8/7.
//

import Foundation
class Memory
{
    func test()->UInt8
    {
        return 120
    }
    var memorySize:UInt = 0
    var rawMemory:[UInt8] = Array<UInt8>()
    //var memPointer:UnsafeMutablePointer<UInt8>!
    func initial(size:UInt)
    {
        memorySize = size
        rawMemory.removeAll()
        for _ in 0...size-1
        {
            rawMemory.append(0)
        }
        //memPointer = UnsafePointer<UInt8>(rawMemory)
        
        //memPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(memorySize))
        //memPointer!.initialize(from: &rawMemory, count: Int(memorySize))
        
        //return self
    }
    
    func putValue(address:UInt16,value:UInt8)
    {
        rawMemory[Int(address)] = value
    }
    
    func Read(_ address:UInt16)->UInt8
    {
        return rawMemory[Int(address)]
        //let alpha = memPointer! + Int(address)
        //let value = alpha.pointee
        //return value
    }

    func Write( address:UInt16,  value:UInt8)
    {
        rawMemory[Int(address)] = value
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
        spriteData.bmpLow = rawMemory[addressBegin]
        spriteData.bmpHigh = rawMemory[addressBegin+1]
        spriteData.attributes = rawMemory[addressBegin+2]
        spriteData.x = rawMemory[addressBegin+3]
        
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
        spriteData.bmpLow = rawMemory[addressBegin]
        spriteData.bmpHigh = rawMemory[addressBegin+1]
        spriteData.attributes = rawMemory[addressBegin+2]
        spriteData.x = rawMemory[addressBegin+3]
        
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
        for index in 0 ... memorySize-1
        {
            let mIndex = Int(index)
            rawMemory[mIndex] = 0xFF
        }
    }
    
    func saveSprite(sprite:SpriteData,index:Int)
    {
        rawMemory[index*4] = sprite.bmpLow
        rawMemory[index*4+1] = sprite.bmpHigh
        rawMemory[index*4+2] = sprite.attributes
        rawMemory[index*4+3] = sprite.x
    }
    
    func saveSprites(sprites:[SpriteData])
    {
        var index:Int = 0
        for sprite in sprites
        {
            rawMemory[index*4] = sprite.bmpLow
            rawMemory[index*4+1] = sprite.bmpHigh
            rawMemory[index*4+2] = sprite.attributes
            rawMemory[index*4+3] = sprite.x
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
    
    func Initialize(initSize:UInt)->NameTableMemory
    {
        memorySize = initSize
        initial(size: initSize)
        return self
    }
}

