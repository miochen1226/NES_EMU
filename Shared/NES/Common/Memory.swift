//
//  Memory.swift
//  NES_EMU
//
//  Created by mio on 2021/8/7.
//

import Foundation
class Memory:NSObject, Codable {
    enum CodingKeys: String, CodingKey {
        case memorySize
        case rawBuffer
        case dataArray
    }
    
    override init() {
        
    }
    
    required init(from decoder: Decoder) throws {
        super.init()
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        memorySize = try values.decode(Int.self, forKey: .memorySize)
        rawBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(memorySize))
        dataArray = try values.decode([UInt8].self, forKey: .dataArray)
        
        
        rawBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(memorySize))
        var address = 0
        for dataValue in dataArray {
            self.putValue(address: address, value: dataValue)
            address += 1
        }
    }
    
    func encode(to encoder: Encoder) throws {
        prepareSave()
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(memorySize, forKey: .memorySize)
        try container.encode(dataArray, forKey: .dataArray)
    }
    
    func prepareSave() {
        dataArray.removeAll()
        for address in 0 ..< memorySize {
            let value = rawRef(address: Int(address))
            dataArray.append(value)
        }
    }
    
    deinit {
        rawBuffer.deallocate()
    }
    
    func initial(size: Int) {
        memorySize = size
        rawBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(size))
        for index in 0..<memorySize {
            rawBuffer[Int(index)] = 0
        }
    }
    
    func putValue(address: Int, value: UInt8) {
        rawBuffer[address] = value
    }
    
    func rawRef(address: Int) -> UInt8 {
        return rawBuffer[address]
    }
    
    func read(_ address: UInt16) -> UInt8 {
        return rawBuffer[Int(address)]
    }

    func write(address: UInt16, value: UInt8) {
        rawBuffer[Int(address)] = value
    }
    
    var memorySize:Int = 0
    var rawBuffer:UnsafeMutablePointer<UInt8>! = nil
    private var dataArray:[UInt8] = []
}

class PpuRegisterMemory: Memory {
    required init(from decoder: Decoder) throws {
        try! super.init(from: decoder)
        //let values = try decoder.container(keyedBy: CodingKeys.self)
    }
    
    override init() {
        super.init()
        memorySize = 8
        initial(size: 8)
    }
}

class PaletteMemory: Memory {
    required init(from decoder: Decoder) throws {
        try! super.init(from: decoder)
    }
    
    override init() {
        super.init()
        memorySize = 32
        initial(size: 32)
    }
}

class CpuInternalMemory: Memory {
    required init(from decoder: Decoder) throws {
        try! super.init(from: decoder)
    }
    
    override init() {
        super.init()
    }
    /*
    func initialize(initSize:Int) -> CpuInternalMemory {
        memorySize = initSize
        initial(size: initSize)
        return self
    }
     */
}

class NameTableMemory: Memory {
    
    required init(from decoder: Decoder) throws {
        try! super.init(from: decoder)
    }
    
    static var kSize = 2048
    override init() {
        super.init()
    }
    
    /*
    init(initSize: UInt) {
        super.init()
        memorySize = initSize
        initial(size: initSize)
    }
    */
    override func read(_ address: UInt16) -> UInt8 {
        assert(address < 2048)
        return rawBuffer[Int(address)]
    }
    
    override func write( address: UInt16, value: UInt8) {
        assert(address < 2048)
        rawBuffer[Int(address)] = value
    }
}

