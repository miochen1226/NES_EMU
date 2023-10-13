//
//  Nes+Controller.swift
//  NES_EMU
//
//  Created by mio on 2023/10/13.
//

import Foundation

extension Nes {
    func pressL(_ isDown: Bool = true) {
        controllerPorts.pressL(isDown)
    }
    
    func pressR(_ isDown: Bool = true)
    {
        controllerPorts.pressR(isDown)
    }
    
    func pressU(_ isDown: Bool = true)
    {
        controllerPorts.pressU(isDown)
    }
    
    func pressD(_ isDown: Bool = true)
    {
        controllerPorts.pressD(isDown)
    }
    
    func pressA(_ isDown: Bool = true) {
        controllerPorts.pressA(isDown)
    }
    
    func pressB(_ isDown: Bool = true) {
        controllerPorts.pressB(isDown)
    }
    
    func pressStart(_ isDown: Bool = true) {
        controllerPorts.pressStart(isDown)
    }
    
    func pressSelect(_ isDown:Bool = true) {
        controllerPorts.pressSelect(isDown)
    }
}
