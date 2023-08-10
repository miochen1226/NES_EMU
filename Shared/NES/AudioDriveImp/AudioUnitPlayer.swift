//
//  AudioUnitPlayer.swift
//  AudioTest
//
//  Created by mio on 2023/8/3.
//

import Foundation
import AVFoundation

@objc protocol AURenderCallbackDelegate {
func performRender(ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
    inTimeStamp: UnsafePointer<AudioTimeStamp>,
    inBusNumber: UInt32,
    inNumberFrames: UInt32,
    ioData: UnsafeMutablePointer<AudioBufferList>?) -> OSStatus
}

class AudioController:NSObject
{
    static var sharedInstance = AudioController()
    var remoteIOUnit: AudioComponentInstance!
    var m_frameProvider: FrameProvider?
    func processSampleData(_ data:Data)
    {
        
    }
    
    func setUp(frameProvider:FrameProvider)
    {
        self.m_frameProvider = frameProvider
        var status:OSStatus
        
        //ios use kAudioUnitSubType_RemoteIO
        //mac use kAudioUnitSubType_HALOutput
#if os(iOS)
        var audioComponentDesc = AudioComponentDescription(componentType: OSType(kAudioUnitType_Output),
                                                           componentSubType: OSType(kAudioUnitSubType_RemoteIO),
                                                           componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
                                                           componentFlags: 0, componentFlagsMask: 0)
#else
        var audioComponentDesc = AudioComponentDescription(componentType: OSType(kAudioUnitType_Output),
                                                           componentSubType: OSType(kAudioUnitSubType_HALOutput),
                                                           componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
                                                           componentFlags: 0, componentFlagsMask: 0)
#endif
        let inputComponent = AudioComponentFindNext(nil, &audioComponentDesc)
        status = AudioComponentInstanceNew(inputComponent!, &remoteIOUnit)
        
        if status != noErr {
            print("Audio Component Instance New Error )")
        }
        
        var audioDescription = AudioStreamBasicDescription()
        audioDescription.mSampleRate = 44100
        audioDescription.mFormatID = kAudioFormatLinearPCM
        audioDescription.mFormatFlags = kLinearPCMFormatFlagIsFloat
        audioDescription.mChannelsPerFrame = 1
        audioDescription.mFramesPerPacket = 1
        audioDescription.mBitsPerChannel = 32
        audioDescription.mBytesPerFrame = 4 * audioDescription.mChannelsPerFrame
        audioDescription.mBytesPerPacket = 4 * audioDescription.mChannelsPerFrame
        audioDescription.mReserved = 0
        
        status = AudioUnitSetProperty(remoteIOUnit, kAudioUnitProperty_StreamFormat,
                                          kAudioUnitScope_Input, 0, &audioDescription,
                                          UInt32(MemoryLayout<AudioStreamBasicDescription>.size))
        
        if status != noErr {
            print("Enable IO for playback error")
        }
        
        var outputCallbackStruct = AURenderCallbackStruct()
        outputCallbackStruct.inputProcRefCon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        outputCallbackStruct.inputProc = {
                     (inRefCon : UnsafeMutableRawPointer,
                      ioActionFlags : UnsafeMutablePointer<AudioUnitRenderActionFlags>,
                      inTimeStamp : UnsafePointer<AudioTimeStamp>,
                      inBusNumber : UInt32,
                      inNumberFrames : UInt32,
                      ioData : UnsafeMutablePointer<AudioBufferList>?) -> OSStatus in
                    
            
            let _self = Unmanaged<AudioController>.fromOpaque(inRefCon).takeUnretainedValue()
            
            let abl = UnsafeMutableAudioBufferListPointer(ioData)
            let reqByteSize = abl?[0].mDataByteSize ?? 2048
            
            let frameObj = _self.m_frameProvider?.getNextFrame(reqByteSize)
            
            
            if(frameObj!.useFloat)
            {
                let floatCount = Int(frameObj?.countFloat ?? 0)
                if(floatCount==0)
                {
                    /*
                    var empty:[Float32] = []
                    for _ in 0...reqByteSize-1
                    {
                        empty.append(0)
                    }
                    abl?[0].mDataByteSize = 10
                    memcpy(abl?[0].mData, &empty, Int(reqByteSize))
                     */
                    return 0
                }
                
                //let pointer = UnsafeRawPointer(frameObj!.buffer!)
                //var randBuffer:[Float32] = []
                let copyCount = Int(frameObj!.countFloat*4)
                memcpy(abl?[0].mData, &frameObj!.arrayFloat, copyCount)
                return 0
            }
            else
            {
                let byteCount = Int(frameObj?.byteCount ?? 0)
                if(byteCount==0)
                {
                    return 0
                }
                
                let pointer = UnsafeRawPointer(frameObj!.buffer!)
                var randBuffer:[Float32] = []
                for index in 0..<byteCount/4
                {
                    let floatValue = pointer.load(fromByteOffset: index*4, as: Float32.self)
                    randBuffer.append(floatValue)
                }
                memcpy(abl?[0].mData, &randBuffer, byteCount)
                return 0
            }
            
        }
        
        
        status = AudioUnitSetProperty(remoteIOUnit, kAudioUnitProperty_SetRenderCallback,
                                      kAudioUnitScope_Global, 0, &outputCallbackStruct,
                                      UInt32(MemoryLayout<AURenderCallbackStruct>.size))
        status = AudioUnitInitialize(remoteIOUnit)
        if status != noErr {
            print("Failed to initialize audio unit)")
        }
        status = AudioOutputUnitStart(remoteIOUnit)
        if status != noErr {
            print("Failed to initialize output unit)")
        }
    }
}

class AudioUnitPlayer:NSObject,AudioDriveImp
{
    var m_frameProvider: FrameProvider?
    
    required init(frameProvider: FrameProvider) {
        self.m_frameProvider = frameProvider
        super.init()
        self.initEngine()
    }
    
    
    
    
    func initEngine()
    {
        AudioController.sharedInstance.setUp(frameProvider: self.m_frameProvider!)
        /*
        do {
            try AVAudioSession.sharedInstance().setActive(true, options: [])
        } catch { }
        */
        
    }
    
    
    

}
