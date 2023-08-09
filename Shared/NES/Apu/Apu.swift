//
//  Apu.swift
//  NES_EMU
//
//  Created by mio on 2023/7/24.
//

import Foundation
//import SwiftUI

class Apu:NSObject{
    enum ApuChannel
    {
        case PulseChannel1
        case PulseChannel2
        case TriangleChannel
        case NoiseChannel
    }
    
    
    var m_audioDriver:AudioDriver?
    var m_frameCounter:FrameCounter?
    
    var m_pulseChannel0:PulseChannel?
    var m_pulseChannel1:PulseChannel?
    var m_triangleChannel:TriangleChannel?
    var m_noiseChannel:NoiseChannel?
    
    var m_elapsedCpuCycles:Float = 0
    var m_sampleRate:Double = 0
    
    let nesFrameProvider = NesFrameProvider()
    
    override init()
    {
        super.init()
        
        
        initCompoment()
        
        m_sampleRate = 44100
        
        kCpuCyclesPerSample = Apu.kCpuCyclesPerSec / Float(m_sampleRate)
        SetChannelVolume(type: .PulseChannel1, volume: 1.0)
        SetChannelVolume(type: .PulseChannel2, volume: 1.0)
        SetChannelVolume(type: .TriangleChannel, volume: 1.0)
        SetChannelVolume(type: .NoiseChannel, volume: 1.0)
        Reset()
    }
    
    func initCompoment()
    {
        m_frameCounter = FrameCounter.init(apu: self)
        m_audioDriver = AudioDriver(frameProvider: self.nesFrameProvider)
        m_pulseChannel0 = PulseChannel.init(pulseChannelNumber: 0)
        m_pulseChannel1 = PulseChannel.init(pulseChannelNumber: 1)
        m_triangleChannel = TriangleChannel()
        m_noiseChannel = NoiseChannel()
    }
    
    var m_evenFrame = true
    var m_sampleSum = 0
    var m_numSamples = 0
    
    func ClockQuarterFrameChips()
    {
        m_pulseChannel0?.ClockQuarterFrameChips()
        m_pulseChannel1?.ClockQuarterFrameChips()
        m_triangleChannel?.ClockQuarterFrameChips()
        m_noiseChannel?.ClockQuarterFrameChips()
    }

    func ClockHalfFrameChips()
    {
        m_pulseChannel0?.ClockHalfFrameChips()
        m_pulseChannel1?.ClockHalfFrameChips()
        m_triangleChannel?.ClockHalfFrameChips()
        m_noiseChannel?.ClockHalfFrameChips()
    }
    
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
    
    var count = 0
    
    func getChannelValue(_ channel:ApuChannel)->Float32
    {
        var channelValue:Float32 = 0
        var channelVolume:Float32 = 0
        
        channelVolume = m_channelVolumes[ApuChannel.PulseChannel1] ?? 0
        
        switch (channel)
        {
        case .PulseChannel1:
            channelValue = m_pulseChannel0?.GetValue() ?? 0
            break
        case .PulseChannel2:
            channelValue = m_pulseChannel1?.GetValue() ?? 0
            break
        case .TriangleChannel:
            channelValue = m_triangleChannel?.GetValue() ?? 0
            break
        case .NoiseChannel:
            channelValue = m_noiseChannel?.GetValue() ?? 0
            break
        }
        return channelValue * channelVolume
    }
    
    func SampleChannelsAndMix()->Float32
    {
        let kMasterVolume:Float = 1.0
        // Sample all channels
        let pulse1 = getChannelValue(.PulseChannel1)
        let pulse2 = getChannelValue(.PulseChannel2)
        let triangle = getChannelValue(.TriangleChannel)
        let noise = getChannelValue(.NoiseChannel)
        let dmc = 0.0
        
        let pulseOut:Float32 = 0.00752 * Float32((pulse1 + pulse2))//0.00752 * Float32((pulse1 + pulse2))
        let tndOut:Float32 = Float32(0.00851 * Float32(triangle)) + Float32(0.00494 * Float32(noise)) + Float32(0.00335 * Float32(dmc))

        let sample:Float32 = kMasterVolume * (pulseOut + tndOut)
        return sample
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
        let bitField = Bitfield8()

        switch (cpuAddress)
        {
        case 0x4015:
            //@TODO: set bits 7,6,4: DMC interrupt (I), frame interrupt (F), DMC active (D)
            //@TODO: Reading this register clears the frame interrupt flag (but not the DMC interrupt flag).
            
            if(m_pulseChannel0?.GetLengthCounter().GetValue() ?? 0 > 0)
            {
                bitField.SetPos(bitPos: 0, enabled: 1)
            }
            if(m_pulseChannel1?.GetLengthCounter().GetValue() ?? 0 > 0)
            {
                bitField.SetPos(bitPos: 1, enabled: 1)
            }
            if(m_triangleChannel?.GetLengthCounter().GetValue() ?? 0 > 0)
            {
                bitField.SetPos(bitPos: 2, enabled: 1)
            }
            if(m_noiseChannel?.GetLengthCounter().GetValue() ?? 0 > 0)
            {
                bitField.SetPos(bitPos: 4, enabled: 1)
            }
            break
        default:
            break
        }
        
        return bitField.Value()
    }
    
    func HandleCpuWrite(cpuAddress:UInt16, value:UInt8)
    {
        switch (cpuAddress)
        {
        case 0x4000,0x4001,0x4002,0x4003:
            m_pulseChannel0?.HandleCpuWrite(cpuAddress:cpuAddress,value:value)
            break;

        case 0x4004,0x4005,0x4006,0x4007:
            m_pulseChannel1?.HandleCpuWrite(cpuAddress:cpuAddress,value:value)
            break;

        case 0x4008,0x400A,0x400B:
            m_triangleChannel?.HandleCpuWrite(cpuAddress:cpuAddress,value:value)
            break

        case 0x400C,0x400E,0x400F:
            m_noiseChannel?.HandleCpuWrite(cpuAddress:cpuAddress,value:value)
            break

            /////////////////////
            // Misc
            /////////////////////
        case 0x4015:
            //15 =  1 2 4 8
            var e1 = TestBits(target: BIT(0), value: value)//TestBits(value, BIT(0))
            //e1 = true
            m_pulseChannel0?.GetLengthCounter().SetEnabled(e1)
            
            var e2 = TestBits(target: BIT(1), value: value)
            //e2 = true
            m_pulseChannel1?.GetLengthCounter().SetEnabled(e2)
            
            var e3 = TestBits(target: BIT(2), value: value)
            //e3 = true
            m_triangleChannel?.GetLengthCounter().SetEnabled(e3)
            
            var e4 = TestBits(target: BIT(3), value: value)
            //e4 = true
            m_noiseChannel?.GetLengthCounter().SetEnabled(e4)
            //@TODO: DMC Enable bit 4
            
            break

        case 0x4017:
            m_frameCounter?.HandleCpuWrite(cpuAddress:cpuAddress,value:value)
            //m_frameCounter..HandleCpuWrite(cpuAddress:cpuAddress,value:value)
            break
        default:
            break
        }
    }
    
    var kCpuCyclesPerSample:Float32 = 0
    
    func Execute(_ cpuCycles:UInt32)
    {
        for _ in 0...cpuCycles-1
        {
            m_frameCounter?.Clock()
            m_triangleChannel?.ClockTimer()
            //if (m_evenFrame)
            //{
                m_pulseChannel0?.ClockTimer()
                m_pulseChannel1?.ClockTimer()
                m_noiseChannel?.ClockTimer()
            //}
            m_evenFrame = !m_evenFrame;
            
            // Fill the sample buffer at the current output sample rate (i.e. 48 KHz)
            m_elapsedCpuCycles += 1
            if (m_elapsedCpuCycles >= kCpuCyclesPerSample)
            {
                m_elapsedCpuCycles = m_elapsedCpuCycles - kCpuCyclesPerSample
                let sample:Float32 = SampleChannelsAndMix()
                m_audioDriver?.m_frameProvider.enqueue(input: sample)
            }
        }
    }
}
