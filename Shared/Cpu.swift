//
//  Cpu.swift
//  NES_EMU
//
//  Created by mio on 2021/8/8.
//

import Foundation
class Cpu:HandleCpuReadProtocol{
    
    
    func HandleCpuRead(_ cpuAddress: uint16) -> uint8 {
        return 0
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
        //TODO
    }
    
    func Read8(_ address:uint16)->uint8
    {
        return m_cpuMemoryBus!.Read(address)
    }
    
    func UpdateOperandAddress()
    {
        //TODO
    }
    
    func ExecuteInstruction()
    {
        //TODO
    }
    
    
    var PC:uint16 = 0        // Program counter
    var SP:uint8 = 0        // Stack pointer
    var A:uint8 = 0       // Accumulator
    var X:uint8 = 0     // X register
    var Y:uint8 = 0        // Y register
    //var P:Bitfield8    // Processor status (flags) TODO
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
        m_pendingIrq = false;

        //m_controllerPorts.Reset();
    }
    
    
    func TO16(_ v8:uint8)->uint16
    {
        return uint16(v8)
    }
    
    func Read16(_ address:uint16)->uint16
    {
        return TO16(m_cpuMemoryBus!.Read(address)) | (TO16(m_cpuMemoryBus!.Read(address + 1)) << 8);
    }
}
