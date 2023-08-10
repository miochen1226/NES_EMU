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
    var rawBuffer:UnsafeMutablePointer<UInt8>!
    var rawColorsDisplay:UnsafeMutablePointer<UInt8>!
    //var rawColorsDisplay:[UInt8] = []
    let printDebug = false
    static var shared = Renderer()
    
    func Initialize() {
        
        rawBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 256*240*4)
        rawColorsDisplay = UnsafeMutablePointer<UInt8>.allocate(capacity: 256*240*4)
        memset(rawBuffer, 0, 256*240*4)
    }
    
    func pushFrame()
    {
        locker.lock()
        memcpy(rawColorsDisplay, rawBuffer, 256*240*4)
        locker.unlock()
    }
    
    func getFrame(dstArray2Pointer:inout UnsafeMutablePointer<UInt8>)
    {
        locker.lock()
        let srcArray2Pointer = UnsafeRawPointer(self.rawColorsDisplay)
        memcpy(dstArray2Pointer, srcArray2Pointer, 256*240*4)
        locker.unlock()
    }
    
    func GetPixel(_ index:Int)->Color4
    {
        let color = Color4()
        color.d_b = 255
        
        let pos = index*4
        //let shiftCount = index
        //let colorSrc = rawBuffer[Int(shiftCount)]
        
        
        color.d_r = rawBuffer[pos]
        color.d_g = rawBuffer[pos+1]
        color.d_b = rawBuffer[pos+2]
        color.d_a = rawBuffer[pos+3]
        
        return color
    }
    
    func DrawPixelColor(x:UInt32, y:UInt32, pixelColor:PixelColor)
    {
        let pixelPos = Int(x + (239-y)*256)*4
        rawBuffer[pixelPos] = pixelColor.d_r
        rawBuffer[pixelPos+1] = pixelColor.d_g
        rawBuffer[pixelPos+2] = pixelColor.d_b
        rawBuffer[pixelPos+3] = pixelColor.d_a
    }
    
    /*
    func DrawPixel(x:UInt32, y:UInt32, color:inout Color4)
    {
        let pixelPos = Int(x + y*256)
        let shiftCount = x + y*256
        //let destArray2Pointer = UnsafeMutablePointer<Color4>(&self.rawColors)
        //memcpy(destArray2Pointer.advanced(by: Int(shiftCount)), &color, MemoryLayout<Color4>.stride)
        rawBuffer[pixelPos] = p
        self.rawColors[pixelPos].d_r = color.d_r
        self.rawColors[pixelPos].d_g = color.d_g
        self.rawColors[pixelPos].d_b = color.d_b
    }*/
}
