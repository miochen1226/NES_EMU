//
//  OpCodeEntry.swift
//  NES_EMU
//
//  Created by mio on 2021/8/8.
//

import Foundation


enum OpCodeEntryTtype {
    case ADC
    case AND
    case ASL
    case BCC
    case BCS
    case BEQ
    case BIT
    case BMI
    case BNE
    case BPL
    case BRK
    case BVC
    case BVS
    case CLC
    case CLD
    case CLI
    case CLV
    case CMP
    case CPX
    case CPY
    case DEC
    case DEX
    case DEY
    case EOR
    case INC
    case INX
    case INY
    case JMP
    case JSR
    case LDA
    case LDX
    case LDY
    case LSR
    case NOP
    case ORA
    case PHA
    case PHP
    case PLA
    case PLP
    case ROL
    case ROR
    case RTI
    case RTS
    case SBC
    case SEC
    case SED
    case SEI
    case STA
    case STX
    case STY
    case TAX
    case TAY
    case TSX
    case TXA
    case TXS
    case TYA
}

public enum AddressMode:UInt32 {
    case Immedt = 0x0001 // Immediate : #value
    case Implid = 0x0002 // Implied : no operand
    case Accumu = 0x0004 // Accumulator : no operand
    case Relatv = 0x0008 // Relative : $addr8 used with branch instructions
    case ZeroPg = 0x0010 // Zero Page : $addr8
    case ZPIdxX = 0x0020 // Zero Page Indexed with X : $addr8 + X
    case ZPIdxY = 0x0040 // Zero Page Indexed with Y : $addr8 + Y
    case Absolu = 0x0080 // Absolute : $addr16
    case AbIdxX = 0x0100 // Absolute Indexed with X : $addr16 + X
    case AbIdxY = 0x0200 // Absolute Indexed with Y : $addr16 + Y
    case Indrct = 0x0400 // Indirect : ($addr8) used only with JMP
    case IdxInd = 0x0800 // Indexed with X Indirect : ($addr8 + X)
    case IndIdx = 0x1000 // Indirect Indexed with Y : ($addr8) + Y
    //case MemoryValueOperand = Immedt | ZeroPg | ZPIdxX|ZPIdxY|Absolu|AbIdxX|AbIdxY|IdxInd|IndIdx
    //case JmpOrBranchOperand = Relatv|Absolu|Indrct
}

class OpCodeEntry:OpCodeDef
{
    var opCode:UInt8 = 0
    var opCodeName:OpCodeEntryTtype = .ADC
    var numBytes:UInt8 = 0
    var numCycles:UInt8 = 0
    var pageCrossCycles:UInt8 = 0 // 0 or 1
    var addrMode:AddressMode = .Immedt
    
    func initial(opCode:Int,opCodeName:OpCodeEntryTtype,numBytes:Int,numCycles:Int,pageCrossCycles:Int,addrMode:AddressMode)->OpCodeEntry
    {
        self.opCode = UInt8(opCode)
        self.opCodeName = opCodeName
        self.numBytes = UInt8(numBytes)
        self.numCycles = UInt8(numCycles)
        self.pageCrossCycles = UInt8(pageCrossCycles)
        self.addrMode = addrMode
        return self
    }
    
    func getName()->String
    {
        return String(describing: opCodeName)
    }
}
