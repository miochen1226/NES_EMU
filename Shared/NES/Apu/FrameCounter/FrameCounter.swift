//
//  FrameCounter.swift
//  NES_EMU (iOS)
//
//  Created by mio on 2023/7/27.
//

import Foundation

class FrameCounter: NSObject
{
    init(apu: Apu) {
        super.init()
        self.apu = apu
    }

    func setMode(_ mode: UInt8) {
        assert(mode < 2)
        if mode == 0 {
            numSteps = 4
        }
        else {
            numSteps = 5
            //@TODO: This should happen in 3 or 4 CPU cycles
            clockQuarterFrameChips()
            clockHalfFrameChips()
        }

        // Always restart sequence
        //@TODO: This should happen in 3 or 4 CPU cycles
        cpuCycles = 0
    }

    func AllowInterrupt()
    {
        inhibitInterrupt = false
    }

    func handleCpuWrite( cpuAddress: UInt16, value: UInt8) {
        assert(cpuAddress == 0x4017)

        let mode = ReadBits8(target: BIT(7), value: value) >> 7
        setMode(UInt8(mode))
        
        if TestBits(target: BIT(6), value: value) {
            AllowInterrupt()
        }
    }
    
    func Clock() {
        var resetCycles = false

        switch cpuCycles {
        case APU_TO_CPU_CYCLE(3728.5):
            clockQuarterFrameChips()
            break

        case APU_TO_CPU_CYCLE(7456.5):
            clockQuarterFrameChips()
            clockHalfFrameChips()
            break

        case APU_TO_CPU_CYCLE(11185.5):
            clockQuarterFrameChips()
            break

        case APU_TO_CPU_CYCLE(14914):
            if numSteps == 4 {
                //@TODO: set interrupt flag if !inhibit
            }
            break

        case APU_TO_CPU_CYCLE(14914.5):
            if numSteps == 4 {
                //@TODO: set interrupt flag if !inhibit
                clockQuarterFrameChips()
                clockHalfFrameChips()
            }
            break

        case APU_TO_CPU_CYCLE(14915):
            if numSteps == 4 {
                //@TODO: set interrupt flag if !inhibit
                resetCycles = true
            }
            break

        case APU_TO_CPU_CYCLE(18640.5):
            if numSteps == 5 {
                clockQuarterFrameChips()
                clockHalfFrameChips()
            }
            break

        case APU_TO_CPU_CYCLE(18641):
            if numSteps == 5 {
                resetCycles = true
            }
            break
        default:
            break
        }

        if resetCycles {
            cpuCycles = 0
        }
        else
        {
            cpuCycles += 1
        }
    }

    func APU_TO_CPU_CYCLE(_ cpuCycle:Float32)->UInt32
    {
        return UInt32(cpuCycle*2)
    }
    
    func clockQuarterFrameChips()
    {
        apu?.clockQuarterFrameChips()
    }

    func clockHalfFrameChips()
    {
        apu?.clockHalfFrameChips()
    }
    
    var apu:Apu?
    var cpuCycles:UInt32 = 0
    var numSteps = 4
    var inhibitInterrupt = true
}
