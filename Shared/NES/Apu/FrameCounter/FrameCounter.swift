//
//  FrameCounter.swift
//  NES_EMU (iOS)
//
//  Created by mio on 2023/7/27.
//

import Foundation

class FrameCounter:NSObject
{
    var m_apu:Apu?
    var m_cpuCycles:UInt32 = 0
    var m_numSteps = 4
    var m_inhibitInterrupt = true
    
    init(apu:Apu)
    {
        super.init()
        
        self.m_apu = apu
    }

    func SetMode(_ mode:UInt8)
    {
        assert(mode < 2)
        if (mode == 0)
        {
            print("PulseChannel mode 4")
            m_numSteps = 4
        }
        else
        {
            print("PulseChannel mode 5")
            m_numSteps = 5

            //@TODO: This should happen in 3 or 4 CPU cycles
            ClockQuarterFrameChips()
            ClockHalfFrameChips()
        }

        // Always restart sequence
        //@TODO: This should happen in 3 or 4 CPU cycles
        m_cpuCycles = 0
    }

    func AllowInterrupt()
    {
        m_inhibitInterrupt = false
    }

    func HandleCpuWrite( cpuAddress:UInt16, value:UInt8)
    {
        assert(cpuAddress == 0x4017)

        let mode = ReadBits8(target: BIT(7), value: value) >> 7
        SetMode(UInt8(mode))
        //SetMode(UInt8(1))
        
        
        if (TestBits(target: BIT(6), value: value))
        {
            AllowInterrupt()
        }
    }
    
    // Clock every CPU cycle
    func Clock()
    {
        var resetCycles = false

        switch (m_cpuCycles)
        {
        case APU_TO_CPU_CYCLE(3728.5):
            ClockQuarterFrameChips()
            break

        case APU_TO_CPU_CYCLE(7456.5):
            ClockQuarterFrameChips()
            ClockHalfFrameChips()
            break

        case APU_TO_CPU_CYCLE(11185.5):
            ClockQuarterFrameChips()
            break

        case APU_TO_CPU_CYCLE(14914):
            if (m_numSteps == 4)
            {
                //@TODO: set interrupt flag if !inhibit
            }
            break

        case APU_TO_CPU_CYCLE(14914.5):
            if (m_numSteps == 4)
            {
                //@TODO: set interrupt flag if !inhibit
                ClockQuarterFrameChips()
                ClockHalfFrameChips()
            }
            break

        case APU_TO_CPU_CYCLE(14915):
            if (m_numSteps == 4)
            {
                //@TODO: set interrupt flag if !inhibit

                resetCycles = true
            }
            break

        case APU_TO_CPU_CYCLE(18640.5):
            if(m_numSteps == 5)
            {
                ClockQuarterFrameChips()
                ClockHalfFrameChips()
            }
            break

        case APU_TO_CPU_CYCLE(18641):
            if(m_numSteps == 5)
            {
                resetCycles = true
            }
            break
        default:
            break
        }

        if(resetCycles)
        {
            //print("PulseChannel mode 4 m_cpuCycles->" + String(m_cpuCycles))
            m_cpuCycles = 0
        }
        else
        {
            m_cpuCycles += 1
        }
    }

    func APU_TO_CPU_CYCLE(_ cpuCycle:Float32)->UInt32
    {
        return UInt32(cpuCycle*2)
    }
    
    func ClockQuarterFrameChips()
    {
        m_apu?.ClockQuarterFrameChips()
    }

    func ClockHalfFrameChips()
    {
        m_apu?.ClockHalfFrameChips()
    }
}
