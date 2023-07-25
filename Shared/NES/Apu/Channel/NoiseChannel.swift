//
//  NoiseChannel.swift
//  NES_EMU
//
//  Created by mio on 2023/7/25.
//

import Foundation

class NoiseChannel:BaseChannel{
    
    let m_volumeEnvelope = VolumeEnvelope()
    let m_shiftRegister = LinearFeedbackShiftRegister()
    
    override func GetValue()->Float32
    {
        if (m_shiftRegister.SilenceChannel() || m_lengthCounter.SilenceChannel())
        {
            return 0;
        }
        return Float32(m_volumeEnvelope.GetVolume())
    }
    
    func ClockQuarterFrameChips()
    {
        m_volumeEnvelope.Clock()
    }

    func ClockHalfFrameChips()
    {
        m_lengthCounter.Clock()
    }
    
    func ClockTimer()
    {
        if (m_timer.Clock())
        {
            m_shiftRegister.Clock();
        }
    }
    
    func BITS(_ bitsIn:[Int])->UInt16
    {
        var result:UInt16 = 0
        for bit in bitsIn
        {
            let dig = UInt8(1<<bit)
            result += UInt16(dig)
        }
        
        return result
    }
    
    override func HandleCpuWrite(cpuAddress:UInt16, value:UInt8)
    {
        switch (cpuAddress)
        {
        case 0x400C:
            
            m_lengthCounter.SetHalt(TestBits(target: UInt16(BIT(5)), value: value))
            m_volumeEnvelope.SetConstantVolumeMode(TestBits(target: UInt16(BIT(4)), value: value))
            m_volumeEnvelope.SetConstantVolume(ReadBits(target: BITS([0, 1, 2, 3]), value: value))
            break;

        case 0x400E:
            m_shiftRegister.m_mode = TestBits(target: UInt16(BIT(7)), value: value)
            SetNoiseTimerPeriod(ReadBits(target: BITS([0, 1, 2, 3]), value: value))
            
            break;

        case 0x400F:
            m_lengthCounter.LoadCounterFromLUT(value >> 3);
            m_volumeEnvelope.Restart();
            break;

        default:
            assert(false);
            break;
        }
    }
    let ntscPeriods:[UInt16] = [ 4, 8, 16, 32, 64, 96, 128, 160, 202, 254, 380, 508, 762, 1016, 2034, 4068 ]
    func SetNoiseTimerPeriod(_ lutIndex:UInt16)
    {
        let periodReloadValue = (ntscPeriods[Int(lutIndex)] / 2) - 1
        m_timer.SetPeriod(periodReloadValue)
    }

    //let m_linearCounter = LinearCounter()
}

class LinearFeedbackShiftRegister
{
    func BIT(_ n:Int)->UInt16
    {
        let value = UInt16(1<<n)
        return value
    }
    
    func TestBits(target:UInt16,  value:UInt16)->Bool
    {
        return ReadBits(target: target, value: value) != 0
    }

    
    func ReadBits(target:UInt16, value:UInt16)->UInt16
    {
        return target & UInt16(value)
    }
    
    var m_register:UInt16 = 1
    var m_mode = false
    // Clocked by noise channel timer
    func Clock()
    {
        let bit0 = ReadBits(target: UInt16(BIT(0)), value: m_register)
        //(m_register, BIT(0));

        var whichBitN = 1
        if(m_mode)
        {
            whichBitN = 6
        }
        //uint16 whichBitN = m_mode ? 6 : 1;
        //uint16 bitN = ReadBits(m_register, BIT(whichBitN)) >> whichBitN;
        let bitN = ReadBits(target: UInt16(BIT(whichBitN)), value: m_register) >> whichBitN
        //ReadBits(m_register, BIT(whichBitN)) >> whichBitN;
        
        let feedback:UInt16 = UInt16(bit0 ^ bitN);
        //assert(feedback < 2);

        m_register = (m_register >> 1) | (feedback << 14)
        assert(m_register < BIT(15));
    }

    func SilenceChannel()->Bool
    {
        // If bit 0 is set, silence
        return TestBits(target: UInt16(BIT(0)), value: m_register)//TestBits(m_register, BIT(0));
    }
}
