//
//  AudioUnitPlayer.swift
//  AudioTest
//
//  Created by mio on 2023/8/3.
//

import Foundation
import AVFoundation

class AudioUnitPlayer:NSObject, AudioDriveImp {
    
    required init(frameProvider: FrameProvider) {
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
    
    var frameProvider: FrameProvider?
}
