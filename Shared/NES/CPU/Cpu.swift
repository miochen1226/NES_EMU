//
//  Cpu.swift
//  NES_EMU
//
//  Created by mio on 2021/8/8.
//

import Foundation
class Cpu:CpuRegDef,ICpu{
    func setApu(apu:Apu)
    {
        m_apu = apu
    }
    
    func setControllerPorts(controllerPorts:ControllerPorts)
    {
        m_controllerPorts = controllerPorts
    }
    
    var m_apu:Apu!
    var m_controllerPorts:ControllerPorts!
    
    
    
    func HandleCpuRead(_ cpuAddress: UInt16) -> UInt8 {
        var result:UInt8 = 0

        switch (cpuAddress)
        {
        case CpuMemory.kSpriteDmaReg: // $4014
            result = m_spriteDmaRegister;
            break

        case CpuMemory.kControllerPort1: // $4016
            result = m_controllerPorts.HandleCpuRead(cpuAddress: cpuAddress)
            break
            
        case 0x4015: // $4015
            result = m_apu.HandleCpuRead(cpuAddress: cpuAddress)
            break
            
        case CpuMemory.kControllerPort2: // $4017
            result = m_controllerPorts.HandleCpuRead(cpuAddress: cpuAddress)
            break

        default:
            
            //NSLog("TODOOOO")
            result = m_apu.HandleCpuRead(cpuAddress: cpuAddress)
            break
        }
        
        return result
    }
    
    func SpriteDmaTransfer(_ cpuAddress:UInt16)
    {
        //for (uint16 i = 0; i < 256; ++i) //@TODO: Use constant for 256 (kSpriteMemorySize?)
        for i in 0...255
        {
            let value:UInt8 = m_cpuMemoryBus!.Read(cpuAddress + UInt16(i))
            m_cpuMemoryBus!.Write(cpuAddress: CpuMemory.kPpuSprRamIoReg, value: value);
        }

        // While DMA transfer occurs, the memory bus is in use, preventing CPU from fetching memory
        m_cycles += 512
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
            break;

        case CpuMemory.kControllerPort1: // $4016
            //NSLog("TODOOOO")
            m_controllerPorts.HandleCpuWrite(cpuAddress: cpuAddress, value:value)
            break

        case CpuMemory.kControllerPort2: // $4017 For writes, this address is mapped to the APU!
            //NSLog("TODOOOO")
            break
        default:
            m_apu.HandleCpuWrite(cpuAddress: cpuAddress, value: value)
            break
        }
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
            //_opCodeTableEx[item.opCode] = item
            
            //g_opCodeTableEx = NSDictionary.init()
        }
        
        NSLog("===OpTables end===")
    }
    
    
    var m_cycles:UInt32 = 0
    var m_totalCycles:UInt32 = 0
    var m_opCodeEntry:OpCodeEntry!
    
    var g_opCodeTableEx: NSDictionary = [0:1,1:2,2:3]
    
    var g_opCodeTable:[UInt8:OpCodeEntry] = [:]
    
    func Execute(_ cpuCyclesElapsed:inout UInt32)
    {
        m_cycles = 0
        ExecutePendingInterrupts()// Handle when interrupts are called "between" CPU updates (e.g. PPU sends NMI)
        
        let opCode:UInt8 = Read8(PC)
        m_opCodeEntry = g_opCodeTable[opCode]

        assert((m_opCodeEntry != nil))
        
        UpdateOperandAddress()

        ExecuteInstruction()
        
        ExecutePendingInterrupts() // Handle when instruction (memory read) causes interrupt
    
        cpuCyclesElapsed = m_cycles
    }
    
    func Read16(_ address:UInt16)->UInt16
    {
        return TO16(m_cpuMemoryBus!.Read(address)) | (TO16(m_cpuMemoryBus!.Read(address + 1)) << 8)
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
            Push16(PC)
            PushProcessorStatus(false)
            P.Clear(BrkExecuted)
            P.Set(IrqDisabled)
            PC = Read16(CpuMemory.kIrqVector)
            m_cycles += UInt32(kInterruptCycles)
            m_pendingIrq = false
        }
    }
    
    func Read8Ex(_ address:UInt16,readValue:inout UInt8)
    {
        return m_cpuMemoryBus!.ReadEx(address,readValue:&readValue)
    }
    
    func Read8(_ address:UInt16)->UInt8
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
            
            //let offsetSigned = ToInt(Read8(PC+1))
            //m_operandAddress = UInt16(Int(PC) + Int(m_opCodeEntry!.numBytes) + Int(offsetSigned))
            
            
            let offset = ToInt(Read8(PC+1)) // Signed offset in [-128,127]
            //m_operandAddress = UInt16( Int(PC) + Int(m_opCodeEntry.numBytes) + offset)
            
            if(offset>0)
            {
                m_operandAddress = PC + UInt16(m_opCodeEntry.numBytes) + UInt16(abs(offset))
            }
            else
            {
                m_operandAddress = PC + UInt16(m_opCodeEntry.numBytes) - UInt16(abs(offset))
            }
            /*
            let offsetSigned = ToInt(Read8(PC+1))
            
            
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
            */
            //Origin code
            //const int8 offset = Read8(PC+1); // Signed offset in [-128,127]
            //m_operandAddress = PC + m_opCodeEntry->numBytes + offset;
            //Origin code end
            
            break

        case AddressMode.ZeroPg:
            m_operandAddress = TO16(Read8(PC+1))
            break

        case AddressMode.ZPIdxX:
            
            let plus_result = UInt16(Read8(PC+1)) + UInt16(X)
            m_operandAddress = plus_result & 0x00FF // Wrap around zero-page boundary
                
            //m_operandAddress = TO16((Read8(PC+1) + X)) & 0x00FF // Wrap around zero-page boundary
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
            if(basePage != GetPageAddress(m_operandAddress))
            {
                m_operandReadCrossedPage = true
            }
            else
            {
                m_operandReadCrossedPage = false
            }
            //m_operandReadCrossedPage = basePage != GetPageAddress(m_operandAddress)
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
            let high:UInt16 = TO16(UInt8(low + 1)) & 0x00FF // Wrap high byte around zero page
            m_operandAddress = TO16(Read8(low)) | TO16(Read8(high)) << 8
            break

        case AddressMode.IndIdx:
            let low:UInt16 = TO16(Read8(PC+1)) // Zero page low byte of operand address
            let high:UInt16 = (low + 1) & 0x00FF // Wrap high byte around zero page
            let baseAddress:UInt16 = (TO16(Read8(low)) | TO16(Read8(high)) << 8)
            let basePage:UInt16 = GetPageAddress(baseAddress)
            m_operandAddress = baseAddress + UInt16(Y)
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
            let result = Int(A) - Int(memValue)
            P.Set(bits: Negative, enabled: CalcNegativeFlag(result))
            P.Set(bits: Zero, enabled: CalcZeroFlag(result))
            P.Set(bits: Carry, enabled: CalcCarryFlag(result))
            break

        case OpCodeEntryTtype.CPX: // CPX Compare Memory and Index X
            let memValue = GetMemValue()
            let result = Int(X) - Int(memValue)
            P.Set(bits: Negative, enabled: CalcNegativeFlag(result))
            P.Set(bits: Zero, enabled: CalcZeroFlag(result))
            P.Set(bits: Carry, enabled: CalcCarryFlag(result))
            break

        case OpCodeEntryTtype.CPY: // CPY Compare memory and index Y
            let memValue = GetMemValue()
            let result = Int(Y) - Int(memValue)
            P.Set(bits: Negative, enabled: CalcNegativeFlag(result))
            P.Set(bits: Zero, enabled: CalcZeroFlag(result))
            P.Set(bits: Carry, enabled: CalcCarryFlag(result))
            break

        case OpCodeEntryTtype.DEC: // Decrement memory by one
            let memValue = GetMemValue()
            let result = Int(memValue) - Int(1)
            P.Set(bits: Negative, enabled: CalcNegativeFlag(result))
            let newMemValue = IntToUint(result)
            SetMemValue(newMemValue)
            P.Set(bits: Zero, enabled: CalcZeroFlag(newMemValue))
            break

        case OpCodeEntryTtype.DEX: // Decrement index X by one
            let result = Int(X) - Int(1)
            P.Set(bits: Negative, enabled: CalcNegativeFlag(result))
            X = IntToUint(result)
            P.Set(bits: Zero, enabled: CalcZeroFlag(X))
            break

        case OpCodeEntryTtype.DEY: // Decrement index Y by one
            let result = Int(Y) - Int(1)
            P.Set(bits: Negative, enabled: CalcNegativeFlag(result))
            Y = IntToUint(result)
            P.Set(bits: Zero, enabled: CalcZeroFlag(Y))
            break

        case OpCodeEntryTtype.EOR: // "Exclusive-Or" memory with accumulator
            A = A ^ GetMemValue()
            P.Set(bits: Negative, enabled: CalcNegativeFlag(A))
            P.Set(bits: Zero, enabled: CalcZeroFlag(A))
            break

        case OpCodeEntryTtype.INC: // Increment memory by one
            let memValue = GetMemValue()
            let result = Int(memValue) + Int(1)
            P.Set(bits: Negative, enabled: CalcNegativeFlag(result))
            let newMemValue = IntToUint(result)
            SetMemValue(newMemValue)
            P.Set(bits: Zero, enabled: CalcZeroFlag(newMemValue))
            break

        case OpCodeEntryTtype.INX: // Increment Index X by one
            let result = Int(X) + Int(1)
            P.Set(bits: Negative, enabled: CalcNegativeFlag(result))
            X = IntToUint(result)
            P.Set(bits: Zero, enabled: CalcZeroFlag(X))
            break

        case OpCodeEntryTtype.INY: // Increment Index Y by one
            let result = Int(Y) + Int(1)
            P.Set(bits: Negative, enabled: CalcNegativeFlag(result))
            
            Y = IntToUint(result)
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
            
            let value = GetAccumOrMemValue()
            let result = (value >> 1) | (P.Test01(Carry) << 7)
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

        m_cycles += UInt32(cycles)
        
        // Move to next instruction
        PC = nextPC
        
        //NSLog("PC->%d",PC)
    }
    
    
    var PC:UInt16 = 0        // Program counter
    var SP:UInt8 = 0        // Stack pointer
    var A:UInt8 = 0       // Accumulator
    var X:UInt8 = 0     // X register
    var Y:UInt8 = 0        // Y register
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
        P.Set(StatusFlag.IrqDisabled.rawValue)

        // Entry point is located at the Reset interrupt location
        PC = Read16(CpuMemory.kResetVector)

        m_cycles = 0
        m_pendingNmi = false
        m_pendingIrq = false

        //m_controllerPorts.Reset();
    }

    
    func GetMemValue()->UInt8
    {
        let result = Read8(m_operandAddress)
        return result
    }
    
    func CalcNegativeFlag(_ v:UInt16)->UInt8
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
    func CalcNegativeFlag(_ v:Int)->UInt8
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
    func CalcNegativeFlag(_ v:UInt8)->UInt8
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
    func CalcZeroFlag(_ v:UInt16)->UInt8
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
    
    func CalcCarryFlag(_ v:Int)->UInt8
    {
        if(v >= 0)
        {
            return 1
        }
        else
        {
            return 0
        }
    }
    
    func IntToUint(_ v:Int)->UInt8
    {
        var inputValue = v
        if(inputValue >= 256)
        {
            inputValue -= 256
        }
        if(inputValue < 0)
        {
            inputValue = 256 + inputValue
        }
        
        return UInt8(inputValue)
    }
    
    func CalcZeroFlag(_ v:Int)->UInt8
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
    
    func CalcZeroFlag(_ v:UInt8)->UInt8
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
        // return ((uint16)a ^ r) & ((uint16)b ^ r) & 0x0080;
        
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
    
    func Push16(_ value:UInt16)
    {
        Push8(UInt8(value >> 8))
        Push8(UInt8(value & 0x00FF))
    }
    
    func Push8(_ value:UInt8)
    {
        Write8(address: CpuMemory.kStackBase + UInt16(SP), value: value);
        
        SP = SP - 1
        
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
    
    func GetBranchOrJmpLocation()->UInt16
    {
        assert(IsJmpOrBranchOperand(m_opCodeEntry!.addrMode.rawValue))
        return m_operandAddress
    }
    
    //func ToInt(_ x : UInt8) -> Int16 {
    //      return Int16(Int8(bitPattern: x))
    //}
    
    func ToInt(_ x : UInt8) -> Int {
          return Int(Int8(bitPattern: x))
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

        if (!P.Test(StatusFlag.IrqDisabled.rawValue))
        {
            m_pendingIrq = true
        }
    }

}
