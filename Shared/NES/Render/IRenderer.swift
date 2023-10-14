//
//  IRenderer.swift
//  NES_EMU
//
//  Created by mio on 2023/10/14.
//

import Foundation
protocol IRenderer {
    func pushFrame()
    func getFrame(dstArray2Pointer: inout UnsafeMutablePointer<UInt8>)
    func drawPixelColor(x: UInt32, y: UInt32, pixelColor: PixelColor)
}
