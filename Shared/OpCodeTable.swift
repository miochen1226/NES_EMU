//
// .OpCodeTable.swift
// .NES_EMU
//
// .Created.By mio.On 2021/8/9.
//

import Foundation

class OpCodeTable:OpCodeNameSpace
{
    static var opCodeTable:[[Any]] =
    [
        [ 0x69, OpCodeEntryTtype.ADC, 2, 2, 0, AddressMode.Immedt ],
        [ 0x65, OpCodeEntryTtype.ADC, 2, 3, 0, AddressMode.ZeroPg ],
        [ 0x75, OpCodeEntryTtype.ADC, 2, 4, 0, AddressMode.ZPIdxX ],
        [ 0x6D, OpCodeEntryTtype.ADC, 3, 4, 0, AddressMode.Absolu ],
        [ 0x7D, OpCodeEntryTtype.ADC, 3, 4, 1, AddressMode.AbIdxX ],
        [ 0x79, OpCodeEntryTtype.ADC, 3, 4, 1, AddressMode.AbIdxY ],
        [ 0x61, OpCodeEntryTtype.ADC, 2, 6, 0, AddressMode.IdxInd ],
        [ 0x71, OpCodeEntryTtype.ADC, 2, 5, 1, AddressMode.IndIdx ],

        [ 0x29, OpCodeEntryTtype.AND, 2, 2, 0, AddressMode.Immedt ],
        [ 0x25, OpCodeEntryTtype.AND, 2, 3, 0, AddressMode.ZeroPg ],
        [ 0x35, OpCodeEntryTtype.AND, 2, 4, 0, AddressMode.ZPIdxX ],
        [ 0x2D, OpCodeEntryTtype.AND, 3, 4, 0, AddressMode.Absolu ],
        [ 0x3D, OpCodeEntryTtype.AND, 3, 4, 1, AddressMode.AbIdxX ],
        [ 0x39, OpCodeEntryTtype.AND, 3, 4, 1, AddressMode.AbIdxY ],
        [ 0x21, OpCodeEntryTtype.AND, 2, 6, 0, AddressMode.IdxInd ],
        [ 0x31, OpCodeEntryTtype.AND, 2, 5, 1, AddressMode.IndIdx ],

        [ 0x0A, OpCodeEntryTtype.ASL, 1, 2, 0, AddressMode.Accumu ],
        [ 0x06, OpCodeEntryTtype.ASL, 2, 5, 0, AddressMode.ZeroPg ],
        [ 0x16, OpCodeEntryTtype.ASL, 2, 6, 0, AddressMode.ZPIdxX ],
        [ 0x0E, OpCodeEntryTtype.ASL, 3, 6, 0, AddressMode.Absolu ],
        [ 0x1E, OpCodeEntryTtype.ASL, 3, 7, 0, AddressMode.AbIdxX ],

        [ 0x90, OpCodeEntryTtype.BCC, 2, 2, 0, AddressMode.Relatv ],
        [ 0xB0, OpCodeEntryTtype.BCS, 2, 2, 0, AddressMode.Relatv ],
        [ 0xF0, OpCodeEntryTtype.BEQ, 2, 2, 0, AddressMode.Relatv ],
        [ 0x24, OpCodeEntryTtype.BIT, 2, 3, 0, AddressMode.ZeroPg ],
        [ 0x2C, OpCodeEntryTtype.BIT, 3, 4, 0, AddressMode.Absolu ],
        [ 0x30, OpCodeEntryTtype.BMI, 2, 2, 0, AddressMode.Relatv ],
        [ 0xD0, OpCodeEntryTtype.BNE, 2, 2, 0, AddressMode.Relatv ],
        [ 0x10, OpCodeEntryTtype.BPL, 2, 2, 0, AddressMode.Relatv ],
        [ 0x00, OpCodeEntryTtype.BRK, 1, 7, 0, AddressMode.Implid ],
        [ 0x50, OpCodeEntryTtype.BVC, 2, 2, 0, AddressMode.Relatv ],
        [ 0x70, OpCodeEntryTtype.BVS, 2, 2, 0, AddressMode.Relatv ],

        [ 0x18, OpCodeEntryTtype.CLC, 1, 2, 0, AddressMode.Implid ],
        [ 0xD8, OpCodeEntryTtype.CLD, 1, 2, 0, AddressMode.Implid ],
        [ 0x58, OpCodeEntryTtype.CLI, 1, 2, 0, AddressMode.Implid ],
        [ 0xB8, OpCodeEntryTtype.CLV, 1, 2, 0, AddressMode.Implid ],

        [ 0xC9, OpCodeEntryTtype.CMP, 2, 2, 0, AddressMode.Immedt ],
        [ 0xC5, OpCodeEntryTtype.CMP, 2, 3, 0, AddressMode.ZeroPg ],
        [ 0xD5, OpCodeEntryTtype.CMP, 2, 4, 0, AddressMode.ZPIdxX ],
        [ 0xCD, OpCodeEntryTtype.CMP, 3, 4, 0, AddressMode.Absolu ],
        [ 0xDD, OpCodeEntryTtype.CMP, 3, 4, 1, AddressMode.AbIdxX ],
        [ 0xD9, OpCodeEntryTtype.CMP, 3, 4, 1, AddressMode.AbIdxY ],
        [ 0xC1, OpCodeEntryTtype.CMP, 2, 6, 0, AddressMode.IdxInd ],
        [ 0xD1, OpCodeEntryTtype.CMP, 2, 5, 1, AddressMode.IndIdx ],

        [ 0xE0, OpCodeEntryTtype.CPX, 2, 2, 0, AddressMode.Immedt ],
        [ 0xE4, OpCodeEntryTtype.CPX, 2, 3, 0, AddressMode.ZeroPg ],
        [ 0xEC, OpCodeEntryTtype.CPX, 3, 4, 0, AddressMode.Absolu ],

        [ 0xC0, OpCodeEntryTtype.CPY, 2, 2, 0, AddressMode.Immedt ],
        [ 0xC4, OpCodeEntryTtype.CPY, 2, 3, 0, AddressMode.ZeroPg ],
        [ 0xCC, OpCodeEntryTtype.CPY, 3, 4, 0, AddressMode.Absolu ],

        [ 0xC6, OpCodeEntryTtype.DEC, 2, 5, 0, AddressMode.ZeroPg ],
        [ 0xD6, OpCodeEntryTtype.DEC, 2, 6, 0, AddressMode.ZPIdxX ],
        [ 0xCE, OpCodeEntryTtype.DEC, 3, 6, 0, AddressMode.Absolu ],
        [ 0xDE, OpCodeEntryTtype.DEC, 3, 7, 0, AddressMode.AbIdxX ],

        [ 0xCA, OpCodeEntryTtype.DEC, 1, 2, 0, AddressMode.Implid ],

        [ 0x88, OpCodeEntryTtype.DEY, 1, 2, 0, AddressMode.Implid ],

        [ 0x49, OpCodeEntryTtype.EOR, 2, 2, 0, AddressMode.Immedt ],
        [ 0x45, OpCodeEntryTtype.EOR, 2, 3, 0, AddressMode.ZeroPg ],
        [ 0x55, OpCodeEntryTtype.EOR, 2, 4, 0, AddressMode.ZPIdxX ],
        [ 0x4D, OpCodeEntryTtype.EOR, 3, 4, 0, AddressMode.Absolu ],
        [ 0x5D, OpCodeEntryTtype.EOR, 3, 4, 1, AddressMode.AbIdxX ],
        [ 0x59, OpCodeEntryTtype.EOR, 3, 4, 1, AddressMode.AbIdxY ],
        [ 0x41, OpCodeEntryTtype.EOR, 2, 6, 0, AddressMode.IdxInd ],
        [ 0x51, OpCodeEntryTtype.EOR, 2, 5, 1, AddressMode.IndIdx ],

        [ 0xE6, OpCodeEntryTtype.INC, 2, 5, 0, AddressMode.ZeroPg ],
        [ 0xF6, OpCodeEntryTtype.INC, 2, 6, 0, AddressMode.ZPIdxX ],
        [ 0xEE, OpCodeEntryTtype.INC, 3, 6, 0, AddressMode.Absolu ],
        [ 0xFE, OpCodeEntryTtype.INC, 3, 7, 0, AddressMode.AbIdxX ],

        [ 0xE8, OpCodeEntryTtype.INX, 1, 2, 0, AddressMode.Implid ],
        [ 0xC8, OpCodeEntryTtype.INY, 1, 2, 0, AddressMode.Implid ],

        [ 0x4C, OpCodeEntryTtype.JMP, 3, 3, 0, AddressMode.Absolu ],
        [ 0x6C, OpCodeEntryTtype.JMP, 3, 5, 0, AddressMode.Indrct ],
        [ 0x20, OpCodeEntryTtype.JSR, 3, 6, 0, AddressMode.Absolu ],

        [ 0xA9, OpCodeEntryTtype.LDA, 2, 2, 0, AddressMode.Immedt ],
        [ 0xA5, OpCodeEntryTtype.LDA, 2, 3, 0, AddressMode.ZeroPg ],
        [ 0xB5, OpCodeEntryTtype.LDA, 2, 4, 0, AddressMode.ZPIdxX ],
        [ 0xAD, OpCodeEntryTtype.LDA, 3, 4, 0, AddressMode.Absolu ],
        [ 0xBD, OpCodeEntryTtype.LDA, 3, 4, 1, AddressMode.AbIdxX ],
        [ 0xB9, OpCodeEntryTtype.LDA, 3, 4, 1, AddressMode.AbIdxY ],
        [ 0xA1, OpCodeEntryTtype.LDA, 2, 6, 0, AddressMode.IdxInd ],
        [ 0xB1, OpCodeEntryTtype.LDA, 2, 5, 1, AddressMode.IndIdx ],

        [ 0xA2, OpCodeEntryTtype.LDX, 2, 2, 0, AddressMode.Immedt ],
        [ 0xA6, OpCodeEntryTtype.LDX, 2, 3, 0, AddressMode.ZeroPg ],
        [ 0xB6, OpCodeEntryTtype.LDX, 2, 4, 0, AddressMode.ZPIdxY ],
        [ 0xAE, OpCodeEntryTtype.LDX, 3, 4, 0, AddressMode.Absolu ],
        [ 0xBE, OpCodeEntryTtype.LDX, 3, 4, 1, AddressMode.AbIdxY ],

        [ 0xA0, OpCodeEntryTtype.LDY, 2, 2, 0, AddressMode.Immedt ],
        [ 0xA4, OpCodeEntryTtype.LDY, 2, 3, 0, AddressMode.ZeroPg ],
        [ 0xB4, OpCodeEntryTtype.LDY, 2, 4, 0, AddressMode.ZPIdxX ],
        [ 0xAC, OpCodeEntryTtype.LDY, 3, 4, 0, AddressMode.Absolu ],
        [ 0xBC, OpCodeEntryTtype.LDY, 3, 4, 1, AddressMode.AbIdxX ],

        [ 0x4A, OpCodeEntryTtype.LSR, 1, 2, 0, AddressMode.Accumu ],
        [ 0x46, OpCodeEntryTtype.LSR, 2, 5, 0, AddressMode.ZeroPg ],
        [ 0x56, OpCodeEntryTtype.LSR, 2, 6, 0, AddressMode.ZPIdxX ],
        [ 0x4E, OpCodeEntryTtype.LSR, 3, 6, 0, AddressMode.Absolu ],
        [ 0x5E, OpCodeEntryTtype.LSR, 3, 7, 0, AddressMode.AbIdxX ],

        [ 0xEA, OpCodeEntryTtype.NOP, 1, 2, 0, AddressMode.Implid ],

        [ 0x09, OpCodeEntryTtype.ORA, 2, 2, 0, AddressMode.Immedt ],
        [ 0x05, OpCodeEntryTtype.ORA, 2, 3, 0, AddressMode.ZeroPg ],
        [ 0x15, OpCodeEntryTtype.ORA, 2, 4, 0, AddressMode.ZPIdxX ],
        [ 0x0D, OpCodeEntryTtype.ORA, 3, 4, 0, AddressMode.Absolu ],
        [ 0x1D, OpCodeEntryTtype.ORA, 3, 4, 1, AddressMode.AbIdxX ],
        [ 0x19, OpCodeEntryTtype.ORA, 3, 4, 1, AddressMode.AbIdxY ],
        [ 0x01, OpCodeEntryTtype.ORA, 2, 6, 0, AddressMode.IdxInd ],
        [ 0x11, OpCodeEntryTtype.ORA, 2, 5, 1, AddressMode.IndIdx ],

        [ 0x48, OpCodeEntryTtype.PHA, 1, 3, 0, AddressMode.Implid ],
        [ 0x08, OpCodeEntryTtype.PHP, 1, 3, 0, AddressMode.Implid ],
        [ 0x68, OpCodeEntryTtype.PLA, 1, 4, 0, AddressMode.Implid ],
        [ 0x28, OpCodeEntryTtype.PLP, 1, 4, 0, AddressMode.Implid ],

        [ 0x2A, OpCodeEntryTtype.ROL, 1, 2, 0, AddressMode.Accumu ],
        [ 0x26, OpCodeEntryTtype.ROL, 2, 5, 0, AddressMode.ZeroPg ],
        [ 0x36, OpCodeEntryTtype.ROL, 2, 6, 0, AddressMode.ZPIdxX ],
        [ 0x2E, OpCodeEntryTtype.ROL, 3, 6, 0, AddressMode.Absolu ],
        [ 0x3E, OpCodeEntryTtype.ROL, 3, 7, 0, AddressMode.AbIdxX ],

        [ 0x6A, OpCodeEntryTtype.ROR, 1, 2, 0, AddressMode.Accumu ],
        [ 0x66, OpCodeEntryTtype.ROR, 2, 5, 0, AddressMode.ZeroPg ],
        [ 0x76, OpCodeEntryTtype.ROR, 2, 6, 0, AddressMode.ZPIdxX ],
        [ 0x6E, OpCodeEntryTtype.ROR, 3, 6, 0, AddressMode.Absolu ],
        [ 0x7E, OpCodeEntryTtype.ROR, 3, 7, 0, AddressMode.AbIdxX ],

        [ 0x40, OpCodeEntryTtype.RTI, 1, 6, 0, AddressMode.Implid ],
        [ 0x60, OpCodeEntryTtype.RTS, 1, 6, 0, AddressMode.Implid ],

        [ 0xE9, OpCodeEntryTtype.SBC, 2, 2, 0, AddressMode.Immedt ],
        [ 0xE5, OpCodeEntryTtype.SBC, 2, 3, 0, AddressMode.ZeroPg ],
        [ 0xF5, OpCodeEntryTtype.SBC, 2, 4, 0, AddressMode.ZPIdxX ],
        [ 0xED, OpCodeEntryTtype.SBC, 3, 4, 0, AddressMode.Absolu ],
        [ 0xFD, OpCodeEntryTtype.SBC, 3, 4, 1, AddressMode.AbIdxX ],
        [ 0xF9, OpCodeEntryTtype.SBC, 3, 4, 1, AddressMode.AbIdxY ],
        [ 0xE1, OpCodeEntryTtype.SBC, 2, 6, 0, AddressMode.IdxInd ],
        [ 0xF1, OpCodeEntryTtype.SBC, 2, 5, 1, AddressMode.IndIdx ],

        [ 0x38, OpCodeEntryTtype.SEC, 1, 2, 0, AddressMode.Implid ],
        [ 0xF8, OpCodeEntryTtype.SED, 1, 2, 0, AddressMode.Implid ],
        [ 0x78, OpCodeEntryTtype.SEI, 1, 2, 0, AddressMode.Implid ],

        [ 0x85, OpCodeEntryTtype.STA, 2, 3, 0, AddressMode.ZeroPg ],
        [ 0x95, OpCodeEntryTtype.STA, 2, 4, 0, AddressMode.ZPIdxX ],
        [ 0x8D, OpCodeEntryTtype.STA, 3, 4, 0, AddressMode.Absolu ],
        [ 0x9D, OpCodeEntryTtype.STA, 3, 5, 0, AddressMode.AbIdxX ],
        [ 0x99, OpCodeEntryTtype.STA, 3, 5, 0, AddressMode.AbIdxY ],
        [ 0x81, OpCodeEntryTtype.STA, 2, 6, 0, AddressMode.IdxInd ],
        [ 0x91, OpCodeEntryTtype.STA, 2, 6, 0, AddressMode.IndIdx ],

        [ 0x86, OpCodeEntryTtype.STX, 2, 3, 0, AddressMode.ZeroPg ],
        [ 0x96, OpCodeEntryTtype.STX, 2, 4, 0, AddressMode.ZPIdxY ],
        [ 0x8E, OpCodeEntryTtype.STX, 3, 4, 0, AddressMode.Absolu ],

        [ 0x84, OpCodeEntryTtype.STY, 2, 3, 0, AddressMode.ZeroPg ],
        [ 0x94, OpCodeEntryTtype.STY, 2, 4, 0, AddressMode.ZPIdxX ],
        [ 0x8C, OpCodeEntryTtype.STY, 3, 4, 0, AddressMode.Absolu ],

        [ 0xAA, OpCodeEntryTtype.TAX, 1, 2, 0, AddressMode.Implid ],
        [ 0xA8, OpCodeEntryTtype.TAY, 1, 2, 0, AddressMode.Implid ],
        [ 0xBA, OpCodeEntryTtype.TSX, 1, 2, 0, AddressMode.Implid ],
        [ 0x8A, OpCodeEntryTtype.TXA, 1, 2, 0, AddressMode.Implid ],
        [ 0x9A, OpCodeEntryTtype.TXS, 1, 2, 0, AddressMode.Implid ],
        [ 0x98, OpCodeEntryTtype.TYA, 1, 2, 0, AddressMode.Implid ]
    ]
    
    static func GetOpCodeTable()->[OpCodeEntry]
    {
        var array:[OpCodeEntry] = []
        for obj in opCodeTable
        {
           let opCode = obj[0] as! Int
           let opCodeName = obj[1] as! OpCodeEntryTtype
           let numBytes = obj[2] as! Int
           let numCycles = obj[3] as! Int
           let pageCrossCycles = obj[4] as! Int
           let addrMode = obj[5] as! AddressMode
            
           let opCodeEntry = OpCodeEntry.init().initial(opCode:opCode,  opCodeName:opCodeName,  numBytes:numBytes,  numCycles:numCycles,  pageCrossCycles:pageCrossCycles,  addrMode:addrMode)
           array.append(opCodeEntry)
            
        }
        return array
    }
}

