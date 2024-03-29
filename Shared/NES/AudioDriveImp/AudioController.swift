//
//  AudioController.swift
//  NES_EMU
//
//  Created by mio on 2023/8/12.
//

import Foundation
import AVFoundation

class AudioController: NSObject {
    static var sharedInstance = AudioController()
    var remoteIOUnit: AudioComponentInstance!
    var frameProvider: IFrameProvider?
    
    func start() {
        AudioOutputUnitStart(remoteIOUnit)
    }
    
    func stop() {
        AudioOutputUnitStop(remoteIOUnit)
    }
    
    func getAudioUnitSubType() -> UInt32 {
#if os(iOS)
        return kAudioUnitSubType_RemoteIO
#else
        return kAudioUnitSubType_HALOutput
#endif
    }
    
    func initAudioComponent() {
        let audioUnitSubType: UInt32 = getAudioUnitSubType()
        var audioComponentDesc = AudioComponentDescription(componentType: OSType(kAudioUnitType_Output),
                                                           componentSubType: OSType(audioUnitSubType),
                                                           componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
                                                           componentFlags: 0, componentFlagsMask: 0)

        var status:OSStatus
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
            let frameObj = _self.frameProvider?.getNextFrame(reqByteSize)
            
            if frameObj!.isFloat {
                let floatCount = Int(frameObj?.countFloat ?? 0)
                if floatCount==0 {
                    return 0
                }
                
                let copyCount = Int(frameObj!.countFloat*4)
                memcpy(abl?[0].mData, &frameObj!.arrayFloat, copyCount)
                return 0
            }
            else {
                let byteCount = Int(frameObj?.byteCount ?? 0)
                if byteCount==0 {
                    return 0
                }
                
                let pointer = UnsafeRawPointer(frameObj!.buffer!)
                var randBuffer:[Float32] = []
                for index in 0..<byteCount/4 {
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
    }
    
    func setUp(frameProvider: IFrameProvider) {
        self.frameProvider = frameProvider
        initAudioComponent()
    }
}
