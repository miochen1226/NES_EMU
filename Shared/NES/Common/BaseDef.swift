//
//  BaseDef.swift
//  NES_EMU
//
//  Created by mio on 2021/8/7.
//

import Foundation

func KB(_ n:UInt)->UInt
{
    return n*1024
}

func MB(_ n:UInt)->UInt
{
    return n*1024*1024
}

func BIT(_ n:UInt8)->UInt8
{
     return (1<<n)
}

struct globeDef
{
    static let kPrgBankCount = 8
    static let kPrgBankSize = KB(4)

    static let kChrBankCount = 8
    static let kChrBankSize = KB(1)

    static let kSavBankCount = 1
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

func BIT(_ n:Int)->UInt8
{
    return UInt8(1<<n)
}

func BIT16(_ n:Int)->UInt16
{
    return UInt16(1<<n)
}

func BITS16(_ bitsIn:[Int])->UInt16
{
    var result:UInt16 = 0
    for bit in bitsIn
    {
        let dig = 1<<bit
        result |= UInt16(dig)
    }
    return result
}

func BITS(_ bitsIn:[UInt8])->UInt8
{
    var result:UInt8 = 0
    for bit in bitsIn
    {
        let dig = 1<<bit
        result |= UInt8(dig)
    }
    return result
}

func ClearBits(target:inout UInt16, value:UInt8)
{
    target = (target & ~UInt16(value))
}

func TestBits(target:UInt8,  value:UInt8)->Bool
{
    return ReadBits8(target: target, value: value) != 0
}

func TestBits(target:UInt16,  value:UInt8)->Bool
{
    return ReadBits(target: target, value: value) != 0
}

func TestBits(target:UInt16, value:UInt16)->Bool
{
    return ReadBits(target: target, value: value) != 0
}

func ReadBits(target:UInt16, value:UInt16)->UInt16
{
    return target & value
}

func ReadBits(target:UInt16, value:UInt8)->UInt16
{
    return target & UInt16(value)
}

func ReadBits8(target:UInt8, value:UInt8)->UInt8
{
    return target & value
}

func TestBits01(target:UInt16,value:UInt8)->UInt8
{
    if(ReadBits(target: target, value: value) != 0)
    {
        return 1
    }
    else
    {
        return 0
    }
}

func TO16(_ v8:UInt8)->UInt16
{
    return UInt16(v8)
}

func TO8(_ v16:UInt16)->UInt8
{
    let v8:UInt8 = UInt8(v16 & 0x00FF)
    return v8
}


