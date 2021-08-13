//
//  Renderer.swift
//  NES_EMU
//
//  Created by mio on 2021/8/12.
//

import Foundation
import Cocoa

class Renderer
{
    
    
    let printDebug = false
    func DrawPixel(x:UInt32, y:UInt32, color:Color4)
    {
        if(color.R() != 109)
        {
            //NSLog("what!!!!!")
        }
        
        if(printDebug)
        {
            let message = "X:" + String(x) + ",Y:" + String(y) + "["+String(color.R()) + "," + String(color.G()) + "," + String(color.B()) + "," + String(color.A()) + "]"
            NSLog(message)
        }
    }
    
}
