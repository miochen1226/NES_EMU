//
//  Apu.swift
//  NES_EMU
//
//  Created by mio on 2023/7/24.
//

import Foundation
import SwiftUI









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
    
    
    /*
    FrameCounter(Apu& apu)
        : m_apu(&apu)
        , m_cpuCycles(0)
        , m_numSteps(4)
        , m_inhibitInterrupt(true)
    {
    }

   */

    func SetMode(_ mode:UInt8)
    {
        assert(mode < 2)
        if (mode == 0)
        {
            m_numSteps = 4
        }
        else
        {
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

        let mode = ReadBits(target: UInt16(BIT(7)), value: value) >> 7
        SetMode(UInt8(mode))

        
        if (TestBits(target: UInt16(BIT(6)), value: value))
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
            m_cpuCycles = 0
        }
        else
        {
            m_cpuCycles += 1
        }
    }

    func ReadBits(target:UInt16,  value:UInt8)->UInt16
    {
        return target & UInt16(value)
    }
    
    func TestBits(target:UInt16,  value:UInt8)->Bool
    {
        return ReadBits(target: target, value: value) != 0
    }
    func BIT(_ n:Int)->UInt8
    {
        return (1<<n)
    }
    
    

    func APU_TO_CPU_CYCLE(_ cpuCycle:Float32)->UInt32
    {
        return UInt32(cpuCycle*2)
    }
    
    func ClockQuarterFrameChips()
    {
        m_apu?.m_pulseChannel0.ClockQuarterFrameChips()
        m_apu?.m_pulseChannel1.ClockQuarterFrameChips()
        m_apu?.m_triangleChannel.ClockQuarterFrameChips()
        m_apu?.m_noiseChannel.ClockQuarterFrameChips()
    }

    func ClockHalfFrameChips()
    {
        m_apu?.m_pulseChannel0.ClockHalfFrameChips()
        m_apu?.m_pulseChannel1.ClockHalfFrameChips()
        m_apu?.m_triangleChannel.ClockHalfFrameChips()
        m_apu?.m_noiseChannel.ClockHalfFrameChips()
    }
}



class Apu:NSObject{
    enum ApuChannel
    {
        case PulseChannel1
        case PulseChannel2
        case TriangleChannel
        case NoiseChannel
    }
    var m_audioDriver = AudioDriver()
    var m_pulseChannel0 = PulseChannel.init(pulseChannelNumber: 0)
    var m_pulseChannel1 = PulseChannel.init(pulseChannelNumber: 1)
    var m_triangleChannel = TriangleChannel()
    var m_noiseChannel = NoiseChannel()
    var m_elapsedCpuCycles:Float = 0
    var m_frameCounter:FrameCounter!
    
    override init()
    {
        super.init()
        m_frameCounter = FrameCounter.init(apu: self)
        SetChannelVolume(type: .PulseChannel1, volume: 1.0)
        SetChannelVolume(type: .PulseChannel2, volume: 1.0)
        SetChannelVolume(type: .TriangleChannel, volume: 1.0)
        SetChannelVolume(type: .NoiseChannel, volume: 1.0)
        Reset()
    }
    
    var m_evenFrame = true
    var m_sampleSum = 0
    var m_numSamples = 0
    func Reset()
    {
        m_evenFrame = true
        m_elapsedCpuCycles = 0
        m_sampleSum = 0
        m_numSamples = 0
        
        HandleCpuWrite(cpuAddress: 0x4017, value: 0)
        HandleCpuWrite(cpuAddress: 0x4015, value: 0)
        for address in 0x4000...0x400F
        {
            HandleCpuWrite(cpuAddress:UInt16(address), value:0);
            
        }
    }
    
    static let kAvgNumScreenPpuCycles:Float32 = 89342 - 0.5
    static let kCpuCyclesPerSec:Float32 = (kAvgNumScreenPpuCycles / 3) * 60.0
    var m_channelVolumes:[ApuChannel:Float32] = [:]
    func SetChannelVolume(type:ApuChannel, volume:Float32)
    {
        m_channelVolumes[type] = volume//Clamp(volume, 0.0f, 1.0f);
    }
    
    func SampleChannelsAndMix()->Float32
    {
        let kMasterVolume:Float = 0.5
        // Sample all channels
       
        var pulse1 = Float32(m_pulseChannel0.GetValue() * m_channelVolumes[ApuChannel.PulseChannel1]!)
        var pulse2 = Float32(m_pulseChannel1.GetValue() * m_channelVolumes[ApuChannel.PulseChannel2]!)
        var triangle = Float32(m_triangleChannel.GetValue() * m_channelVolumes[ApuChannel.TriangleChannel]!)
        
        //triangle = 0
        
        var noise = Int(m_noiseChannel.GetValue() * m_channelVolumes[ApuChannel.NoiseChannel]!)
        
        //noise = 0
        //pulse1 = 0
        //pulse2 = 0
        //pulse2 = 0
        let dmc = 0.0
        /*
        const size_t pulse1 = static_cast<size_t>(m_pulseChannel0->GetValue() * m_channelVolumes[ApuChannel::Pulse1]);
        const size_t pulse2 = static_cast<size_t>(m_pulseChannel1->GetValue() * m_channelVolumes[ApuChannel::Pulse2]);
        const size_t triangle = static_cast<size_t>(m_triangleChannel->GetValue() * m_channelVolumes[ApuChannel::Triangle]);
        const size_t noise = static_cast<size_t>(m_noiseChannel->GetValue() * m_channelVolumes[ApuChannel::Noise]);
        const size_t dmc = static_cast<size_t>(0.0f);
        */
        // Mix samples
    //#if MIX_USING_LINEAR_APPROXIMATION
        // Linear approximation (less accurate than lookup table)
        let pulseOut:Float32 = 0.00152 * Float32((pulse1 + pulse2))//0.00752 * Float32((pulse1 + pulse2))
        var tndOut:Float32 = Float32(0.00851 * Float32(triangle)) + Float32(0.00494 * Float32(noise)) + Float32(0.00335 * Float32(dmc))
        
        
        /*
        if(pulseOut != 0)
        {
            print(pulse1)
            print(pulse2)
        }*/
    //#else
        // Lookup Table (accurate)
        /*
        static float32 pulseTable[31] = { ~0 };
        if (pulseTable[0] == ~0)
        {
            for (size_t i = 0; i < ARRAYSIZE(pulseTable); ++i)
            {
                pulseTable[i] = 95.52f / (8128.0f / i + 100.0f);
            }
        }
        static float32 tndTable[203] = { ~0 };
        if (tndTable[0] == ~0)
        {
            for (size_t i = 0; i < ARRAYSIZE(tndTable); ++i)
            {
                tndTable[i] = 163.67f / (24329.0f / i + 100.0f);
            }
        }

        const float32 pulseOut = pulseTable[pulse1 + pulse2];
        const float32 tndOut = tndTable[3 * triangle + 2 * noise + dmc];
         */
    //#endif

        let sample:Float32 = kMasterVolume * (pulseOut + tndOut);
        return sample;
    }

    struct MyOptions: OptionSet
    {
        let rawValue: UInt8
        
        static let One = MyOptions(rawValue: 0x01)
        static let Two = MyOptions(rawValue: 0x02)
        static let Four = MyOptions(rawValue: 0x04)
        static let Eight = MyOptions(rawValue: 0x08)
    }

    
    func HandleCpuRead( cpuAddress:UInt16)->UInt8
    {
        var result:MyOptions = []
        //result.ClearAll();

        switch (cpuAddress)
        {
        case 0x4015:
            //@TODO: set bits 7,6,4: DMC interrupt (I), frame interrupt (F), DMC active (D)
            //@TODO: Reading this register clears the frame interrupt flag (but not the DMC interrupt flag).
            
            if(m_pulseChannel0.GetLengthCounter().GetValue() > 0)
            {
                result.insert(MyOptions.One)
            }
            if(m_pulseChannel1.GetLengthCounter().GetValue() > 0)
            {
                result.insert(MyOptions.Two)
            }
            if(m_triangleChannel.GetLengthCounter().GetValue() > 0)
            {
                result.insert(MyOptions.Four)
            }
            if(m_noiseChannel.GetLengthCounter().GetValue() > 0)
            {
                result.insert(MyOptions.Eight)
            }
            /*
            result.SetPos(0, m_pulseChannel0->GetLengthCounter().GetValue() > 0);
            result.SetPos(1, m_pulseChannel1->GetLengthCounter().GetValue() > 0);
            result.SetPos(2, m_triangleChannel->GetLengthCounter().GetValue() > 0);
            result.SetPos(3, m_noiseChannel->GetLengthCounter().GetValue() > 0);
            */
            break
        default:
            break
        }
        
        return result.rawValue
    }
    
    func HandleCpuWrite(cpuAddress:UInt16, value:UInt8)
    {
        switch (cpuAddress)
        {
        case 0x4000,0x4001,0x4002,0x4003:
            m_pulseChannel0.HandleCpuWrite(cpuAddress:cpuAddress,value:value)
            break;

        case 0x4004,0x4005,0x4006,0x4007:
            m_pulseChannel1.HandleCpuWrite(cpuAddress:cpuAddress,value:value)
            break;

        case 0x4008,0x400A,0x400B:
            m_triangleChannel.HandleCpuWrite(cpuAddress:cpuAddress,value:value)
            break

        case 0x400C,0x400E,0x400F:
            m_noiseChannel.HandleCpuWrite(cpuAddress:cpuAddress,value:value)
            break

            /////////////////////
            // Misc
            /////////////////////
        case 0x4015:
            //15 =  1 2 4 8
            
            if(value != 15)
            {
                break
            }
            var e1 = TestBits(target: UInt16(BIT(0)), value: value)//TestBits(value, BIT(0))
            //e1 = true
            m_pulseChannel0.GetLengthCounter().SetEnabled(e1)
            
            var e2 = TestBits(target: UInt16(BIT(1)), value: value)
            //e2 = true
            m_pulseChannel1.GetLengthCounter().SetEnabled(e2)
            
            var e3 = TestBits(target: UInt16(BIT(2)), value: value)
            //e3 = true
            m_triangleChannel.GetLengthCounter().SetEnabled(e3)
            
            var e4 = TestBits(target: UInt16(BIT(3)), value: value)
            
            m_noiseChannel.GetLengthCounter().SetEnabled(e4)
            //@TODO: DMC Enable bit 4
            
            print(value)
            break

        case 0x4017:
            m_frameCounter.HandleCpuWrite(cpuAddress:cpuAddress,value:value)
            //m_frameCounter..HandleCpuWrite(cpuAddress:cpuAddress,value:value)
            break
        default:
            break
        }
    }
    
    func BIT(_ n:Int)->UInt8
    {
        return (1<<n)
    }
    
    func TestBits(target:UInt16,  value:UInt8)->Bool
    {
        return ReadBits(target: target, value: value) != 0
    }
    
    func ReadBits(target:UInt16,  value:UInt8)->UInt16
    {
        return target & UInt16(value)
    }
    
    func Execute(_ cpuCycles:UInt32)
    {
        let kCpuCyclesPerSample:Float = Apu.kCpuCyclesPerSec / m_audioDriver.GetSampleRate()
        for _ in 0...cpuCycles-1
        {
            m_frameCounter.Clock()

            // Clock all timers
            //{
                m_triangleChannel.ClockTimer()

                // All other timers are clocked every 2nd CPU cycle (every APU cycle)
                if (m_evenFrame)
                {
                    m_pulseChannel0.ClockTimer()
                    m_pulseChannel1.ClockTimer()
                    m_noiseChannel.ClockTimer()
                }

                m_evenFrame = !m_evenFrame;
            //}

        //#if SAMPLE_EVERY_CPU_CYCLE
        //    m_sampleSum += SampleChannelsAndMix();
        //    ++m_numSamples;
        //#endif

            // Fill the sample buffer at the current output sample rate (i.e. 48 KHz)
            m_elapsedCpuCycles += 1
            if (m_elapsedCpuCycles >= kCpuCyclesPerSample)
            {
                m_elapsedCpuCycles = m_elapsedCpuCycles - kCpuCyclesPerSample

            //#if SAMPLE_EVERY_CPU_CYCLE
            //    const float32 sample = m_sampleSum / m_numSamples;
            //    m_sampleSum = m_numSamples = 0;
            //#else
            //    const float32 sample = SampleChannelsAndMix();
            //#endif
                
                let sample:Float32 = SampleChannelsAndMix();
                m_audioDriver.AddSampleF32(sample:sample)
            }
            
            //let sample:Float32 = SampleChannelsAndMix();
            //m_audioDriver.AddSampleF32(sample:sample)
        }
    }
}
