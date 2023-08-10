//
//  OAM.swift
//  NES_EMU
//
//  Created by mio on 2023/8/10.
//

import Foundation

class OAM
{
    var m_memPointer:UnsafeMutablePointer<SpriteData> = UnsafeMutablePointer<SpriteData>.allocate(capacity: 64)
    func getSprite(_ index:Int)->SpriteData
    {
        return m_memPointer[index]
    }
    
    func setSprite(_ index:Int,spriteData:SpriteData)
    {
        var spriteDataNew = spriteData
        memcpy(m_memPointer.advanced(by: index), &spriteDataNew, MemoryLayout<SpriteData>.stride)
    }
    
    func Clear()
    {
        memset(m_memPointer, 0, MemoryLayout<SpriteData>.stride)
    }
    
    func Write( address:UInt16,  value:UInt8)
    {
        var valueSet = value
        let rawMemory = UnsafeMutableRawPointer(m_memPointer)
        memcpy(rawMemory.advanced(by: Int(address)), &valueSet, 1)
    }
}
