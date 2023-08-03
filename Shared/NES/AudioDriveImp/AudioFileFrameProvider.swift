//
//  AudioFileFrameProvider.swift
//  AudioTest
//
//  Created by mio on 2023/8/2.
//

import Foundation

class AudioFileFrameProvider:NSObject,FrameProvider
{
    var m_inputStream:InputStream?
    override init()
    {
        super.init()
        let bundleUrl = Bundle.main.url(forResource: "TestData", withExtension: "bundle")
        let fileUrl = bundleUrl!.appendingPathComponent("audio.pcm")
        //let fileUrl = bundleUrl!.appendingPathComponent("audio_no_tr.pcm")
        
        m_inputStream = InputStream(url: fileUrl)
        
        if(m_inputStream == nil)
        {
            print("file open fail")
        }
        
        m_inputStream?.open()
        
    }
    
    func getNextFrame(_ byteSize:UInt32 = 2048)->FrameObj
    {
        let bufferSize = byteSize//44100*4
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(bufferSize))
        let frameObj = FrameObj()
        let readCount = m_inputStream?.read(buffer, maxLength: Int(bufferSize)) ?? 0
        
        if(readCount>0)
        {
            frameObj.byteCount = UInt32(readCount)
            frameObj.buffer = buffer
        }
        
        return frameObj
    }
}
