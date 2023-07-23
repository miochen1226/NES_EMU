//
//  BaseDef.swift
//  NES_EMU
//
//  Created by mio on 2021/8/7.
//

import Foundation

struct globeDef
{
    static func KB(_ n:UInt)->UInt
    {
        return n*1024
    }
    
    static func MB(_ n:UInt)->UInt
    {
        return n*1024*1024
    }
    
    static let kPrgBankCount = 8;
    static let kPrgBankSize = KB(4)

    static let kChrBankCount = 8;
    static let kChrBankSize = KB(1)

    static let kSavBankCount = 1;
    static let kSavBankSize = KB(8)
}

protocol HandleCpuReadProtocol {
    func HandleCpuRead(_ cpuAddress:UInt16)->UInt8
    func HandleCpuWrite(_ cpuAddress:UInt16, value:UInt8)
}

protocol HandlePpuReadProtocol {
    func HandlePpuRead(_ ppuAddress:UInt16)->UInt8
    func HandlePpuWrite(_ ppuAddress:UInt16, value:UInt8)
}