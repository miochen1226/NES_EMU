//
//  AudioDriver.swift
//  NES_EMU
//
//  Created by mio on 2023/7/24.
//

import Foundation
import AVFAudio

class AudioDriver:NSObject {
    
    //OSX
    //var audioSession: AVCaptureSession = AVCaptureSession()
    var engine:AVAudioEngine!
    var playerNode:AVAudioPlayerNode!
    var audioBuffer:AVAudioPCMBuffer!
    //var audioSession: AVCaptureSession = AVCaptureSession()
    override init()
    {
        super.init()
        do {
            
            
            engine = AVAudioEngine()
            playerNode = AVAudioPlayerNode()
            let outputFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
            //circularBuffer = TPCircularBuffer()
            
            engine.attach(playerNode)
            engine.connect(playerNode, to: engine.outputNode, format: outputFormat)
            engine.prepare()
            do {
                try engine.start()
            } catch {
                print("error")
            }
            self.playerNode.play()
        }
    }
    
    func play(buffer: [Float32]) {
        
        let outputFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        
        let interleavedChannelCount = 1
        let frameLength = buffer.count / interleavedChannelCount
        let audioBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: AVAudioFrameCount(frameLength))!

        // buffer contains 2 channel interleaved data
        // audioBuffer contains 2 channel interleaved data

        var buf = buffer
        memcpy(audioBuffer.mutableAudioBufferList.pointee.mBuffers.mData, &buf, MemoryLayout<Float32>.stride * interleavedChannelCount * frameLength)

        audioBuffer.frameLength = AVAudioFrameCount(frameLength)

        self.playerNode.pause()
        
        self.playerNode.scheduleBuffer(audioBuffer) {
            //print("Played")
        }
        self.playerNode.play()
        
        
    }
    
    func GetSampleRate()->Float32
    {
        return 44100
    }
    
    var bufferF:[Float32] = []
    let limit = 44100/1
    func AddSampleF32(sample:Float32)
    {
        assert(sample >= 0.0 && sample <= 1.0)
        bufferF.append(sample)
        //bufferF.append(0)
        //print(bufferF.count)
        if(bufferF.count > limit)
        {
            play(buffer: bufferF)
            bufferF.removeAll()
        }
        //m_rawAudioOutputFS.WriteValue(sample);
        
        /*
        assert(sample >= 0.0f && sample <= 1.0f);
        //@TODO: This multiply is wrong for signed format types (S16, S32)
        float targetSample = sample * std::numeric_limits<SampleFormatType>::max();

        SDL_LockAudioDevice(m_audioDeviceID);
        m_samples.PushBack(static_cast<SampleFormatType>(targetSample));
        SDL_UnlockAudioDevice(m_audioDeviceID);

        // Unpause when buffer is half full; pause if almost depleted to give buffer a chance to
        // fill up again.
        const auto bufferUsageRatio = GetBufferUsageRatio();
        if (bufferUsageRatio >= 0.5f)
        {
            SetPaused(false);
        }
        else if (bufferUsageRatio < 0.1f)
        {
            SetPaused(true);
        }

    #if OUTPUT_RAW_AUDIO_FILE_STREAM
        m_rawAudioOutputFS.WriteValue(sample);
    #endif
         */
    }
}
