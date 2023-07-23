//
//  Cartridge.swift
//  NES_EMU
//
//  Created by mio on 2021/8/6.
//

import Foundation

class Cartridge:ICartridge{
    func HandlePpuRead(_ ppuAddress: UInt16) -> UInt8 {
        return AccessChrMem(ppuAddress)
    }
    
    func AccessChrMem(_ ppuAddress:UInt16)->UInt8
    {
        let bankIndex:UInt = UInt(GetBankIndex(address: ppuAddress, baseAddress: PpuMemory.kChrRomBase, bankSize: kChrBankSize))
        let offset:UInt16 = GetBankOffset(address: ppuAddress, bankSize: kChrBankSize);
        let mappedBankIndex:Int = m_mapper.GetMappedChrBankIndex(ppuBankIndex: Int(bankIndex))
        return m_chrBanks[mappedBankIndex].Read(offset)
    }
    
    func HandlePpuWrite(_ ppuAddress: UInt16, value: UInt8) {
        return
    }
    
    
    static func KB(_ n:UInt)->UInt
    {
        return n*1024
    }
    
    static func MB(_ n:UInt)->UInt
    {
        return n*1024*1024
    }
    
    let kMaxSavBanks:UInt = 4
    let kPrgBankCount:UInt16 = 8
    let kPrgBankSize:UInt16 = UInt16(KB(4))

    let kChrBankCount:UInt16 = 8
    let kChrBankSize:UInt16 = UInt16(KB(1))

    let kSavBankCount:UInt16 = 1
    let kSavBankSize:UInt16 = UInt16(KB(8))
    
    func HandleCpuReadEx(_ cpuAddress: UInt16,readValue:inout UInt8)
    {
        if (cpuAddress >= CpuMemory.kPrgRomBase)
        {
            AccessPrgMemEx(cpuAddress,readValue:&readValue)
        }
        else if (cpuAddress >= CpuMemory.kSaveRamBase)
        {
            // We don't bother with SRAM chip disable
            readValue = AccessSavMem(cpuAddress)
        }
        else
        {
            readValue = 0
        }
    }
    
    func HandleCpuRead(_ cpuAddress: UInt16)->UInt8 {
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
    
    func HandleCpuWrite(_ cpuAddress:UInt16, value:UInt8)
    {
        m_mapper.OnCpuWrite(cpuAddress: cpuAddress, value: value)

        if (cpuAddress >= CpuMemory.kPrgRomBase)
        {
            if (m_mapper.CanWritePrgMemory())
            {
                AccessPrgMem(cpuAddress,value: value)
            }
        }
        else if (cpuAddress >= CpuMemory.kSaveRamBase)
        {
            if (m_mapper.CanWriteSavMemory())
            {
                AccessSavMem(cpuAddress,value: value)
            }
        }
        else
        {
            print("Unhandled by mapper - write: $%04X\n", cpuAddress)
    //#if CONFIG_DEBUG
            //if (!Debugger::IsExecuting())
             //   printf("Unhandled by mapper - write: $%04X\n", cpuAddress);
            
            
    //#endif
        }
        
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
    
    func AccessPrgMemEx(_ cpuAddress:UInt16,readValue:inout UInt8)
    {
        //Mio speed up
        let bankIndexCache = cache[cpuAddress]
        if(bankIndexCache != nil)
        {
            let offset = GetBankOffset(address: cpuAddress, bankSize: kPrgBankSize)
            let memory = m_prgBanks[bankIndexCache!]
            readValue = memory.RawRef(address: Int(offset))
        }
        
        let bankIndex = GetBankIndex(address: cpuAddress, baseAddress: CpuMemory.kPrgRomBase, bankSize: kPrgBankSize)
        let offset = GetBankOffset(address: cpuAddress, bankSize: kPrgBankSize)
        let mappedBankIndex = m_mapper.GetMappedPrgBankIndex(Int(bankIndex))
        
        //Mio speed up
        cache[cpuAddress] = mappedBankIndex
        
        let memory = m_prgBanks[mappedBankIndex]
        readValue = memory.RawRef(address: Int(offset))
    }
    
    var m_mapper:Mapper = Mapper.init()
    var cache:[UInt16:Int] = [:]
    func AccessPrgMem(_ cpuAddress:UInt16)->UInt8
    {
        //Mio speed up
        let bankIndexCache = cache[cpuAddress]
        
        if(bankIndexCache != nil)
        {
            let offset = GetBankOffset(address: cpuAddress, bankSize: kPrgBankSize)
            let memory = m_prgBanks[bankIndexCache!]
            return memory.RawRef(address: Int(offset))
        }
        
        
        let bankIndex = GetBankIndex(address: cpuAddress, baseAddress: CpuMemory.kPrgRomBase, bankSize: kPrgBankSize)
        let offset = GetBankOffset(address: cpuAddress, bankSize: kPrgBankSize)
        let mappedBankIndex = m_mapper.GetMappedPrgBankIndex(Int(bankIndex))
        
        //Mio speed up
        cache[cpuAddress] = mappedBankIndex
        
        let memory = m_prgBanks[mappedBankIndex]
        return memory.RawRef(address: Int(offset))
    }
    
    func AccessPrgMem(_ cpuAddress:UInt16,value:UInt8)
    {
        let bankIndex = GetBankIndex(address: cpuAddress, baseAddress: CpuMemory.kPrgRomBase, bankSize: kPrgBankSize)
        let offset = GetBankOffset(address: cpuAddress, bankSize: kPrgBankSize)
        let mappedBankIndex = m_mapper.GetMappedPrgBankIndex(Int(bankIndex))
        let memory = m_prgBanks[mappedBankIndex]
        memory.Write(address: offset, value: value)
    }
    
    func AccessSavMem(_ cpuAddress:UInt16,value:UInt8)
    {
        let bankIndex = GetBankIndex(address: cpuAddress, baseAddress: CpuMemory.kSaveRamBase, bankSize: kSavBankSize)
        let offset = GetBankOffset(address: cpuAddress, bankSize: kSavBankSize)
        let mappedBankIndex = m_mapper.GetMappedSavBankIndex(cpuBankIndex: bankIndex)
        let memory = m_savBanks[mappedBankIndex]
        memory.Write(address: offset, value: value)
        //return m_savBanks[mappedBankIndex].RawRef(offset)
        
    }
    
    func AccessSavMem(_ cpuAddress:UInt16)->UInt8
    {
        let bankIndex = GetBankIndex(address: cpuAddress, baseAddress: CpuMemory.kSaveRamBase, bankSize: kSavBankSize)
        let offset = GetBankOffset(address: cpuAddress, bankSize: kSavBankSize)
        let mappedBankIndex = m_mapper.GetMappedSavBankIndex(cpuBankIndex: bankIndex)
        //return m_savBanks[mappedBankIndex].RawRef(offset)
        let memory = m_savBanks[mappedBankIndex]
        return memory.Read(offset)
    }
    
    func loadFile()
    {
        loadMarioRom()
    }
    
    var romHeader:RomHeader?
    
    var m_prgBanks:[Memory] = []
    var m_chrBanks:[Memory] = []
    var m_savBanks:[Memory] = []
    func loadMarioRom()
    {
        //Donkey Kong  mario Donkey Kong (Japan) Donkey Kong (World) (Rev A)
        //if let filepath = Bundle.main.path(forResource: "Super Mario Bros. (Japan, USA)", ofType: "nes")
        //if let filepath = Bundle.main.path(forResource: "Donkey Kong (Japan)", ofType: "nes")
        
        
        //if let filepath = Bundle.main.path(forResource: "Circus Charlie (J) [p1]", ofType: "nes")
        //if let filepath = Bundle.main.path(forResource: "Ice Climber (Japan)", ofType: "nes")
        if let filepath = Bundle.main.path(forResource: "Donkey Kong Jr. (USA) (GameCube Edition)", ofType: "nes")
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
                
                for _ in 0...numSavBanks
                {
                    let newMemory = Memory.init().initial(size: globeDef.kSavBankSize)
                    m_savBanks.append(newMemory)
                }
                //kMaxSavBanks

                let mN = romHeader!.GetMapperNumber()
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
                
                if(mN == 0)
                {
                    m_mapper = Mapper0()
                    m_mapper.Initialize(numPrgBanks: numPrgBanks, numChrBanks: numChrBanks, numSavBanks: numSavBanks)
                }
                else
                {
                    //Mario is Map1
                    m_mapper = Mapper1()
                    m_mapper.Initialize(numPrgBanks: numPrgBanks, numChrBanks: numChrBanks, numSavBanks: numSavBanks)
                }
                
                m_cartNameTableMirroring = romHeader!.GetNameTableMirroring()
                m_hasSRAM = romHeader!.HasSRAM();
            }
        }
    }
    
    func GetNameTableMirroring()->RomHeader.NameTableMirroring
    {
        return m_cartNameTableMirroring
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
