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



class Cartridge{
    func loadFile()
    {
        NSLog("LOAD ROM")
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
                NSLog("loadMarioRom finish")
                
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
                
                NSLog("Load finish")
            }
        }
    }
    
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
