//
//  GameScene+GameController.swift
//  NES_EMU
//
//  Created by mio on 2023/8/12.
//

import Foundation
import GameController

extension GameScene
{
    @objc func didConnectController(_ notification: Notification) {
        let controller = notification.object as! GCController
        gameController = controller
        self.updatePad()
    }
    
    func scanPad() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.didConnectController), name: NSNotification.Name.GCControllerDidConnect, object: nil)
        GCController.startWirelessControllerDiscovery {}
    }
    
    func updatePad() {
        if(gameController.extendedGamepad == nil) {
            gameController = GCController.controllers()[0]
        }
        
        setControllerInputHandler()
    }
    
    func setControllerInputHandler() {
        gameController.extendedGamepad?.valueChangedHandler =
        {(gamepad: GCExtendedGamepad, element: GCControllerElement) in
            if element == gamepad.dpad {
                nes.pressU(gamepad.dpad.up.isPressed)
                nes.pressD(gamepad.dpad.down.isPressed)
                nes.pressL(gamepad.dpad.left.isPressed)
                nes.pressR(gamepad.dpad.right.isPressed)
            }
            
            
            if element == gamepad.buttonA {
                nes.pressB(gamepad.buttonA.isPressed)
            }
            
            if element == gamepad.buttonB {
                nes.pressA(gamepad.buttonB.isPressed)
            }
            
            if element == gamepad.buttonY {
                nes.pressStart(gamepad.buttonY.isPressed)
            }
            
            if element == gamepad.buttonX {
                nes.pressSelect(gamepad.buttonX.isPressed)
            }
            
            if element == gamepad.buttonOptions {
                nes.pressSelect(gamepad.buttonOptions!.isPressed)
            }
            
            if element == gamepad.buttonMenu {
                nes.pressStart(gamepad.buttonMenu.isPressed)
            }
        }
    }
}
