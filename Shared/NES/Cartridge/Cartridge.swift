//
//  Cartridge.swift
//  NES_EMU
//
//  Created by mio on 2021/8/6.
//

import Foundation

class Cartridge:ICartridge{
    func HandlePpuRead(_ ppuAddress: uint16) -> uint8 {
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
    let kPrgBankCount:uint16 = 8
    let kPrgBankSize:uint16 = uint16(KB(4))

    let kChrBankCount:uint16 = 8
    let kChrBankSize:uint16 = uint16(KB(1))

    let kSavBankCount:uint16 = 1
    let kSavBankSize:uint16 = uint16(KB(8))
    
    func HandleCpuReadEx(_ cpuAddress: uint16,readValue:inout UInt8)
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
    
    func AccessPrgMemEx(_ cpuAddress:uint16,readValue:inout UInt8)
    {
        /*
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
         */
    }
    
    var m_mapper:Mapper = Mapper.init()
    var cache:[uint16:uint16] = [:]
    var rawCache:[uint16:uint8] = [:]
    
    let firstBankIndex_a = Int(CpuMemory.kPrgRomBase) / Int(globeDef.kPrgBankSize)
    let kPrgBankSize_1 = globeDef.kPrgBankSize
    let kPrgBankSize_2 = globeDef.kPrgBankSize*2
    let kPrgBankSize_3 = globeDef.kPrgBankSize*3
    let kPrgBankSize_4:UInt16 = UInt16(globeDef.kPrgBankSize*4)
    let kPrgBankSize_5 = globeDef.kPrgBankSize*5
    let kPrgBankSize_6 = globeDef.kPrgBankSize*6
    let kPrgBankSize_7 = globeDef.kPrgBankSize*7
    let kPrgBankSize_8 = globeDef.kPrgBankSize*8
    let kPrgBankSize_9 = globeDef.kPrgBankSize*9
    let kPrgBankSize_10 = globeDef.kPrgBankSize*10
    let kPrgBankSize_11 = globeDef.kPrgBankSize*11
    let kPrgBankSize_12 = globeDef.kPrgBankSize*12
    let kPrgBankSize_13 = globeDef.kPrgBankSize*13
    let kPrgBankSize_14 = globeDef.kPrgBankSize*14
    let kPrgBankSize_15 = globeDef.kPrgBankSize*15
    let kPrgBankSize_16 = globeDef.kPrgBankSize*16
    
    func cpuToBankIndex(_ cpuAddress_t:UInt16)->Int
    {
        if(cpuAddress_t>kPrgBankSize_16)
        {
            return 16
        }
        if(cpuAddress_t>kPrgBankSize_15)
        {
            return 15
        }
        if(cpuAddress_t>kPrgBankSize_14)
        {
            return 14
        }
        if(cpuAddress_t>kPrgBankSize_13)
        {
            return 13
        }
        if(cpuAddress_t>kPrgBankSize_12)
        {
            return 12
        }
        if(cpuAddress_t>kPrgBankSize_11)
        {
            return 11
        }
        if(cpuAddress_t>kPrgBankSize_10)
        {
            return 10
        }
        if(cpuAddress_t>kPrgBankSize_9)
        {
            return 9
        }
        else if(cpuAddress_t>kPrgBankSize_8)
        {
            return 8
        }
        else if(cpuAddress_t>kPrgBankSize_7)
        {
            return 7
        }
        else if(cpuAddress_t>kPrgBankSize_6)
        {
            return 6
        }
        else if(cpuAddress_t>kPrgBankSize_5)
        {
            return 5
        }
        else if(cpuAddress_t>kPrgBankSize_4)
        {
            return 4
        }
        else if(cpuAddress_t>kPrgBankSize_3)
        {
            return 3
        }
        else if(cpuAddress_t>kPrgBankSize_2)
        {
            return 2
        }
        else if(cpuAddress_t>kPrgBankSize_1)
        {
            return 1
        }
        else
        {
            return 0
        }
    }
    
    
    func AccessPrgMem(_ cpuAddress:uint16)->UInt8
    {
        //let valueCache = rawCache[cpuAddress]
        
        //if(valueCache != nil)
        //{
        //    return valueCache!
        //}
        //Speedup version
        /*
        if(cpuAddress == 51102)
        {
            return 120
        }
        let valueCache = rawCache[cpuAddress]
        
        if(valueCache != nil)
        {
            return valueCache!
        }
        
        if(cpuAddress == 51102)
        {
            rawCache[cpuAddress] = 120
            //return m_prgBigMemory.rawMemory[120]
            return 120
        }
        */
        /*
        if(cpuAddress == 51102)
        {
            return m_prgBigMemory.rawMemory[120]
            return 120
            for i in 0...51102
            {
                
            }
            return m_prgBigMemory.Read(1950)
        }
        */
        
        //if(cpuAddress == 51102)
        //{
        //    return m_prgBigMemory.rawMemory[120]
        //}
        
        
        /*
        let addressCache = cache[cpuAddress]
        
        if(addressCache != nil)
        {
            return m_prgBigMemory.rawMemory[Int(addressCache!)]
            //return m_prgBigMemory.Read(addressCache!)
        }*/
        
        //let bankIndex = GetBankIndex(address: cpuAddress, baseAddress: CpuMemory.kPrgRomBase, bankSize: kPrgBankSize)
        
        //let bankIndex = (Int(cpuAddress / kPrgBankSize) - firstBankIndex_a)
        //if(cpuAddress == 51102)
        //{
        //    return m_prgBigMemory.rawMemory[120]
        //}
        
        //let bankIndex2 = GetBankIndex(address: cpuAddress, baseAddress: CpuMemory.kPrgRomBase, bankSize: kPrgBankSize)
        
        
        
        //var bankIndex = cpuToBankIndex(cpuAddress)
        let bankIndex = GetBankIndex(address: cpuAddress, baseAddress: CpuMemory.kPrgRomBase, bankSize: kPrgBankSize)
        let mappedBankIndex = m_mapper.GetMappedPrgBankIndex(Int(bankIndex))
        let offset = GetBankOffset(address: cpuAddress, bankSize: kPrgBankSize)
        let memory = m_prgBanks[mappedBankIndex]
        return memory.Read(offset)
        
        //let correctAddress = UInt16(mappedBankIndex) * kPrgBankSize + offset
        /*
        if(cpuAddress == 51102)
        {
        //    return m_prgBigMemory.Read(1950)
        }
        //V1
        let base = CpuMemory.kPrgRomBase
        var correctAddress = cpuAddress - base
        correctAddress -= kPrgBankSize_4
        
        return m_prgBigMemory.Read(correctAddress)
        //cache[cpuAddress] = correctAddress
        */
        //if(correctAddress == 1950)
        //{
        //    return m_prgBigMemory.test()
        //}
        
        //let value = m_prgBigMemory.rawMemory[Int(correctAddress)]
        //rawCache[cpuAddress] = value
        //return value
        //return m_prgBigMemory.Read(correctAddress)
        
        /*
        
        //Mio speed up
        
        let bankIndexCache = cache[cpuAddress]
        
        if(bankIndexCache != nil)
        {
            let bankIndex = GetBankIndex(address: cpuAddress, baseAddress: CpuMemory.kPrgRomBase, bankSize: kPrgBankSize)
            let offset = GetBankOffset(address: cpuAddress, bankSize: kPrgBankSize)
            //let memory = m_prgBanks[bankIndexCache!]
            let mappedBankIndex = m_mapper.GetMappedPrgBankIndex(Int(bankIndex))
            let memory = m_prgBanks[mappedBankIndex]
            return memory.RawRef(address: Int(offset))
        }
        
        
        let bankIndex = GetBankIndex(address: cpuAddress, baseAddress: CpuMemory.kPrgRomBase, bankSize: kPrgBankSize)
        let offset = GetBankOffset(address: cpuAddress, bankSize: kPrgBankSize)
        let mappedBankIndex = m_mapper.GetMappedPrgBankIndex(Int(bankIndex))
        
        //Mio speed up
        cache[cpuAddress] = mappedBankIndex
        
        let memory = m_prgBanks[mappedBankIndex]
        return memory.RawRef(address: Int(offset))
        */
    }
    
    func AccessPrgMem(_ cpuAddress:uint16,value:UInt8)
    {
        let bankIndex = GetBankIndex(address: cpuAddress, baseAddress: CpuMemory.kPrgRomBase, bankSize: kPrgBankSize)
        let offset = GetBankOffset(address: cpuAddress, bankSize: kPrgBankSize)
        let mappedBankIndex = m_mapper.GetMappedPrgBankIndex(Int(bankIndex))
        let memory = m_prgBanks[mappedBankIndex]
        memory.Write(address: offset, value: value)
    }
    
    func AccessSavMem(_ cpuAddress:uint16,value:UInt8)
    {
        let bankIndex = GetBankIndex(address: cpuAddress, baseAddress: CpuMemory.kSaveRamBase, bankSize: kSavBankSize)
        let offset = GetBankOffset(address: cpuAddress, bankSize: kSavBankSize)
        let mappedBankIndex = m_mapper.GetMappedSavBankIndex(cpuBankIndex: bankIndex)
        let memory = m_savBanks[mappedBankIndex]
        memory.Write(address: offset, value: value)
        //return m_savBanks[mappedBankIndex].RawRef(offset)
        
    }
    
    func AccessSavMem(_ cpuAddress:uint16)->UInt8
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
    
    var m_prgBigMemory:Memory = Memory.init()
    var m_prgBanks:[Memory] = []
    var m_chrBanks:[Memory] = []
    var m_savBanks:[Memory] = []
    func loadMarioRom()
    {
        //Donkey Kong  mario Donkey Kong (Japan) Donkey Kong (World) (Rev A)
        if let filepath = Bundle.main.path(forResource: "Donkey Kong (Japan)", ofType: "nes")
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
                    let newMemory = Memory.init()
                    newMemory.initial(size: globeDef.kPrgBankSize)
                    let beginIndex:UInt = UInt(readIndex)
                    fillMemory(srcMem: arrayData, begin: beginIndex, size: Int(globeDef.kPrgBankSize), memory: newMemory)
                    readIndex = readIndex + Int(globeDef.kPrgBankSize)
                    m_prgBanks.append(newMemory)
                }
                
                //Fill big memory
                var bigMemSize = globeDef.kPrgBankSize * numPrgBanks
                m_prgBigMemory.initial(size: UInt(Int(globeDef.kPrgBankSize)*Int(numPrgBanks)))
                fillMemory(srcMem: arrayData, begin: UInt(16), size: Int(globeDef.kPrgBankSize*numPrgBanks), memory: m_prgBigMemory)
                
                
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
                    let newMemory = Memory.init()
                    newMemory.initial(size: globeDef.kChrBankSize)
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
                    let newMemory = Memory.init()
                    newMemory.initial(size: globeDef.kSavBankSize)
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
            memory.putValue(address: UInt16(index), value: rawValue)
            beginIndex = beginIndex + 1
        }
    }
    
    func HACK_OnScanline(){}
}
