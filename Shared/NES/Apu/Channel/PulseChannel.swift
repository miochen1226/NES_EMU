//
//  PulseChannel.swift
//  NES_EMU
//
//  Created by mio on 2023/7/25.
//

import Foundation

class PulseChannel:BaseChannel {
    
    init(pulseChannelNumber:UInt8)
    {
        super.init()
        
        if (pulseChannelNumber == 0)
        {
            m_sweepUnit.SetSubtractExtra()
        }
    }
    
    func ClockQuarterFrameChips()
    {
        m_volumeEnvelope.Clock()
    }
    
    func ClockHalfFrameChips()
    {
        m_lengthCounter.Clock()
        m_sweepUnit.Clock(m_timer)
    }
    
    func ClockTimer()
    {
        if (m_timer.Clock())
        {
            m_pulseWaveGenerator.Clock()
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
        //need check
        let newAddress:UInt16 = ReadBits(target: BITS([0,1]), value: value)
        //ReadBits(cpuAddress, BITS(0,1))
        
        switch (newAddress)
        {
        case 0:
            
            let r1 = ReadBits(target: BITS([6,7]), value: value) >> 6
            m_pulseWaveGenerator.SetDuty(UInt8(r1))
            let h1 = TestBits(target: UInt16(BIT(5)), value: value)
            m_lengthCounter.SetHalt(h1)
            
            
            m_volumeEnvelope.SetLoop(h1) // Same bit for length counter halt and envelope loop
            
            let h4 = TestBits(target: UInt16(BIT(4)), value: value)
            m_volumeEnvelope.SetConstantVolumeMode(h4)
            
            let r = ReadBits(target: BITS([0,1,2,3]), value: value)
            m_volumeEnvelope.SetConstantVolume(r)
            break

        case 1: // Sweep unit setup
            let t = TestBits(target: UInt16(BIT(7)), value: value)
            m_sweepUnit.SetEnabled(t)
            
            let t456 = ReadBits(target: BITS([4,5,6]), value: value) >> 4
            m_sweepUnit.SetPeriod(period: t456, timer: m_timer)
            m_sweepUnit.SetNegate(TestBits(target: UInt16(BIT(3)), value: value ));
            m_sweepUnit.SetShiftCount(UInt8(ReadBits( target:BITS([0,1,2]),value:value)))
            m_sweepUnit.Restart()// Side effect
            break

        case 2:
            m_timer.SetPeriodLow8(value)
            break

        case 3:
            m_timer.SetPeriodHigh3(ReadBits(target: BITS([0,1,2]),value:value))
                                   
            let readBitsResult = ReadBits( target:BITS([3,4,5,6,7]),value:value) >> 3
            
            m_lengthCounter.LoadCounterFromLUT(UInt8(readBitsResult))
            m_volumeEnvelope.Restart()
            m_pulseWaveGenerator.Restart()
            break

        default:
            //assert(false)
            break
        }
    }
    
    override func GetValue()->Float32
    {
        //if(m_sweepUnit.m_subtractExtra == 0)
        //{
        //    return 0
        //}
        
        if (m_sweepUnit.SilenceChannel())
        {
            return 0
        }

        if (m_lengthCounter.SilenceChannel())
        {
            return 0
        }
        
        //let a = m_volumeEnvelope.GetVolume()
        //let b = m_pulseWaveGenerator.GetValue()
        
        let value = Float32(m_volumeEnvelope.GetVolume()) * Float32(m_pulseWaveGenerator.GetValue())

        assert(value < 16)
        return value
    }
    let m_volumeEnvelope = VolumeEnvelope()
    let m_sweepUnit = SweepUnit()
    let m_pulseWaveGenerator = PulseWaveGenerator()
}

class VolumeEnvelope
{
    let m_divider = ChannelComponent.Divider()
    var m_loop = false
    func SetLoop(_ loop:Bool)
    {
        m_loop = loop
    }
    
    var m_constantVolumeMode:Bool = false
                
    func SetConstantVolume(_ value:UInt16)
    {
        //assert(value < 16);
        m_constantVolume = value
        m_divider.SetPeriod(m_constantVolume)
    }
                
    func SetConstantVolumeMode(_ mode:Bool)
    {
        m_constantVolumeMode = mode
    }
    var m_restart = false
    func Restart()
    {
        m_restart = true
    }
    
    var m_constantVolume:UInt16 = 0
    var m_counter:UInt16 = 0
    func GetVolume()->UInt16
    {
        var result:UInt16 = 0
        if (m_constantVolumeMode)
        {
            result = m_constantVolume
        }
        else
        {
            result = m_counter
        }
        //assert(result < 16)
        return result
    }
                
    func Clock()
    {
        if (m_restart)
        {
            m_restart = false
            m_counter = 15
            m_divider.ResetCounter()
        }
        else
        {
            if (m_divider.Clock())
            {
                if (m_counter > 0)
                {
                    m_counter = m_counter - 1
                }
                else if (m_loop)
                {
                    m_counter = 15
                }
            }
        }
    }
    
}

class SweepUnit
{
    var m_negate = false
    var m_targetPeriod:UInt16 = 0
    var m_subtractExtra:UInt16 = 0
    var m_enabled = false
    var m_reload = false
    var m_shiftCount:UInt8 = 0
    var m_silenceChannel = false
    let m_divider = ChannelComponent.Divider()
    
    func SetSubtractExtra()
    {
        m_subtractExtra = 1
    }
    
    func SetEnabled(_ enabled:Bool)
    {
        m_enabled = enabled
        
        if(m_enabled)
        {
            //print("SweepUnit->enable yes")
        }
        else
        {
            //print("SweepUnit->enable No")
        }
    }
    
    func SetNegate(_ negate:Bool)
    {
        m_negate = negate
    }
    
    func SetPeriod(period:UInt16, timer:ChannelComponent.Timer)
    {
        //assert(period < 8); // 3 bitsVolumeEnvelope
        m_divider.SetPeriod(period); // Don't reset counter

        ComputeTargetPeriod(timer:timer);
    }
    
    func SetShiftCount(_ shiftCount:UInt8)
    {
        //assert(shiftCount < BIT(3))
        m_shiftCount = shiftCount
    }
    
    func Restart()
    {
        m_reload = true
    }
    
    // Clocked by FrameCounter
    func Clock(_ timer:ChannelComponent.Timer)
    {
        ComputeTargetPeriod(timer: timer)

        if (m_reload)
        {
            if (m_enabled && m_divider.Clock())
            {
                AdjustTimerPeriod(timer:timer)
            }

            m_divider.ResetCounter()

            m_reload = false
        }
        else
        {

            // From the nesdev wiki, it looks like the divider is always decremented, but only
            // reset to its period if the sweep is enabled.
            if (m_divider.GetCounter() > 0)
            {
                m_divider.Clock()
            }
            else if (m_enabled && m_divider.Clock())
            {
                AdjustTimerPeriod(timer:timer)
            }
        }
    }
    
    func SilenceChannel()->Bool
    {
        return m_silenceChannel
    }
    
    func ComputeTargetPeriod(timer:ChannelComponent.Timer)
    {
        assert(m_shiftCount < 8); // 3 bits

        let currPeriod = timer.GetPeriod()
        let shiftedPeriod = currPeriod >> m_shiftCount

        if (m_negate)
        {
            // Pulse 1's adder's carry is hardwired, so the subtraction adds the one's complement
            // instead of the expected two's complement (as pulse 2 does)
            m_targetPeriod = currPeriod - (shiftedPeriod - m_subtractExtra)
        }
        else
        {
            m_targetPeriod = currPeriod + shiftedPeriod;
        }

        // Channel will be silenced under certain conditions even if Sweep unit is disabled
        m_silenceChannel = (currPeriod < 8 || m_targetPeriod > 0x7FF)
        
        if(m_silenceChannel)
        {
            //print("m_silenceChannel = true " + String(currPeriod))
        }
        else
        {
            //print("m_silenceChannel = false " + String(currPeriod))
        }
    }
            
    func AdjustTimerPeriod(timer:ChannelComponent.Timer)
    {
        // If channel is not silenced, it means we're in range
        if (m_enabled && m_shiftCount > 0 && !m_silenceChannel)
        {
            timer.SetPeriod(m_targetPeriod)
        }
    }
}

class PulseWaveGenerator
{
    var m_duty:UInt8 = 0
    var m_step:UInt8 = 0
    
    func SetDuty(_ duty:UInt8)
    {
        assert(duty < 4);
        m_duty = duty;
    }
    
    func Restart()
    {
        m_step = 0
    }
                
    let sequences:[[UInt8]] =
    [
        [ 0, 1, 0, 0, 0, 0, 0, 0 ], // 12.5%
        [ 0, 1, 1, 0, 0, 0, 0, 0 ], // 25%
        [ 0, 1, 1, 1, 1, 0, 0, 0 ], // 50%
        [ 1, 0, 0, 1, 1, 1, 1, 1 ]  // 25% negated
    ]
                
    func GetValue()->UInt8
    {
        let duty = m_duty
        let step = m_step
        let value = sequences[Int(m_duty)][Int(m_step)]
        return value
    }
                
    func Clock()
    {
        m_step = (m_step + 1) % 8;
    }
}
