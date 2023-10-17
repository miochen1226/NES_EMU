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
        AudioController.sharedInstance.setUp(frameProvider: self.frameProvider!)
    }
    
    func start() {
        AudioController.sharedInstance.start()
    }
    
    func stop() {
        AudioController.sharedInstance.stop()
    }
}
