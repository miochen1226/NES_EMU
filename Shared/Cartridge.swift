//
//  Cartridge.swift
//  NES_EMU
//
//  Created by mio on 2021/8/6.
//

import Foundation

//extension Data {
//   func hexString() -> String {
//       return self.map { String(format:"%02x", $0) }.joined()}
//}



class Cartridge{
    func loadFile()
    {
        NSLog("LOAD ROM")
        loadMarioRom()
    }
    var romHeader:RomHeader?
    func loadMarioRom()
    {
        if let filepath = Bundle.main.path(forResource: "mario", ofType: "nes")
        {
            if let data = NSData(contentsOfFile: filepath)
            {
                let arrayData = [UInt8](data)
                romHeader = RomHeader.init().Initialize(bytes: arrayData)
                NSLog("loadMarioRom finish")
            }
        }
    }
}
