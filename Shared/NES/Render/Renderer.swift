//
//  Renderer.swift
//  NES_EMU
//
//  Created by mio on 2021/8/12.
//

import Foundation
import CoreAudio

class Renderer
{
    let locker = NSLock()
    var rawColors:[Color4] = []
    var rawColorsDisplay:[UInt8] = []
    let printDebug = false
    static var shared = Renderer()
    
    func Initialize() {
        for _ in 0..<256
        {
            for _ in 0..<240
            {
                rawColors.append(Color4.init())
                rawColorsDisplay.append(0)
                rawColorsDisplay.append(0)
                rawColorsDisplay.append(0)
                rawColorsDisplay.append(0)
            }
        }
    }
    
    func pushFrame()
    {
        locker.lock()
        
        for x in 0..<256
        {
            for y in 0..<240
            {
                let posColor = y*256+x
                let posP = (239-y)*256+x
                let posPixel = posP*4
                let color4 = rawColors[posColor]
                rawColorsDisplay[posPixel] = color4.d_r
                rawColorsDisplay[posPixel+1] = color4.d_g
                rawColorsDisplay[posPixel+2] = color4.d_b
                rawColorsDisplay[posPixel+3] = color4.d_a
            }
        }
        
        locker.unlock()
    }
    
    func getFrame(dstArray2Pointer:inout UnsafeMutablePointer<UInt8>)
    {
        locker.lock()
        //MemoryLayout<Color4>.stride*
        let srcArray2Pointer = UnsafeMutablePointer<UInt8>(&self.rawColorsDisplay)
        memcpy(dstArray2Pointer, srcArray2Pointer, MemoryLayout<UInt8>.stride*256*240*4)
        locker.unlock()
    }
    
    func GetPixel(_ index:Int)->Color4
    {
        let color = Color4()
        color.d_b = 255
        
        let shiftCount = index
        let colorSrc = rawColors[Int(shiftCount)]
        color.d_r = colorSrc.d_r
        color.d_g = colorSrc.d_g
        color.d_b = colorSrc.d_b
        
        return color
    }
    
    func DrawPixel(x:UInt32, y:UInt32, color:inout Color4)
    {
        let pixelPos = Int(x + y*256)
        let shiftCount = x + y*256
        //let destArray2Pointer = UnsafeMutablePointer<Color4>(&self.rawColors)
        //memcpy(destArray2Pointer.advanced(by: Int(shiftCount)), &color, MemoryLayout<Color4>.stride)
        
        self.rawColors[pixelPos].d_r = color.d_r
        self.rawColors[pixelPos].d_g = color.d_g
        self.rawColors[pixelPos].d_b = color.d_b
    }
}
