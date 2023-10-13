//
//  Mapper1.swift
//  NES_EMU
//
//  Created by mio on 2021/8/8.
//

import Foundation


extension LoadRegister: Codable {
    /*
     var bitsWritten:UInt8 = 0
     var value:Bitfield8 = Bitfield8()
     */
    enum CodingKeys: String, CodingKey {
        case bitsWritten
        case value
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(bitsWritten, forKey: .bitsWritten)
        try container.encode(value, forKey: .value)
    }
}

class LoadRegister: NSObject{
    
    required init(from decoder: Decoder) throws {
    }
    
    override init() {
        super.init()
        reset()
    }
    
    func reset() {
        value.clearAll()
        bitsWritten = 0
    }
    
    func SetBit(bit:UInt8) {
        
        //"All bits already written, must Reset"
        assert(bitsWritten < 5)
        
        var enable:UInt8 = 0
        if (bit & 0x01) != 0 {
            enable = 1
        }
        
        value.setPos(bitPos: bitsWritten, enabled: enable)
        bitsWritten += 1
    }
    
    func AllBitsSet() -> Bool {
        return bitsWritten == 5
    }
    
    func Value() -> UInt8 {
        return value.value()
    }
    
    var bitsWritten:UInt8 = 0
    var value:Bitfield8 = Bitfield8()
}

extension Mapper1 {
    
    /*
     var controlReg:Bitfield8 = Bitfield8()
     var chrReg0:Bitfield8 = Bitfield8()
     var chrReg1:Bitfield8 = Bitfield8()
     var prgReg:Bitfield8 = Bitfield8()
     var boardType:BoardType  = BoardType.DEFAULT
     var loadReg:LoadRegister = LoadRegister()
     */
    enum CodingKeys: String, CodingKey {
        case controlReg
        case chrReg0
        case chrReg1
        case prgReg
        case boardType
        case loadReg
    }
}

class Mapper1: Mapper {
    var controlReg:Bitfield8 = Bitfield8()
    var chrReg0:Bitfield8 = Bitfield8()
    var chrReg1:Bitfield8 = Bitfield8()
    var prgReg:Bitfield8 = Bitfield8()
    var boardType:BoardType  = BoardType.DEFAULT
    var loadReg:LoadRegister = LoadRegister()
    
    override init(){
        super.init()
    }
    
    required init(from decoder: Decoder) throws {
        try! super.init(from: decoder)
        print("Mapper1.decoder")
        let values = try decoder.container(keyedBy: CodingKeys.self)
        controlReg = try values.decode(Bitfield8.self, forKey: .controlReg)
        chrReg0 = try values.decode(Bitfield8.self, forKey: .chrReg0)
        chrReg1 = try values.decode(Bitfield8.self, forKey: .chrReg1)
        prgReg = try values.decode(Bitfield8.self, forKey: .prgReg)
        boardType = try values.decode(BoardType.self, forKey: .boardType)
        loadReg = try values.decode(LoadRegister.self, forKey: .loadReg)
    }
    
    override func encode(to encoder: Encoder) throws {
        print("Mapper1.encode")
        var container = encoder.container(keyedBy: CodingKeys.self)
        try super.encode(to: encoder)
        
        try container.encode(controlReg, forKey: .controlReg)
        try container.encode(chrReg0, forKey: .chrReg0)
        try container.encode(chrReg1, forKey: .chrReg1)
        try container.encode(prgReg, forKey: .prgReg)
        try container.encode(boardType, forKey: .boardType)
        try container.encode(loadReg, forKey: .loadReg)
        
    }
    
    
    override func OnCpuWrite(cpuAddress:UInt16, value:UInt8) {
        if (cpuAddress < 0x8000) {
            return
        }
        
        let reset:Bool = (value & BIT(7)) != 0

        if reset {
            loadReg.reset()
            controlReg.set(BITS([2,3]))
        }
        else {
            let dataBit:UInt8 = value & BIT(0)
            loadReg.SetBit(bit: dataBit)
            
            if loadReg.AllBitsSet() {
                switch (cpuAddress & 0xE000) {
                    case 0x8000:
                        controlReg.setValue(loadReg.Value())
                        UpdatePrgBanks()
                        UpdateChrBanks()
                        UpdateMirroring()
                        break

                    case 0xA000:
                        chrReg0.setValue(loadReg.Value())
                        
                        // Hijacks CHR reg bit 4 to select PRG 256k bank
                        if (boardType == BoardType.SUROM) {
                            UpdatePrgBanks()
                        }
                    
                        UpdateChrBanks()
                        break

                    case 0xC000:
                        chrReg1.setValue(loadReg.Value())
                        UpdateChrBanks()
                        break;

                    case 0xE000:
                        prgReg.setValue(loadReg.Value())
                        UpdatePrgBanks()
                        break

                    default:
                        assert(false)
                        break
                }

                loadReg.reset()
            }
        }
    }

    enum BoardType: Codable{
        case DEFAULT
        case SUROM
    }
    
    override func postInitialize() {
        boardType = BoardType.DEFAULT
        
        if (PrgMemorySize() == KB(512)) {
            boardType = BoardType.SUROM
        }
            
        loadReg.reset()

        controlReg.setValue(BITS([2,3]))
        chrReg0.clearAll()
        chrReg1.clearAll()
        prgReg.clearAll()

        UpdatePrgBanks()
        UpdateChrBanks()
        UpdateMirroring()
    }
    
    func UpdatePrgBanks() {
        let bankMode = controlReg.read(BITS([2,3])) >> 2

        // 32k mode
        if (bankMode <= 1) {
            let mask = NumPrgBanks32k() - 1
            let cartBankIndex = (prgReg.read(BITS([0,1,2,3])) >> 1) & mask
            
            SetPrgBankIndex32k(cpuBankIndexIn: 0, cartBankIndexIn: cartBankIndex)
        }
        // 16k mode
        else {
            var mask:UInt8 = NumPrgBanks16k() - 1
            if mask > 16 {
                mask = 16
                assert(true)
            }
            var cartBankIndex = prgReg.read(BITS([0,1,2,3])) & mask
            var firstBankIndex:UInt8 = 0
            var lastBankIndex = (NumPrgBanks16k() - 1) & mask

            if boardType == BoardType.SUROM {
                let prgBankSelect256k = chrReg0.read(BIT(4))
                cartBankIndex |= prgBankSelect256k
                firstBankIndex |= prgBankSelect256k
                lastBankIndex |= prgBankSelect256k
            }

            if bankMode == 2 {
                SetPrgBankIndex16k(cpuBankIndexIn: 0, cartBankIndexIn: firstBankIndex)
                SetPrgBankIndex16k(cpuBankIndexIn: 1, cartBankIndexIn: cartBankIndex)
            }
            else {
                SetPrgBankIndex16k(cpuBankIndexIn: 0, cartBankIndexIn: cartBankIndex)
                SetPrgBankIndex16k(cpuBankIndexIn: 1, cartBankIndexIn: lastBankIndex)
            }
        }

        let bSavRamChipEnabled = prgReg.readPos(4) == 0
        SetCanWriteSavMemory(bSavRamChipEnabled)
    }
    
    func UpdateChrBanks() {
        let mode8k:Bool = controlReg.readPos(4) == 0
        
        if mode8k {
            let mask = NumChrBanks8k() - 1
            
            let value = (chrReg0.value() >> 1) & mask
            SetChrBankIndex8k(ppuBankIndexIn: 0, cartBankIndexIn: value)
        }
        else {
            let mask = NumChrBanks4k() - 1
            let value_0 = chrReg0.value() & mask
            let value_1 = chrReg1.value() & mask
            SetChrBankIndex4k(ppuBankIndex: 0, cartBankIndex: value_0)
            SetChrBankIndex4k(ppuBankIndex: 1, cartBankIndex: value_1)
        }
    }

    func UpdateMirroring() {
        let table:[NameTableMirroring] =
        [
            NameTableMirroring.OneScreenLower,
            NameTableMirroring.OneScreenUpper,
            NameTableMirroring.Vertical,
            NameTableMirroring.Horizontal,
        ]

        let mirroringType = controlReg.read(BITS([0,1]))
        SetNameTableMirroring(table[Int(mirroringType)])
    }
}
