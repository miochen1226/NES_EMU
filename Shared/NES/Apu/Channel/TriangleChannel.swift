//
//  TriangleChannel.swift
//  NES_EMU
//
//  Created by mio on 2023/7/25.
//

import Foundation

class TriangleChannel: BaseChannel {
    
    override init() {
        super.init()
        timer.setMinPeriod(2)
    }
    
    func clockQuarterFrameChips() {
        linearCounter.clock()
    }

    func clockHalfFrameChips() {
        lengthCounter.clock()
    }
    
    func clockTimer() {
        if timer.clock() {
            let a = linearCounter.getValue()
            let b = lengthCounter.getValue()
            if (a > 0 && b > 0)
            {
                triangleWaveGenerator.clock();
            }
        }
    }
    
    override func getValue() -> Float32 {
        return triangleWaveGenerator.getValue()
    }
    
    override func handleCpuWrite(cpuAddress: UInt16, value: UInt8) {
        switch cpuAddress {
        case 0x4008:
            lengthCounter.setHalt(TestBits(target: BIT(7), value: value))
            let control = TestBits(target: BIT(7),value:value)
            let period = ReadBits8(target: 0x7f, value: value)
            linearCounter.setControlAndPeriod(control: control, period: UInt16(period))
            break

        case 0x400A:
            timer.setPeriodLow8(value)
            break

        case 0x400B:
            let period = ReadBits8(target: 0x7, value: value)
            timer.setPeriodHigh3(UInt16(period))
            linearCounter.restart()
            lengthCounter.loadCounterFromLUT(value >> 3)
            break

        default:
            assert(false)
            break
        }
    }
    
    let triangleWaveGenerator = TriangleWaveGenerator()
}

class TriangleWaveGenerator {
    
    func clock() {
        step = (step + 1) % 32
    }
    
    let sequence:[Float32] =
    [
        15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0,
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
    ]
    
    func getValue()->Float32
    {
        assert(step < 32);
        let step = step
        let value = sequence[Int(step)]
        return value
    }
    
    var step: UInt8 = 0
}
