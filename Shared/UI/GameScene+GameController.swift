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
                if gamepad.dpad.up.isPressed {
                    nes.controllerPorts.pressU()
                }
                else {
                    nes.controllerPorts.pressU(false)
                }
                
                if gamepad.dpad.down.isPressed {
                    nes.controllerPorts.pressD()
                }
                else {
                    nes.controllerPorts.pressD(false)
                }
                
                if gamepad.dpad.left.isPressed {
                    nes.controllerPorts.pressL()
                }
                else {
                    nes.controllerPorts.pressL(false)
                }
                
                if gamepad.dpad.right.isPressed {
                    nes.controllerPorts.pressR()
                }
                else {
                    nes.controllerPorts.pressR(false)
                }
            }
            
            
            if element == gamepad.buttonA {
                if gamepad.buttonA.isPressed {
                    nes.controllerPorts.pressB()
                }
                else {
                    nes.controllerPorts.pressB(false)
                }
            }
            
            if element == gamepad.buttonB {
                if gamepad.buttonB.isPressed {
                    nes.controllerPorts.pressA()
                }
                else {
                    nes.controllerPorts.pressA(false)
                }
            }
            
            if element == gamepad.buttonY {
                if gamepad.buttonY.isPressed {
                    nes.controllerPorts.pressStart()
                }
                else {
                    nes.controllerPorts.pressStart(false)
                }
            }
            
            if element == gamepad.buttonX {
                if gamepad.buttonX.isPressed {
                    nes.controllerPorts.pressSelect()
                }
                else {
                    nes.controllerPorts.pressSelect(false)
                }
            }
            
            if element == gamepad.buttonOptions {
                if gamepad.buttonOptions!.isPressed {
                    nes.controllerPorts.pressSelect()
                }
                else {
                    nes.controllerPorts.pressSelect(false)
                }
            }
            
            if element == gamepad.buttonMenu {
                if gamepad.buttonMenu.isPressed {
                    nes.controllerPorts.pressStart()
                }
                else {
                    nes.controllerPorts.pressStart(false)
                }
            }
        }
    }
}
