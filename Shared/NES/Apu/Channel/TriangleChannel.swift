//
//  TriangleChannel.swift
//  NES_EMU
//
//  Created by mio on 2023/7/25.
//

import Foundation

class TriangleChannel:BaseChannel{
    override init()
    {
        super.init()
        m_timer.SetMinPeriod(2)
    }
    
    func ClockQuarterFrameChips()
    {
        m_linearCounter.Clock()
    }

    func ClockHalfFrameChips()
    {
        m_lengthCounter.Clock()
    }
    
    func ClockTimer()
    {
        if (m_timer.Clock())
        {
            let a = m_linearCounter.GetValue()
            let b = m_lengthCounter.GetValue()
            if (a > 0 && b > 0)
            {
                m_triangleWaveGenerator.Clock();
            }
        }
    }
    let m_triangleWaveGenerator = TriangleWaveGenerator()
    override func GetValue()->Float32
    {
        return m_triangleWaveGenerator.GetValue()
    }
    
    override func  HandleCpuWrite(cpuAddress:UInt16, value:UInt8)
    {
        switch (cpuAddress)
        {
        case 0x4008:
            m_lengthCounter.SetHalt(TestBits(target: BIT(7), value: value))
            let control = TestBits(target: BIT(7),value:value)
            let period = ReadBits8(target: 0x7f, value: value)
            m_linearCounter.SetControlAndPeriod(control: control, period: UInt16(period))
            break

        case 0x400A:
            m_timer.SetPeriodLow8(value);
            break

        case 0x400B:
            let period = ReadBits8(target: 0x7, value: value)
            m_timer.SetPeriodHigh3(UInt16(period))
            m_linearCounter.Restart()
            m_lengthCounter.LoadCounterFromLUT(value >> 3)
            break

        default:
            assert(false)
            break
        };
    }
    
}

class TriangleWaveGenerator
{
    var m_step:UInt8 = 0
    func Clock()
    {
        m_step = (m_step + 1) % 32
        //let step = m_step
        //print(step)
    }
    
    let sequence:[Float32] =
    [
        15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0,
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
    ]
    
    func GetValue()->Float32
    {
        assert(m_step < 32);
        let step = m_step
        let value = sequence[Int(step)]
        /*
        if(value == 15)
        {
            return 0
        }
         */
        return value
    }
}
