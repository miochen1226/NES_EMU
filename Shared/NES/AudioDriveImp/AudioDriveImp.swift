//
//  AudioDriveImp.swift
//  AudioTest
//
//  Created by mio on 2023/8/2.
//

import Foundation

class FrameObj: NSObject
{
    deinit
    {
        arrayFloat.removeAll()
        if(bufferFloat != nil)
        {
            bufferFloat?.deallocate()
        }
        
        if(buffer != nil)
        {
            buffer?.deallocate()
        }
    }
    
    var isFloat = true
    var arrayFloat: [Float32] = []
    var bufferFloat: UnsafeMutablePointer<Float32>?
    var countFloat: UInt32 = 0
    
    var buffer: UnsafeMutablePointer<UInt8>?
    var byteCount: UInt32 = 0
}

protocol FrameProvider {
    func getNextFrame(_ byteSize: UInt32) -> FrameObj
}

protocol AudioDriveImp {
    var frameProvider: FrameProvider? { get set }
    init(frameProvider: FrameProvider)
    func start()
    func stop()
}
