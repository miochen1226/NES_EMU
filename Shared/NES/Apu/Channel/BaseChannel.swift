//
//  BaseChannel.swift
//  NES_EMU
//
//  Created by mio on 2023/7/25.
//

import Foundation




class ChannelComponent
{
    class Divider
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
                return true
            }
            m_counter -= 1
            return false
        }
    }

    class LinearCounter
    {
        let m_divider = Divider()
        
        var m_reload = true
        var m_control = true
        
        func Restart()
        {
            m_reload = true
        }
        
        func  SetControlAndPeriod(control:Bool, period:UInt16)
        {
            m_control = control;
            assert(period < BIT(7))
            m_divider.SetPeriod(period)
        }
        
        func Clock()
        {
            if (m_reload)
            {
                m_divider.ResetCounter()
            }
            else if (m_divider.GetCounter() > 0)
            {
                m_divider.Clock()
            }

            if (!m_control)
            {
                m_reload = false
            }
        }
        
        func GetValue()->UInt16
        {
            return m_divider.GetCounter()
        }

        func SilenceChannel()->Bool
        {
            if(GetValue() == 0)
            {
                return true
            }
            else
            {
                return false
            }
        }
    }
    
    class LengthCounter
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
                return
            }
            
            //print("LoadCounterFromLUT" + String(index))
            //static_assert(ARRAYSIZE(lut) == 32, "Invalid");
            //assert(index < ARRAYSIZE(lut));
            m_counter = UInt16(lut[Int(index)])
        }
        
        func Clock()
        {
            if (m_halt)
            {
                return
            }
            
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
            if(m_counter == 0)
            {
                return true
            }
            else
            {
                return false
            }
        }
    }

    class Timer
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
        /*
        let m_divider = Divider()
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
            SetPeriod(period)
        }
        
        func SetPeriodHigh3(_ value:UInt16)
        {
            //assert(value < BIT(3));
            var period:UInt16 = m_divider.GetPeriod()
            //period = (value << 8) | (period & 0xFF); // Keep low 8 bits
            period = (value << 8) | (period & 0xFF)
            m_divider.SetPeriod(period)
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
            if (m_divider.GetPeriod() < m_minPeriod)
            {
                return false
            }
                
            if (m_divider.Clock())
            {
                return true
            }
            
            return false
        }*/
    }
}


class BaseChannel
{
    let m_timer = ChannelComponent.Timer()
    let m_linearCounter = ChannelComponent.LinearCounter()
    var m_lengthCounter = ChannelComponent.LengthCounter()
    
    func GetLengthCounter()->ChannelComponent.LengthCounter
    {
        return m_lengthCounter;
    }
    
    func GetValue()->Float32
    {
        assert(false)
        return 1.0
    }
    
    func HandleCpuWrite(cpuAddress:UInt16, value:UInt8)
    {
        assert(false)
    }
}
