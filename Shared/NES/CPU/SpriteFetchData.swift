//
//  SpriteFetchData.swift
//  NES_EMU
//
//  Created by mio on 2021/8/13.
//

import Foundation

struct SpriteData {
    
    // Fetched from VRAM
    var bmpLow:UInt8 = 0
    var bmpHigh:UInt8 = 0
    
    // Copied from OAM2
    var attributes:UInt8 = 0
    var x:UInt8 = 0
}

struct SpriteFetchData {
    
    // Fetched from VRAM
    var bmpLow:UInt8 = 0
    var bmpHigh:UInt8 = 0
    
    // Copied from OAM2
    var attributes:UInt8 = 0
    var x:UInt8 = 0
}
