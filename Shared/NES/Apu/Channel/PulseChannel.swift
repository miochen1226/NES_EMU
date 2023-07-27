//
//  PulseChannel.swift
//  NES_EMU
//
//  Created by mio on 2023/7/25.
//

import Foundation

class DividerEx
{
    var m_period:UInt16 = 0
    var m_counter:UInt16 = 0
    func SetPeriod(_ period:UInt16)
    {
        m_period  = period
    }
    
    func GetPeriod()->UInt16
    {
        return m_period
    }
    
    func GetCounter()->UInt16
    {
        return m_counter
    }
    
    func ResetCounter()
    {
        m_counter = m_period
    }
    
    func Clock()->Bool
    {
        if (m_counter == 0)
        {
            ResetCounter()
            //print("SweepUnit:Clock O ->"+String(m_counter))
            return true
        }
        m_counter -= 1
        return false
    }
}

class TimerEx
{
    let m_divider = DividerEx()
    var m_minPeriod = 0
    
    func Reset()
    {
        m_divider.ResetCounter()
    }
    
    func GetPeriod()->UInt16
    {
        return m_divider.GetPeriod()
    }
    
    func SetPeriod(_ period:UInt16)
    {
        m_divider.SetPeriod(period)
    }
    
    func SetPeriodLow8(_ value:UInt8)
    {
        var period:UInt16 = m_divider.GetPeriod()
        period = (period & BITS([8,9,10])) | UInt16(value) // Keep high 3 bits
        SetPeriod(UInt16(value))
    }
    
    func SetPeriodHigh3(_ value:UInt16)
    {
        assert(value < BIT(3));
        var period:UInt16 = m_divider.GetPeriod()
        //period = (value << 8) | (period & 0xFF); // Keep low 8 bits
        period = (value << 8) | (period & 0xFF)
        
        SetPeriod(UInt16(period))
        m_divider.ResetCounter()
    }
    
    func SetMinPeriod(_ minPeriod:Int)
    {
        m_minPeriod = minPeriod;
    }

    // Clocked by CPU clock every cycle (triangle channel) or second cycle (pulse/noise channels)
    // Returns true when output chip should be clocked
    func Clock()->Bool
    {
        // Avoid popping and weird noises from ultra sonic frequencies
        //if (m_divider.GetPeriod() < m_minPeriod)
        //{
        //    return false
        //}
            
        if (m_divider.Clock())
        {
            return true
        }
        
        return false
    }
}

class LengthCounterEx
{
    var m_enabled = false
    var m_halt = false
    var m_counter:UInt16 = 0
    let lut:[UInt8] =
    [
        10, 254, 20, 2, 40, 4, 80, 6, 160, 8, 60, 10, 14, 12, 26, 14,
        12, 16, 24, 18, 48, 20, 96, 22, 192, 24, 72, 26, 16, 28, 32, 30
    ]
    
    func SetEnabled(_ value:Bool)
    {
        m_enabled = value
        
        if (!m_enabled)
        {
            m_counter = 0
        }
    }
    
    func SetHalt(_ halt:Bool)
    {
        m_halt = halt
    }
    
    func LoadCounterFromLUT(_ index:UInt8)
    {
        if (!m_enabled)
        {
            //print("LengthCounterEx LoadCounterFromLUT set m_counter->" + String(m_counter) + "index->" + String(index))
            return
        }
        //print("LoadCounterFromLUT" + String(index))
        //static_assert(ARRAYSIZE(lut) == 32, "Invalid");
        //assert(index < ARRAYSIZE(lut));
        m_counter = UInt16(lut[Int(index)])
        //print("LengthCounterEx LoadCounterFromLUT set m_counter->" + String(m_counter) + ",index->" + String(index))
    }
    
    func Clock()
    {
        if (m_halt)
        {
            //print("LengthCounterEx Clock()->Hald")
            return
        }
        
        //print("PulseChannel Clock()")
        //print("LengthCounterEx before clock m_counter->" + String(m_counter))
        if (m_counter > 0) // Once it reaches 0, it stops, and channel is silenced
        {
            m_counter = m_counter-1
        }
    }
    
    func GetValue()->UInt16
    {
        return m_counter
    }
    
    func SilenceChannel()->Bool
    {
        /*
        if (!m_enabled)
        {
            return false
        }
         */
        
        if(m_counter == 0)
        {
            //print("LengthCounterEx SilenceChannel->true")
            return true
        }
        else
        {
            //print("LengthCounterEx SilenceChannel->False")
            return false
        }
    }
}

class PulseChannel:NSObject {
    
    var m_timerEx = TimerEx()
    var m_lengthCounterEx = LengthCounterEx()
    
    func GetLengthCounterEx()->LengthCounterEx
    {
        return m_lengthCounterEx
    }
    
    init(pulseChannelNumber:UInt8)
    {
        super.init()
        
        m_lengthCounterEx.SetEnabled(true)
        
        if (pulseChannelNumber == 0)
        {
            m_sweepUnit.SetSubtractExtra()
        }
        m_pulseWaveGenerator.m_num = Int(pulseChannelNumber)
    }
    
    func ClockQuarterFrameChips()
    {
        m_volumeEnvelope.Clock()
    }
    
    func ClockHalfFrameChips()
    {
        m_lengthCounterEx.Clock()
        m_sweepUnit.Clock(&m_timerEx)
    }
    
    func ClockTimer()
    {
        if (m_timerEx.Clock())
        {
            m_pulseWaveGenerator.Clock()
        }
    }
    
    func handle40004004(cpuAddress:UInt16, value:UInt8)
    {
        //DDlc.vvvv
        //l
        //表示 envelope loop 标志
        let l = TestBits(target: UInt16(BIT(5)), value: value)
        //c
        //表示是否为常量音量
        
        let c = TestBits(target: UInt16(BIT(4)), value: value)
        
        //vvvv
        //如果 c 置位，表示音量大小，否则表示 envelope 的分频计数
        let vvvv = ReadBits(target: BITS([0,1,2,3]), value: value)
        
        let DD = ReadBits(target: BITS([6,7]), value: value) >> 6
        m_pulseWaveGenerator.SetDuty(UInt8(DD))
        
        m_lengthCounterEx.SetHalt(l)
        
        m_volumeEnvelope.SetLoop(l) // Same bit for length counter halt and envelope loop
        
        if(c)
        {
            m_volumeEnvelope.SetConstantVolume(vvvv)
        }
        else
        {
            m_volumeEnvelope.SetCounter(vvvv)
        }
    }
    
    func handle40014005(cpuAddress:UInt16, value:UInt8)
    {
        //EPPP.NSSS
        //E
        //表示是否使能 sweep
        //PPP
        //sweep 的分频计数
        //N
        //sweep 是否为负，用来控制频率随时间增大还是减小
        //SSS
        //位移量，用于每个 sweep 周期将 timer 右移对应的位移量得到增量

        let E = TestBits(target: UInt16(BIT(7)), value: value)
        //m_sweepUnit.SetEnabled(E)
        m_sweepUnit.SetEnabled(E)
        
        let PPP = ReadBits(target: BITS([4,5,6]), value: value) >> 4
        m_sweepUnit.SetPeriod(period: PPP, timer: &m_timerEx)
        
        let N = TestBits(target: UInt16(BIT(3)), value: value)
        m_sweepUnit.SetNegate(N)
        
        let SSS = UInt8(ReadBits( target:BITS([0,1,2]),value:value))
        m_sweepUnit.SetShiftCount(SSS)
        
        m_sweepUnit.Restart()
        
    }
    
    func handle40024006(cpuAddress:UInt16, value:UInt8)
    {
        //LLLL.LLLL

        //LLLLLLLL
        //timer 的低 8 位（一共 11 位，用于将 cpu 二分频后的时钟继续分频）
        m_timerEx.SetPeriodLow8(value)
        m_timerEx.Reset()
    }
    
    func handle40034007(cpuAddress:UInt16, value:UInt8)
    {
        //llll.lHHH

        //lllll
        //length counter 分频计数
        //HHH
        //timer 的高 3 位，和 0x4002 / 0x4006 组成完整的计数
        let HHH = ReadBits(target: BITS([0,1,2]),value:value)
        m_timerEx.SetPeriodHigh3(HHH)
        
        let LLLL = ReadBits( target:BITS([3,4,5,6,7]),value:value) >> 3
        m_lengthCounterEx.LoadCounterFromLUT(UInt8(LLLL))
        
        //Side effect
        m_volumeEnvelope.Restart()
        m_pulseWaveGenerator.Restart()
        
        //m_volumeEnvelope.Restart()
        //m_pulseWaveGenerator.Restart()
        //m_volumeEnvelope.Restart()
        //m_pulseWaveGenerator.Restart()
    }
    
    func HandleCpuWrite(cpuAddress:UInt16, value:UInt8)
    {
        //let newAddress:UInt16 = ReadBits(target: BITS([0,1]), value: value)
        //ReadBits(cpuAddress, BITS(0,1))
        
        //0x4005
        
        switch (cpuAddress)
        {
        case 0x4000,0x4004:
            handle40004004(cpuAddress: cpuAddress, value: value)
            break
            
        case 0x4001,0x4005:
            handle40014005(cpuAddress: cpuAddress, value: value)
            break
        case 0x4002,0x4006:
            handle40024006(cpuAddress: cpuAddress, value: value)
            break
        case 0x4003,0x4007:
            handle40034007(cpuAddress: cpuAddress, value: value)
            break
            
        case 0:
            
            let duty = ReadBits(target: BITS([6,7]), value: value) >> 6
            m_pulseWaveGenerator.SetDuty(UInt8(duty))
            
            let halt = TestBits(target: UInt16(BIT(5)), value: value)
            m_lengthCounterEx.SetHalt(halt)
            m_volumeEnvelope.SetLoop(halt) // Same bit for length counter halt and envelope loop
            
            m_volumeEnvelope.SetConstantVolumeMode(TestBits(target: UInt16(BIT(4)), value: value))
            m_volumeEnvelope.SetConstantVolume(ReadBits(target: BITS([0,1,2,3]), value: value))
            m_volumeEnvelope.Restart()
            break

        case 1: // Sweep unit setup
            
            //m_sweepUnit.SetEnabled(TestBits(target: UInt16(BIT(7)), value: value))
            
            m_sweepUnit.SetEnabled(false)
            
            let period = ReadBits(target: BITS([4,5,6]), value: value) >> 4
            m_sweepUnit.SetPeriod(period: period, timer: &m_timerEx)
            m_sweepUnit.SetNegate(TestBits(target: UInt16(BIT(3)), value: value))
            m_sweepUnit.SetShiftCount(UInt8(ReadBits( target:BITS([0,1,2]),value:value)))
            
            //print("PulseChannel m_sweepUnit.Restart")
            //m_sweepUnit.Restart()// Side effect
            
            break

        case 2:
            m_timerEx.SetPeriodLow8(value)
            //print("PulseChannel.setPeriod(low)"+String(value))
            break

        case 3:
            //Tri
            //m_timer.SetPeriod(UInt16(0))
            //let period = ReadBits(target: 0x7, value: value)//(ta value, )
            //m_timer.SetPeriodHigh3(period)
            
            //m_timer.SetPeriod(UInt16(768))
            
            m_timerEx.SetPeriodHigh3(ReadBits(target: BITS([0,1,2]),value:value))
            
            //m_timer.SetPeriod(1792)
            //print("PulseChannel.setPeriod(High)"+String(value))
            //print("PulseChannel.GetPeriod(2)->" + String(m_timerEx.GetPeriod()))
            
            let readBitsResult = ReadBits( target:BITS([3,4,5,6,7]),value:value) >> 3
            m_lengthCounterEx.LoadCounterFromLUT(UInt8(readBitsResult))
            
            //Tri
            //m_lengthCounterEx.LoadCounterFromLUT(value >> 3)
            
            //Side effect
            m_volumeEnvelope.Restart()
            m_pulseWaveGenerator.Restart()
            break

        default:
            //assert(false)
            break
        }
    }
    
    func GetValue()->Float32
    {
        if (m_sweepUnit.SilenceChannel())
        {
            return 0
        }
        if (m_lengthCounterEx.SilenceChannel())
        {
            return 0
        }
        
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
    //let m_divider = ChannelComponent.Divider()
    var m_loop = false
    var m_restart = true
    var m_counter:UInt16 = 0
    var m_constantVolumeMode:Bool = false
    var m_constantVolume:UInt16 = 0
    
    
    func Restart()
    {
        m_restart = true
    }
    
    func SetLoop(_ loop:Bool)
    {
        m_loop = loop
    }
    
    func SetConstantVolumeMode(_ mode:Bool)
    {
        m_constantVolumeMode = mode
    }
                
    func SetCounter(_ value:UInt16)
    {
        m_divider.SetPeriod(value)
    }
    
    func SetConstantVolume(_ value:UInt16)
    {
        m_constantVolume = value
        m_divider.SetPeriod(m_constantVolume)
    }
                
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
        
        return result
    }
                
    func Clock()
    {
        if (m_restart)
        {
            m_restart = false
            m_counter = 15;
            m_divider.ResetCounter();
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
                    m_counter = 15;
                }
            }
        }
    }
    let m_divider = DividerEx()
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
    let m_divider = DividerEx()
    
    func SetSubtractExtra()
    {
        m_subtractExtra = 1
    }
    
    func SetEnabled(_ enabled:Bool)
    {
        m_enabled = enabled
    }
    
    func SetNegate(_ negate:Bool)
    {
        m_negate = negate
    }
    
    func SetPeriod(period:UInt16, timer: inout TimerEx)
    {
        //assert(period < 8); // 3 bitsVolumeEnvelope
        m_divider.SetPeriod(period); // Don't reset counter

        //ComputeTargetPeriod(timer:&timer);
    }
    
    func SetShiftCount(_ shiftCount:UInt8)
    {
        //assert(shiftCount < BIT(3))
        
        m_shiftCount = shiftCount
        //print("SweepUnit->SetShiftCount:"+String(shiftCount))
    }
    
    func Restart()
    {
        m_reload = true
    }
    
    // Clocked by FrameCounter
    func Clock(_ timer: inout TimerEx)
    {
        if(!m_enabled)
        {
            return
        }
        
        if (m_reload)
        {
            if (m_enabled)
            {
                if(m_divider.Clock())
                {
                    AdjustTimerPeriod(timer:&timer)
                }
            }
            
            m_divider.ResetCounter()
            m_reload = false
        }
        else
        {
            ComputeTargetPeriod(timer: &timer)
            if (m_enabled)
            {
                if(m_divider.Clock())
                {
                    AdjustTimerPeriod(timer:&timer)
                }
            }
        }
    }
    
    func SilenceChannel()->Bool
    {
        if(!m_enabled)
        {
            return false
        }
        return m_silenceChannel
    }
    
    func ComputeTargetPeriod(timer: inout TimerEx)
    {
        if(!m_enabled)
        {
            return
        }
        assert(m_shiftCount < 8); // 3 bits

        let currPeriod = timer.GetPeriod()
        let shiftedPeriod = currPeriod >> m_shiftCount

        
        if (m_negate)
        {
            // Pulse 1's adder's carry is hardwired, so the subtraction adds the one's complement
            // instead of the expected two's complement (as pulse 2 does)
            //print(String(shiftedPeriod))
            
            if(shiftedPeriod > m_subtractExtra)
            {
                let del = (shiftedPeriod - m_subtractExtra)
                if(currPeriod > del)
                {
                    m_targetPeriod = currPeriod - (shiftedPeriod - m_subtractExtra)
                }
            }
        }
        else
        {
            m_targetPeriod = currPeriod + shiftedPeriod
        }
        
        if(currPeriod < 8 || m_targetPeriod > 0x7FF)
        {
            /*
            print("=======================")
            print("PulseChannel m_shiftCount ->" + String(m_shiftCount))
            print("PulseChannel shiftedPeriod ->" + String(shiftedPeriod))
            print("PulseChannel m_targetPeriod ->" + String(m_targetPeriod))
            print("PulseChannel currPeriod ->" + String(currPeriod))
            
            print("PulseChannel m_silenceChannel")
            
            print("=======================")
            */
        }
        
        //print("PulseChannel m_targetPeriod ->" + String(m_targetPeriod))
        // Channel will be silenced under certain conditions even if Sweep unit is disabled
        m_silenceChannel = (currPeriod < 8 || m_targetPeriod > 0x7FF)
    }
            
    func AdjustTimerPeriod(timer: inout TimerEx)
    {
        if(!m_enabled)
        {
            return
        }
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
    var m_num = 0
    
    func Restart()
    {
        m_step = 0
    }
    
    func SetDuty(_ duty:UInt8)
    {
        assert(duty < 4);
        m_duty = duty;
    }
    
    func Clock()
    {
        m_step = (m_step + 1) % 8;
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
        
        //m_duty = 0
        let step = m_step
        let value = sequences[Int(m_duty)][Int(m_step)]
        
        if(m_num == 0)
        {
            
        }
        
        //print(String(duty)+"-"+String(step))
        return value
    }
}
