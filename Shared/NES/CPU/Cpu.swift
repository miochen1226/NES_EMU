//
//  Cpu.swift
//  NES_EMU
//
//  Created by mio on 2021/8/8.
//

import Foundation
class Cpu:CpuStatusFlag,ICpu{
    
    var input:UInt8 = 0
    var lastInput:UInt8 = 0
    var pushTime = 0
    var inputIndex:UInt8 = 0
    func HandleCpuRead(_ cpuAddress: uint16) -> uint8 {
        var result:UInt8 = 0;
        switch (cpuAddress)
        {
        case CpuMemory.kSpriteDmaReg: // $4014
            result = m_spriteDmaRegister;
            break

        case CpuMemory.kControllerPort1: // $4016
            //NSLog("TODOOOO")
            inputIndex += 1
            
            if(inputIndex > 8)
            {
                inputIndex = 1
            }
            if(inputIndex == 10)
            {
                if(pushTime>1)
                {
                    if(lastInput == 0)
                    {
                        lastInput = 1
                    }
                    else
                    {
                        lastInput = 0
                    }
                    pushTime  = 0
                }
                pushTime += 1
                return lastInput
            }
            else
            {
                input = 0
            }
            return input
            break
        case CpuMemory.kControllerPort2: // $4017
            //NSLog("TODOOOO")
            //result = m_controllerPorts.HandleCpuRead(cpuAddress);
            //Irq()
            return 0
            break

        default:
            print(cpuAddress)
            //NSLog("TODOOOO m_apu->HandleCpuRead")
            //result = m_apu->HandleCpuRead(cpuAddress);
            break
        }
        
        return result
    }
    
    func SpriteDmaTransfer(_ cpuAddress:UInt16)
    {
        for i in 0...255
        {
            let value:UInt8 = m_cpuMemoryBus!.Read(cpuAddress + UInt16(i))
            m_cpuMemoryBus!.Write(cpuAddress: CpuMemory.kPpuSprRamIoReg, value: value);
        }
        //mio.
        //m_cycles += m_cycles % 2 == 0 ? 513 : 514
        
        m_cycles += 514
    }
    
    var m_spriteDmaRegister:UInt8 = 0
    func HandleCpuWrite(_ cpuAddress:UInt16, value:UInt8)
    {
        switch (cpuAddress)
        {
        case CpuMemory.kSpriteDmaReg: // $4014
            
            // Initiate a DMA transfer from the input page to sprite ram.
            m_spriteDmaRegister = value
            let spriteDmaRegister = TO16(m_spriteDmaRegister)
            let srcCpuAddress:UInt16 = spriteDmaRegister * 0x100

            // Note: we perform the full DMA transfer right here instead of emulating the transfers over multiple frames.
            // If we need to do it right, see http://wiki.nesdev.com/w/index.php/PPU_programmer_reference#DMA
            SpriteDmaTransfer(srcCpuAddress)
            break

        case CpuMemory.kControllerPort1: // $4016
            //NSLog("write kControllerPort1")
            //m_controllerPorts.HandleCpuWrite(cpuAddress, value);
            break;

        case CpuMemory.kControllerPort2: // $4017 For writes, this address is mapped to the APU!
            //NSLog("write kControllerPort2")
            break
        default:
            //NSLog("write m_apu")
            //NSLog("TODOOOO m_apu->HandleCpuWrite(cpuAddress, value);")
            //m_apu->HandleCpuWrite(cpuAddress, value);
            break;
        }
    }
    
    var m_cpuMemoryBus:CpuMemoryBus?
    func Initialize(cpuMemoryBus:CpuMemoryBus)
    {
        m_cpuMemoryBus = cpuMemoryBus
        
        
        NSLog("===OpTables===")
        OpCodeTable.ValidateOpCodeTable()
        let array = OpCodeTable.GetOpCodeTable()
        for item in array
        {
            NSLog(item.getName())
            g_opCodeTable[item.opCode] = item
            //_opCodeTableEx[item.opCode] = item
            
            //g_opCodeTableEx = NSDictionary.init()
        }
        
        NSLog("===OpTables end===")
    }
    
    
    var m_cycles:uint32 = 0
    var m_totalCycles:uint32 = 0
    var m_opCodeEntry:OpCodeEntry!
    
    var g_opCodeTableEx: NSDictionary = [0:1,1:2,2:3]
    
    var g_opCodeTable:[uint8:OpCodeEntry] = [:]
    var array:[UInt8] = [1,2,3,4,5,6,7,8,9,0,1,2,3,4]
    let isDev = true
    
    func getOpCodeEntryTtype(_ opCode:UInt8)->OpCodeEntryTtype
    {
        switch opCode
        {
            case 0x69:
                return OpCodeEntryTtype.ADC
            case 0x65:
                return OpCodeEntryTtype.ADC
            case 0x75:
                return OpCodeEntryTtype.ADC
            case 0x6D:
                return OpCodeEntryTtype.ADC
            case 0x7D:
                return OpCodeEntryTtype.ADC
            case 0x79:
                return OpCodeEntryTtype.ADC
            case 0x61:
                return OpCodeEntryTtype.ADC
            case 0x71:
                return OpCodeEntryTtype.ADC
            case 0x29:
                return OpCodeEntryTtype.AND
            case 0x25:
                return OpCodeEntryTtype.AND
            case 0x35:
                return OpCodeEntryTtype.AND
            case 0x2D:
                return OpCodeEntryTtype.AND
            case 0x3D:
                return OpCodeEntryTtype.AND
            case 0x39:
                return OpCodeEntryTtype.AND
        
        
            case 0x21:return OpCodeEntryTtype.AND
            case 0x31:return OpCodeEntryTtype.AND

            case 0x0A:return OpCodeEntryTtype.ASL
            case 0x06:return OpCodeEntryTtype.ASL
            case 0x16:return OpCodeEntryTtype.ASL
            case 0x0E:return OpCodeEntryTtype.ASL
            case 0x1E:return OpCodeEntryTtype.ASL

            case 0x90:return OpCodeEntryTtype.BCC
            case 0xB0:return OpCodeEntryTtype.BCS
            case 0xF0:return OpCodeEntryTtype.BEQ
            case 0x24:return OpCodeEntryTtype.BIT
            case 0x2C:return OpCodeEntryTtype.BIT
            case 0x30:return OpCodeEntryTtype.BMI
            case 0xD0:return OpCodeEntryTtype.BNE
            case 0x10:return OpCodeEntryTtype.BPL
            case 0x00:return OpCodeEntryTtype.BRK
            case 0x50:return OpCodeEntryTtype.BVC
            case 0x70:return OpCodeEntryTtype.BVS

            case 0x18:return OpCodeEntryTtype.CLC
            case 0xD8:return OpCodeEntryTtype.CLD
            case 0x58:return OpCodeEntryTtype.CLI
            case 0xB8:return OpCodeEntryTtype.CLV

            case 0xC9:return OpCodeEntryTtype.CMP
            case 0xC5:return OpCodeEntryTtype.CMP
            case 0xD5:return OpCodeEntryTtype.CMP
            case 0xCD:return OpCodeEntryTtype.CMP
            case 0xDD:return OpCodeEntryTtype.CMP
            case 0xD9:return OpCodeEntryTtype.CMP
            case 0xC1:return OpCodeEntryTtype.CMP
            case 0xD1:return OpCodeEntryTtype.CMP

            case 0xE0:return OpCodeEntryTtype.CPX
            case 0xE4:return OpCodeEntryTtype.CPX
            case 0xEC:return OpCodeEntryTtype.CPX

            case 0xC0:return OpCodeEntryTtype.CPY
            case 0xC4:return OpCodeEntryTtype.CPY
            case 0xCC:return OpCodeEntryTtype.CPY

            case 0xC6:return OpCodeEntryTtype.DEC
            case 0xD6:return OpCodeEntryTtype.DEC
            case 0xCE:return OpCodeEntryTtype.DEC
            case 0xDE:return OpCodeEntryTtype.DEC

            case 0xCA:return OpCodeEntryTtype.DEX

            case 0x88:return OpCodeEntryTtype.DEY

            case 0x49:return OpCodeEntryTtype.EOR
            case 0x45:return OpCodeEntryTtype.EOR
            case 0x55:return OpCodeEntryTtype.EOR
            case 0x4D:return OpCodeEntryTtype.EOR
            case 0x5D:return OpCodeEntryTtype.EOR
            case 0x59:return OpCodeEntryTtype.EOR
            case 0x41:return OpCodeEntryTtype.EOR
            case 0x51:return OpCodeEntryTtype.EOR

            case 0xE6:return OpCodeEntryTtype.INC
            case 0xF6:return OpCodeEntryTtype.INC
            case 0xEE:return OpCodeEntryTtype.INC
            case 0xFE:return OpCodeEntryTtype.INC

            case 0xE8:return OpCodeEntryTtype.INX
            case 0xC8:return OpCodeEntryTtype.INY

            case 0x4C:return OpCodeEntryTtype.JMP
            case 0x6C:return OpCodeEntryTtype.JMP
            case 0x20:return OpCodeEntryTtype.JSR

            case 0xA9:return OpCodeEntryTtype.LDA
            case 0xA5:return OpCodeEntryTtype.LDA
            case 0xB5:return OpCodeEntryTtype.LDA
            case 0xAD:return OpCodeEntryTtype.LDA
            case 0xBD:return OpCodeEntryTtype.LDA
            case 0xB9:return OpCodeEntryTtype.LDA
            case 0xA1:return OpCodeEntryTtype.LDA
            case 0xB1:return OpCodeEntryTtype.LDA

            case 0xA2:return OpCodeEntryTtype.LDX
            case 0xA6:return OpCodeEntryTtype.LDX
            case 0xB6:return OpCodeEntryTtype.LDX
            case 0xAE:return OpCodeEntryTtype.LDX
            case 0xBE:return OpCodeEntryTtype.LDX

            case 0xA0:return OpCodeEntryTtype.LDY
            case 0xA4:return OpCodeEntryTtype.LDY
            case 0xB4:return OpCodeEntryTtype.LDY
            case 0xAC:return OpCodeEntryTtype.LDY
            case 0xBC:return OpCodeEntryTtype.LDY

            case 0x4A:return OpCodeEntryTtype.LSR
            case 0x46:return OpCodeEntryTtype.LSR
            case 0x56:return OpCodeEntryTtype.LSR
            case 0x4E:return OpCodeEntryTtype.LSR
            case 0x5E:return OpCodeEntryTtype.LSR

            case 0xEA:return OpCodeEntryTtype.NOP

            case 0x09:return OpCodeEntryTtype.ORA
            case 0x05:return OpCodeEntryTtype.ORA
            case 0x15:return OpCodeEntryTtype.ORA
            case 0x0D:return OpCodeEntryTtype.ORA
            case 0x1D:return OpCodeEntryTtype.ORA
            case 0x19:return OpCodeEntryTtype.ORA
            case 0x01:return OpCodeEntryTtype.ORA
            case 0x11:return OpCodeEntryTtype.ORA

            case 0x48:return OpCodeEntryTtype.PHA
            case 0x08:return OpCodeEntryTtype.PHP
            case 0x68:return OpCodeEntryTtype.PLA
            case 0x28:return OpCodeEntryTtype.PLP

            case 0x2A:return OpCodeEntryTtype.ROL
            case 0x26:return OpCodeEntryTtype.ROL
            case 0x36:return OpCodeEntryTtype.ROL
            case 0x2E:return OpCodeEntryTtype.ROL
            case 0x3E:return OpCodeEntryTtype.ROL

            case 0x6A:return OpCodeEntryTtype.ROR
            case 0x66:return OpCodeEntryTtype.ROR
            case 0x76:return OpCodeEntryTtype.ROR
            case 0x6E:return OpCodeEntryTtype.ROR
            case 0x7E:return OpCodeEntryTtype.ROR

            case 0x40:return OpCodeEntryTtype.RTI
            case 0x60:return OpCodeEntryTtype.RTS

            case 0xE9:return OpCodeEntryTtype.SBC
            case 0xE5:return OpCodeEntryTtype.SBC
            case 0xF5:return OpCodeEntryTtype.SBC
            case 0xED:return OpCodeEntryTtype.SBC
            case 0xFD:return OpCodeEntryTtype.SBC
            case 0xF9:return OpCodeEntryTtype.SBC
            case 0xE1:return OpCodeEntryTtype.SBC
            case 0xF1:return OpCodeEntryTtype.SBC

            case 0x38:return OpCodeEntryTtype.SEC
            case 0xF8:return OpCodeEntryTtype.SED
            case 0x78:return OpCodeEntryTtype.SEI

            case 0x85:return OpCodeEntryTtype.STA
            case 0x95:return OpCodeEntryTtype.STA
            case 0x8D:return OpCodeEntryTtype.STA
            case 0x9D:return OpCodeEntryTtype.STA
            case 0x99:return OpCodeEntryTtype.STA
            case 0x81:return OpCodeEntryTtype.STA
            case 0x91:return OpCodeEntryTtype.STA

            case 0x86:return OpCodeEntryTtype.STX
            case 0x96:return OpCodeEntryTtype.STX
            case 0x8E:return OpCodeEntryTtype.STX

            case 0x84:return OpCodeEntryTtype.STY
            case 0x94:return OpCodeEntryTtype.STY
            case 0x8C:return OpCodeEntryTtype.STY

            case 0xAA:return OpCodeEntryTtype.TAX
            case 0xA8:return OpCodeEntryTtype.TAY
            case 0xBA:return OpCodeEntryTtype.TSX
            case 0x8A:return OpCodeEntryTtype.TXA
            case 0x9A:return OpCodeEntryTtype.TXS
            case 0x98:
        return OpCodeEntryTtype.TYA
        default:
            return OpCodeEntryTtype.TYA
        }
    
    }
    
    var _pCodeEntry = OpCodeEntry()
    
    @inline(__always) func Execute(_ cpuCyclesElapsed:inout uint32)
    {
        m_cycles = 0
        ExecutePendingInterrupts()// Handle when interrupts are called "between" CPU updates (e.g. PPU sends NMI)
        
        let opCode:uint8 = Read8(PC)
        m_opCodeEntry = g_opCodeTable[opCode]

       // m_cycles = 2
        UpdateOperandAddress()

        ExecuteInstruction()
        
        ExecutePendingInterrupts() // Handle when instruction (memory read) causes interrupt
    
        cpuCyclesElapsed = m_cycles
    }
    
    func ExecutePendingInterrupts()
    {
        let kInterruptCycles = 7

        if (m_pendingNmi)
        {
            Push16(PC)
            PushProcessorStatus(false)
            P.Clear(BrkExecuted)
            P.Set(IrqDisabled)
            PC = Read16(CpuMemory.kNmiVector)
            
            //@HACK: *2 here fixes Battletoads not loading levels, and also Marble Madness
            // not rendering start of level text box correctly. This is likely due to discrepencies
            // in cycle timing for when PPU signals an NMI and CPU handles it.
            m_cycles = m_cycles + UInt32((kInterruptCycles * 2))
            
            m_pendingNmi = false
        }
        else if (m_pendingIrq)
        {
            Push16(PC);
            PushProcessorStatus(false)
            P.Clear(BrkExecuted)
            P.Set(IrqDisabled)
            PC = Read16(CpuMemory.kIrqVector)
            m_cycles += UInt32(kInterruptCycles)
            m_pendingIrq = false
        }
    }
    
    @inline(__always) func Read8(_ address:uint16)->uint8
    {
        return m_cpuMemoryBus!.Read(address)
    }
    
    func GetPageAddress(_ address:UInt16)->UInt16
    {
        return (address & 0xFF00)
    }
    
    var m_operandAddress:UInt16 = 0
    var m_operandReadCrossedPage = false
    func UpdateOperandAddress()
    {
        m_operandReadCrossedPage = false

        switch (m_opCodeEntry!.addrMode)
        {
        case AddressMode.Immedt:
            m_operandAddress = PC + 1 // Set to address of immediate value in code segment
            break

        case AddressMode.Implid:
            break

        case AddressMode.Accumu:
            break

        case AddressMode.Relatv: // For conditional branch instructions
            let offsetSigned = ToInt(Read8(PC+1))
            
            //let k = abs(-128)
            //let i = UInt16(k)
            
            if(offsetSigned<0)
            {
                let offsetAbs:UInt16 = UInt16(offsetSigned * -1)
                m_operandAddress = PC + UInt16(m_opCodeEntry!.numBytes) - offsetAbs
            }
            else
            {
                let offsetAbs:UInt16 = UInt16(offsetSigned)
                m_operandAddress = PC + UInt16(m_opCodeEntry!.numBytes) + offsetAbs
            }
            
            //Origin code
            //const int8 offset = Read8(PC+1); // Signed offset in [-128,127]
            //m_operandAddress = PC + m_opCodeEntry->numBytes + offset;
            //Origin code end
            
            break

        case AddressMode.ZeroPg:
            m_operandAddress = TO16(Read8(PC+1))
            break

        case AddressMode.ZPIdxX:
            m_operandAddress = TO16((Read8(PC+1) + X)) & 0x00FF // Wrap around zero-page boundary
            break

        case AddressMode.ZPIdxY:
            m_operandAddress = TO16((Read8(PC+1) + Y)) & 0x00FF // Wrap around zero-page boundary
            break

        case AddressMode.Absolu:
            m_operandAddress = Read16(PC+1)
            break

        case AddressMode.AbIdxX:
            
            let baseAddress = Read16(PC+1)
            let basePage = GetPageAddress(baseAddress)
            m_operandAddress = baseAddress + UInt16(X)
            m_operandReadCrossedPage = basePage != GetPageAddress(m_operandAddress)
            break

        case AddressMode.AbIdxY:
            let baseAddress = Read16(PC+1)
            let basePage = GetPageAddress(baseAddress)
            m_operandAddress = baseAddress + UInt16(Y)
            m_operandReadCrossedPage = basePage != GetPageAddress(m_operandAddress)
            break

        case AddressMode.Indrct: // for JMP only
            let low = Read16(PC+1)
            // Handle the 6502 bug for when the low-byte of the effective address is FF,
            // in which case the 2nd byte read does not correctly cross page boundaries.
            // The bug is that the high byte does not change.
            let high = (low & 0xFF00) | ((low + 1) & 0x00FF)

            m_operandAddress = TO16(Read8(low)) | TO16(Read8(high)) << 8
            
            break

        case AddressMode.IdxInd:
            let low:UInt16 = TO16((Read8(PC+1) + X)) & 0x00FF // Zero page low byte of operand address, wrap around zero page
            let high:UInt16 = TO16(uint8(low + 1)) & 0x00FF // Wrap high byte around zero page
            m_operandAddress = TO16(Read8(low)) | TO16(Read8(high)) << 8
            break

        case AddressMode.IndIdx:
            let low:UInt16 = TO16(Read8(PC+1)) // Zero page low byte of operand address
            let high:UInt16 = (low + 1) & 0x00FF // Wrap high byte around zero page
            let baseAddress:UInt16 = (TO16(Read8(low)) | TO16(Read8(high)) << 8)
            let basePage:UInt16 = GetPageAddress(baseAddress)
            m_operandAddress = baseAddress + UInt16(Y);
            m_operandReadCrossedPage = basePage != GetPageAddress(m_operandAddress);
            
            //Original code
            //const uint16 low = TO16(Read8(PC+1)); // Zero page low byte of operand address
            //const uint16 high = TO16(low + 1) & 0x00FF; // Wrap high byte around zero page
            //const uint16 baseAddress = (TO16(Read8(low)) | TO16(Read8(high)) << 8);
            //const uint16 basePage = GetPageAddress(baseAddress);
            //m_operandAddress = baseAddress + Y;
            //m_operandReadCrossedPage = basePage != GetPageAddress(m_operandAddress);
            break
        }
        
        //let pc = PC
        //let opa = m_operandAddress
        //NSLog("%d,%d",pc,opa)
    }
    
    func ExecuteInstruction()
    {
        //using namespace OpCodeName;
        //using namespace StatusFlag;

        // By default, next instruction is after current, but can also be changed by a branch or jump
        var nextPC = UInt16(PC + UInt16(m_opCodeEntry!.numBytes))
        
        var branchTaken = false

        switch (m_opCodeEntry!.opCodeName)
        {
        case OpCodeEntryTtype.ADC: // Add memory to accumulator with carry
            // Operation:  A + M + C -> A, C
            let value = GetMemValue()
            let result = TO16(A) + TO16(value) + TO16(P.Test01(Carry))
            
            P.Set(bits: Negative, enabled: CalcNegativeFlag(result))
            P.Set(bits: Zero, enabled: CalcZeroFlag(result))
            P.Set(bits: Carry, enabled: CalcCarryFlag(result))
            P.Set(bits: Overflow, enabled: CalcOverflowFlag(a: A, b: value, r: result))
            A = TO8(result)
            
            break

        case OpCodeEntryTtype.AND: // "AND" memory with accumulator
            A &= GetMemValue()
            P.Set(bits: Negative, enabled: CalcNegativeFlag(A))
            P.Set(bits: Zero, enabled: CalcZeroFlag(A))
            
            
            //Original code
            //A &= GetMemValue();
            //P.Set(Negative, CalcNegativeFlag(A));
            //P.Set(Zero, CalcZeroFlag(A));
            break

        case OpCodeEntryTtype.ASL: // Shift Left One Bit (Memory or Accumulator)
            
            let result = TO16(GetAccumOrMemValue()) << 1
            P.Set(bits: Negative, enabled: CalcNegativeFlag(result))
            P.Set(bits: Zero, enabled: CalcZeroFlag(result))
            P.Set(bits: Carry, enabled: CalcCarryFlag(result))
            SetAccumOrMemValue(TO8(result))
            
            break

        case OpCodeEntryTtype.BCC: // Branch on Carry Clear
            if (!P.Test(Carry))
            {
                nextPC = GetBranchOrJmpLocation()
                branchTaken = true
            }
            break;

        case OpCodeEntryTtype.BCS: // Branch on Carry Set
            if (P.Test(Carry))
            {
                nextPC = GetBranchOrJmpLocation()
                branchTaken = true
            }
            break;

        case OpCodeEntryTtype.BEQ: // Branch on result zero (equal means compare difference is 0)
            if (P.Test(Zero))
            {
                nextPC = GetBranchOrJmpLocation()
                branchTaken = true
            }
            
            //Original code
            //if (P.Test(Zero))
            //{
            //    nextPC = GetBranchOrJmpLocation();
            //    branchTaken = true;
            //}
            
            break

        case OpCodeEntryTtype.BIT: // Test bits in memory with accumulator
            
            let memValue = GetMemValue()
            let result = A & GetMemValue()
            P.SetValue( (P.Value() & 0x3F) | (memValue & 0xC0) ) // Copy bits 6 and 7 of mem value to status register
            P.Set(bits: Zero, enabled: CalcZeroFlag(result))
            
            break

        case OpCodeEntryTtype.BMI: // Branch on result minus
            if (P.Test(Negative))
            {
                nextPC = GetBranchOrJmpLocation()
                branchTaken = true
            }
            break

        case OpCodeEntryTtype.BNE:  // Branch on result non-zero
            if (!P.Test(Zero))
            {
                nextPC = GetBranchOrJmpLocation()
                branchTaken = true
            }
            break

        case OpCodeEntryTtype.BPL: // Branch on result plus
            if (!P.Test(Negative))
            {
                nextPC = GetBranchOrJmpLocation()
                branchTaken = true
            }
            break

        case OpCodeEntryTtype.BRK: // Force break (Forced Interrupt PC + 2 toS P toS) (used with RTI)
            
            // Note that BRK is weird in that the instruction is 1 byte, but the return address
            // we store is 2 bytes after the instruction, so the byte after BRK will be skipped
            // upon return (RTI). Usually an NOP is inserted after a BRK for this reason.
            let returnAddr = PC + 2
            Push16(returnAddr)
            PushProcessorStatus(true)
            P.Set(IrqDisabled) // Disable hardware IRQs
            nextPC = Read16(CpuMemory.kIrqVector)
            
            break;

        case OpCodeEntryTtype.BVC: // Branch on Overflow Clear
            if (!P.Test(Overflow))
            {
                nextPC = GetBranchOrJmpLocation();
                branchTaken = true
            }
            break

        case OpCodeEntryTtype.BVS: // Branch on Overflow Set
            if (P.Test(Overflow))
            {
                nextPC = GetBranchOrJmpLocation()
                branchTaken = true
            }
            break

        case OpCodeEntryTtype.CLC: // CLC Clear carry flag
            P.Clear(Carry);
            break;

        case OpCodeEntryTtype.CLD: // CLD Clear decimal mode
            P.Clear(Decimal);
            break;

        case OpCodeEntryTtype.CLI: // CLI Clear interrupt disable bit
            P.Clear(IrqDisabled);
            break;

        case OpCodeEntryTtype.CLV: // CLV Clear overflow flag
            P.Clear(Overflow);
            break;

        case OpCodeEntryTtype.CMP: // CMP Compare memory and accumulator
            
            let memValue = GetMemValue()
            
            let result = A &- memValue
            
            P.Set(bits: Negative, enabled: CalcNegativeFlag(result))
            P.Set(bits: Zero, enabled: CalcZeroFlag(result))
            
            var enabled = 0
            if(A >= memValue)
            {
                enabled = 1
            }
            P.Set(bits: Carry, enabled: UInt8(enabled)) // Carry set if result positive or 0
            
            break

        case OpCodeEntryTtype.CPX: // CPX Compare Memory and Index X
            
            let memValue = GetMemValue()
            
            let result = X &- memValue
            P.Set(bits: Negative, enabled: CalcNegativeFlag(result))
            P.Set(bits: Zero, enabled: CalcZeroFlag(result))
            
            
            let enabled = X >= memValue ? 1:0
            P.Set(bits: Carry, enabled: UInt8(enabled)) // Carry set if result positive or 0
            
            break

        case OpCodeEntryTtype.CPY: // CPY Compare memory and index Y
            
            let memValue = GetMemValue()
            let result = Y &- memValue
            P.Set(bits: Negative, enabled: CalcNegativeFlag(result))
            P.Set(bits: Zero, enabled: CalcZeroFlag(result))
            
            let enabled = Y >= memValue ? 1:0
            P.Set(bits: Carry, enabled: UInt8(enabled)) // Carry set if result positive or 0
            
            break

        case OpCodeEntryTtype.DEC: // Decrement memory by one
            
            let memValue = GetMemValue()
            let result = memValue &- 1
            
            P.Set(bits: Negative, enabled: CalcNegativeFlag(result))
            P.Set(bits: Zero, enabled: CalcZeroFlag(result))
            SetMemValue(result)
            
            //Original code
            //const uint8 result = GetMemValue() - 1;
            //P.Set(Negative, CalcNegativeFlag(result));
            //P.Set(Zero, CalcZeroFlag(result));
            //SetMemValue(result);
            
            break

        case OpCodeEntryTtype.DEX: // Decrement index X by one
            X = X &- 1
            P.Set(bits: Negative, enabled: CalcNegativeFlag(X))
            P.Set(bits: Zero, enabled: CalcZeroFlag(X))
            break

        case OpCodeEntryTtype.DEY: // Decrement index Y by one
            Y = Y &- 1
            
            P.Set(bits: Negative, enabled: CalcNegativeFlag(Y))
            P.Set(bits: Zero, enabled: CalcZeroFlag(Y))
            break

        case OpCodeEntryTtype.EOR: // "Exclusive-Or" memory with accumulator
            A = A ^ GetMemValue()
            P.Set(bits: Negative, enabled: CalcNegativeFlag(A))
            P.Set(bits: Zero, enabled: CalcZeroFlag(A))
            break

        case OpCodeEntryTtype.INC: // Increment memory by one
            
            let result = GetMemValue() &+ 1
            P.Set(bits: Negative, enabled: CalcNegativeFlag(result))
            P.Set(bits: Zero, enabled: CalcZeroFlag(result))
            SetMemValue(result)
            
            break

        case OpCodeEntryTtype.INX: // Increment Index X by one
            
            X = X &+ 1
            P.Set(bits: Negative, enabled: CalcNegativeFlag(X))
            P.Set(bits: Zero, enabled: CalcZeroFlag(X))
            break

        case OpCodeEntryTtype.INY: // Increment Index Y by one
            
            Y = Y &+ 1
            P.Set(bits: Negative, enabled: CalcNegativeFlag(Y))
            P.Set(bits: Zero, enabled: CalcZeroFlag(Y))
            break

        case OpCodeEntryTtype.JMP: // Jump to new location
            nextPC = GetBranchOrJmpLocation()
            break

        case OpCodeEntryTtype.JSR: // Jump to subroutine (used with RTS)
            
            // JSR actually pushes address of the next instruction - 1.
            // RTS jumps to popped value + 1.
            let returnAddr:UInt16 = PC + UInt16(m_opCodeEntry!.numBytes) - 1
            Push16(returnAddr)
            nextPC = GetBranchOrJmpLocation()
            
            //Original Code
            //const uint16 returnAddr = PC + m_opCodeEntry->numBytes - 1;
            //Push16(returnAddr);
            //nextPC = GetBranchOrJmpLocation();
            
            break

        case OpCodeEntryTtype.LDA: // Load accumulator with memory
            A = GetMemValue()
            P.Set(bits: Negative, enabled: CalcNegativeFlag(A))
            P.Set(bits: Zero, enabled: CalcZeroFlag(A))
            
            
            //Original code
            //A = GetMemValue();
            //P.Set(Negative, CalcNegativeFlag(A));
            //P.Set(Zero, CalcZeroFlag(A));
            break

        case OpCodeEntryTtype.LDX: // Load index X with memory
            X = GetMemValue()
            P.Set(bits: Negative, enabled: CalcNegativeFlag(X))
            P.Set(bits: Zero, enabled: CalcZeroFlag(X))
            break

        case OpCodeEntryTtype.LDY: // Load index Y with memory
            Y = GetMemValue();
            P.Set(bits: Negative, enabled: CalcNegativeFlag(Y))
            P.Set(bits: Zero, enabled: CalcZeroFlag(Y))
            break

        case OpCodeEntryTtype.LSR: // Shift right one bit (memory or accumulator)
            
            let value = GetAccumOrMemValue()
            let result = value >> 1
            P.Set(bits: Carry, enabled: value & 0x01) // Will get shifted into carry
            P.Set(bits: Zero, enabled: CalcZeroFlag(result))
            P.Clear(Negative) // 0 is shifted into sign bit position
            SetAccumOrMemValue(result)
            
            break

        case OpCodeEntryTtype.NOP: // No Operation (2 cycles)
            break

        case OpCodeEntryTtype.ORA: // "OR" memory with accumulator
            A |= GetMemValue()
            P.Set(bits: Negative, enabled: CalcNegativeFlag(A))
            P.Set(bits: Zero, enabled: CalcZeroFlag(A))
            break

        case OpCodeEntryTtype.PHA: // Push accumulator on stack
            Push8(A)
            break

        case OpCodeEntryTtype.PHP: // Push processor status on stack
            PushProcessorStatus(true)
            break

        case OpCodeEntryTtype.PLA: // Pull accumulator from stack
            A = Pop8();
            P.Set(bits: Negative, enabled: CalcNegativeFlag(A))
            P.Set(bits: Zero, enabled: CalcZeroFlag(A))
            break

        case OpCodeEntryTtype.PLP: // Pull processor status from stack
            PopProcessorStatus()
            break

        case OpCodeEntryTtype.ROL: // Rotate one bit left (memory or accumulator)
            
            let result = (TO16(GetAccumOrMemValue()) << 1) | TO16(P.Test01(Carry))
            P.Set(bits: Carry, enabled: CalcCarryFlag(result))
            P.Set(bits: Negative, enabled: CalcNegativeFlag(result))
            P.Set(bits: Zero, enabled: CalcZeroFlag(result))
            SetAccumOrMemValue(TO8(result))
            
            break

        case OpCodeEntryTtype.ROR: // Rotate one bit right (memory or accumulator)
            
            let value:UInt8 = GetAccumOrMemValue()
            let result:UInt8 = (value >> 1) | (P.Test01(Carry) << 7)
            P.Set(bits: Carry, enabled: value & 0x01)
            P.Set(bits: Negative, enabled: CalcNegativeFlag(result))
            P.Set(bits: Zero, enabled: CalcZeroFlag(result))
            SetAccumOrMemValue(result)
            
            break

        case OpCodeEntryTtype.RTI: // Return from interrupt (used with BRK, Nmi or Irq)
            PopProcessorStatus()
            nextPC = Pop16()
            break

        case OpCodeEntryTtype.RTS: // Return from subroutine (used with JSR)
            
            nextPC = Pop16() + 1
            
            break

        case OpCodeEntryTtype.SBC: // Subtract memory from accumulator with borrow
            
            // Operation:  A - M - C -> A

            // Can't simply negate mem value because that results in two's complement
            // and we want to perform the bitwise add ourself
            let value = GetMemValue() ^ 0xFF

            let result = TO16(A) + TO16(value) + TO16(P.Test01(Carry))
            P.Set(bits: Negative, enabled: CalcNegativeFlag(result))
            P.Set(bits: Zero, enabled: CalcZeroFlag(result))
            P.Set(bits: Carry, enabled: CalcCarryFlag(result))
            P.Set(bits: Overflow, enabled: CalcOverflowFlag(a: A, b: value, r: result))
            A = TO8(result)
            
            break

        case OpCodeEntryTtype.SEC: // Set carry flag
            P.Set(Carry)
            break

        case OpCodeEntryTtype.SED: // Set decimal mode
            P.Set(Decimal)
            break

        case OpCodeEntryTtype.SEI: // Set interrupt disable status
            P.Set(IrqDisabled)
            break

        case OpCodeEntryTtype.STA: // Store accumulator in memory
            SetMemValue(A)
            break

        case OpCodeEntryTtype.STX: // Store index X in memory
            SetMemValue(X)
            break

        case OpCodeEntryTtype.STY: // Store index Y in memory
            SetMemValue(Y)
            break

        case OpCodeEntryTtype.TAX: // Transfer accumulator to index X
            X = A
            P.Set(bits: Negative, enabled: CalcNegativeFlag(X))
            P.Set(bits: Zero, enabled: CalcZeroFlag(X))
            break

        case OpCodeEntryTtype.TAY: // Transfer accumulator to index Y
            Y = A
            P.Set(bits: Negative, enabled: CalcNegativeFlag(Y))
            P.Set(bits: Zero, enabled: CalcZeroFlag(Y))
            break

        case OpCodeEntryTtype.TSX: // Transfer stack pointer to index X
            X = SP
            P.Set(bits: Negative, enabled: CalcNegativeFlag(X))
            P.Set(bits: Zero, enabled: CalcZeroFlag(X))
            break

        case OpCodeEntryTtype.TXA: // Transfer index X to accumulator
            A = X
            P.Set(bits: Negative, enabled: CalcNegativeFlag(A))
            P.Set(bits: Zero, enabled: CalcZeroFlag(A))
            break

        case OpCodeEntryTtype.TXS: // Transfer index X to stack pointer
            SP = X
            break

        case OpCodeEntryTtype.TYA: // Transfer index Y to accumulator
            A = Y
            P.Set(bits: Negative, enabled: CalcNegativeFlag(A))
            P.Set(bits: Zero, enabled: CalcZeroFlag(A))
            break
        }

        // Compute cycles for instruction
        
        var cycles = m_opCodeEntry!.numCycles;

        // Some instructions take an extra cycle when reading operand across page boundary
        if (m_operandReadCrossedPage)
        {
            cycles = cycles + m_opCodeEntry!.pageCrossCycles
        }

        // Extra cycle when branch is taken
        if (branchTaken)
        {
            cycles = cycles + 1

            // And extra cycle when branching to a different page
            if (GetPageAddress(PC) != GetPageAddress(nextPC))
            {
                cycles = cycles + 1
            }
        }

        m_cycles += uint32(cycles)
        
        // Move to next instruction
        PC = nextPC
        
        //NSLog("PC->%d",PC)
    }
    
    
    var PC:uint16 = 0        // Program counter
    var SP:uint8 = 0        // Stack pointer
    var A:uint8 = 0       // Accumulator
    var X:uint8 = 0     // X register
    var Y:uint8 = 0        // Y register
    var P:Bitfield8 = Bitfield8()   // Processor status (flags) TODO
    var m_pendingNmi = false
    var m_pendingIrq = false
    func Reset()
    {
        // See http://wiki.nesdev.com/w/index.php/CPU_power_up_state

        A = 0
        X = 0
        Y = 0
        SP = 0xFF; // Should be FD, but for improved compatibility set to FF
        
        P.ClearAll()
        P.Set(IrqDisabled)

        // Entry point is located at the Reset interrupt location
        PC = Read16(CpuMemory.kResetVector)

        m_cycles = 0
        m_pendingNmi = false
        m_pendingIrq = false

        //m_controllerPorts.Reset();
    }
    
    
    @inline(__always) func TO16(_ v8:uint8)->uint16
    {
        return uint16(v8)
    }
    
    @inline(__always) func TO8(_ v16:uint16)->uint8
    {
        let v8:UInt8 = UInt8(v16 & 0x00FF)
        return v8
    }
    
    @inline(__always) func Read16(_ address:uint16)->uint16
    {
        return TO16(m_cpuMemoryBus!.Read(address)) | (TO16(m_cpuMemoryBus!.Read(address + 1)) << 8)
    }
    
    @inline(__always) func GetMemValue()->UInt8
    {
        return Read8(m_operandAddress)
    }
    
    @inline(__always) func CalcNegativeFlag(_ v:UInt16)->UInt8
    {
        // Check if bit 7 is set
        if((v & 0x0080) != 0)
        {
            return 1
        }
        else
        {
            return 0
        }
    }
    
    //ok
    @inline(__always) func CalcNegativeFlag(_ v:UInt8)->UInt8
    {
        // Check if bit 7 is set
        if((v & 0x80) != 0)
        {
            return 1
        }
        else
        {
            return 0
        }
        
    }
    
    //ok
    @inline(__always) func CalcZeroFlag(_ v:UInt16)->UInt8
    {
        // Check if bit 7 is set
        if((v & 0x00FF) == 0)
        {
            return 1
        }
        else
        {
            return 0
        }
    }
    
    //ok
    @inline(__always) func CalcZeroFlag(_ v:UInt8)->UInt8
    {
        if(v == 0)
        {
            return 1
        }
        else
        {
            return 0
        }
    }
    
    //ok
    @inline(__always) func CalcCarryFlag(_ v:UInt16)->UInt8
    {
        if((v & 0xFF00) != 0)
        {
            return 1
        }
        else
        {
            return 0
        }
    }
    
    @inline(__always) func CalcOverflowFlag(a:UInt8, b:UInt8, r:UInt16)->UInt8
    {
        // With r = a + b, overflow occurs if both a and b are negative and r is positive,
        // or both a and b are positive and r is negative. Looking at sign bits of a, b, r,
        // overflow occurs when 0 0 1 or 1 1 0, so we can use simple xor logic to figure it out.
        // return ((uint16)a ^ r) & ((uint16)b ^ r) & 0x0080;
        let result = (uint16(a) ^ r) & (uint16(b) ^ r) & 0x0080
        
        if(result != 0)
        {
            //NSLog("OverFolow")
        }
        return UInt8(result)
    }
    
    func GetAccumOrMemValue()->UInt8
    {
        //assert(m_opCodeEntry->addrMode == AddressMode::Accumu || m_opCodeEntry->addrMode & AddressMode::MemoryValueOperand);

        if (m_opCodeEntry!.addrMode == AddressMode.Accumu)
        {
            return A
        }
        
        let result = Read8(m_operandAddress)
        return result
    }
    
    func SetAccumOrMemValue(_ value:UInt8)
    {
        //assert(m_opCodeEntry->addrMode == AddressMode::Accumu || m_opCodeEntry->addrMode & AddressMode::MemoryValueOperand);

        if (m_opCodeEntry!.addrMode == AddressMode.Accumu)
        {
            A = value
        }
        else
        {
            Write8(address: m_operandAddress, value: value);
        }
    }
    
    func Write8(address:UInt16, value:UInt8)
    {
        m_cpuMemoryBus!.Write(cpuAddress: address, value: value)
    }
    
    func Push16(_ value:UInt16)
    {
        Push8(UInt8(value >> 8))
        Push8(UInt8(value & 0x00FF))
    }
    
    func Push8(_ value:UInt8)
    {
        Write8(address: CpuMemory.kStackBase + UInt16(SP), value: value);
        
        SP = SP &- 1
        
        if (SP == 0xFF)
        {
            NSLog("Stack overflow!");
        }
    }


    func Pop8()->UInt8
    {
        SP = SP + 1

        if (SP == 0)
        {
            NSLog("Stack overflow!");
        }
        
        return Read8(CpuMemory.kStackBase + UInt16(SP))
    }

    func Pop16()->UInt16
    {
        let low = TO16(Pop8())
        let high = TO16(Pop8())
        return (high << 8) | low
    }

    func PushProcessorStatus(_ softwareInterrupt:Bool)
    {
        //assert(!P.Test(StatusFlag::Unused) && !P.Test(StatusFlag::BrkExecuted) && "P should never have these set, only on stack");
        var brkFlag:UInt8 = 0
        
        if(softwareInterrupt)
        {
            brkFlag = BrkExecuted
        }
        Push8(P.Value() | Unused | brkFlag)
    }

    func PopProcessorStatus()
    {
        //123
        P.SetValue(Pop8() & ~Unused & ~BrkExecuted)
        //assert(!P.Test(Unused) && !P.Test(BrkExecuted) && "P should never have these set, only on stack");
    }
    
    
    func IsMemoryValueOperand(_ v:UInt32)->Bool
    {
        //Immedt | ZeroPg | ZPIdxX|ZPIdxY|Absolu|AbIdxX|AbIdxY|IdxInd|IndIdx
        if(v == AddressMode.Immedt.rawValue)
        {
            return true
        }
        if(v == AddressMode.ZeroPg.rawValue)
        {
            return true
        }
        if(v == AddressMode.ZPIdxX.rawValue)
        {
            return true
        }
        if(v == AddressMode.ZPIdxY.rawValue)
        {
            return true
        }
        if(v == AddressMode.Absolu.rawValue)
        {
            return true
        }
        if(v == AddressMode.AbIdxX.rawValue)
        {
            return true
        }
        if(v == AddressMode.AbIdxY.rawValue)
        {
            return true
        }
        if(v == AddressMode.IdxInd.rawValue)
        {
            return true
        }
        if(v == AddressMode.IndIdx.rawValue)
        {
            return true
        }
        
        return false
    }
    
    func IsJmpOrBranchOperand(_ v:UInt32)->Bool
    {
        let attrMode = m_opCodeEntry!.addrMode
        //Relatv|Absolu|Indrct
        if(v == AddressMode.Relatv.rawValue)
        {
            return true
        }
        if(v == AddressMode.Absolu.rawValue)
        {
            return true
        }
        if(v == AddressMode.Indrct.rawValue)
        {
            return true
        }
        
        
        return false
    }
    
    func SetMemValue(_ value:UInt8)
    {
        assert(IsMemoryValueOperand(m_opCodeEntry!.addrMode.rawValue))
        
        //if(!(IsMemoryValueOperand(m_opCodeEntry!.addrMode.rawValue)))
        //{
        //    return
        //}
        Write8(address: m_operandAddress, value: value)
    }
    
    @inline(__always) func GetBranchOrJmpLocation()->UInt16
    {
        //assert(IsJmpOrBranchOperand(m_opCodeEntry!.addrMode.rawValue))
        return m_operandAddress
    }
    
    func ToInt(_ x : UInt8) -> Int16 {
          return Int16(Int8(bitPattern: x))
    }
    
    func Nmi()
    {
        //assert(!m_pendingNmi && "Interrupt already pending");
        //assert(!m_pendingIrq && "One interrupt at at time");
        m_pendingNmi = true
    }

    func Irq()
    {
        //assert(!m_pendingIrq && "Interrupt already pending");
        //assert(!m_pendingNmi && "One interrupt at at time");

        if (!P.Test(IrqDisabled))
        {
            m_pendingIrq = true
        }
    }

}
