//
//  Renderer.swift
//  NES_EMU
//
//  Created by mio on 2021/8/12.
//

import Foundation

class Renderer
{
    var rawColors:[[Color4]] = [[]]
    let printDebug = false
    
    func Initialize() {
        
        for x in 0...255
        {
            var array:[Color4] = []
            rawColors.append(array)
            for _ in 0...239
            {
                rawColors[x].append(Color4.init())
            }
        }
        
    }
    
    var enableDraw = true
    @inline(__always)
    func DrawPixel(x:UInt32, y:UInt32, color:inout Color4)
    {
        if(enableDraw)
        {
            let indexX = Int(x)
            let indexY = Int(y)
            self.rawColors[indexX][indexY].d_r = color.d_r
            //self.rawColors[indexX][indexY].d_g = color.d_g
            //self.rawColors[indexX][indexY].d_b = color.d_b
            //self.rawColors[indexX][indexY].d_a = color.d_a
        }
        
        if(printDebug)
        {
            let message = "X:" + String(x) + ",Y:" + String(y) + "["+String(color.R()) + "," + String(color.G()) + "," + String(color.B()) + "," + String(color.A()) + "]"
            NSLog(message)
        }
    }
}
