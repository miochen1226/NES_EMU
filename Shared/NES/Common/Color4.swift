//
//  Color4.swift
//  NES_EMU
//
//  Created by mio on 2021/8/11.
//

import Foundation

class Color4
{
    var argb:UInt32 = 0
    
    var d_r:UInt8 = 0
    var d_g:UInt8 = 0
    var d_b:UInt8 = 0
    var d_a:UInt8 = 0

    func SetRGBA( r:UInt8,  g:UInt8,  b:UInt8,  a:UInt8)
    {
        d_r = r
        d_g = g
        d_b = b
        d_a = a
        argb = UInt32((a << 24) | (r << 16) | (g << 8) | b)
    }

    
    func A()->UInt8
    {
        return d_a
    }
    
    func R()->UInt8
    {
        return d_r
    }
    
    func G()->UInt8
    {
        return d_g
    }
    func B()->UInt8
    {
        return d_b
    }
    
    /*
    func A()->UInt8{ return UInt8((argb & 0xFF000000)>>24) }
    func R()->UInt8{
        
        return UInt8((argb & 0x00FF0000)>>16)
    }
    func G()->UInt8{ return UInt8((argb & 0x0000FF00)>>8) }
    func B()->UInt8{ return UInt8((argb & 0x000000FF)) }
 */
    /*
    static func Black()->Color4        { static Color4 c(0x00, 0x00, 0x00, 0xFF); return c; }
    static func White()->Color4        { static Color4 c(0xFF, 0xFF, 0xFF, 0xFF); return c; }
    static func Red()->Color4        { static Color4 c(0xFF, 0x00, 0x00, 0xFF); return c; }
    static func Green()->Color4        { static Color4 c(0x00, 0xFF, 0x00, 0xFF); return c; }
    static func Blue()->Color4        { static Color4 c(0x00, 0x00, 0xFF, 0xFF); return c; }
    static func Cyan()->Color4        { static Color4 c(0x00, 0xFF, 0xFF, 0xFF); return c; }
    static func Magenta()->Color4    { static Color4 c(0xFF, 0x00, 0xFF, 0xFF); return c; }
    static func Yellow()->Color4        { static Color4 c(0xFF, 0xFF, 0x00, 0xFF); return c; }
    */
}

