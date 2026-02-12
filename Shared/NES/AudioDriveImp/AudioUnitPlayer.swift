//
//  AudioUnitPlayer.swift
//  AudioTest
//
//  Created by mio on 2023/8/3.
//

import Foundation
import AVFoundation

class AudioUnitPlayer: NSObject, IAudioDrive {
    var frameProvider: IFrameProvider?
    
    required init(frameProvider: IFrameProvider) {
        self.frameProvider = frameProvider
        super.init()
        self.initEngine()
    }
    
    func initEngine() {
#if os(watchOS)
#else
        AudioController.sharedInstance.setUp(frameProvider: self.frameProvider!)
#endif
    }
    
    func start() {
#if os(watchOS)
#else
        AudioController.sharedInstance.start()
#endif
    }
    
    func stop() {
#if os(watchOS)
#else
        AudioController.sharedInstance.stop()
#endif
    }
}
