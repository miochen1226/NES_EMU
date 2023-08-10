//
//  AudioDriver.swift
//  NES_EMU
//
//  Created by mio on 2023/7/24.
//

import Foundation
import AVFAudio
import AVFoundation

class NesFrameProvider:FrameProvider
{
    var frames:[Float32] = []
    let lockInput = NSLock()
    func enqueue(input: Float32)
    {
        lockInput.lock()
        frames.append(input)
        lockInput.unlock()
    }
    
    func dequeue(byteSize: UInt32)->FrameObj
    {
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

class AudioDriver:NSObject
{
    var m_frameProvider:NesFrameProvider!
    var m_audioUnitPlayer:AudioUnitPlayer!
    required init(frameProvider: NesFrameProvider) {
        self.m_frameProvider = frameProvider
        super.init()
        m_audioUnitPlayer = AudioUnitPlayer(frameProvider: frameProvider)
    }
}
/*
extension Data {
     func append(fileURL: URL) throws {
         if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
             defer {
                 fileHandle.closeFile()
             }
             fileHandle.seekToEndOfFile()
             fileHandle.write(self)
         }
         else {
             try write(to: fileURL, options: .atomic)
         }
     }
 }

class AudioBufferProvider:NSObject
{
    var m_buffer: [Float32] = []
    var m_bufferToPlay: [Float32] = []
    var m_unitSampleCount:Int = 0
    var m_sampleRate:Double = 0
    let m_bufferA = UnsafeMutablePointer<UInt8>.allocate(capacity: 44100*4)
    let m_bufferB = UnsafeMutablePointer<UInt8>.allocate(capacity: 44100*4)
    var arrayFrame:[UnsafeMutablePointer<UInt8>] = []
    override init()
    {
        super.init()
        openFileRead()
        
        cleanBufferA()
    }
    
    func cleanBufferA()
    {
        var bufferEmpty:[UInt8] = []
        for _ in 0..<44100*4
        {
            bufferEmpty.append(0)
        }
        //Clean buffer
        memcpy(m_bufferA, &bufferEmpty, 44100*4)
    }
    
    var m_audioFile:AVAudioFile?
    var m_fileUrl:URL?
    //let m_fileUrl
    func openFileRead()
    {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as NSURL

        m_fileUrl = documentsUrl.appendingPathComponent("audio.pcm")
        
        print(m_fileUrl)
        
        
        
        //m_audioFile = try! AVAudioFile.init(forWriting: <#T##URL#>, settings: <#T##[String : Any]#>: m_fileUrl!)
        
        /*
        m_audioFile = try! AVAudioFile(forWriting: m_fileUrl!, settings: [AVFormatIDKey: kAudioFormatMPEG4AAC,AVNumberOfChannelsKey:1,AVSampleRateKey:44100], commonFormat: .pcmFormatFloat32, interleaved: false)
        */
    }
    
    func setUnitSampleCount(_ unitSampleCount:Int)
    {
        m_unitSampleCount = Int(unitSampleCount)
    }
    
    func setSampleRate(_ sampleRate:Double)
    {
        m_sampleRate = sampleRate
    }
    
    /*
    func getAudioBuffer()->UnsafeMutablePointer<UInt8>
    {
        let bufferSize = 44100*10*4
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        let readCount = m_inputStream?.read(buffer, maxLength: bufferSize)
        return buffer
    }
     */
    
    private let lock = NSLock()
    private let lockTake = NSLock()
    
    public func enqueue(input:Float32)->Bool
    {
        var isReadyToPlay = false
        lock.lock()
        
        //print(String(input))
        //m_buffer.append(0.1)
        
        m_buffer.append(input)
        
        //feedCount += 1
        if(m_buffer.count >= m_unitSampleCount)
        {
            fillInBuffer(buffer: m_buffer)
            m_buffer.removeAll()
            isReadyToPlay = true
        }
        
        lock.unlock()
        
        return isReadyToPlay
    }
    
    
    
    
    //var audioBuffer0:AVAudioPCMBuffer?
    //var audioBuffer1:AVAudioPCMBuffer?
    var m_curIndex = -1
    
    var feedCount = 0
    var lostCount = 0
    var lostRate = 0.0
    private let lockFillBuffer = NSLock()
    func fillInBuffer(buffer:[Float32])
    {
        //Save
        var bufSave = buffer
        let data = Data(buffer: UnsafeBufferPointer<Float32>(start: &bufSave, count: buffer.count))
        try? data.append(fileURL: m_fileUrl!)
        
        lockFillBuffer.lock()
        var buf = buffer
        
        let bufferFrame = UnsafeMutablePointer<UInt8>.allocate(capacity: 44100*4)
        memcpy(bufferFrame, &buf, m_unitSampleCount*4)
        arrayFrame.append(bufferFrame)
        m_curIndex = 0
        /*
        if(m_curIndex == -1 || m_curIndex == 0)
        {
            var buf = buffer
            memcpy(m_bufferA, &buf, 44100*4)
        }
        else if(m_curIndex == 1)
        {
            var buf = buffer
            memcpy(m_bufferB, &buf, 44100*4)
        }
        
        m_curIndex = m_curIndex + 1
        if(m_curIndex > 1)
        {
            m_curIndex = 0
        }*/
        lockFillBuffer.unlock()
    }
    
    
    func getNextBuffer()->UnsafeMutablePointer<UInt8>
    {
        lockFillBuffer.lock()
        var out:UnsafeMutablePointer<UInt8>?// = m_bufferA
        
        if(arrayFrame.count>0)
        {
            let bufferFrame = arrayFrame.removeFirst()
            out = bufferFrame
        }
        else
        {
            let bufferFrame = UnsafeMutablePointer<UInt8>.allocate(capacity: 44100*4)
            
            var bufferEmpty:[UInt8] = []
            for _ in 0..<44100*4
            {
                bufferEmpty.append(0)
            }
            //Clean buffer
            memcpy(bufferFrame, &bufferEmpty, m_unitSampleCount*4)
            out = bufferFrame
        }
        /*
        if(m_curIndex == -1)
        {
            NSLog("get--nil")
            out = m_bufferA
        }
        
        if(m_curIndex == 0)
        {
            NSLog("get--0")
            out = m_bufferA
        }
        else if(m_curIndex == 1)
        {
            NSLog("get--1")
            out = m_bufferB
        }*/
        lockFillBuffer.unlock()
        
        return out!
    }
    
    public func dequeue()->AVAudioPCMBuffer?
    {
        var audioPCMBuffer:AVAudioPCMBuffer?
        //print("dequeue->" + String(m_bufferToPlay.count))
        lockTake.lock()
        if(m_bufferToPlay.count > 0)
        {
            
            audioPCMBuffer = readAudioBuffer(buffer: m_bufferToPlay, sampleRate: m_sampleRate)
            m_bufferToPlay.removeAll()
            //audioPCMBufferLast = audioPCMBuffer
        }
        else
        {
            /*
            if(audioPCMBufferLast != nil)
            {
                lockTake.unlock()
                
                print("==audioPCMBufferLast==")
                return audioPCMBufferLast
            }
             */
        }
        
        lockTake.unlock()
        //print("dequeue->end")
        return audioPCMBuffer
    }
    var m_lastValue:Float32 = 0.0
    func readAudioBuffer(buffer: [Float32],sampleRate:Double)->AVAudioPCMBuffer
    {
        //let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: Double(m_sampleRate), channels: 1, interleaved: false)
        //var bufferA:[Int16] = []
        //for index in 0...buffer.count-1
        //{
            //bufferA.append(Int16(buffer[index]*100))
            //print(bufferA[index])
            //print(buffer[index])
        //}
        let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: Double(m_sampleRate), channels: 1, interleaved: false)
        
        let frameLength = buffer.count
        let audioBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat!, frameCapacity: AVAudioFrameCount(frameLength))!

        
        var buf = buffer
        
        //memcpy(audioBuffer.mutableAudioBufferList.pointee.mBuffers.mData, &buf, MemoryLayout<Float32>.stride * frameLength)

        memcpy(audioBuffer.mutableAudioBufferList.pointee.mBuffers.mData, &buf, MemoryLayout<Float32>.stride * frameLength)

        
        audioBuffer.frameLength = AVAudioFrameCount(frameLength)
        return audioBuffer
    }
    
}

class AudioDriver:NSObject {
    var audioBufferProvider:AudioBufferProvider = AudioBufferProvider()
    //OSX
    //var audioSession: AVCaptureSession = AVCaptureSession()
    var engine:AVAudioEngine!
    var playerNode:AVAudioPlayerNode!
    var audioBuffer:AVAudioPCMBuffer!
    
    public func enqueue(input:Float32)
    {
        if(audioBufferProvider.enqueue(input: input))
        {
            //enqueueDataWithPacketsCount(packetCount: 1)
        }
        
    }
    
    override init()
    {
        super.init()
        let unitSampleCount = 44100
        self.audioBufferProvider.setUnitSampleCount(unitSampleCount)
        
        self.audioBufferProvider.setSampleRate(self.GetSampleRate())
        
        
        self.queuePlayer = AVQueuePlayer()
        
        //var streamFormat = self.audioBufferProvider.streamFormat
        
        var streamFormat = AudioStreamBasicDescription()
        
        streamFormat.mSampleRate = 44100
        streamFormat.mFormatID = kAudioFormatLinearPCM
        streamFormat.mFormatFlags = kLinearPCMFormatFlagIsFloat
        streamFormat.mBitsPerChannel = 32
        streamFormat.mChannelsPerFrame = 1
        streamFormat.mBytesPerPacket = 4 * streamFormat.mChannelsPerFrame;
        streamFormat.mBytesPerFrame = 4 * streamFormat.mChannelsPerFrame;
        
        //PCM 固定1
        streamFormat.mFramesPerPacket = 1
        streamFormat.mReserved = 0
        
        var status: OSStatus = 0
        let selfPointer = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
        
        status = AudioQueueNewOutput(&streamFormat, KKAudioQueueOutputCallback, selfPointer, nil, nil, 0, &self.outputQueue)
        
        //status = AudioQueueNewOutput(&streamFormat, self.KKAudioQueueOutputCallback, selfPointer, CFRunLoopGetCurrent(), kCFRunLoopCommonModes as! CFString, 0, &self.outputQueue)
        assert(noErr == status)
        
        /*
        status = AudioQueueAddPropertyListener(self.outputQueue, kAudioQueueProperty_IsRunning, self.KKAudioQueueRunningListener, selfPointer)
        assert(noErr == status)
         
         */
        AudioQueuePrime(self.outputQueue, 0, nil)
        AudioQueueStart(self.outputQueue, nil)
        
        //self.enqueueDataWithPacketsCount(packetCount: 1)
        
        /*
        do {
            engine = AVAudioEngine()
            playerNode = AVAudioPlayerNode()
            
            let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: Double(self.GetSampleRate()), channels: 1, interleaved: false)!
            //circularBuffer = TPCircularBuffer()
            engine.isAutoShutdownEnabled = false
        
            engine.attach(playerNode)
            engine.connect(playerNode, to: engine.outputNode, format: outputFormat)
            engine.prepare()
            
            do {
                try engine.start()
            } catch {
                print("error")
            }
            self.playerNode.play()
            
            self.startPlay()
        }*/
        
        self.startPlay()
    }
    
    
    var queuePlayer:AVQueuePlayer?
    var outputQueue:AudioQueueRef!
    
    let KKAudioQueueOutputCallback : @convention(c) (UnsafeMutableRawPointer?, AudioQueueRef, AudioQueueBufferRef) -> Void =
    {clientData,AQ,buffer in
        let this = Unmanaged<AudioDriver>.fromOpaque(clientData!).takeUnretainedValue()
        this.enqueueDataWithPacketsCount(packetCount:1)
        
    }
    
    func enqueueDataWithPacketsCount(packetCount: Int){
        if self.outputQueue == nil {
            return
        }
        
        let audioBuffer = self.audioBufferProvider.getNextBuffer()
        var buffer: AudioQueueBufferRef! = nil
        var status: OSStatus = 0
        let totalSize = self.audioBufferProvider.m_unitSampleCount*4
        var packetDescs = [AudioStreamPacketDescription]()
        status = AudioQueueAllocateBuffer(outputQueue, UInt32(totalSize), &buffer)
        assert(noErr == status)
        
        buffer.pointee.mAudioDataByteSize = UInt32(totalSize)
        
        let description = AudioStreamPacketDescription(mStartOffset: Int64(0), mVariableFramesInPacket: 0, mDataByteSize: UInt32(totalSize))
        
        memcpy(buffer.pointee.mAudioData.advanced(by: 0), audioBuffer, Int(totalSize))
        packetDescs.append(description)
        status = AudioQueueEnqueueBuffer(outputQueue, buffer, 1, packetDescs)
        assert(noErr == status)
    }
    
    let serialQueue = DispatchQueue(label: "SerialQueueAudio")
    
    var m_wantQuit = false
    func stop()
    {
        m_wantQuit = true
    }
    
    let sleepTime:UInt32 = 1000000
    
    var isBusy = false
    func startPlay()
    {
        self.enqueueDataWithPacketsCount(packetCount: 1)
        serialQueue.async {
            while (self.m_wantQuit == false)
            {
                usleep(self.sleepTime)
                /*
                if(self.isBusy)
                {
                    return
                }
                */
                //self.enqueueDataWithPacketsCount(packetCount: 1)
                //if(ret)
                //{
                //    self.isBusy = true
                //}
                
                /*
                let audioBuffer = self.audioBufferProvider.getNextBuffer()
                if(audioBuffer != nil)
                {
                    //self.playerNode.scheduleBuffer(<#T##buffer: AVAudioPCMBuffer##AVAudioPCMBuffer#>) {
                        
                    //}
                    NSLog("get-play")
                    self.playerNode.scheduleBuffer(audioBuffer!, at: nil, options: [.interrupts]){
                        NSLog("get-end")
                    }
                    //self.isBusy = true
                }
                 */
            }
        }
    }
    
    
    func GetSampleRate()->Double
    {
        return 44100
    }
}
*/
