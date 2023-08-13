//
//  NoiseChannel.swift
//  NES_EMU
//
//  Created by mio on 2023/7/25.
//

import Foundation

class NoiseChannel: BaseChannel {
    override func getValue() -> Float32 {
        if shiftRegister.silenceChannel() || lengthCounter.silenceChannel() {
            return 0;
        }
        
        return Float32(volumeEnvelope.getVolume())
    }
    
    func clockQuarterFrameChips() {
        volumeEnvelope.clock()
    }

    func clockHalfFrameChips() {
        lengthCounter.clock()
    }
    
    func clockTimer() {
        if timer.clock() {
            shiftRegister.clock()
        }
    }
    
    override func handleCpuWrite(cpuAddress: UInt16, value: UInt8) {
        switch cpuAddress {
        case 0x400C:
            lengthCounter.setHalt(testBits(target: UInt16(BIT(5)), value: value))
            volumeEnvelope.setConstantVolumeMode(testBits(target: UInt16(BIT(4)), value: value))
            volumeEnvelope.setConstantVolume(readBits(target: BITS16([0, 1, 2, 3]), value: value))
            break

        case 0x400E:
            shiftRegister.mode = testBits(target: UInt16(BIT(7)), value: value)
            setNoiseTimerPeriod(readBits(target: BITS16([0, 1, 2, 3]), value: value))
            break

        case 0x400F:
            lengthCounter.loadCounterFromLUT(value >> 3)
            volumeEnvelope.restart()
            break

        default:
            assert(false)
            break
        }
    }
    
    func setNoiseTimerPeriod(_ lutIndex: UInt16) {
        let periodReloadValue = (ntscPeriods[Int(lutIndex)] / 2) - 1
        timer.setPeriod(periodReloadValue)
    }
    
    let ntscPeriods:[UInt16] = [ 4, 8, 16, 32, 64, 96, 128, 160, 202, 254, 380, 508, 762, 1016, 2034, 4068 ]
    let volumeEnvelope = VolumeEnvelope()
    let shiftRegister = LinearFeedbackShiftRegister()
}

class LinearFeedbackShiftRegister {
    func clock() {
        let bit0: UInt16 = readBits(target: UInt16(BIT(0)), value: register)
        var whichBitN: UInt16 = 1
        if mode {
            whichBitN = 6
        }
        let bitN:UInt16 = readBits(target: UInt16(BIT(Int(whichBitN))), value: register) >> whichBitN
        
        let feedback = bit0 ^ bitN
        assert(feedback < 2)

        register = (register >> 1) | (feedback << 14)
        assert(register < BIT16(15))
    }

    func silenceChannel() -> Bool {
        return testBits(target: UInt16(BIT(0)), value: register)//TestBits(m_register, BIT(0));
    }
    
    var register:UInt16 = 1
    var mode: Bool = false
}
