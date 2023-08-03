//
//  AudioQueuePlayer.swift
//  AudioTest
//
//  Created by mio on 2023/8/2.
//

import Foundation
import AVFoundation

class AudioQueuePlayer:NSObject,AudioDriveImp
{
    var outputQueue:AudioQueueRef!
    var m_frameProvider: FrameProvider?
    
    required init(frameProvider:FrameProvider)
    {
        m_frameProvider = frameProvider
        super.init()
        
        self.initEngine()
        
        self.enqueueData()
    }
    
    func initEngine()
    {
        var streamFormat = AudioStreamBasicDescription()
        streamFormat.mSampleRate = 44100
        streamFormat.mFormatID = kAudioFormatLinearPCM
        streamFormat.mFormatFlags = kLinearPCMFormatFlagIsFloat
        streamFormat.mBitsPerChannel = 32
        streamFormat.mChannelsPerFrame = 1
        streamFormat.mBytesPerPacket = 4 * streamFormat.mChannelsPerFrame;
        streamFormat.mBytesPerFrame = 4 * streamFormat.mChannelsPerFrame;
        streamFormat.mFramesPerPacket = 1
        streamFormat.mReserved = 0
        
        var status: OSStatus = 0
        let selfPointer = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
        
        status = AudioQueueNewOutput(&streamFormat, AudioQueueOutputCallback, selfPointer, nil, nil, 0, &self.outputQueue)
        
        var deviceVolume:AudioQueueParameterValue = 0.0
        AudioQueueGetParameter(self.outputQueue, kAudioQueueParam_Volume, &deviceVolume)
        AudioQueueSetParameter(self.outputQueue, kAudioQueueParam_VolumeRampTime, 0.0005)
        
        
        //status = AudioQueueNewOutput(&streamFormat, self.KKAudioQueueOutputCallback, selfPointer, CFRunLoopGetCurrent(), kCFRunLoopCommonModes as! CFString, 0, &self.outputQueue)
        assert(noErr == status)
        
        /*
        status = AudioQueueAddPropertyListener(self.outputQueue, kAudioQueueProperty_IsRunning, self.KKAudioQueueRunningListener, selfPointer)
        assert(noErr == status)
         
         */
        AudioQueuePrime(self.outputQueue, 0, nil)
        AudioQueueStart(self.outputQueue, nil)
    }
    
    func enqueueData() {
        if self.outputQueue == nil {
            return
        }
        
        let bufferObj = self.m_frameProvider!.getNextFrame(2048)
        if(bufferObj.byteCount == 0)
        {
            return
        }
        
        var buffer: AudioQueueBufferRef! = nil
        var status: OSStatus = 0
        var packetDescs = [AudioStreamPacketDescription]()
        status = AudioQueueAllocateBuffer(outputQueue, bufferObj.byteCount, &buffer)
        assert(noErr == status)
        
        buffer.pointee.mAudioDataByteSize = bufferObj.byteCount
        
        let description = AudioStreamPacketDescription(mStartOffset: Int64(0), mVariableFramesInPacket: 0, mDataByteSize: UInt32(bufferObj.byteCount))
        
        memcpy(buffer.pointee.mAudioData.advanced(by: 0), bufferObj.buffer, Int(bufferObj.byteCount))
        packetDescs.append(description)
        status = AudioQueueEnqueueBuffer(outputQueue, buffer, 1, packetDescs)
        assert(noErr == status)
    }
    
    let AudioQueueOutputCallback : @convention(c) (UnsafeMutableRawPointer?, AudioQueueRef, AudioQueueBufferRef) -> Void =
    {clientData,AQ,buffer in
        let this = Unmanaged<AudioQueuePlayer>.fromOpaque(clientData!).takeUnretainedValue()
        this.enqueueData()
    }
    
    
    
    func AudioQueueRunningListener(clientData: UnsafeMutableRawPointer, AQ: AudioQueueRef, propertyID: AudioQueuePropertyID) {
        
        /*
        let this = Unmanaged<KKSimplePlayer>.fromOpaque(COpaquePointer(clientData)).takeUnretainedValue()
        var status: OSStatus = 0
        var dataSize: UInt32 = 0
        status = AudioQueueGetPropertySize(AQ, propertyID, &dataSize);
        assert(noErr == status)
        if propertyID == kAudioQueueProperty_IsRunning {
            var running: UInt32 = 0
            status = AudioQueueGetProperty(AQ, propertyID, &running, &dataSize)
            this.stopped = running == 0
        }*/
    }
}
