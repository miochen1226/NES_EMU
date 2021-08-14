//
//  Renderer.swift
//  NES_EMU
//
//  Created by mio on 2021/8/12.
//

import Foundation

class Renderer
{
    var rawColors:[Color4] = []
    let printDebug = false
    
    func Initialize() {
        for _ in 0...255
        {
            for _ in 0...239
            {
                rawColors.append(Color4.init())
            }
        }
    }
    
    func DrawPixel(x:UInt32, y:UInt32, color:Color4)
    {
        self.rawColors[Int(x + y*256)].d_r = color.d_r
        self.rawColors[Int(x + y*256)].d_g = color.d_g
        self.rawColors[Int(x + y*256)].d_b = color.d_b
        
        if(printDebug)
        {
            let message = "X:" + String(x) + ",Y:" + String(y) + "["+String(color.R()) + "," + String(color.G()) + "," + String(color.B()) + "," + String(color.A()) + "]"
            NSLog(message)
        }
    }
}
