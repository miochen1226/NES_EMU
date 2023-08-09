//
//  Bitfield8.swift
//  NES_EMU
//
//  Created by mio on 2021/8/10.
//

import Foundation
class Bitfield8 {
    var m_field:UInt8 = 0
    
    /*
    init()->Bitfield8
    {
        ClearAll()
        return self
    }
    */

    func Value()->UInt8
    {
        return m_field
    }
    
    func SetValue(_ value:UInt8)
    {
        m_field = value
    }

    func  ClearAll() { m_field = 0 }
    func SetAll()
    {
        m_field = UInt8(~0)
    }

    func Set(bits:UInt8, enabled:UInt8)
    {
        if ((enabled) != 0)
        {
            Set(bits)
        }
        else
        {
            Clear(bits)
        }
    }
    
    func Set(_ bits:UInt8)
    {
        m_field |= bits
    }
    
    func Clear(_ bits:UInt8)
    {
        m_field &= ~bits
    }
    
    func Read(_ bits:UInt8)->UInt8
    {
        return m_field & bits
    }
    
    func Test(_ bits:UInt8)->Bool
    {
        let ret = Read(bits)
        
        if(ret == 0)
        {
            return false
        }
        else
        {
            return true
        }
        //return Read(bits) != 0
    }
    
    func Test01(_ bits:UInt8)->UInt8
    {
        if(Read(bits) != 0)
        {
            return 1
        }
        else
        {
            return 0
        }
    }

    // Bit position functions
    func SetPos(bitPos:UInt8, enabled:UInt8)
    {
        if (enabled != 0)
        {
            SetPos(bitPos)
        }
        else
        {
            ClearPos(bitPos)
        }
    }
    
    func SetPos(_ bitPos:UInt8)
    {
        Set(1 << bitPos)
    }
    
    func ClearPos(_ bitPos:UInt8)
    {
        Clear(1 << bitPos)
    }
    
    func ReadPos(_ bitPos:UInt8)->UInt8
    {
        return Read(1 << bitPos)
    }
        
    func TestPos(bitPos:UInt8)->Bool
    {
        return Read(1 << bitPos) != 0
    }
        
    func TestPos01(_ bitPos:UInt8)->UInt8
    {
        if(Read(1 << bitPos) != 0)
        {
            return 1
        }
        else
        {
            return 0
        }
    }
    
}
