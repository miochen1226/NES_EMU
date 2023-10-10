//
//  Apu.swift
//  NES_EMU
//
//  Created by mio on 2023/7/24.
//

import Foundation

class Apu: NSObject {
    
    func initialize(nes:Nes) {
        self.nes = nes
        initCompoment()
        setChannelVolume(type: .PulseChannel1, volume: 1.0)
        setChannelVolume(type: .PulseChannel2, volume: 1.0)
        setChannelVolume(type: .TriangleChannel, volume: 1.0)
        setChannelVolume(type: .NoiseChannel, volume: 1.0)
        setChannelVolume(type: .DmcChannel, volume: 1.0)
        reset()
    }
    
    override init() {
        super.init()
    }
    
    func initCompoment() {
        frameCounter = FrameCounter.init(apu: self)
        audioDriver = AudioDriver()
        
        pulseChannel0 = PulseChannel.init(pulseChannelNumber: 0)
        pulseChannel1 = PulseChannel.init(pulseChannelNumber: 1)
        triangleChannel = TriangleChannel()
        noiseChannel = NoiseChannel()
        //dmcChannel = DmcChannel()
    }
    
    func clockQuarterFrameChips() {
        pulseChannel0?.clockQuarterFrameChips()
        pulseChannel1?.clockQuarterFrameChips()
        triangleChannel?.clockQuarterFrameChips()
        noiseChannel?.clockQuarterFrameChips()
        dmcChannel?.clockQuarterFrameChips()
    }

    func clockHalfFrameChips() {
        pulseChannel0?.clockHalfFrameChips()
        pulseChannel1?.clockHalfFrameChips()
        triangleChannel?.clockHalfFrameChips()
        noiseChannel?.clockHalfFrameChips()
        dmcChannel?.clockHalfFrameChips()
    }
    
    func reset() {
        elapsedCpuCycles = 0
        sampleSum = 0
        numSamples = 0
        
        HandleCpuWrite(cpuAddress: 0x4017, value: 0)
        HandleCpuWrite(cpuAddress: 0x4015, value: 0)
        for address in 0x4000...0x400F {
            HandleCpuWrite(cpuAddress:UInt16(address), value:0);
        }
    }
    
    func setChannelVolume(type:ApuChannel, volume: Float32) {
        channelVolumes[type] = volume
    }
    
    func getChannelValue(_ channel: ApuChannel) -> Float32 {
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
        case .DmcChannel:
            channelValue = dmcChannel?.getValue() ?? 0
            break
        }
        return channelValue * channelVolume
    }
    
    func SampleChannelsAndMix() -> Float32 {
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
        print("APU HandleCpuRead")
        switch cpuAddress {
        case 0x4015:
            //IF-D NT21
            //@TODO: set bits 7,6,4: DMC interrupt (I), frame interrupt (F), DMC active (D)
            //@TODO: Reading this register clears the frame interrupt flag (but not the DMC interrupt flag).
            frameCounter?.InhibitInterrupt()
            
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
                bitField.setPos(bitPos: 3, enabled: 1)
            }
            
            let D:UInt8 = dmcChannel?.interrupt ?? 0
            bitField.setPos(bitPos: 4, enabled: D)
            
            let F:UInt8 = getFrameInterrupt()
            bitField.setPos(bitPos: 6, enabled: F)
            
            //let I:UInt8 = dmcChannel?.getI() ?? 0
            //bitField.setPos(bitPos: 7, enabled: I)
            
            break
        default:
            break
        }
        
        return bitField.value()
    }
    
    func getFrameInterrupt() -> UInt8 {
        let interrupt = frameCounter?.enableIRQ ?? 0
        return interrupt
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
        case 0x4010,0x4011,0x4012,0x4013:
            
            //print("$4010–$4013")
            dmcChannel?.handleCpuWrite(cpuAddress:cpuAddress,value:value)
            break
        case 0x4015:
            //---D NT21
            let enableP1 = testBits(target: BIT(0), value: value)
            pulseChannel0?.getLengthCounter().setEnabled(enableP1)
            
            let enableP2 = testBits(target: BIT(1), value: value)
            pulseChannel1?.getLengthCounter().setEnabled(enableP2)
            
            
            let enableTriangle = testBits(target: BIT(2), value: value)
            triangleChannel?.getLengthCounter().setEnabled(enableTriangle)
            
            let enableNoise = testBits(target: BIT(3), value: value)
            noiseChannel?.getLengthCounter().setEnabled(enableNoise)
            
            //@TODO: DMC Enable bit 4
            let enableDMC = testBits(target: BIT(4), value: value)
            dmcChannel?.getLengthCounter().setEnabled(enableDMC)
            break
        case 0x4017:
            frameCounter?.handleCpuWrite(cpuAddress:cpuAddress,value:value)
            break
        default:
            break
        }
    }
    
    var evenFrame = false
    func execute(_ cpuCycles: UInt32) {
        for _ in 0 ..< cpuCycles {
            frameCounter?.Clock()
            
            evenFrame = !evenFrame
            
            triangleChannel?.clockTimer()
            //if evenFrame {
                pulseChannel0?.clockTimer()
                pulseChannel1?.clockTimer()
                noiseChannel?.clockTimer()
                dmcChannel?.clockTimer()
            //}
            
            elapsedCpuCycles += 1
            
            //All output
            //let inputFrame: Float32 = SampleChannelsAndMix()
            //audioDriver?.enqueue(inputFrame: inputFrame)
            
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
        case DmcChannel
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
    var dmcChannel:DmcChannel?
    var elapsedCpuCycles: Float = 0
    var sampleSum = 0
    var numSamples = 0
    var channelVolumes:[ApuChannel:Float32] = [:]
    var nes:Nes? = nil
}
