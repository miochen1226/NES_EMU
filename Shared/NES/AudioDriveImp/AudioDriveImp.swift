//
//  AudioDriveImp.swift
//  AudioTest
//
//  Created by mio on 2023/8/2.
//

import Foundation

protocol IFrameProvider {
    func getNextFrame(_ byteSize: UInt32) -> AudioFrameObj
}

protocol IAudioDrive {
    var frameProvider: IFrameProvider? { get set }
    init(frameProvider: IFrameProvider)
    func start()
    func stop()
}

class AudioFrameObj: NSObject {
    var isFloat = true
    var arrayFloat: [Float32] = []
    var bufferFloat: UnsafeMutablePointer<Float32>?
    var countFloat: UInt32 = 0
    
    var buffer: UnsafeMutablePointer<UInt8>?
    var byteCount: UInt32 = 0
    
    deinit {
        arrayFloat.removeAll()
        if bufferFloat != nil {
            bufferFloat?.deallocate()
        }
        
        if buffer != nil {
            buffer?.deallocate()
        }
    }
}

