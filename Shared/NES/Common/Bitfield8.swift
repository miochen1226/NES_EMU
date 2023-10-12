//
//  Bitfield8.swift
//  NES_EMU
//
//  Created by mio on 2021/8/10.
//

import Foundation
class Bitfield8 : Codable {
    
    enum CodingKeys: String, CodingKey {
        case field
    }
    
    init() {
        
    }
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        field = try values.decode(UInt8.self, forKey: .field)
        
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(field, forKey: .field)
        
    }
    
    
    func value() -> UInt8 {
        return field
    }
    
    func setValue(_ value: UInt8) {
        field = value
    }

    func  clearAll() {
        field = 0
    }
    
    func setAll() {
        field = UInt8(~0)
    }

    func set(bits: UInt8, enabled: UInt8) {
        if enabled != 0 {
            set(bits)
        }
        else {
            clear(bits)
        }
    }
    
    func set(_ bits:UInt8)
    {
        field |= bits
    }
    
    func clear(_ bits:UInt8) {
        field &= ~bits
    }
    
    func read(_ bits:UInt8)->UInt8
    {
        return field & bits
    }
    
    func test(_ bits:UInt8) -> Bool {
        let ret = read(bits)
        if(ret == 0) {
            return false
        }
        else {
            return true
        }
    }
    
    func test01(_ bits:UInt8) -> UInt8 {
        if read(bits) != 0 {
            return 1
        }
        else {
            return 0
        }
    }

    // Bit position functions
    func setPos(bitPos:UInt8, enabled: UInt8) {
        if enabled != 0 {
            setPos(bitPos)
        }
        else {
            clearPos(bitPos)
        }
    }
    
    func setPos(_ bitPos: UInt8) {
        set(1 << bitPos)
    }
    
    func clearPos(_ bitPos: UInt8) {
        clear(1 << bitPos)
    }
    
    func readPos(_ bitPos: UInt8) -> UInt8 {
        return read(1 << bitPos)
    }
        
    func testPos(bitPos: UInt8) -> Bool {
        return read(1 << bitPos) != 0
    }
        
    func testPos01(_ bitPos: UInt8) -> UInt8 {
        if read(1 << bitPos) != 0 {
            return 1
        }
        else {
            return 0
        }
    }
    
    var field: UInt8 = 0
}
