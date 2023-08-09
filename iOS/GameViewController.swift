//
//  GameViewController.swift
//  NES_EMU (iOS)
//
//  Created by mio on 2023/8/9.
//

import UIKit
import GameController


class GameViewController: UIViewController {
    
    private var virtualController: GCVirtualController!
        let nes = Nes.sharedInstance
        override func viewDidLoad() {
            super.viewDidLoad()
            
            let config = GCVirtualController.Configuration()
            config.elements = [
                GCInputDirectionPad,
                GCInputButtonB,
                GCInputButtonA,
                GCInputButtonX,
                GCInputButtonY,
            ]
            self.virtualController = GCVirtualController(configuration: config)
            
            self.virtualController.connect { error in
                if let error = error {
                    print(error)
                }
            }
            
            if let dpad: GCControllerDirectionPad = self.virtualController.controller?.extendedGamepad?.dpad {
                        dpad.valueChangedHandler = { (dpad: GCControllerDirectionPad, xValue: Float, yValue: Float) in
                            if dpad.up.isPressed {
                                print("↑")
                                self.nes.m_controllerPorts.pressU()
                            }
                            if !dpad.up.isPressed {
                                self.nes.m_controllerPorts.pressU(false)
                            }
                            if dpad.down.isPressed {
                                print("↓")
                                self.nes.m_controllerPorts.pressD()
                            }
                            if !dpad.down.isPressed {
                                print("↓")
                                self.nes.m_controllerPorts.pressD(false)
                            }
                            if dpad.left.isPressed {
                                print("←")
                                self.nes.m_controllerPorts.pressL()
                            }
                            if !dpad.left.isPressed {
                                print("←")
                                self.nes.m_controllerPorts.pressL(false)
                            }
                            if dpad.right.isPressed {
                                self.nes.m_controllerPorts.pressR()
                            }
                            if !dpad.right.isPressed {
                                self.nes.m_controllerPorts.pressR(false)
                            }
                        }
                    }
                    
            if let buttonA: GCControllerButtonInput = self.virtualController.controller?.extendedGamepad?.buttonA {
                buttonA.valueChangedHandler = { (button: GCControllerButtonInput, value: Float, pressed: Bool) in
                    if buttonA.isPressed {
                        print("B")
                        self.nes.m_controllerPorts.pressB()
                    }
                    if !buttonA.isPressed {
                        print("B")
                        self.nes.m_controllerPorts.pressB(false)
                    }
                }
            }
            
            if let buttonB: GCControllerButtonInput = self.virtualController.controller?.extendedGamepad?.buttonB {
                buttonB.valueChangedHandler = { (button: GCControllerButtonInput, value: Float, pressed: Bool) in
                    if buttonB.isPressed {
                        print("A")
                        self.nes.m_controllerPorts.pressA()
                    }
                    if !buttonB.isPressed {
                        print("A")
                        self.nes.m_controllerPorts.pressA(false)
                    }
                }
            }
            
            if let buttonB: GCControllerButtonInput = self.virtualController.controller?.extendedGamepad?.buttonX {
                buttonB.valueChangedHandler = { (button: GCControllerButtonInput, value: Float, pressed: Bool) in
                    if buttonB.isPressed {
                        print("Option")
                        self.nes.m_controllerPorts.pressSelect()
                    }
                    if !buttonB.isPressed {
                        print("Option")
                        self.nes.m_controllerPorts.pressSelect(false)
                    }
                }
            }
            
            if let buttonB: GCControllerButtonInput = self.virtualController.controller?.extendedGamepad?.buttonY {
                buttonB.valueChangedHandler = { (button: GCControllerButtonInput, value: Float, pressed: Bool) in
                    if buttonB.isPressed {
                        print("Start")
                        self.nes.m_controllerPorts.pressStart()
                    }
                    if !buttonB.isPressed {
                        print("Start")
                        self.nes.m_controllerPorts.pressStart(false)
                    }
                }
            }
        }
    
        func updateConfig()
        {
            self.virtualController.updateConfiguration(forElement: GCInputButtonA, configuration: { _ in
            let elementConfiguration: GCVirtualController.ElementConfiguration = GCVirtualController.ElementConfiguration()
            
            elementConfiguration.path = UIBezierPath()
            
            let bezierPath: UIBezierPath = UIBezierPath()
            bezierPath.move(to: CGPoint(x: 0, y: 0))
            bezierPath.addLine(to: CGPoint(x: -10, y: -10))
            bezierPath.addLine(to: CGPoint(x: 10, y: -10))
            bezierPath.addLine(to: CGPoint(x: 10, y: 10))
            bezierPath.addLine(to: CGPoint(x: -10, y: 10))
            bezierPath.close()
            
            elementConfiguration.path?.append(bezierPath)

            return elementConfiguration
        })
        }
        
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            
            self.virtualController.disconnect()
        }
}
