//
//  DmcChannel.swift
//  NES_EMU
//
//  Created by mio on 2023/10/9.
//

import Foundation

class DmcChannel: BaseChannel {
    
    override init() {
        super.init()
        timer.setMinPeriod(2)
    }
    
    func clockQuarterFrameChips() {
        linearCounter.clock()
    }

    func clockHalfFrameChips() {
        lengthCounter.clock()
    }
    var counter = 0
    
    var interruptFlag:UInt8 = 0
    var loopFlag:UInt8 = 0
    
    
    func getD()-> UInt8 {
        return 1
    }
    
    func getI()-> UInt8 {
        return 1
    }
    
    func clockTimer() {
        
        /*
        counter = counter + 1
        
        if counter > 5 {
            interruptFlag = 0
            nes?
        }
        */
        
        
        if timer.clock() {
            let a = linearCounter.getValue()
            let b = lengthCounter.getValue()
            if a > 0 && b > 0 {
                //TODO
                print("IRQ")
            }
        }
    }
    
    override func getValue() -> Float32 {
        //TODO
        return 0
    }
    
    var interrupt:UInt8 = 0
    //https://www.nesdev.org/wiki/APU_DMC
    override func handleCpuWrite(cpuAddress: UInt16, value: UInt8) {
        switch cpuAddress {
        case 0x4010:
            //IL--.RRRR Flags and Rate (write)
            //I IRQ enabled flag. If clear, the interrupt flag is cleared.
            //L Loop flag
            
            let I = testBits(target: BIT(7), value: value)
            let L = testBits(target: BIT(6), value: value)
            
            let RRRR = readBits8(target: BITS([0,1,2,3]), value: value)
            
            //I IRQ enabled flag. If clear, the interrupt flag is cleared.
            if I == false {
                interrupt = 0
            }
            print("DMC 0x4010 I->" + String(I) + " L->" + String(L))
            break

        case 0x4011:
            //-DDD.DDDD Direct load (write)
            print("DMC 0x4011")
            break

        case 0x4012:
            //AAAA.AAAA    Sample address (write)
            print("DMC 0x4012")
            break
        case 0x4013:
            //LLLL.LLLL    Sample length (write)
            print("DMC 0x4013")
            break
        default:
            assert(false)
            break
        }
    }
}
