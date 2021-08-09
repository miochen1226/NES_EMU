//
//  Cpu.swift
//  NES_EMU
//
//  Created by mio on 2021/8/8.
//

import Foundation
class Cpu:OpCodeNameSpace,HandleCpuReadProtocol{
    
    //static func BIT(_ n:Int)->UInt8
    //{
    //    return (1<<n)
    //}
    
    enum StatusFlag : UInt8
    {
        case Carry              = 0b00000001//(1<<0)
        case Zero               = 0b00000010//(1<<1)
        case IrqDisabled        = 0b00000100// Interrupt (IRQ) disabled
        case Decimal            = 0b00001000 // *NOTE: Present in P, but Decimal mode not supported by NES CPU
        case BrkExecuted        = 0b00010000 // BRK executed (IRQ/software interupt) *NOTE: Not actually a bit in P, only set on stack for s/w interrupts
        case Unused             = 0b00100000 // *NOTE: Never set in P, but always set on stack
        case Overflow           = 0b01000000 // 'V'
        case Negative           = 0b10000000 // aka Sign flag
    }
    
    
    var Carry = StatusFlag.Carry.rawValue
    var Zero = StatusFlag.Zero.rawValue
    var IrqDisabled = StatusFlag.IrqDisabled.rawValue
    var Decimal = StatusFlag.Decimal.rawValue
    var BrkExecuted = StatusFlag.BrkExecuted.rawValue
    var Unused = StatusFlag.Unused.rawValue
    var Overflow = StatusFlag.Overflow.rawValue
    var Negative = StatusFlag.Negative.rawValue
    
    
    func HandleCpuRead(_ cpuAddress: uint16) -> uint8 {
        return 0
    }
    
    func HandleCpuWrite(cpuAddress:UInt16, value:UInt8)
    {
        
    }
    
    var m_cpuMemoryBus:CpuMemoryBus?
    func Initialize(cpuMemoryBus:CpuMemoryBus)
    {
        m_cpuMemoryBus = cpuMemoryBus
        
        
        NSLog("===OpTables===")
        let array = OpCodeTable.GetOpCodeTable()
        for item in array
        {
            NSLog(item.getName())
            g_opCodeTable[item.opCode] = item
        }
        
        NSLog("===OpTables end===")
    }
    
    
    var m_cycles:uint32 = 0
    var m_totalCycles:uint32 = 0
    var m_opCodeEntry:OpCodeEntry?
    var g_opCodeTable:[uint8:OpCodeEntry?] = [:]

    func Execute(_ cpuCyclesElapsed:inout uint32)
    {
        m_cycles = 0
        ExecutePendingInterrupts()// Handle when interrupts are called "between" CPU updates (e.g. PPU sends NMI)
        
        NSLog("PC="+String(PC))
        let opCode = Read8(PC)
        m_opCodeEntry = g_opCodeTable[opCode] as? OpCodeEntry

        if (m_opCodeEntry == nil)
        {
            NSLog("Unknown opcode")
            return
        }
        else
        {
            let opName = m_opCodeEntry?.getName() ?? "UNKNOW"
            NSLog("Execute->" + opName)
        }

        UpdateOperandAddress()

        ExecuteInstruction()
        ExecutePendingInterrupts(); // Handle when instruction (memory read) causes interrupt
    
        cpuCyclesElapsed = m_cycles
        m_totalCycles += m_cycles
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
    
    func Read8(_ address:uint16)->uint8
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
            m_operandAddress = PC + 1; // Set to address of immediate value in code segment
            break

        case AddressMode.Implid:
            break

        case AddressMode.Accumu:
            break

        case AddressMode.Relatv: // For conditional branch instructions
            
            // For branch instructions, resolve the target address
            //const int8 offset = Read8(PC+1); // Signed offset in [-128,127]
            
            let offsetSigned = ToInt8(Read8(PC+1)) // Signed offset in [-128,127]
            //let offset:Int8 = Int8(Read8(PC+1)) // Signed offset in [-128,127]
            let offset = UInt16(abs(offsetSigned))
            //mio modify
            if(offsetSigned>=0)
            {
                m_operandAddress = PC + UInt16(m_opCodeEntry!.numBytes)+offset
            }
            else
            {
                m_operandAddress = PC + UInt16(m_opCodeEntry!.numBytes)-offset
            }
            //m_operandAddress = UInt16(UInt8(PC) + m_opCodeEntry!.numBytes + offset)
            
            
            //m_operandAddress = UInt16(UInt8(PC) + m_opCodeEntry!.numBytes + offset)
            
            break

        case AddressMode.ZeroPg:
            m_operandAddress = TO16(Read8(PC+1))
            break;

        case AddressMode.ZPIdxX:
            m_operandAddress = TO16((Read8(PC+1) + X)) & 0x00FF // Wrap around zero-page boundary
            break;

        case AddressMode.ZPIdxY:
            m_operandAddress = TO16((Read8(PC+1) + Y)) & 0x00FF // Wrap around zero-page boundary
            break;

        case AddressMode.Absolu:
            m_operandAddress = Read16(PC+1)
            break;

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
            let low = TO16(Read8(PC+1)) // Zero page low byte of operand address
            let high:UInt16 = TO16(uint8(low + 1)) & 0x00FF // Wrap high byte around zero page
            let baseAddress = (TO16(Read8(low)) | TO16(Read8(high)) << 8)
            let basePage = GetPageAddress(baseAddress)
            m_operandAddress = baseAddress + UInt16(Y);
            m_operandReadCrossedPage = basePage != GetPageAddress(m_operandAddress);
            break
        default:
            NSLog("Invalid addressing mode")
            break
        }
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
            A &= GetMemValue();
            P.Set(bits: Negative, enabled: CalcNegativeFlag(UInt16(A)))
            P.Set(bits: Zero, enabled: CalcZeroFlag(A))
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
                branchTaken = true;
            }
            break;

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
            break;

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
                branchTaken = true;
            }
            break;

        case OpCodeEntryTtype.BVS: // Branch on Overflow Set
            if (P.Test(Overflow))
            {
                nextPC = GetBranchOrJmpLocation();
                branchTaken = true;
            }
            break;

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
            let result = A - memValue
            P.Set(bits: Negative, enabled: CalcNegativeFlag(UInt16(result)))
            P.Set(bits: Zero, enabled: CalcZeroFlag(result))
            
            var enabled = A >= memValue ? 1:0
            P.Set(bits: Carry, enabled: UInt8(enabled)) // Carry set if result positive or 0
            
            break

        case OpCodeEntryTtype.CPX: // CPX Compare Memory and Index X
            
            let memValue = GetMemValue();
            let result = X - memValue;
            P.Set(bits: Negative, enabled: CalcNegativeFlag(UInt16(result)))
            P.Set(bits: Zero, enabled: CalcZeroFlag(result))
            var enabled = X >= memValue ? 1:0
            P.Set(bits: Carry, enabled: UInt8(enabled)) // Carry set if result positive or 0
            
            break

        case OpCodeEntryTtype.CPY: // CPY Compare memory and index Y
            
            let memValue = GetMemValue()
            let result = Y - memValue
            P.Set(bits: Negative, enabled: CalcNegativeFlag(UInt16(result)))
            P.Set(bits: Zero, enabled: CalcZeroFlag(result))
            var enabled = Y >= memValue ? 1:0
            P.Set(bits: Carry, enabled: UInt8(enabled)) // Carry set if result positive or 0
            
            break

        case OpCodeEntryTtype.DEC: // Decrement memory by one
            
            let result = GetMemValue() - 1
            P.Set(bits: Negative, enabled: CalcNegativeFlag(UInt16(result)))
            P.Set(bits: Zero, enabled: CalcZeroFlag(result))
            SetMemValue(result)
            
            break

        case OpCodeEntryTtype.DEX: // Decrement index X by one
            X = X - 1
            P.Set(bits: Negative, enabled: CalcNegativeFlag(UInt16(X)))
            P.Set(bits: Zero, enabled: CalcZeroFlag(X))
            break

        case OpCodeEntryTtype.DEY: // Decrement index Y by one
            Y = Y - 1
            P.Set(bits: Negative, enabled: CalcNegativeFlag(UInt16(Y)))
            P.Set(bits: Zero, enabled: CalcZeroFlag(Y))
            break

        case OpCodeEntryTtype.EOR: // "Exclusive-Or" memory with accumulator
            A = A ^ GetMemValue()
            P.Set(bits: Negative, enabled: CalcNegativeFlag(UInt16(A)))
            P.Set(bits: Zero, enabled: CalcZeroFlag(A))
            break

        case OpCodeEntryTtype.INC: // Increment memory by one
            
            let result = GetMemValue() + 1
            P.Set(bits: Negative, enabled: CalcNegativeFlag(UInt16(result)))
            P.Set(bits: Zero, enabled: CalcZeroFlag(result))
            SetMemValue(result)
            
            break

        case OpCodeEntryTtype.INX: // Increment Index X by one
            X = X + 1
            P.Set(bits: Negative, enabled: CalcNegativeFlag(UInt16(X)))
            P.Set(bits: Zero, enabled: CalcZeroFlag(X))
            break

        case OpCodeEntryTtype.INY: // Increment Index Y by one
            Y = Y + 1
            P.Set(bits: Negative, enabled: CalcNegativeFlag(UInt16(Y)));
            P.Set(bits: Zero, enabled: CalcZeroFlag(Y))
            break

        case OpCodeEntryTtype.JMP: // Jump to new location
            nextPC = GetBranchOrJmpLocation()
            break

        case OpCodeEntryTtype.JSR: // Jump to subroutine (used with RTS)
            
            // JSR actually pushes address of the next instruction - 1.
            // RTS jumps to popped value + 1.
            let returnAddr = PC + UInt16(m_opCodeEntry!.numBytes) - 1
            Push16(returnAddr)
            nextPC = GetBranchOrJmpLocation()
            
            break

        case OpCodeEntryTtype.LDA: // Load accumulator with memory
            A = GetMemValue()
            P.Set(bits: Negative, enabled: CalcNegativeFlag(UInt16(A)))
            P.Set(bits: Zero, enabled: CalcZeroFlag(A))
            break

        case OpCodeEntryTtype.LDX: // Load index X with memory
            X = GetMemValue()
            P.Set(bits: Negative, enabled: CalcNegativeFlag(UInt16(X)))
            P.Set(bits: Zero, enabled: CalcZeroFlag(X))
            break

        case OpCodeEntryTtype.LDY: // Load index Y with memory
            Y = GetMemValue();
            P.Set(bits: Negative, enabled: CalcNegativeFlag(UInt16(Y)))
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
            P.Set(bits: Negative, enabled: CalcNegativeFlag(UInt16(A)))
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
            P.Set(bits: Negative, enabled: CalcNegativeFlag(UInt16(A)))
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
            
            let value = GetAccumOrMemValue()
            let result = (value >> 1) | (P.Test01(Carry) << 7)
            P.Set(bits: Carry, enabled: value & 0x01)
            P.Set(bits: Negative, enabled: CalcNegativeFlag(UInt16(result)))
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
            break;

        case OpCodeEntryTtype.STX: // Store index X in memory
            SetMemValue(X)
            break;

        case OpCodeEntryTtype.STY: // Store index Y in memory
            SetMemValue(Y)
            break;

        case OpCodeEntryTtype.TAX: // Transfer accumulator to index X
            X = A
            P.Set(bits: Negative, enabled: CalcNegativeFlag(UInt16(X)))
            P.Set(bits: Zero, enabled: CalcZeroFlag(X))
            break

        case OpCodeEntryTtype.TAY: // Transfer accumulator to index Y
            Y = A
            P.Set(bits: Negative, enabled: CalcNegativeFlag(UInt16(Y)))
            P.Set(bits: Zero, enabled: CalcZeroFlag(Y))
            break

        case OpCodeEntryTtype.TSX: // Transfer stack pointer to index X
            X = SP
            P.Set(bits: Negative, enabled: CalcNegativeFlag(UInt16(X)))
            P.Set(bits: Zero, enabled: CalcZeroFlag(X))
            break

        case OpCodeEntryTtype.TXA: // Transfer index X to accumulator
            A = X
            P.Set(bits: Negative, enabled: CalcNegativeFlag(UInt16(A)))
            P.Set(bits: Zero, enabled: CalcZeroFlag(A))
            break

        case OpCodeEntryTtype.TXS: // Transfer index X to stack pointer
            SP = X
            break

        case OpCodeEntryTtype.TYA: // Transfer index Y to accumulator
            A = Y
            P.Set(bits: Negative, enabled: CalcNegativeFlag(UInt16(A)))
            P.Set(bits: Zero, enabled: CalcZeroFlag(A))
            break

        default:
            assert(false)
            break;
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
        
        //P.ClearAll();
        //P.Set(StatusFlag::IrqDisabled);

        // Entry point is located at the Reset interrupt location
        PC = Read16(CpuMemory.kResetVector)

        m_cycles = 0;
        m_totalCycles = 0;
        m_pendingNmi = false
        m_pendingIrq = false

        //m_controllerPorts.Reset();
    }
    
    
    func TO16(_ v8:uint8)->uint16
    {
        return uint16(v8)
    }
    
    func TO8(_ v16:uint16)->uint8
    {
        return uint8(v16)
    }
    
    func Read16(_ address:uint16)->uint16
    {
        return TO16(m_cpuMemoryBus!.Read(address)) | (TO16(m_cpuMemoryBus!.Read(address + 1)) << 8);
    }
    
    func GetMemValue()->UInt8
    {
        let result = Read8(m_operandAddress)
        return result
    }
    
    func CalcNegativeFlag(_ v:UInt16)->UInt8
    {
        if((v & 0x0080) != 0)
        {
            return 1
        }
        else
        {
            return 0
        }
    }
    
    func CalcZeroFlag(_ v:UInt16)->UInt8
    {
        if((v & 0x00FF) != 0)
        {
            return 1
        }
        else
        {
            return 0
        }
    }
    
    func CalcZeroFlag(_ v:UInt8)->UInt8
    {
        if(v != 0)
        {
            return 1
        }
        else
        {
            return 0
        }
    }
    
    func CalcCarryFlag(_ v:UInt16)->UInt8
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
    
    
    func CalcOverflowFlag(a:UInt8, b:UInt8, r:UInt16)->UInt8
    {
        // With r = a + b, overflow occurs if both a and b are negative and r is positive,
        // or both a and b are positive and r is negative. Looking at sign bits of a, b, r,
        // overflow occurs when 0 0 1 or 1 1 0, so we can use simple xor logic to figure it out.
        
        //TODO need check
        let intA = Int(a)
        let intB = Int(b)
        let intR = Int(r)
        
        if(intA==0 && intB==0 && intR==0)
        {
            return 1
        }
        
        if(intA==0 && intB==0 && intR==0)
        {
            return 1
        }
        
        return 0
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
    
    func GetBranchOrJmpLocation()->UInt16
    {
        //assert(m_opCodeEntry->addrMode & AddressMode::JmpOrBranchOperand);
        return m_operandAddress
    }
    
    
    func Push16(_ value:UInt16)
    {
        Push8(UInt8(value >> 8))
        Push8(UInt8(value & 0x00FF))
    }
    
    func Push8(_ value:UInt8)
    {
        Write8(address: CpuMemory.kStackBase + UInt16(SP), value: value);
        
        SP = SP-1
    //#if FAIL_ON_STACK_OVERFLOW
      //  if (SP == 0xFF)
      //  {
      //      FAIL("Stack overflow!");
      //  }
    //#endif
    }


    func Pop8()->UInt8
    {
        SP = SP+1

        
    //#if FAIL_ON_STACK_OVERFLOW
    //    if (SP == 0)
     //   {
     //       FAIL("Stack underflow!");
     //   }
    //#endif

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
        P.SetValue(Pop8() & ~Unused & ~BrkExecuted)
        //assert(!P.Test(Unused) && !P.Test(BrkExecuted) && "P should never have these set, only on stack");
    }
    
    
    
    func SetMemValue(_ value:UInt8)
    {
        //assert(m_opCodeEntry->addrMode & AddressMode::MemoryValueOperand);
        Write8(address: m_operandAddress, value: value)
    }
    
    func ToInt8(_ x : UInt8) -> Int8 {
          return Int8(bitPattern: x)
    }
}
