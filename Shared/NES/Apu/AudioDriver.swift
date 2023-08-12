//
//  AudioDriver.swift
//  NES_EMU
//
//  Created by mio on 2023/7/24.
//

import Foundation
import AVFAudio
import AVFoundation

class NesFrameProvider : FrameProvider{
    var frames:[Float32] = []
    let lockInput = NSLock()
    
    func enqueue(inputFrame: Float32)
    {
        lockInput.lock()
        frames.append(inputFrame)
        lockInput.unlock()
    }
    
    func dequeue(byteSize: UInt32)-> FrameObj {
        let frameObj = FrameObj()
        let floatCount:Int = Int(byteSize/4)
        
        lockInput.lock()
        
        if(frames.count >= byteSize/4)
        {
            for _ in 0..<floatCount
            {
                frameObj.arrayFloat.append(frames.removeFirst())
            }
            
            frameObj.countFloat = UInt32(frameObj.arrayFloat.count)
        }
        
        lockInput.unlock()
        
        return frameObj
    }
    
    func getNextFrame(_ byteSize: UInt32) -> FrameObj {
        return dequeue(byteSize:byteSize)
    }
}

class AudioDriver: NSObject {
    let nesFrameProvider = NesFrameProvider()
    var audioUnitPlayer: AudioUnitPlayer!
    required override init() {
        super.init()
        audioUnitPlayer = AudioUnitPlayer(frameProvider: nesFrameProvider)
        audioUnitPlayer.start()
    }
    
    func enqueue(inputFrame: Float32)
    {
        nesFrameProvider.enqueue(inputFrame: inputFrame)
    }
}
