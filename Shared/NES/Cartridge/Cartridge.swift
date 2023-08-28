//
//  Cartridge.swift
//  NES_EMU
//
//  Created by mio on 2021/8/6.
//

import Foundation

class Cartridge: ICartridge {
    func hackOnScanline(nes:Nes) {
        mapper.hackOnScanline()
        if mapper.TestAndClearIrqPending() {
            nes.SignalCpuIrq()
        }
    }
    
    func handlePpuRead(_ ppuAddress: UInt16) -> UInt8 {
        return accessChrMem(ppuAddress)
    }
    
    func accessChrMem(_ ppuAddress: UInt16) -> UInt8 {
        let bankIndex:Int = getBankIndex(address: ppuAddress, baseAddress: PpuMemory.kChrRomBase, bankSize: kChrBankSize)
        let offset:Int = Int(getBankOffset(address: ppuAddress, bankSize: kChrBankSize))
        let mappedBankIndex:Int = Int(mapper.GetMappedChrBankIndex(ppuBankIndex: Int(bankIndex)))
        return chrBanks[mappedBankIndex].rawRef(address:offset)
    }
    
    func handlePpuWrite(_ ppuAddress: UInt16, value: UInt8) {
        if mapper.CanWriteChrMemory() {
            accessChrMem(ppuAddress:ppuAddress,value:value)
        }
    }
    
    func accessChrMem( ppuAddress: UInt16, value: UInt8) {
        let bankIndex = getBankIndex(address: ppuAddress, baseAddress: PpuMemory.kChrRomBase, bankSize: kChrBankSize)
        let offset = getBankOffset(address: ppuAddress, bankSize: kChrBankSize)
        let mappedBankIndex = mapper.GetMappedChrBankIndex(ppuBankIndex: bankIndex)
        chrBanks[Int(mappedBankIndex)].write(address: offset, value: value)
    }
    
    func handleCpuRead(_ cpuAddress: UInt16) -> UInt8 {
        if cpuAddress >= CpuMemory.kPrgRomBase {
            return accessPrgMem(cpuAddress)
        }
        else if cpuAddress >= CpuMemory.kSaveRamBase {
            return AccessSavMem(cpuAddress)
        }

        return 0
    }
    
    func handleCpuWrite(_ cpuAddress: UInt16, value: UInt8) {
        mapper.OnCpuWrite(cpuAddress: cpuAddress, value: value)
        if cpuAddress >= CpuMemory.kPrgRomBase {
            if mapper.CanWritePrgMemory() {
                AccessPrgMem(cpuAddress,value: value)
            }
        }
        else if cpuAddress >= CpuMemory.kSaveRamBase {
            if mapper.CanWriteSavMemory() {
                AccessSavMem(cpuAddress,value: value)
            }
        }
        else {
            print("Unhandled by mapper - write: $%04X\n", cpuAddress)
        }
    }
    
    func getBankIndex(address: UInt16, baseAddress: UInt16, bankSize: UInt16) -> Int {
        let firstBankIndex = baseAddress / bankSize
        return Int((address / bankSize) - firstBankIndex)
    }
    
    func getBankOffset(address: UInt16, bankSize: UInt16) -> UInt16 {
        return address & (bankSize - 1)
    }
    
    func accessPrgMem(_ cpuAddress: UInt16) -> UInt8 {
        let bankIndex = getBankIndex(address: cpuAddress, baseAddress: CpuMemory.kPrgRomBase, bankSize: kPrgBankSize)
        let offset = getBankOffset(address: cpuAddress, bankSize: kPrgBankSize)
        let mappedBankIndex = mapper.GetMappedPrgBankIndex(Int(bankIndex))
        let memory = prgBanks[mappedBankIndex]
        return memory.rawRef(address: Int(offset))
    }
    
    func AccessPrgMem(_ cpuAddress: UInt16, value: UInt8) {
        let bankIndex = getBankIndex(address: cpuAddress, baseAddress: CpuMemory.kPrgRomBase, bankSize: kPrgBankSize)
        let offset = getBankOffset(address: cpuAddress, bankSize: kPrgBankSize)
        let mappedBankIndex = mapper.GetMappedPrgBankIndex(Int(bankIndex))
        let memory = prgBanks[mappedBankIndex]
        memory.write(address: offset, value: value)
    }
    
    func AccessSavMem(_ cpuAddress: UInt16,value: UInt8) {
        let bankIndex = getBankIndex(address: cpuAddress, baseAddress: CpuMemory.kSaveRamBase, bankSize: kSavBankSize)
        let offset = getBankOffset(address: cpuAddress, bankSize: kSavBankSize)
        let mappedBankIndex = mapper.GetMappedSavBankIndex(cpuBankIndex: bankIndex)
        let memory = savBanks[Int(mappedBankIndex)]
        memory.write(address: offset, value: value)
    }
    
    func AccessSavMem(_ cpuAddress: UInt16) -> UInt8 {
        let bankIndex = getBankIndex(address: cpuAddress, baseAddress: CpuMemory.kSaveRamBase, bankSize: kSavBankSize)
        let offset = getBankOffset(address: cpuAddress, bankSize: kSavBankSize)
        let mappedBankIndex = mapper.GetMappedSavBankIndex(cpuBankIndex: bankIndex)
        let memory = savBanks[Int(mappedBankIndex)]
        return memory.read(offset)
    }
    
    func loadFile() {
        loadRom()
    }
    
    func loadRom() {
        //let filepath = Bundle.main.path(forResource: "Donkey Kong (Japan)", ofType: "nes")
        
        let bundleUrl = Bundle.main.url(forResource: "Roms", withExtension: "bundle")
        //let filepath = bundleUrl!.appendingPathComponent("Super Mario Bros. (Japan, USA).nes")
        //let filepath = bundleUrl!.appendingPathComponent("Donkey Kong (Japan).nes")
        //let filepath = bundleUrl!.appendingPathComponent("Ice Climber (Japan).nes")
        let filepath = bundleUrl!.appendingPathComponent("Super Mario Bros. 3 (USA).nes")
        //let filepath = bundleUrl!.appendingPathComponent("Donkey Kong (Japan).nes")
        //if let filepath = Bundle.main.path(forResource: "Donkey Kong (Japan)", ofType: "nes")
        //if let filepath = Bundle.main.path(forResource: "Circus Charlie (J) [p1]", ofType: "nes")
        //if let filepath = Bundle.main.path(forResource: "Ice Climber (Japan)", ofType: "nes")
        //if let filepath = Bundle.main.path(forResource: "Donkey Kong Jr. (USA) (GameCube Edition)", ofType: "nes")
        
        if let data = NSData(contentsOf: filepath) {
            let arrayData = [UInt8](data)
            romHeader = RomHeader.init().Initialize(bytes: arrayData)
            
            if romHeader == nil {
                NSLog("Rom header incorrect")
                return
            }
            
            //PRG_ROM
            let prgRomSize = romHeader!.GetPrgRomSizeBytes()
            if prgRomSize % globeDef.kPrgBankSize != 0 {
                NSLog("prgRomSize incorrect")
                return
            }
            
            let numPrgBanks = prgRomSize / globeDef.kPrgBankSize
            var readIndex = 16
            for _ in 0..<numPrgBanks {
                let newMemory = Memory.init()
                newMemory.initial(size: globeDef.kPrgBankSize)
                let beginIndex:UInt = UInt(readIndex)
                fillMemory(srcMem: arrayData, begin: beginIndex, size: Int(globeDef.kPrgBankSize), memory: newMemory)
                readIndex = readIndex + Int(globeDef.kPrgBankSize)
                prgBanks.append(newMemory)
            }
            
            // CHR-ROM data
            let chrRomSize = romHeader!.GetChrRomSizeBytes()
            if chrRomSize % globeDef.kChrBankSize != 0 {
                NSLog("chrRomSize incorrect")
                return
            }
            
            let numChrBanks = chrRomSize / globeDef.kChrBankSize
            for _ in 0..<numChrBanks {
                let newMemory = Memory.init()
                newMemory.initial(size: globeDef.kChrBankSize)
                let beginIndex:UInt = UInt(readIndex)
                
                fillMemory(srcMem: arrayData, begin: beginIndex, size: Int(globeDef.kChrBankSize), memory: newMemory)
                
                readIndex = readIndex + Int(globeDef.kChrBankSize)
                chrBanks.append(newMemory)
            }
            
            let numSavBanks = romHeader!.GetNumPrgRamBanks();
            if numSavBanks > kMaxSavBanks {
                NSLog("numSavBanks incorrect")
                return
            }
            
            for _ in 0..<numSavBanks {
                let newMemory = Memory.init()
                newMemory.initial(size: globeDef.kSavBankSize)
                savBanks.append(newMemory)
            }
            
            let mN = romHeader!.GetMapperNumber()
            if mN == 0 {
                mapper = Mapper0()
                mapper.Initialize(numPrgBanks: UInt8(numPrgBanks), numChrBanks: UInt8(numChrBanks), numSavBanks: UInt8(numSavBanks))
            }
            else if mN == 4 {
                mapper = Mapper4()
                mapper.Initialize(numPrgBanks: UInt8(numPrgBanks), numChrBanks: UInt8(numChrBanks), numSavBanks: UInt8(numSavBanks))
            }
            else {
                mapper = Mapper1()
                mapper.Initialize(numPrgBanks: UInt8(numPrgBanks), numChrBanks: UInt8(numChrBanks), numSavBanks: UInt8(numSavBanks))
            }
            
            cartNameTableMirroring = romHeader!.GetNameTableMirroring()
            hasSRAM = romHeader!.HasSRAM();
        }
    }
    
    func getNameTableMirroring() -> NameTableMirroring {
        return cartNameTableMirroring
    }
    
    func fillMemory( srcMem: [UInt8],begin: UInt,size: Int,memory: Memory) {
        var beginIndex:UInt = begin
        for index in 0..<size {
            let indexInFile = Int(beginIndex)
            let rawValue = srcMem[indexInFile]
            memory.putValue(address: Int(index), value: rawValue)
            beginIndex = beginIndex + 1
        }
    }
    
    static func KB(_ n:UInt) -> UInt {
        return n*1024
    }
    
    static func MB(_ n:UInt) -> UInt {
        return n*1024*1024
    }
    
    let kMaxSavBanks:UInt = 4
    let kPrgBankCount:UInt16 = 8
    let kPrgBankSize:UInt16 = UInt16(KB(4))

    let kChrBankCount:UInt16 = 8
    let kChrBankSize:UInt16 = UInt16(KB(1))

    let kSavBankCount:UInt16 = 1
    let kSavBankSize:UInt16 = UInt16(KB(8))
    
    var romHeader:RomHeader?
    var prgBanks:[Memory] = []
    var chrBanks:[Memory] = []
    var savBanks:[Memory] = []
    var mapper:Mapper = Mapper.init()
    
    var hasSRAM = false
    var cartNameTableMirroring:NameTableMirroring = .Undefined
}
