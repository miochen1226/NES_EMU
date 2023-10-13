//
//  Cpu.swift
//  NES_EMU
//
//  Created by mio on 2021/8/8.
//

import Foundation


class CpuBase : Codable {
    
    init() {
        
    }
    var PC:UInt16 = 0        // Program counter
    var SP:UInt8 = 0        // Stack pointer
    var A:UInt8 = 0       // Accumulator
    var X:UInt8 = 0     // X register
    var Y:UInt8 = 0        // Y register
    var P: Bitfield8 = Bitfield8()   // Processor status (flags) TODO
    var pendingNmi:Bool = false
    var pendingIrq:Bool = false
    
    var spriteDmaRegister:UInt8 = 0
    
    var cycles:UInt32 = 0
    var totalCycles:UInt32 = 0
    
    enum CodingKeys: String, CodingKey {
        case PC
        case SP
        case A
        case X
        case Y
        case P
        case pendingNmi
        case pendingIrq
        case spriteDmaRegister
        case cycles
        case totalCycles
    }
    
    required init(from decoder: Decoder) throws {
        print("Cpu.decoder")
        let values = try decoder.container(keyedBy: CodingKeys.self)
        PC = try values.decode(UInt16.self, forKey: .PC)
        SP = try values.decode(UInt8.self, forKey: .SP)
        A = try values.decode(UInt8.self, forKey: .A)
        X = try values.decode(UInt8.self, forKey: .X)
        Y = try values.decode(UInt8.self, forKey: .Y)
        P = try values.decode(Bitfield8.self, forKey: .P)
        
        pendingNmi = try values.decode(Bool.self, forKey: .pendingNmi)
        pendingIrq = try values.decode(Bool.self, forKey: .pendingIrq)
        
        cycles = try values.decode(UInt32.self, forKey: .cycles)
        totalCycles = try values.decode(UInt32.self, forKey: .totalCycles)
    }
    
    func encode(to encoder: Encoder) throws {
        print("Cpu.encoder")
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(PC, forKey: .PC)
        try container.encode(SP, forKey: .SP)
        try container.encode(A, forKey: .A)
        try container.encode(X, forKey: .X)
        try container.encode(Y, forKey: .Y)
        
        try container.encode(P, forKey: .P)
        
        try container.encode(pendingNmi, forKey: .pendingNmi)
        try container.encode(pendingIrq, forKey: .pendingIrq)
        
        try container.encode(cycles, forKey: .cycles)
        try container.encode(totalCycles, forKey: .totalCycles)
    }
}


class Cpu: CpuBase, ICpu {
    func setApu(apu: Apu) {
        self.apu = apu
    }
    
    func setControllerPorts(controllerPorts: ControllerPorts) {
        self.controllerPorts = controllerPorts
    }
    
    func handleCpuRead(_ cpuAddress: UInt16) -> UInt8 {
        var result:UInt8 = 0

        switch (cpuAddress)
        {
        case CpuMemory.kSpriteDmaReg: // $4014
            result = spriteDmaRegister
            break

        case CpuMemory.kControllerPort1: // $4016
            result = controllerPorts.handleCpuRead(cpuAddress: cpuAddress)
            break
            
        case 0x4015: // $4015
            result = apu.HandleCpuRead(cpuAddress: cpuAddress)
            break
            
        case CpuMemory.kControllerPort2: // $4017
            result = controllerPorts.handleCpuRead(cpuAddress: cpuAddress)
            break
        default:
            result = apu.HandleCpuRead(cpuAddress: cpuAddress)
            break
        }
        return result
    }
    
    func SpriteDmaTransfer(_ cpuAddress:UInt16)
    {
        for i in 0 ..< 256
        {
            let value:UInt8 = cpuMemoryBus!.read(cpuAddress + UInt16(i))
            cpuMemoryBus!.write(cpuAddress: CpuMemory.kPpuSprRamIoReg, value: value)
        }

        // While DMA transfer occurs, the memory bus is in use, preventing CPU from fetching memory
        cycles += 512
    }
    
    func handleCpuWrite(_ cpuAddress:UInt16, value:UInt8)
    {
        switch (cpuAddress)
        {
        case CpuMemory.kSpriteDmaReg: // $4014
            
            // Initiate a DMA transfer from the input page to sprite ram.
            spriteDmaRegister = value
            let spriteDmaRegister = tO16(spriteDmaRegister)
            let srcCpuAddress:UInt16 = spriteDmaRegister * 0x100
            // Note: we perform the full DMA transfer right here instead of emulating the transfers over multiple frames.
            // If we need to do it right, see http://wiki.nesdev.com/w/index.php/PPU_programmer_reference#DMA
            SpriteDmaTransfer(srcCpuAddress)
            break

        case CpuMemory.kControllerPort1: // $4016
            controllerPorts.handleCpuWrite(cpuAddress: cpuAddress, value:value)
            break

        case CpuMemory.kControllerPort2: // $4017 For writes, this address is mapped to the APU!
            break
        default:
            apu.HandleCpuWrite(cpuAddress: cpuAddress, value: value)
            break
        }
    }
    
    func initialize(cpuMemoryBus: CpuMemoryBus) {
        self.cpuMemoryBus = cpuMemoryBus
        let array = OpCodeTable.GetOpCodeTable()
        opCodeTable.removeAll()
        for item in array {
            opCodeTable[item.opCode] = item
        }
    }
    
    func execute(_ cpuCyclesElapsed: inout UInt32) {
        cycles = 0
        executePendingInterrupts()// Handle when interrupts are called "between" CPU updates (e.g. PPU sends NMI)
        
        //print(PC)
        let opCode:UInt8 = read8(PC)
        opCodeEntry = opCodeTable[opCode]

        if opCodeEntry == nil {
            let opCode:UInt8 = read8(PC)
            print("opCode->" + String(opCode))
        }
        assert((opCodeEntry != nil))
        
        updateOperandAddress()

        executeInstruction()
        
        executePendingInterrupts() // Handle when instruction (memory read) causes interrupt
    
        cpuCyclesElapsed = cycles
        totalCycles += 1
    }
    
    func read16(_ address: UInt16) -> UInt16 {
        return tO16(cpuMemoryBus!.read(address)) | (tO16(cpuMemoryBus!.read(address + 1)) << 8)
    }
    
    func executePendingInterrupts() {
        let kInterruptCycles = 7
        if pendingNmi {
            push16(PC)
            pushProcessorStatus(false)
            P.clear(CpuRegDef.BrkExecuted)
            P.set(CpuRegDef.IrqDisabled)
            PC = read16(CpuMemory.kNmiVector)
            
            //@HACK: *2 here fixes Battletoads not loading levels, and also Marble Madness
            // not rendering start of level text box correctly. This is likely due to discrepencies
            // in cycle timing for when PPU signals an NMI and CPU handles it.
            cycles = cycles + UInt32((kInterruptCycles * 2))
            
            pendingNmi = false
        }
        else if pendingIrq {
            push16(PC)
            pushProcessorStatus(false)
            P.clear(CpuRegDef.BrkExecuted)
            P.set(CpuRegDef.IrqDisabled)
            PC = read16(CpuMemory.kIrqVector)
            cycles += UInt32(kInterruptCycles)
            pendingIrq = false
        }
    }
    
    func read8(_ address: UInt16) -> UInt8 {
        return cpuMemoryBus!.read(address)
    }
    
    func getPageAddress(_ address: UInt16) -> UInt16 {
        return (address & 0xFF00)
    }
    
    func updateOperandAddress() {
        operandReadCrossedPage = false

        switch opCodeEntry!.addrMode {
        case AddressMode.Immedt:
            operandAddress = PC + 1 // Set to address of immediate value in code segment
            break

        case AddressMode.Implid:
            break

        case AddressMode.Accumu:
            break

        case AddressMode.Relatv: // For conditional branch instructions
            let offset = toInt(read8(PC+1)) // Signed offset in [-128,127]
            
            if offset > 0 {
                operandAddress = PC + UInt16(opCodeEntry.numBytes) + UInt16(abs(offset))
            }
            else {
                operandAddress = PC + UInt16(opCodeEntry.numBytes) - UInt16(abs(offset))
            }
            //Origin code
            //const int8 offset = read8(PC+1); // Signed offset in [-128,127]
            //operandAddress = PC + opCodeEntry->numBytes + offset;
            //Origin code end
            break
        case AddressMode.ZeroPg:
            operandAddress = tO16(read8(PC+1))
            break
        case AddressMode.ZPIdxX:
            let plus_result = UInt16(read8(PC+1)) + UInt16(X)
            operandAddress = plus_result & 0x00FF // Wrap around zero-page boundary
            break

        case AddressMode.ZPIdxY:
            operandAddress = tO16((read8(PC+1) + Y)) & 0x00FF // Wrap around zero-page boundary
            break
        case AddressMode.Absolu:
            operandAddress = read16(PC+1)
            break
        case AddressMode.AbIdxX:
            let baseAddress = read16(PC+1)
            let basePage = getPageAddress(baseAddress)
            operandAddress = baseAddress + UInt16(X)
            operandReadCrossedPage = basePage != getPageAddress(operandAddress)
            break
        case AddressMode.AbIdxY:
            let baseAddress = read16(PC+1)
            let basePage = getPageAddress(baseAddress)
            operandAddress = baseAddress + UInt16(Y)
            if basePage != getPageAddress(operandAddress) {
                operandReadCrossedPage = true
            }
            else {
                operandReadCrossedPage = false
            }
            //operandReadCrossedPage = basePage != getPageAddress(operandAddress)
            break

        case AddressMode.Indrct: // for JMP only
            let low = read16(PC+1)
            // Handle the 6502 bug for when the low-byte of the effective address is FF,
            // in which case the 2nd byte read does not correctly cross page boundaries.
            // The bug is that the high byte does not change.
            let high = (low & 0xFF00) | ((low + 1) & 0x00FF)

            operandAddress = tO16(read8(low)) | tO16(read8(high)) << 8
            
            break

        case AddressMode.IdxInd:
            let low:UInt16 = tO16((read8(PC+1) + X)) & 0x00FF // Zero page low byte of operand address, wrap around zero page
            let high:UInt16 = tO16(UInt8(low + 1)) & 0x00FF // Wrap high byte around zero page
            operandAddress = tO16(read8(low)) | tO16(read8(high)) << 8
            break

        case AddressMode.IndIdx:
            let low:UInt16 = tO16(read8(PC+1)) // Zero page low byte of operand address
            let high:UInt16 = (low + 1) & 0x00FF // Wrap high byte around zero page
            let baseAddress:UInt16 = (tO16(read8(low)) | tO16(read8(high)) << 8)
            let basePage:UInt16 = getPageAddress(baseAddress)
            operandAddress = baseAddress + UInt16(Y)
            operandReadCrossedPage = basePage != getPageAddress(operandAddress)
            
            //Original code
            //const uint16 low = tO16(read8(PC+1)); // Zero page low byte of operand address
            //const uint16 high = tO16(low + 1) & 0x00FF; // Wrap high byte around zero page
            //const uint16 baseAddress = (tO16(read8(low)) | tO16(read8(high)) << 8);
            //const uint16 basePage = getPageAddress(baseAddress);
            //operandAddress = baseAddress + Y;
            //operandReadCrossedPage = basePage != getPageAddress(operandAddress);
            break
        }
        
        //let pc = PC
        //let opa = operandAddress
        //NSLog("%d,%d",pc,opa)
    }
    
    func executeInstruction() {
        // By default, next instruction is after current, but can also be changed by a branch or jump
        var nextPC = UInt16(PC + UInt16(opCodeEntry!.numBytes))
        
        var branchTaken = false

        switch (opCodeEntry!.opCodeName)
        {
        case OpCodeEntryTtype.ADC: // Add memory to accumulator with carry
            // Operation:  A + M + C -> A, C
            let value = getMemValue()
            let result = tO16(A) + tO16(value) + tO16(P.test01(CpuRegDef.Carry))
            P.set(bits: CpuRegDef.Negative, enabled: calcNegativeFlag(result))
            P.set(bits: CpuRegDef.Zero, enabled: calcZeroFlag(result))
            P.set(bits: CpuRegDef.Carry, enabled: calcCarryFlag(result))
            P.set(bits: CpuRegDef.Overflow, enabled: calcOverflowFlag(a: A, b: value, r: result))
            A = tO8(result)
            
            break

        case OpCodeEntryTtype.AND: // "AND" memory with accumulator
            A &= getMemValue()
            P.set(bits: CpuRegDef.Negative, enabled: calcNegativeFlag(A))
            P.set(bits: CpuRegDef.Zero, enabled: calcZeroFlag(A))
            break

        case OpCodeEntryTtype.ASL: // Shift Left One Bit (Memory or Accumulator)
            
            let result = tO16(getAccumOrMemValue()) << 1
            P.set(bits: CpuRegDef.Negative, enabled: calcNegativeFlag(result))
            P.set(bits: CpuRegDef.Zero, enabled: calcZeroFlag(result))
            P.set(bits: CpuRegDef.Carry, enabled: calcCarryFlag(result))
            setAccumOrMemValue(tO8(result))
            
            break

        case OpCodeEntryTtype.BCC: // Branch on Carry Clear
            if !P.test(CpuRegDef.Carry) {
                nextPC = getBranchOrJmpLocation()
                branchTaken = true
            }
            break

        case OpCodeEntryTtype.BCS: // Branch on Carry Set
            if P.test(CpuRegDef.Carry) {
                nextPC = getBranchOrJmpLocation()
                branchTaken = true
            }
            break

        case OpCodeEntryTtype.BEQ: // Branch on result zero (equal means compare difference is 0)
            if P.test(CpuRegDef.Zero) {
                nextPC = getBranchOrJmpLocation()
                branchTaken = true
            }
            break

        case OpCodeEntryTtype.BIT: // Test bits in memory with accumulator
            
            let memValue = getMemValue()
            let result = A & getMemValue()
            P.setValue( (P.value() & 0x3F) | (memValue & 0xC0) ) // Copy bits 6 and 7 of mem value to status register
            P.set(bits: CpuRegDef.Zero, enabled: calcZeroFlag(result))
            break
        case OpCodeEntryTtype.BMI: // Branch on result minus
            if P.test(CpuRegDef.Negative) {
                nextPC = getBranchOrJmpLocation()
                branchTaken = true
            }
            break
        case OpCodeEntryTtype.BNE:  // Branch on result non-zero
            if !P.test(CpuRegDef.Zero) {
                nextPC = getBranchOrJmpLocation()
                branchTaken = true
            }
            break
        case OpCodeEntryTtype.BPL: // Branch on result plus
            if !P.test(CpuRegDef.Negative) {
                nextPC = getBranchOrJmpLocation()
                branchTaken = true
            }
            break
        case OpCodeEntryTtype.BRK: // Force break (Forced Interrupt PC + 2 toS P toS) (used with RTI)
            
            // Note that BRK is weird in that the instruction is 1 byte, but the return address
            // we store is 2 bytes after the instruction, so the byte after BRK will be skipped
            // upon return (RTI). Usually an NOP is inserted after a BRK for this reason.
            let returnAddr = PC + 2
            push16(returnAddr)
            pushProcessorStatus(true)
            P.set(CpuRegDef.IrqDisabled) // Disable hardware IRQs
            nextPC = read16(CpuMemory.kIrqVector)
            break
        case OpCodeEntryTtype.BVC: // Branch on Overflow Clear
            if !P.test(CpuRegDef.Overflow) {
                nextPC = getBranchOrJmpLocation()
                branchTaken = true
            }
            break
        case OpCodeEntryTtype.BVS: // Branch on Overflow Set
            if P.test(CpuRegDef.Overflow) {
                nextPC = getBranchOrJmpLocation()
                branchTaken = true
            }
            break
        case OpCodeEntryTtype.CLC: // CLC Clear carry flag
            P.clear(CpuRegDef.Carry)
            break

        case OpCodeEntryTtype.CLD: // CLD Clear decimal mode
            P.clear(CpuRegDef.Decimal)
            break

        case OpCodeEntryTtype.CLI: // CLI Clear interrupt disable bit
            P.clear(CpuRegDef.IrqDisabled)
            break

        case OpCodeEntryTtype.CLV: // CLV Clear overflow flag
            P.clear(CpuRegDef.Overflow)
            break

        case OpCodeEntryTtype.CMP: // CMP Compare memory and accumulator
            let memValue = getMemValue()
            let result = Int(A) - Int(memValue)
            P.set(bits: CpuRegDef.Negative, enabled: calcNegativeFlag(result))
            P.set(bits: CpuRegDef.Zero, enabled: calcZeroFlag(result))
            P.set(bits: CpuRegDef.Carry, enabled: calcCarryFlag(result))
            break

        case OpCodeEntryTtype.CPX: // CPX Compare Memory and Index X
            let memValue = getMemValue()
            let result = Int(X) - Int(memValue)
            P.set(bits: CpuRegDef.Negative, enabled: calcNegativeFlag(result))
            P.set(bits: CpuRegDef.Zero, enabled: calcZeroFlag(result))
            P.set(bits: CpuRegDef.Carry, enabled: calcCarryFlag(result))
            break

        case OpCodeEntryTtype.CPY: // CPY Compare memory and index Y
            let memValue = getMemValue()
            let result = Int(Y) - Int(memValue)
            P.set(bits: CpuRegDef.Negative, enabled: calcNegativeFlag(result))
            P.set(bits: CpuRegDef.Zero, enabled: calcZeroFlag(result))
            P.set(bits: CpuRegDef.Carry, enabled: calcCarryFlag(result))
            break

        case OpCodeEntryTtype.DEC: // Decrement memory by one
            let memValue = getMemValue()
            let result = Int(memValue) - Int(1)
            P.set(bits: CpuRegDef.Negative, enabled: calcNegativeFlag(result))
            let newMemValue = intToUint(result)
            setMemValue(newMemValue)
            P.set(bits: CpuRegDef.Zero, enabled: calcZeroFlag(newMemValue))
            break

        case OpCodeEntryTtype.DEX: // Decrement index X by one
            let result = Int(X) - Int(1)
            P.set(bits: CpuRegDef.Negative, enabled: calcNegativeFlag(result))
            X = intToUint(result)
            P.set(bits: CpuRegDef.Zero, enabled: calcZeroFlag(X))
            break

        case OpCodeEntryTtype.DEY: // Decrement index Y by one
            let result = Int(Y) - Int(1)
            P.set(bits: CpuRegDef.Negative, enabled: calcNegativeFlag(result))
            Y = intToUint(result)
            P.set(bits: CpuRegDef.Zero, enabled: calcZeroFlag(Y))
            break

        case OpCodeEntryTtype.EOR: // "Exclusive-Or" memory with accumulator
            A = A ^ getMemValue()
            P.set(bits: CpuRegDef.Negative, enabled: calcNegativeFlag(A))
            P.set(bits: CpuRegDef.Zero, enabled: calcZeroFlag(A))
            break

        case OpCodeEntryTtype.INC: // Increment memory by one
            let memValue = getMemValue()
            let result = Int(memValue) + Int(1)
            P.set(bits: CpuRegDef.Negative, enabled: calcNegativeFlag(result))
            let newMemValue = intToUint(result)
            setMemValue(newMemValue)
            P.set(bits: CpuRegDef.Zero, enabled: calcZeroFlag(newMemValue))
            break

        case OpCodeEntryTtype.INX: // Increment Index X by one
            let result = Int(X) + Int(1)
            P.set(bits: CpuRegDef.Negative, enabled: calcNegativeFlag(result))
            X = intToUint(result)
            P.set(bits: CpuRegDef.Zero, enabled: calcZeroFlag(X))
            break

        case OpCodeEntryTtype.INY: // Increment Index Y by one
            let result = Int(Y) + Int(1)
            P.set(bits: CpuRegDef.Negative, enabled: calcNegativeFlag(result))
            
            Y = intToUint(result)
            P.set(bits: CpuRegDef.Zero, enabled: calcZeroFlag(Y))
            break

        case OpCodeEntryTtype.JMP: // Jump to new location
            nextPC = getBranchOrJmpLocation()
            break

        case OpCodeEntryTtype.JSR: // Jump to subroutine (used with RTS)
            
            // JSR actually pushes address of the next instruction - 1.
            // RTS jumps to popped value + 1.
            let returnAddr:UInt16 = PC + UInt16(opCodeEntry!.numBytes) - 1
            push16(returnAddr)
            nextPC = getBranchOrJmpLocation()
            break

        case OpCodeEntryTtype.LDA: // Load accumulator with memory
            A = getMemValue()
            P.set(bits: CpuRegDef.Negative, enabled: calcNegativeFlag(A))
            P.set(bits: CpuRegDef.Zero, enabled: calcZeroFlag(A))
            break

        case OpCodeEntryTtype.LDX: // Load index X with memory
            X = getMemValue()
            P.set(bits: CpuRegDef.Negative, enabled: calcNegativeFlag(X))
            P.set(bits: CpuRegDef.Zero, enabled: calcZeroFlag(X))
            break

        case OpCodeEntryTtype.LDY: // Load index Y with memory
            Y = getMemValue()
            P.set(bits: CpuRegDef.Negative, enabled: calcNegativeFlag(Y))
            P.set(bits: CpuRegDef.Zero, enabled: calcZeroFlag(Y))
            break

        case OpCodeEntryTtype.LSR: // Shift right one bit (memory or accumulator)
            let value = getAccumOrMemValue()
            let result = value >> 1
            P.set(bits: CpuRegDef.Carry, enabled: value & 0x01) // Will get shifted into carry
            P.set(bits: CpuRegDef.Zero, enabled: calcZeroFlag(result))
            P.clear(CpuRegDef.Negative) // 0 is shifted into sign bit position
            setAccumOrMemValue(result)
            break

        case OpCodeEntryTtype.NOP: // No Operation (2 cycles)
            break

        case OpCodeEntryTtype.ORA: // "OR" memory with accumulator
            A |= getMemValue()
            P.set(bits: CpuRegDef.Negative, enabled: calcNegativeFlag(A))
            P.set(bits: CpuRegDef.Zero, enabled: calcZeroFlag(A))
            break

        case OpCodeEntryTtype.PHA: // Push accumulator on stack
            push8(A)
            break

        case OpCodeEntryTtype.PHP: // Push processor status on stack
            pushProcessorStatus(true)
            break

        case OpCodeEntryTtype.PLA: // Pull accumulator from stack
            A = pop8()
            P.set(bits: CpuRegDef.Negative, enabled: calcNegativeFlag(A))
            P.set(bits: CpuRegDef.Zero, enabled: calcZeroFlag(A))
            break

        case OpCodeEntryTtype.PLP: // Pull processor status from stack
            popProcessorStatus()
            break

        case OpCodeEntryTtype.ROL: // Rotate one bit left (memory or accumulator)
            let result = (tO16(getAccumOrMemValue()) << 1) | tO16(P.test01(CpuRegDef.Carry))
            P.set(bits: CpuRegDef.Carry, enabled: calcCarryFlag(result))
            P.set(bits: CpuRegDef.Negative, enabled: calcNegativeFlag(result))
            P.set(bits: CpuRegDef.Zero, enabled: calcZeroFlag(result))
            setAccumOrMemValue(tO8(result))
            break

        case OpCodeEntryTtype.ROR: // Rotate one bit right (memory or accumulator)
            let value = getAccumOrMemValue()
            let result = (value >> 1) | (P.test01(CpuRegDef.Carry) << 7)
            P.set(bits: CpuRegDef.Carry, enabled: value & 0x01)
            P.set(bits: CpuRegDef.Negative, enabled: calcNegativeFlag(result))
            P.set(bits: CpuRegDef.Zero, enabled: calcZeroFlag(result))
            setAccumOrMemValue(result)
            break

        case OpCodeEntryTtype.RTI: // Return from interrupt (used with BRK, Nmi or Irq)
            popProcessorStatus()
            nextPC = Pop16()
            break

        case OpCodeEntryTtype.RTS: // Return from subroutine (used with JSR)
            nextPC = Pop16() + 1
            break

        case OpCodeEntryTtype.SBC: // Subtract memory from accumulator with borrow
            
            // Operation:  A - M - C -> A

            // Can't simply negate mem value because that results in two's complement
            // and we want to perform the bitwise add ourself
            let value = getMemValue() ^ 0xFF

            let result = tO16(A) + tO16(value) + tO16(P.test01(CpuRegDef.Carry))
            P.set(bits: CpuRegDef.Negative, enabled: calcNegativeFlag(result))
            P.set(bits: CpuRegDef.Zero, enabled: calcZeroFlag(result))
            P.set(bits: CpuRegDef.Carry, enabled: calcCarryFlag(result))
            P.set(bits: CpuRegDef.Overflow, enabled: calcOverflowFlag(a: A, b: value, r: result))
            A = tO8(result)
            
            break

        case OpCodeEntryTtype.SEC: // Set carry flag
            P.set(CpuRegDef.Carry)
            break

        case OpCodeEntryTtype.SED: // Set decimal mode
            P.set(CpuRegDef.Decimal)
            break

        case OpCodeEntryTtype.SEI: // Set interrupt disable status
            P.set(CpuRegDef.IrqDisabled)
            break

        case OpCodeEntryTtype.STA: // Store accumulator in memory
            setMemValue(A)
            break

        case OpCodeEntryTtype.STX: // Store index X in memory
            setMemValue(X)
            break

        case OpCodeEntryTtype.STY: // Store index Y in memory
            setMemValue(Y)
            break

        case OpCodeEntryTtype.TAX: // Transfer accumulator to index X
            X = A
            P.set(bits: CpuRegDef.Negative, enabled: calcNegativeFlag(X))
            P.set(bits: CpuRegDef.Zero, enabled: calcZeroFlag(X))
            break

        case OpCodeEntryTtype.TAY: // Transfer accumulator to index Y
            Y = A
            P.set(bits: CpuRegDef.Negative, enabled: calcNegativeFlag(Y))
            P.set(bits: CpuRegDef.Zero, enabled: calcZeroFlag(Y))
            break

        case OpCodeEntryTtype.TSX: // Transfer stack pointer to index X
            X = SP
            P.set(bits: CpuRegDef.Negative, enabled: calcNegativeFlag(X))
            P.set(bits: CpuRegDef.Zero, enabled: calcZeroFlag(X))
            break

        case OpCodeEntryTtype.TXA: // Transfer index X to accumulator
            A = X
            P.set(bits: CpuRegDef.Negative, enabled: calcNegativeFlag(A))
            P.set(bits: CpuRegDef.Zero, enabled: calcZeroFlag(A))
            break

        case OpCodeEntryTtype.TXS: // Transfer index X to stack pointer
            SP = X
            break

        case OpCodeEntryTtype.TYA: // Transfer index Y to accumulator
            A = Y
            P.set(bits: CpuRegDef.Negative, enabled: calcNegativeFlag(A))
            P.set(bits: CpuRegDef.Zero, enabled: calcZeroFlag(A))
            break
        }

        // Compute cycles for instruction
        
        var cyclesOfOp = opCodeEntry!.numCycles

        // Some instructions take an extra cycle when reading operand across page boundary
        if operandReadCrossedPage {
            cyclesOfOp = cyclesOfOp + opCodeEntry!.pageCrossCycles
        }

        // Extra cycle when branch is taken
        if branchTaken {
            cyclesOfOp = cyclesOfOp + 1

            // And extra cycle when branching to a different page
            if getPageAddress(PC) != getPageAddress(nextPC) {
                cyclesOfOp = cyclesOfOp + 1
            }
        }

        self.cycles += UInt32(cyclesOfOp)
        
        // Move to next instruction
        PC = nextPC
        
        //NSLog("PC->%d",PC)
    }
    
    func reset() {
        // See http://wiki.nesdev.com/w/index.php/CPU_power_up_state
        A = 0
        X = 0
        Y = 0
        SP = 0xFF // Should be FD, but for improved compatibility set to FF
        
        P.clearAll()
        P.set(CpuRegDef.IrqDisabled)

        // Entry point is located at the Reset interrupt location
        PC = read16(CpuMemory.kResetVector)

        cycles = 0
        pendingNmi = false
        pendingIrq = false
        //m_controllerPorts.Reset();
    }

    
    func getMemValue() -> UInt8 {
        let result = read8(operandAddress)
        return result
    }
    
    func calcNegativeFlag(_ v: UInt16) -> UInt8
    {
        // Check if bit 7 is set
        if (v & 0x0080) != 0 {
            return 1
        }
        else {
            return 0
        }
    }
    
    func calcNegativeFlag(_ v: Int) -> UInt8
    {
        // Check if bit 7 is set
        if (v & 0x80) != 0 {
            return 1
        }
        else {
            return 0
        }
    }
    
    func calcNegativeFlag(_ v: UInt8) -> UInt8
    {
        // Check if bit 7 is set
        if (v & 0x80) != 0 {
            return 1
        }
        else {
            return 0
        }
    }
    
    func calcZeroFlag(_ v: UInt16) -> UInt8 {
        // Check if bit 7 is set
        if (v & 0x00FF) == 0 {
            return 1
        }
        else {
            return 0
        }
    }
    
    func calcCarryFlag(_ v: Int) -> UInt8
    {
        if v >= 0 {
            return 1
        }
        else {
            return 0
        }
    }
    
    func intToUint(_ v: Int) -> UInt8 {
        var inputValue = v
        if inputValue >= 256 {
            inputValue -= 256
        }
        if inputValue < 0 {
            inputValue = 256 + inputValue
        }
        
        return UInt8(inputValue)
    }
    
    func calcZeroFlag(_ v: Int) -> UInt8 {
        if v == 0 {
            return 1
        }
        else {
            return 0
        }
    }
    
    func calcZeroFlag(_ v: UInt8) -> UInt8 {
        if v == 0 {
            return 1
        }
        else {
            return 0
        }
    }
    
    func calcCarryFlag(_ v: UInt16) -> UInt8 {
        if (v & 0xFF00) != 0 {
            return 1
        }
        else {
            return 0
        }
    }
    
    func calcOverflowFlag(a: UInt8, b: UInt8, r: UInt16) -> UInt8 {
        // With r = a + b, overflow occurs if both a and b are negative and r is positive,
        // or both a and b are positive and r is negative. Looking at sign bits of a, b, r,
        // overflow occurs when 0 0 1 or 1 1 0, so we can use simple xor logic to figure it out.
        // return ((uint16)a ^ r) & ((uint16)b ^ r) & 0x0080;
        
        //TODO need check
        let intA = Int(a)
        let intB = Int(b)
        let intR = Int(r)
        
        if intA==0 && intB==0 && intR==0 {
            return 1
        }
        
        if intA==0 && intB==0 && intR==0 {
            return 1
        }
        
        return 0
    }
    
    func getAccumOrMemValue() -> UInt8 {
        if opCodeEntry!.addrMode == AddressMode.Accumu {
            return A
        }
        
        let result = read8(operandAddress)
        return result
    }
    
    func setAccumOrMemValue(_ value: UInt8) {
        if opCodeEntry!.addrMode == AddressMode.Accumu {
            A = value
        }
        else {
            write8(address: operandAddress, value: value)
        }
    }
    
    func write8(address:UInt16, value: UInt8) {
        cpuMemoryBus!.write(cpuAddress: address, value: value)
    }
    
    func push16(_ value: UInt16) {
        push8(UInt8(value >> 8))
        push8(UInt8(value & 0x00FF))
    }
    
    func push8(_ value:UInt8) {
        write8(address: CpuMemory.kStackBase + UInt16(SP), value: value)
        SP = SP - 1
        
        
        if SP == 0xFF {
            NSLog("Stack overflow!")
        }
    }

    func pop8() -> UInt8 {
        SP = SP + 1
        if  SP == 0 {
            NSLog("Stack overflow!")
        }
        
        return read8(CpuMemory.kStackBase + UInt16(SP))
    }

    func Pop16() -> UInt16 {
        let low = tO16(pop8())
        let high = tO16(pop8())
        return (high << 8) | low
    }

    func pushProcessorStatus(_ softwareInterrupt: Bool) {
        var brkFlag:UInt8 = 0
        if softwareInterrupt {
            brkFlag = CpuRegDef.BrkExecuted
        }
        push8(P.value() | CpuRegDef.Unused | brkFlag)
    }

    func popProcessorStatus() {
        P.setValue(pop8() & ~CpuRegDef.Unused & ~CpuRegDef.BrkExecuted)
        //assert(!P.test(Unused) && !P.test(BrkExecuted) && "P should never have these set, only on stack");
    }
    
    
    func isMemoryValueOperand(_ v: UInt32) -> Bool {
        //Immedt | ZeroPg | ZPIdxX|ZPIdxY|Absolu|AbIdxX|AbIdxY|IdxInd|IndIdx
        if v == AddressMode.Immedt.rawValue {
            return true
        }
        if v == AddressMode.ZeroPg.rawValue {
            return true
        }
        if v == AddressMode.ZPIdxX.rawValue {
            return true
        }
        if v == AddressMode.ZPIdxY.rawValue {
            return true
        }
        if v == AddressMode.Absolu.rawValue {
            return true
        }
        if v == AddressMode.AbIdxX.rawValue {
            return true
        }
        if v == AddressMode.AbIdxY.rawValue {
            return true
        }
        if v == AddressMode.IdxInd.rawValue {
            return true
        }
        if v == AddressMode.IndIdx.rawValue {
            return true
        }
        
        return false
    }
    
    func isJmpOrBranchOperand(_ v: UInt32) -> Bool {
        if v == AddressMode.Relatv.rawValue {
            return true
        }
        if v == AddressMode.Absolu.rawValue {
            return true
        }
        if v == AddressMode.Indrct.rawValue {
            return true
        }
        return false
    }
    
    func setMemValue(_ value: UInt8) {
        assert(isMemoryValueOperand(opCodeEntry!.addrMode.rawValue))
        
        //if(!(IsMemoryValueOperand(opCodeEntry!.addrMode.rawValue)))
        //{
        //    return
        //}
        write8(address: operandAddress, value: value)
    }
    
    func getBranchOrJmpLocation() -> UInt16 {
        assert(isJmpOrBranchOperand(opCodeEntry!.addrMode.rawValue))
        return operandAddress
    }
    
    func toInt(_ x : UInt8) -> Int {
          return Int(Int8(bitPattern: x))
    }
    
    func Nmi() {
        pendingNmi = true
    }

    func Irq() {
        if !P.test(CpuRegDef.IrqDisabled) {
            pendingIrq = true
        }
    }

    var opCodeEntry:OpCodeEntry!
    var opCodeTable:[UInt8:OpCodeEntry] = [:]
    var cpuMemoryBus:CpuMemoryBus?
    
    var apu:Apu!
    var controllerPorts:ControllerPorts!
    var operandAddress:UInt16 = 0
    var operandReadCrossedPage = false
}
