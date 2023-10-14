//
//  Renderer.swift
//  NES_EMU
//
//  Created by mio on 2021/8/12.
//

import Foundation
import CoreAudio

extension Renderer: IRenderer {
    func pushFrame() {
        locker.lock()
        memcpy(rawColorsDisplay, rawBuffer, bufferSize)
        locker.unlock()
    }
    
    func getFrame(dstArray2Pointer: inout UnsafeMutablePointer<UInt8>) {
        locker.lock()
        let srcArray2Pointer = UnsafeRawPointer(self.rawColorsDisplay)
        memcpy(dstArray2Pointer, srcArray2Pointer, bufferSize)
        locker.unlock()
    }
    
    func drawPixelColor(x: UInt32, y: UInt32, pixelColor: PixelColor) {
        let pixelPos = Int(x + (239-y)*256)*4
        rawBuffer[pixelPos] = pixelColor.d_r
        rawBuffer[pixelPos+1] = pixelColor.d_g
        rawBuffer[pixelPos+2] = pixelColor.d_b
        rawBuffer[pixelPos+3] = pixelColor.d_a
    }
}

class Renderer: NSObject {
    override init() {
        rawBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        rawColorsDisplay = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        memset(rawBuffer, 0, bufferSize)
        memset(rawColorsDisplay, 0, bufferSize)
    }
    
    deinit {
        rawBuffer.deallocate()
        rawColorsDisplay.deallocate()
    }
    
    func getPixel(_ index: Int) -> Color4 {
        let color = Color4()
        color.d_b = 255
        
        let pos = index*4
        color.d_r = rawBuffer[pos]
        color.d_g = rawBuffer[pos+1]
        color.d_b = rawBuffer[pos+2]
        color.d_a = rawBuffer[pos+3]
        return color
    }
    
    let locker = NSLock()
    var rawBuffer:UnsafeMutablePointer<UInt8>!
    var rawColorsDisplay:UnsafeMutablePointer<UInt8>!
    let printDebug = false
    let bufferSize = 256*240*4
    static var shared = Renderer()
}
