//
//  Mapper.swift
//  NES_EMU
//
//  Created by mio on 2021/8/8.
//

import Foundation

class MapperBase: NSObject, Codable {
    var irqEnabled: Bool = false
    var irqReloadPending: Bool = false
    var irqPending: Bool = false
    var numPrgBanks: UInt8 = 0
    var numChrBanks: UInt8 = 0
    var numSavBanks: UInt8 = 0
    var canWritePrgMemory = false
    var canWriteChrMemory = false
    var canWriteSavMemory = false
    var nextBankToUpdate: UInt8 = 0
    var nametableMirroring = NameTableMirroring.Vertical
    var prgBankIndices: [Int:UInt8] = [:]
    var chrBankIndices: [Int:UInt8] = [:]
    var savBankIndices: [Int:UInt8] = [:]
    
    override init() {}
    
    enum CodingKeys: String, CodingKey {
        case irqEnabled
        case irqReloadPending
        case irqPending
        case numPrgBanks
        case numChrBanks
        case numSavBanks
        case canWritePrgMemory
        case canWriteChrMemory
        case canWriteSavMemory
        case nextBankToUpdate
        case nametableMirroring
        case prgBankIndices
        case chrBankIndices
        case savBankIndices
    }
    
    required init(from decoder: Decoder) throws {
        print("MapperBase.decoder")
        let values = try decoder.container(keyedBy: CodingKeys.self)
        irqEnabled = try values.decode(Bool.self, forKey: .irqEnabled)
        irqReloadPending = try values.decode(Bool.self, forKey: .irqReloadPending)
        irqPending = try values.decode(Bool.self, forKey: .irqPending)
        numPrgBanks = try values.decode(UInt8.self, forKey: .numPrgBanks)
        numChrBanks = try values.decode(UInt8.self, forKey: .numChrBanks)
        numSavBanks = try values.decode(UInt8.self, forKey: .numSavBanks)
        canWritePrgMemory = try values.decode(Bool.self, forKey: .canWritePrgMemory)
        canWriteChrMemory = try values.decode(Bool.self, forKey: .canWriteChrMemory)
        canWriteSavMemory = try values.decode(Bool.self, forKey: .canWriteSavMemory)
        nextBankToUpdate = try values.decode(UInt8.self, forKey: .nextBankToUpdate)
        nametableMirroring = try values.decode(NameTableMirroring.self, forKey: .nametableMirroring)
        prgBankIndices = try values.decode([Int:UInt8].self, forKey: .prgBankIndices)
        chrBankIndices = try values.decode([Int:UInt8].self, forKey: .chrBankIndices)
        savBankIndices = try values.decode([Int:UInt8].self, forKey: .savBankIndices)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(irqEnabled, forKey: .irqEnabled)
        try container.encode(irqReloadPending, forKey: .irqReloadPending)
        try container.encode(irqPending, forKey: .irqPending)
        
        try container.encode(numPrgBanks, forKey: .numPrgBanks)
        try container.encode(numChrBanks, forKey: .numChrBanks)
        try container.encode(numSavBanks, forKey: .numSavBanks)
        
        try container.encode(canWritePrgMemory, forKey: .canWritePrgMemory)
        try container.encode(canWriteChrMemory, forKey: .canWriteChrMemory)
        try container.encode(canWriteSavMemory, forKey: .canWriteSavMemory)
        
        try container.encode(nextBankToUpdate, forKey: .nextBankToUpdate)
        try container.encode(nametableMirroring, forKey: .nametableMirroring)
        
        try container.encode(prgBankIndices, forKey: .prgBankIndices)
        try container.encode(chrBankIndices, forKey: .chrBankIndices)
        try container.encode(savBankIndices, forKey: .savBankIndices)
        
        print("MapperBase.encode")
    }
}


class Mapper : MapperBase,IMapper {
    func CanWriteChrMemory() -> Bool {
        return canWriteChrMemory
    }
    
    func OnCpuWrite(cpuAddress:UInt16, value: UInt8) {
    }
    
    func GetMappedSavBankIndex(cpuBankIndex: Int) -> UInt8 {
        return savBankIndices[cpuBankIndex]!
    }
    
    func GetMappedChrBankIndex(ppuBankIndex: Int) -> UInt8 {
        return chrBankIndices[ppuBankIndex]!
    }
    
    func CanWritePrgMemory() -> Bool {
        return canWritePrgMemory
    }
    
    func CanWriteSavMemory() -> Bool {
        return canWriteSavMemory
    }
    
    func Initialize(numPrgBanks: UInt8, numChrBanks: UInt8, numSavBanks: UInt8) {
        self.numPrgBanks = numPrgBanks
        self.numChrBanks = numChrBanks
        self.numSavBanks = numSavBanks
    
        canWritePrgMemory = false
        canWriteChrMemory = false
        canWriteSavMemory = true

        if numChrBanks == 0 {
            self.numChrBanks = 8 // 8K of CHR-RAM
            canWriteChrMemory = true
        }

        // Default init banks to most common mapping
        SetPrgBankIndex32k(cpuBankIndexIn:0, cartBankIndexIn:0)
        SetChrBankIndex8k(ppuBankIndexIn:0, cartBankIndexIn:0)
        SetSavBankIndex8k(cpuBankIndexIn:0, cartBankIndexIn:0)
        postInitialize()
    }
    
    func postInitialize() {
        
    }
    
    func TestAndClearIrqPending() -> Bool {
        return false
    }
    
    func SetCanWritePrgMemory(_ enabled: Bool) {
        canWritePrgMemory = enabled
    }
    
    func SetCanWriteChrMemory(_ enabled: Bool) {
        canWriteChrMemory = enabled
    }
    
    func SetCanWriteSavMemory(_ enabled: Bool) {
        canWriteSavMemory = enabled
    }
    
    func SetNameTableMirroring(_ value: NameTableMirroring) {
        nametableMirroring = value
    }
    
    func GetNameTableMirroring() -> NameTableMirroring {
        return nametableMirroring
    }
    
    func SetPrgBankIndex16k(cpuBankIndexIn:Int, cartBankIndexIn: UInt8) {
        let cpuBankIndex = cpuBankIndexIn * 4
        let cartBankIndex = cartBankIndexIn * 4
        prgBankIndices[cpuBankIndex] = cartBankIndex
        prgBankIndices[cpuBankIndex + 1] = cartBankIndex + 1
        prgBankIndices[cpuBankIndex + 2] = cartBankIndex + 2
        prgBankIndices[cpuBankIndex + 3] = cartBankIndex + 3
    }
    
    func SetPrgBankIndex32k(cpuBankIndexIn: Int, cartBankIndexIn: UInt8) {
        var cpuBankIndex = cpuBankIndexIn
        var cartBankIndex = cartBankIndexIn
        
        cpuBankIndex *= 8
        cartBankIndex *= 8
        prgBankIndices[cpuBankIndex] = cartBankIndex
        prgBankIndices[cpuBankIndex + 1] = cartBankIndex + 1
        prgBankIndices[cpuBankIndex + 2] = cartBankIndex + 2
        prgBankIndices[cpuBankIndex + 3] = cartBankIndex + 3
        prgBankIndices[cpuBankIndex + 4] = cartBankIndex + 4
        prgBankIndices[cpuBankIndex + 5] = cartBankIndex + 5
        prgBankIndices[cpuBankIndex + 6] = cartBankIndex + 6
        prgBankIndices[cpuBankIndex + 7] = cartBankIndex + 7
    }
    
    func SetChrBankIndex8k(ppuBankIndexIn: Int, cartBankIndexIn: UInt8) {
        var ppuBankIndex = ppuBankIndexIn
        var cartBankIndex = cartBankIndexIn
        ppuBankIndex *= 8
        cartBankIndex *= 8
        chrBankIndices[ppuBankIndex] = cartBankIndex
        chrBankIndices[ppuBankIndex + 1] = cartBankIndex + 1
        chrBankIndices[ppuBankIndex + 2] = cartBankIndex + 2
        chrBankIndices[ppuBankIndex + 3] = cartBankIndex + 3
        chrBankIndices[ppuBankIndex + 4] = cartBankIndex + 4
        chrBankIndices[ppuBankIndex + 5] = cartBankIndex + 5
        chrBankIndices[ppuBankIndex + 6] = cartBankIndex + 6
        chrBankIndices[ppuBankIndex + 7] = cartBankIndex + 7
    }
    
    func SetSavBankIndex8k(cpuBankIndexIn:Int, cartBankIndexIn: UInt8) {
        savBankIndices[cpuBankIndexIn] = cartBankIndexIn
    }
    
    func GetMappedPrgBankIndex(_ cpuBankIndex:Int) -> Int {
        return Int(prgBankIndices[cpuBankIndex]!)
    }
    
    func NumPrgBanks4k() -> UInt8 {
        return numPrgBanks / 2
    }
    
    func NumPrgBanks8k() -> UInt8 {
        return numPrgBanks / 2
    }
    
    func NumPrgBanks16k() -> UInt8 {
        return numPrgBanks / 4
    }
    
    func NumPrgBanks32k() -> UInt8 {
        return numPrgBanks / 8
    }
    
    func NumChrBanks1k() -> UInt8 {
        return numChrBanks
    }
    
    func NumChrBanks4k() -> UInt8 {
        return numChrBanks / 4
    }
    
    func NumChrBanks8k() -> UInt8 {
        return numChrBanks / 8
    }
    
    func NumSavBanks8k() -> UInt8 {
        return numSavBanks
    }
    
    func SetPrgBankIndex4k(cpuBankIndex: UInt8, cartBankIndex: UInt8) {
        prgBankIndices[Int(cpuBankIndex)] = cartBankIndex
    }
    
    func SetPrgBankIndex8k(cpuBankIndex: UInt8, cartBankIndex: UInt8) {
        var cpuBankIndex_ = Int(cpuBankIndex)
        var cartBankIndex_ = cartBankIndex
        cpuBankIndex_ *= 2
        cartBankIndex_ *= 2
        prgBankIndices[cpuBankIndex_] = cartBankIndex_
        prgBankIndices[cpuBankIndex_ + 1] = cartBankIndex_ + 1
    }
    
    func SetPrgBankIndex16k(cpuBankIndex: UInt8, cartBankIndex: UInt8) {
        var cpuBankIndex_ = Int(cpuBankIndex)
        var cartBankIndex_ = cartBankIndex
        cpuBankIndex_ *= 4
        cartBankIndex_ *= 4
        prgBankIndices[cpuBankIndex_] = cartBankIndex_
        prgBankIndices[cpuBankIndex_ + 1] = cartBankIndex_ + 1
        prgBankIndices[cpuBankIndex_ + 2] = cartBankIndex_ + 2
        prgBankIndices[cpuBankIndex_ + 3] = cartBankIndex_ + 3
    }
    
    func SetPrgBankIndex32k(cpuBankIndex: UInt8, cartBankIndex : UInt8) {
        var cpuBankIndex_ = cpuBankIndex
        var cartBankIndex_ = cartBankIndex
        
        cpuBankIndex_ *= 8
        cartBankIndex_ *= 8
        prgBankIndices[Int(cpuBankIndex_)] = cartBankIndex_
        prgBankIndices[Int(cpuBankIndex_) + 1] = (cartBankIndex_) + 1
        prgBankIndices[Int(cpuBankIndex_) + 2] = (cartBankIndex_) + 2
        prgBankIndices[Int(cpuBankIndex_) + 3] = (cartBankIndex_) + 3
        prgBankIndices[Int(cpuBankIndex_) + 4] = (cartBankIndex_) + 4
        prgBankIndices[Int(cpuBankIndex_) + 5] = (cartBankIndex_) + 5
        prgBankIndices[Int(cpuBankIndex_) + 6] = (cartBankIndex_) + 6
        prgBankIndices[Int(cpuBankIndex_) + 7] = (cartBankIndex_) + 7
    }

    func SetChrBankIndex1k(ppuBankIndex:UInt8, cartBankIndex: UInt8) {
        chrBankIndices[Int(ppuBankIndex)] = cartBankIndex
    }
    
    func SetChrBankIndex4k(ppuBankIndex:UInt8, cartBankIndex: UInt8) {
        var ppuBankIndex_ = Int(ppuBankIndex)
        var cartBankIndex_ = cartBankIndex
        
        ppuBankIndex_ *= 4
        cartBankIndex_ *= 4
        
        chrBankIndices[ppuBankIndex_] = cartBankIndex_
        chrBankIndices[ppuBankIndex_ + 1] = cartBankIndex_ + 1
        chrBankIndices[ppuBankIndex_ + 2] = cartBankIndex_ + 2
        chrBankIndices[ppuBankIndex_ + 3] = cartBankIndex_ + 3
    }
    
    func SetChrBankIndex8k(ppuBankIndex:UInt, cartBankIndex: UInt8) {
        var ppuBankIndex_ = Int(ppuBankIndex)
        var cartBankIndex_ = cartBankIndex
        
        ppuBankIndex_ *= 8
        cartBankIndex_ *= 8
        chrBankIndices[ppuBankIndex_] = cartBankIndex_
        chrBankIndices[ppuBankIndex_ + 1] = cartBankIndex_ + 1;
        chrBankIndices[ppuBankIndex_ + 2] = cartBankIndex_ + 2;
        chrBankIndices[ppuBankIndex_ + 3] = cartBankIndex_ + 3;
        chrBankIndices[ppuBankIndex_ + 4] = cartBankIndex_ + 4;
        chrBankIndices[ppuBankIndex_ + 5] = cartBankIndex_ + 5;
        chrBankIndices[ppuBankIndex_ + 6] = cartBankIndex_ + 6;
        chrBankIndices[ppuBankIndex_ + 7] = cartBankIndex_ + 7;
    }
    
    func PrgMemorySize() -> UInt {
        return UInt(numPrgBanks) * Mapper.kPrgBankSize
    }
    
    static var kPrgBankCount:UInt = 8
    static var kPrgBankSize:UInt = KB(4)
    static var kChrBankCount:UInt = 8
    static var kChrBankSize:UInt = KB(1)
    static var kSavBankCount:UInt = 1
    static var kSavBankSize:UInt = KB(8)
}
