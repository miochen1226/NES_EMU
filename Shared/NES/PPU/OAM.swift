//
//  OAM.swift
//  NES_EMU
//
//  Created by mio on 2023/8/10.
//

import Foundation

class OAM
{
    func getSprite(_ index: Int) -> SpriteData {
        return memPointer[index]
    }
    
    func setSprite(_ index: Int, spriteData: SpriteData) {
        var spriteDataNew = spriteData
        memcpy(memPointer.advanced(by: index), &spriteDataNew, MemoryLayout<SpriteData>.stride)
    }
    
    func clear() {
        memset(memPointer, 0, MemoryLayout<SpriteData>.stride)
    }
    
    func Write(address: UInt16, value: UInt8) {
        var valueSet = value
        let rawMemory = UnsafeMutableRawPointer(memPointer)
        memcpy(rawMemory.advanced(by: Int(address)), &valueSet, 1)
    }
    
    var memPointer:UnsafeMutablePointer<SpriteData> = UnsafeMutablePointer<SpriteData>.allocate(capacity: 64)
}
