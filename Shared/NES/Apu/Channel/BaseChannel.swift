//
//  BaseChannel.swift
//  NES_EMU
//
//  Created by mio on 2023/7/25.
//

import Foundation


class ChannelComponent {
    class Divider {
        func setPeriod(_ period: UInt16){
            self.period  = period
        }
        
        func getPeriod() -> UInt16 {
            return period
        }
        
        func getCounter() -> UInt16 {
            return counter
        }
        
        func resetCounter() {
            counter = period
        }
        
        func clock()->Bool {
            if counter == 0 {
                resetCounter()
                return true
            }
            counter -= 1
            return false
        }
        
        var period:UInt16 = 0
        var counter:UInt16 = 0
    }

    class Timer {
        func reset() {
            divider.resetCounter()
        }
        
        func getPeriod() -> UInt16 {
            return divider.getPeriod()
        }
        
        func setPeriod(_ period: UInt16) {
            divider.setPeriod(period)
        }
        
        func setPeriodLow8(_ value: UInt8) {
            var period:UInt16 = divider.getPeriod()
            //period = (period & BITS16([8,9,10])) | UInt16(value)
            period = (period & BITS16([8,9,10])) | UInt16(value)
            //periodTemp = UInt16(value)
            setPeriod(period)
            //print("periodTemp->" + String(periodTemp))
            //setPeriod(UInt16(value))
            //divider.resetCounter()
        }
        
        //var periodTemp:UInt16 = 0
        func setPeriodHigh3(_ value: UInt16) {
            assert(value < BIT(3))
            
            var period:UInt16 = divider.getPeriod()
            period = (value << 8) | (period & 0xFF)
            
            //periodTemp = (value << 8) | (periodTemp & 0xFF)
            setPeriod(period)
            //print("periodTemp->" + String(periodTemp))
            //setPeriod(UInt16(400))
            //divider.resetCounter()
        }
        
        func setMinPeriod(_ minPeriod: Int){
            self.minPeriod = minPeriod
        }

        // Clocked by CPU clock every cycle (triangle channel) or second cycle (pulse/noise channels)
        // Returns true when output chip should be clocked
        func clock()-> Bool {
            // Avoid popping and weird noises from ultra sonic frequencies
            //if (m_divider.GetPeriod() < m_minPeriod)
            //{
            //    return false
            //}
                
            if divider.clock() {
                return true
            }
            
            return false
        }
        
        let divider = Divider()
        var minPeriod = 0
    }

    class LengthCounter {
        func setEnabled(_ enabled: Bool) {
            self.enabled = enabled
            if !enabled {
                counter = 0
            }
        }
        
        //DMC use
        func getEnabled() -> Bool {
            return enabled
        }
        
        func setHalt(_ halt: Bool) {
            self.halt = halt
        }
        
        func loadCounterFromLUT(_ index: UInt8) {
            if !enabled {
                return
            }
            counter = UInt16(lut[Int(index)])
        }
        
        func clock() {
            if halt {
                return
            }
            
            if counter > 0 {
                counter = counter-1
            }
        }
        
        func getValue() -> UInt16 {
            return counter
        }
        
        func silenceChannel() -> Bool {
            if counter == 0 {
                return true
            }
            else {
                return false
            }
        }
        
        var enabled = false
        var halt = false
        var counter:UInt16 = 0
        let lut:[UInt8] =
        [
            10, 254, 20, 2, 40, 4, 80, 6, 160, 8, 60, 10, 14, 12, 26, 14,
            12, 16, 24, 18, 48, 20, 96, 22, 192, 24, 72, 26, 16, 28, 32, 30
        ]
    }
    
    class LinearCounter {
        func restart() {
            reload = true
        }
        
        func setControlAndPeriod(control: Bool, period: UInt16) {
            self.control = control
            assert(period < BIT(7))
            divider.setPeriod(period)
        }
        
        func clock() {
            if reload {
                divider.resetCounter()
            }
            else if divider.getCounter() > 0 {
                _ = divider.clock()
            }

            if !control {
                reload = false
            }
        }
        
        func getValue() -> UInt16 {
            return divider.getCounter()
        }

        func silenceChannel() -> Bool {
            if getValue() == 0 {
                return true
            }
            else {
                return false
            }
        }
        
        let divider = Divider()
        var reload: Bool = true
        var control: Bool = true
    }
}

class BaseChannel {
    func getLengthCounter() -> ChannelComponent.LengthCounter {
        return lengthCounter
    }
    
    func getValue() -> Float32 {
        assert(false)
        return 1.0
    }
    
    func handleCpuWrite(cpuAddress: UInt16, value: UInt8) {
        assert(false)
    }
    
    var timer = ChannelComponent.Timer()
    let linearCounter = ChannelComponent.LinearCounter()
    var lengthCounter = ChannelComponent.LengthCounter()
}
