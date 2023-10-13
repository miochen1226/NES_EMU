//
//  IMapper.swift
//  NES_EMU
//
//  Created by mio on 2023/10/13.
//

import Foundation

@objc protocol IMapper {
    //General
    func Initialize(numPrgBanks: UInt8, numChrBanks: UInt8, numSavBanks: UInt8)
    
    func GetNameTableMirroring() -> NameTableMirroring
    
    func GetMappedPrgBankIndex(_ cpuBankIndex:Int) -> Int
    func GetMappedChrBankIndex(ppuBankIndex: Int) -> UInt8
    func GetMappedSavBankIndex(cpuBankIndex: Int) -> UInt8
    
    func OnCpuWrite(cpuAddress:UInt16, value:UInt8)
    func TestAndClearIrqPending() -> Bool
    func CanWritePrgMemory() -> Bool
    func CanWriteChrMemory() -> Bool
    func CanWriteSavMemory() -> Bool
    //Mapper 4
    @objc optional func hackOnScanline()
}
