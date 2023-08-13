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
                                self.nes.pressU()
                            }
                            if !dpad.up.isPressed {
                                self.nes.pressU(false)
                            }
                            if dpad.down.isPressed {
                                print("↓")
                                self.nes.pressD()
                            }
                            if !dpad.down.isPressed {
                                print("↓")
                                self.nes.pressD(false)
                            }
                            if dpad.left.isPressed {
                                print("←")
                                self.nes.pressL()
                            }
                            if !dpad.left.isPressed {
                                print("←")
                                self.nes.pressL(false)
                            }
                            if dpad.right.isPressed {
                                self.nes.pressR()
                            }
                            if !dpad.right.isPressed {
                                self.nes.pressR(false)
                            }
                        }
                    }
                    
            if let buttonA: GCControllerButtonInput = self.virtualController.controller?.extendedGamepad?.buttonA {
                buttonA.valueChangedHandler = { (button: GCControllerButtonInput, value: Float, pressed: Bool) in
                    if buttonA.isPressed {
                        print("B")
                        self.nes.pressB()
                    }
                    if !buttonA.isPressed {
                        print("B")
                        self.nes.pressB(false)
                    }
                }
            }
            
            if let buttonB: GCControllerButtonInput = self.virtualController.controller?.extendedGamepad?.buttonB {
                buttonB.valueChangedHandler = { (button: GCControllerButtonInput, value: Float, pressed: Bool) in
                    if buttonB.isPressed {
                        print("A")
                        self.nes.pressA()
                    }
                    if !buttonB.isPressed {
                        print("A")
                        self.nes.pressA(false)
                    }
                }
            }
            
            if let buttonB: GCControllerButtonInput = self.virtualController.controller?.extendedGamepad?.buttonX {
                buttonB.valueChangedHandler = { (button: GCControllerButtonInput, value: Float, pressed: Bool) in
                    if buttonB.isPressed {
                        print("Option")
                        self.nes.pressSelect()
                    }
                    if !buttonB.isPressed {
                        print("Option")
                        self.nes.pressSelect(false)
                    }
                }
            }
            
            if let buttonB: GCControllerButtonInput = self.virtualController.controller?.extendedGamepad?.buttonY {
                buttonB.valueChangedHandler = { (button: GCControllerButtonInput, value: Float, pressed: Bool) in
                    if buttonB.isPressed {
                        print("Start")
                        self.nes.pressStart()
                    }
                    if !buttonB.isPressed {
                        print("Start")
                        self.nes.pressStart(false)
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
