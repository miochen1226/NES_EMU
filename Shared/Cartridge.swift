//
//  Cartridge.swift
//  NES_EMU
//
//  Created by mio on 2021/8/6.
//

import Foundation

//extension Data {
//   func hexString() -> String {
//       return self.map { String(format:"%02x", $0) }.joined()}
//}



class Cartridge:HandleCpuReadProtocol{
    
    static func KB(_ n:UInt)->UInt
    {
        return n*1024
    }
    
    static func MB(_ n:UInt)->UInt
    {
        return n*1024*1024
    }
    
    let kMaxSavBanks:UInt = 4
    let kPrgBankCount:uint16 = 8
    let kPrgBankSize:uint16 = uint16(KB(4))

    let kChrBankCount:uint16 = 8
    let kChrBankSize:uint16 = uint16(KB(1))

    let kSavBankCount:uint16 = 1
    let kSavBankSize:uint16 = uint16(KB(8))
    
    func HandleCpuRead(_ cpuAddress: uint16)->uint8 {
        if (cpuAddress >= CpuMemory.kPrgRomBase)
        {
            return AccessPrgMem(cpuAddress)
        }
        else if (cpuAddress >= CpuMemory.kSaveRamBase)
        {
            // We don't bother with SRAM chip disable
            return AccessSavMem(cpuAddress)
        }

        return 0;
    }
    
    func HandleCpuWrite(cpuAddress:UInt16, value:UInt8)
    {
        //TODO
    }
    
    func GetBankIndex(address:UInt16,baseAddress:UInt16,bankSize:UInt16)->Int
    {
        let firstBankIndex = baseAddress / bankSize
        return Int((address / bankSize) - firstBankIndex)
    }
    
    func GetBankOffset(address:UInt16,bankSize:UInt16)->UInt16
    {
        return address & (bankSize - 1)
    }
    
    var m_mapper:Mapper = Mapper.init()
    func AccessPrgMem(_ cpuAddress:uint16)->UInt8
    {
        let bankIndex = GetBankIndex(address: cpuAddress, baseAddress: CpuMemory.kPrgRomBase, bankSize: kPrgBankSize)
        let offset = GetBankOffset(address: cpuAddress, bankSize: kPrgBankSize)
        let mappedBankIndex = m_mapper.GetMappedPrgBankIndex(Int(bankIndex))
        let memory = m_prgBanks[mappedBankIndex]
        return memory.RawRef(address: Int(offset))
    }
    
    func AccessSavMem(_ cpuAddress:uint16)->UInt8
    {
        //TODO
        return 0
    }
    
    func loadFile()
    {
        loadMarioRom()
    }
    
    var romHeader:RomHeader?
    
    var m_prgBanks:[Memory] = []
    var m_chrBanks:[Memory] = []
    func loadMarioRom()
    {
        if let filepath = Bundle.main.path(forResource: "mario", ofType: "nes")
        {
            if let data = NSData(contentsOfFile: filepath)
            {
                let arrayData = [UInt8](data)
                romHeader = RomHeader.init().Initialize(bytes: arrayData)
                
                if(romHeader == nil)
                {
                    NSLog("Rom header incorrect")
                    return
                }
                
                //PRG_ROM
                let prgRomSize = romHeader!.GetPrgRomSizeBytes();
                if(prgRomSize % globeDef.kPrgBankSize != 0)
                {
                    NSLog("prgRomSize incorrect")
                    return
                }
                
                let numPrgBanks = prgRomSize / globeDef.kPrgBankSize;
                var readIndex = 16
                for _ in 0...numPrgBanks-1
                {
                    let newMemory = Memory.init().initial(size: globeDef.kPrgBankSize)
                    let beginIndex:UInt = UInt(readIndex)
                    fillMemory(srcMem: arrayData, begin: beginIndex, size: Int(globeDef.kPrgBankSize), memory: newMemory)
                    readIndex = readIndex + Int(globeDef.kPrgBankSize)
                    m_prgBanks.append(newMemory)
                }
                
                // CHR-ROM data
                let chrRomSize = romHeader!.GetChrRomSizeBytes();
                
                if(chrRomSize % globeDef.kChrBankSize != 0)
                {
                    NSLog("chrRomSize incorrect")
                    return
                }
                
                let numChrBanks = chrRomSize / globeDef.kChrBankSize;

                for _ in 0...numChrBanks-1
                {
                    let newMemory = Memory.init().initial(size: globeDef.kChrBankSize)
                    let beginIndex:UInt = UInt(readIndex)
                    
                    fillMemory(srcMem: arrayData, begin: beginIndex, size: Int(globeDef.kChrBankSize), memory: newMemory)
                    
                    readIndex = readIndex + Int(globeDef.kChrBankSize)
                    m_chrBanks.append(newMemory)
                }
                
                
                let numSavBanks = romHeader!.GetNumPrgRamBanks();
                if(numSavBanks > kMaxSavBanks)
                {
                    NSLog("numSavBanks incorrect")
                    return
                }

                /*
                switch (romHeader!.GetMapperNumber())
                {
                    case 0: m_mapperHolder.reset(new Mapper0()); break;
                    case 1: m_mapperHolder.reset(new Mapper1()); break;
                    case 2: m_mapperHolder.reset(new Mapper2()); break;
                    case 3: m_mapperHolder.reset(new Mapper3()); break;
                    case 4: m_mapperHolder.reset(new Mapper4()); break;
                    case 7: m_mapperHolder.reset(new Mapper7()); break;
                default:
                    NSLog("Unsupported mapper")
                    //FAIL("Unsupported mapper: %d", romHeader.GetMapperNumber());
                }
                */
                
                //m_mapper = m_mapperHolder.get();
                
                //Mario is Map1
                m_mapper = Mapper1()
                m_mapper.Initialize(numPrgBanks: numPrgBanks, numChrBanks: numChrBanks, numSavBanks: numSavBanks)

                m_cartNameTableMirroring = romHeader!.GetNameTableMirroring()
                m_hasSRAM = romHeader!.HasSRAM();
            }
        }
    }
    
    var m_hasSRAM = false
    var m_cartNameTableMirroring:RomHeader.NameTableMirroring = .Undefined
    
    func fillMemory( srcMem:[UInt8],begin:UInt,size:Int,memory:Memory)
    {
        var beginIndex:UInt = begin
        for index in 0...size-1
        {
            let indexInFile = Int(beginIndex)
            let rawValue = srcMem[indexInFile]
            memory.putValue(address: Int(index), value: rawValue)
            beginIndex = beginIndex + 1
        }
    }
}
