//
//  Apu.swift
//  NES_EMU
//
//  Created by mio on 2023/7/24.
//

import Foundation

class Apu: NSObject {
    override init() {
        super.init()
        initCompoment()
        setChannelVolume(type: .PulseChannel1, volume: 1.0)
        setChannelVolume(type: .PulseChannel2, volume: 1.0)
        setChannelVolume(type: .TriangleChannel, volume: 1.0)
        setChannelVolume(type: .NoiseChannel, volume: 1.0)
        reset()
    }
    
    func initCompoment() {
        frameCounter = FrameCounter.init(apu: self)
        audioDriver = AudioDriver()
        
        pulseChannel0 = PulseChannel.init(pulseChannelNumber: 0)
        pulseChannel1 = PulseChannel.init(pulseChannelNumber: 1)
        triangleChannel = TriangleChannel()
        noiseChannel = NoiseChannel()
    }
    
    func clockQuarterFrameChips() {
        pulseChannel0?.clockQuarterFrameChips()
        pulseChannel1?.clockQuarterFrameChips()
        triangleChannel?.clockQuarterFrameChips()
        noiseChannel?.clockQuarterFrameChips()
    }

    func clockHalfFrameChips() {
        pulseChannel0?.clockHalfFrameChips()
        pulseChannel1?.clockHalfFrameChips()
        triangleChannel?.clockHalfFrameChips()
        noiseChannel?.clockHalfFrameChips()
    }
    
    func reset() {
        elapsedCpuCycles = 0
        sampleSum = 0
        numSamples = 0
        
        HandleCpuWrite(cpuAddress: 0x4017, value: 0)
        HandleCpuWrite(cpuAddress: 0x4015, value: 0)
        for address in 0x4000...0x400F
        {
            HandleCpuWrite(cpuAddress:UInt16(address), value:0);
        }
    }
    
    func setChannelVolume(type:ApuChannel, volume: Float32){
        channelVolumes[type] = volume
    }
    
    func getChannelValue(_ channel: ApuChannel) -> Float32
    {
        var channelValue:Float32 = 0
        var channelVolume:Float32 = 0
        
        channelVolume = channelVolumes[ApuChannel.PulseChannel1] ?? 0
        
        switch (channel)
        {
        case .PulseChannel1:
            channelValue = pulseChannel0?.getValue() ?? 0
            break
        case .PulseChannel2:
            channelValue = pulseChannel1?.getValue() ?? 0
            break
        case .TriangleChannel:
            channelValue = triangleChannel?.getValue() ?? 0
            break
        case .NoiseChannel:
            channelValue = noiseChannel?.getValue() ?? 0
            break
        }
        return channelValue * channelVolume
    }
    
    func SampleChannelsAndMix() -> Float32
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
    
    func HandleCpuRead( cpuAddress:UInt16) -> UInt8 {
        let bitField = Bitfield8()

        switch cpuAddress {
        case 0x4015:
            //@TODO: set bits 7,6,4: DMC interrupt (I), frame interrupt (F), DMC active (D)
            //@TODO: Reading this register clears the frame interrupt flag (but not the DMC interrupt flag).
            
            if(pulseChannel0?.getLengthCounter().getValue() ?? 0 > 0)
            {
                bitField.setPos(bitPos: 0, enabled: 1)
            }
            if(pulseChannel1?.getLengthCounter().getValue() ?? 0 > 0)
            {
                bitField.setPos(bitPos: 1, enabled: 1)
            }
            if(triangleChannel?.getLengthCounter().getValue() ?? 0 > 0)
            {
                bitField.setPos(bitPos: 2, enabled: 1)
            }
            if(noiseChannel?.getLengthCounter().getValue() ?? 0 > 0)
            {
                bitField.setPos(bitPos: 4, enabled: 1)
            }
            break
        default:
            break
        }
        
        return bitField.value()
    }
    
    func HandleCpuWrite(cpuAddress: UInt16, value: UInt8) {
        switch cpuAddress {
        case 0x4000,0x4001,0x4002,0x4003:
            pulseChannel0?.handleCpuWrite(cpuAddress:cpuAddress,value:value)
            break;
        case 0x4004,0x4005,0x4006,0x4007:
            pulseChannel1?.handleCpuWrite(cpuAddress:cpuAddress,value:value)
            break;
        case 0x4008,0x400A,0x400B:
            triangleChannel?.handleCpuWrite(cpuAddress:cpuAddress,value:value)
            break
        case 0x400C,0x400E,0x400F:
            noiseChannel?.handleCpuWrite(cpuAddress:cpuAddress,value:value)
            break
        case 0x4015:
            pulseChannel0?.getLengthCounter().setEnabled(testBits(target: BIT(0), value: value))
            pulseChannel1?.getLengthCounter().setEnabled(testBits(target: BIT(1), value: value))
            triangleChannel?.getLengthCounter().setEnabled(testBits(target: BIT(2), value: value))
            noiseChannel?.getLengthCounter().setEnabled(testBits(target: BIT(3), value: value))
            //@TODO: DMC Enable bit 4
            
            break
        case 0x4017:
            frameCounter?.handleCpuWrite(cpuAddress:cpuAddress,value:value)
            break
        default:
            break
        }
    }
    
    func execute(_ cpuCycles: UInt32) {
        for _ in 0 ..< cpuCycles {
            frameCounter?.Clock()
            triangleChannel?.clockTimer()
            pulseChannel0?.clockTimer()
            pulseChannel1?.clockTimer()
            noiseChannel?.clockTimer()
            
            elapsedCpuCycles += 1
            if elapsedCpuCycles >= Apu.kCpuCyclesPerSample {
                elapsedCpuCycles = elapsedCpuCycles - Apu.kCpuCyclesPerSample
                let inputFrame: Float32 = SampleChannelsAndMix()
                audioDriver?.enqueue(inputFrame: inputFrame)
            }
        }
    }
    
    enum ApuChannel {
        case PulseChannel1
        case PulseChannel2
        case TriangleChannel
        case NoiseChannel
    }
    
    static let kAvgNumScreenPpuCycles:Float32 = 89342 - 0.5
    static let kCpuCyclesPerSec:Float32 = (kAvgNumScreenPpuCycles / 3) * 60.0
    static let sampleRate: Double = 44100
    static let kCpuCyclesPerSample:Float32 = Apu.kCpuCyclesPerSec/Float(sampleRate)
    
    
    var audioDriver: AudioDriver?
    var frameCounter: FrameCounter?
    
    var pulseChannel0: PulseChannel?
    var pulseChannel1: PulseChannel?
    var triangleChannel: TriangleChannel?
    var noiseChannel: NoiseChannel?
    
    var elapsedCpuCycles: Float = 0
    var sampleSum = 0
    var numSamples = 0
    var channelVolumes:[ApuChannel:Float32] = [:]
}
