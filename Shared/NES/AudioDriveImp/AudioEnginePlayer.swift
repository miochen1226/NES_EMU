//
//  AudioEnginePlayer.swift
//  AudioTest
//
//  Created by mio on 2023/8/2.
//

import Foundation
import AVFoundation

class AudioEnginePlayer:NSObject,AudioDriveImp
{
    var m_frameProvider: FrameProvider?
    
    var engine:AVAudioEngine!
    var playerNode:AVAudioPlayerNode!
    var audioBuffer:AVAudioPCMBuffer!
    
    required init(frameProvider: FrameProvider) {
        self.m_frameProvider = frameProvider
        super.init()
        self.initEngine()
    }
    
    func initEngine()
    {
        var streamFormat = AudioStreamBasicDescription()
        streamFormat.mSampleRate = 44100
        streamFormat.mFormatID = kAudioFormatLinearPCM
        streamFormat.mFormatFlags = kLinearPCMFormatFlagIsFloat
        streamFormat.mBitsPerChannel = 32
        streamFormat.mChannelsPerFrame = 1
        streamFormat.mBytesPerPacket = 4 * streamFormat.mChannelsPerFrame
        streamFormat.mBytesPerFrame = 4 * streamFormat.mChannelsPerFrame
        streamFormat.mFramesPerPacket = 1
        streamFormat.mReserved = 0
        
        do
        {
            engine = AVAudioEngine()
            playerNode = AVAudioPlayerNode()
            let sampleRate = 44100
            let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: Double(sampleRate), channels: 1, interleaved: false)!
            
            engine.isAutoShutdownEnabled = false
        
            engine.attach(playerNode)
            
            engine.connect(playerNode, to: engine.outputNode, format: outputFormat)
            
            do {
                try engine.start()
            } catch {
                print("error")
            }
            self.playerNode.play()
            
            self.startPlay()
        }
    }
    
    func startPlay()
    {
        enqueueBuffer()
    }
    
    func enqueueBuffer()
    {
        let audioBuffer = self.getNextBuffer()
        if(audioBuffer != nil)
        {
            self.playerNode.scheduleBuffer(audioBuffer!) {
                self.enqueueBuffer()
            }
        }
    }
    
    func getNextBuffer()->AVAudioPCMBuffer?
    {
        let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: Double(44100), channels: 1, interleaved: false)
        
        let frameObj = self.m_frameProvider?.getNextFrame(2048)
        
        let byteCount = Int(frameObj!.byteCount)
        
        let audioPcmBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat!, frameCapacity: AVAudioFrameCount(byteCount))
        var bytesArray = UnsafeBufferPointer(start: frameObj!.buffer!, count: byteCount).map{$0}
        
        memcpy(audioPcmBuffer!.mutableAudioBufferList.pointee.mBuffers.mData, &bytesArray, byteCount)
        audioPcmBuffer!.frameLength = AVAudioFrameCount(byteCount)/4 //Int8 to Float32
        return audioPcmBuffer
    }
}
