//
//  OAM.swift
//  NES_EMU
//
//  Created by mio on 2023/8/10.
//

import Foundation

class OAM: NSObject, Codable {
    enum CodingKeys: String, CodingKey {
        case spriteDatas
    }
    var spriteDatas:[SpriteData] = []
    var memPointer:UnsafeMutablePointer<SpriteData> = UnsafeMutablePointer<SpriteData>.allocate(capacity: 64)
    
    override init() {}
    deinit {
        memPointer.deallocate()
    }
    
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
    
    func write(address: UInt16, value: UInt8) {
        var valueSet = value
        let rawMemory = UnsafeMutableRawPointer(memPointer)
        memcpy(rawMemory.advanced(by: Int(address)), &valueSet, 1)
    }
    
    
    //var paletteColorsData:[PixelColor] = []
    required init(from decoder: Decoder) throws {
        super.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        spriteDatas = try values.decode([SpriteData].self, forKey: .spriteDatas)
        
        var index = 0
        for spriteData in spriteDatas {
            setSprite(index, spriteData: spriteData)
            index += 1
        }
    }
    
    func encode(to encoder: Encoder) throws {
        beforeSave()
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(spriteDatas, forKey: .spriteDatas)
    }
    
    func beforeSave() {
        spriteDatas.removeAll()
        for i in 0 ..< 64 {
            spriteDatas.append(getSprite(i))
        }
    }
}
