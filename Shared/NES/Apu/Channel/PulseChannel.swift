//
//  PulseChannel.swift
//  NES_EMU
//
//  Created by mio on 2023/7/25.
//

import Foundation

class PulseChannel:BaseChannel {
    init(pulseChannelNumber: UInt8) {
        super.init()
        lengthCounter.setEnabled(true)
        if pulseChannelNumber == 0 {
            sweepUnit.setSubtractExtra()
        }
        pulseWaveGenerator.num = Int(pulseChannelNumber)
    }
    
    func clockQuarterFrameChips() {
        volumeEnvelope.clock()
    }
    
    func clockHalfFrameChips() {
        lengthCounter.clock()
        sweepUnit.clock(&timer)
    }
    
    func clockTimer() {
        if timer.clock() {
            pulseWaveGenerator.clock()
        }
    }
    
    func handle40004004(cpuAddress: UInt16, value: UInt8) {
        //DDlc.vvvv
        //l
        //表示 envelope loop 标志
        let l = testBits(target: BIT(5), value: value)
        //c
        //表示是否为常量音量
        
        let c = testBits(target: BIT(4), value: value)
        
        //vvvv
        //如果 c 置位，表示音量大小，否则表示 envelope 的分频计数
        let vvvv = readBits8(target: BITS([0,1,2,3]), value: value)
        
        let DD = readBits8(target: BITS([6,7]), value: value) >> 6
        pulseWaveGenerator.setDuty(UInt8(DD))
        
        lengthCounter.setHalt(l)
        volumeEnvelope.setLoop(l)
        
        if c {
            volumeEnvelope.setConstantVolumeMode(true)
            volumeEnvelope.setConstantVolume(UInt16(vvvv))
        }
        else {
            volumeEnvelope.setConstantVolumeMode(false)
            volumeEnvelope.setCounter(UInt16(vvvv))
        }
    }
    
    func handle40014005(cpuAddress:UInt16, value: UInt8) {
        //EPPP.NSSS
        //E
        //表示是否使能 sweep
        //PPP
        //sweep 的分频计数
        //N
        //sweep 是否为负，用来控制频率随时间增大还是减小
        //SSS
        //位移量，用于每个 sweep 周期将 timer 右移对应的位移量得到增量

        let E = testBits(target: BIT(7), value: value)
        sweepUnit.setEnabled(E)
        
        let PPP = readBits8(target: BITS([4,5,6]), value: value) >> 4
        sweepUnit.setPeriod(period: UInt16(PPP), timer: &timer)
        
        let N = testBits(target: BIT(3), value: value)
        sweepUnit.setNegate(N)
        
        let SSS = readBits8( target:BITS([0,1,2]),value:value)
        sweepUnit.setShiftCount(SSS)
        
        sweepUnit.restart()
    }
    
    func handle40024006(cpuAddress:UInt16, value:UInt8)
    {
        //LLLL.LLLL
        //LLLLLLLL
        //timer 的低 8 位（一共 11 位，用于将 cpu 二分频后的时钟继续分频）
        timer.setPeriodLow8(value)
    }
    
    func handle40034007(cpuAddress: UInt16, value: UInt8) {
        //llll.lHHH
        //lllll
        //length counter 分频计数
        //HHH
        //timer 的高 3 位，和 0x4002 / 0x4006 组成完整的计数
        let HHH = readBits8(target: BITS([0,1,2]),value:value)
        timer.setPeriodHigh3(UInt16(HHH))
        
        let LLLL = readBits8( target:BITS([3,4,5,6,7]),value:value) >> 3
        lengthCounter.loadCounterFromLUT(LLLL)
        
        volumeEnvelope.restart()
        pulseWaveGenerator.restart()
    }
    
    override func handleCpuWrite(cpuAddress: UInt16, value:UInt8) {
        switch cpuAddress {
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
        default:
            //assert(false)
            break
        }
    }
    
    override func getValue() -> Float32 {
        
        if sweepUnit.silenceChannel() {
            return 0
        }
        if lengthCounter.silenceChannel() {
            return 0
        }
        
        let value = Float32(volumeEnvelope.getVolume()) * Float32(pulseWaveGenerator.getValue())
        assert(value < 16)
        return value
    }
    
    let volumeEnvelope = VolumeEnvelope()
    let sweepUnit = SweepUnit()
    let pulseWaveGenerator = PulseWaveGenerator()
}

class VolumeEnvelope {
    func restart() {
        wantRestart = true
    }
    
    func setLoop(_ loop: Bool) {
        self.loop = loop
    }
    
    func setConstantVolumeMode(_ mode: Bool) {
        constantVolumeMode = mode
    }
                
    func setCounter(_ value: UInt16) {
        divider.setPeriod(value)
    }
    
    func setConstantVolume(_ value: UInt16) {
        constantVolume = value
        divider.setPeriod(constantVolume)
    }
                
    func getVolume() -> UInt16 {
        var result: UInt16 = 0
        if constantVolumeMode {
            result = constantVolume
        }
        else {
            result = counter
        }
        
        return result
    }
                
    func clock() {
        if wantRestart {
            wantRestart = false
            counter = 15
            divider.resetCounter();
        }
        else {
            if divider.clock() {
                if counter > 0 {
                    counter = counter - 1
                }
                else if loop {
                    counter = 15
                }
            }
        }
    }
    
    var loop = false
    var wantRestart = true
    var counter: UInt16 = 0
    var constantVolumeMode: Bool = false
    var constantVolume: UInt16 = 0
    let divider = ChannelComponent.Divider()
}

class SweepUnit {
    func setSubtractExtra() {
        subtractExtra = 1
    }
    
    func setEnabled(_ enabled:Bool) {
        self.enabled = enabled
    }
    
    func setNegate(_ negate: Bool) {
        self.negate = negate
    }
    
    func setPeriod(period: UInt16, timer: inout ChannelComponent.Timer) {
        divider.setPeriod(period)
    }
    
    func setShiftCount(_ shiftCount: UInt8) {
        self.shiftCount = shiftCount
    }
    
    func restart() {
        reload = true
    }
    
    // Clocked by FrameCounter
    func clock(_ timer: inout ChannelComponent.Timer) {
        if !enabled {
            return
        }
        
        if reload {
            if enabled {
                timer.reset()
                computeTargetPeriod(timer: &timer)
                if divider.clock() {
                    adjustTimerPeriod(timer:&timer)
                }
            }
            
            divider.resetCounter()
            reload = false
        }
        else {
            computeTargetPeriod(timer: &timer)
            if enabled {
                if divider.clock() {
                    adjustTimerPeriod(timer:&timer)
                }
            }
        }
    }
    
    func silenceChannel() -> Bool {
        if !enabled {
            return false
        }
        return isSilenceChannel
    }
    
    func computeTargetPeriod(timer: inout ChannelComponent.Timer) {
        if !enabled {
            return
        }
        assert(shiftCount < 8)

        let currPeriod = timer.getPeriod()
        let shiftedPeriod = currPeriod >> shiftCount
        if (negate) {
            // Pulse 1's adder's carry is hardwired, so the subtraction adds the one's complement
            // instead of the expected two's complement (as pulse 2 does)
            //print(String(shiftedPeriod))
            
            if shiftedPeriod > subtractExtra {
                let del = (shiftedPeriod - subtractExtra)
                if currPeriod > del {
                    targetPeriod = currPeriod - (shiftedPeriod - subtractExtra)
                }
            }
        }
        else {
            targetPeriod = currPeriod + shiftedPeriod
        }
        
        isSilenceChannel = (currPeriod < 8 || targetPeriod > 0x7FF)
    }
            
    func adjustTimerPeriod(timer: inout ChannelComponent.Timer) {
        if !enabled {
            return
        }
        // If channel is not silenced, it means we're in range
        if enabled && shiftCount > 0 && !isSilenceChannel {
            timer.setPeriod(targetPeriod)
        }
    }
    
    var negate = false
    var targetPeriod: UInt16 = 0
    var subtractExtra: UInt16 = 0
    var enabled = false
    var reload = false
    var shiftCount: UInt8 = 0
    var isSilenceChannel = false
    let divider = ChannelComponent.Divider()
}

class PulseWaveGenerator {
    func restart() {
        step = 0
    }
    
    func setDuty(_ duty: UInt8) {
        assert(duty < 4)
        self.duty = duty
    }
    
    func clock() {
        step = (step + 1) % 8;
    }
    
    func getValue() -> UInt8 {
        let value = sequences[Int(duty)][Int(step)]
        return value
    }
    
    let sequences:[[UInt8]] =
    [
        [ 0, 1, 0, 0, 0, 0, 0, 0 ], // 12.5%
        [ 0, 1, 1, 0, 0, 0, 0, 0 ], // 25%
        [ 0, 1, 1, 1, 1, 0, 0, 0 ], // 50%
        [ 1, 0, 0, 1, 1, 1, 1, 1 ]  // 25% negated
    ]
    
    var duty: UInt8 = 0
    var step: UInt8 = 0
    var num = 0
}
