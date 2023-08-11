//
//  SwiftUIView.swift
//  NES_EMU
//
//  Created by mio on 2023/7/23.
//

import SwiftUI

import SpriteKit
import GameController

protocol IRenderScreen
{
    func renderScreen()
}

let nes = Nes.sharedInstance
var m_controller: GCController = GCController()
class GameScene: SKScene,IRenderScreen {
    
    private(set) var controllers = Set<GCController>()
    
    @objc func didConnectController(_ notification: Notification) {
            //writeToLog(newLine: "didConnectController")
            
            //guard controllers.count < maximumControllerCount else { return }
            let controller = notification.object as! GCController
            controllers.insert(controller)
            m_controller = controller
            self.updatePad()
            //delegate?.inputManager(self, didConnect: controller)
            /*
            controller.extendedGamepad?.dpad.left.pressedChangedHandler =      { (button, value, pressed) in self.buttonChangedHandler("←", pressed, self.overlayLeft) }
            controller.extendedGamepad?.dpad.right.pressedChangedHandler =     { (button, value, pressed) in self.buttonChangedHandler("→", pressed, self.overlayRight) }
            controller.extendedGamepad?.dpad.up.pressedChangedHandler =        { (button, value, pressed) in self.buttonChangedHandler("↑", pressed, self.overlayUp) }
            controller.extendedGamepad?.dpad.down.pressedChangedHandler =      { (button, value, pressed) in self.buttonChangedHandler("↓", pressed, self.overlayDown) }
            
            // buttonA is labeled "X" (blue) on PS4 controller
            controller.extendedGamepad?.buttonA.pressedChangedHandler =        { (button, value, pressed) in self.buttonChangedHandler("⨯", pressed, self.overlayA) }
            // buttonB is labeled "circle" (red) on PS4 controller
            controller.extendedGamepad?.buttonB.pressedChangedHandler =        { (button, value, pressed) in self.buttonChangedHandler("●", pressed, self.overlayB) }
            // buttonX is labeled "square" (pink) on PS4 controller
            controller.extendedGamepad?.buttonX.pressedChangedHandler =        { (button, value, pressed) in self.buttonChangedHandler("■", pressed, self.overlayX) }
            // buttonY is labeled "triangle" (green) on PS4 controller
            controller.extendedGamepad?.buttonY.pressedChangedHandler =        { (button, value, pressed) in self.buttonChangedHandler("▲", pressed, self.overlayY) }
            
            // buttonOptions is labeled "SHARE" on PS4 controller
            controller.extendedGamepad?.buttonOptions?.pressedChangedHandler = { (button, value, pressed) in self.buttonChangedHandler("SHARE", pressed, self.overlayOptions) }
            // buttonMenu is labeled "OPTIONS" on PS4 controller
            controller.extendedGamepad?.buttonMenu.pressedChangedHandler =     { (button, value, pressed) in self.buttonChangedHandler("OPTIONS", pressed, self.overlayMenu) }
            
            controller.extendedGamepad?.leftShoulder.pressedChangedHandler =   { (button, value, pressed) in self.buttonChangedHandler("L1", pressed, self.overlayLeftShoulder) }
            controller.extendedGamepad?.rightShoulder.pressedChangedHandler =  { (button, value, pressed) in self.buttonChangedHandler("R1", pressed, self.overlayRightShoulder) }
            
            controller.extendedGamepad?.leftTrigger.pressedChangedHandler =    { (button, value, pressed) in self.buttonChangedHandler("L2", pressed, self.overlayLeftShoulder) }
            controller.extendedGamepad?.leftTrigger.valueChangedHandler =      { (button, value, pressed) in self.triggerChangedHandler("L2", value, pressed) }
            controller.extendedGamepad?.rightTrigger.pressedChangedHandler =   { (button, value, pressed) in self.buttonChangedHandler("R2", pressed, self.overlayRightShoulder) }
            controller.extendedGamepad?.rightTrigger.valueChangedHandler =     { (button, value, pressed) in self.triggerChangedHandler("R2", value, pressed) }
            
            controller.extendedGamepad?.leftThumbstick.valueChangedHandler =   { (button, xvalue, yvalue) in self.thumbstickChangedHandler("THUMB-LEFT", xvalue, yvalue) }
            controller.extendedGamepad?.rightThumbstick.valueChangedHandler =  { (button, xvalue, yvalue) in self.thumbstickChangedHandler("THUMB-RIGHT", xvalue, yvalue) }
            
            controller.extendedGamepad?.leftThumbstickButton?.pressedChangedHandler =  { (button, value, pressed) in self.buttonChangedHandler("THUMB-LEFT", pressed, self.overlayLeftThumb) }
            controller.extendedGamepad?.rightThumbstickButton?.pressedChangedHandler = { (button, value, pressed) in self.buttonChangedHandler("THUMB-RIGHT", pressed, self.overlayRightThumb) }
             */
        }
        
        @objc func didDisconnectController(_ notification: Notification) {
            //writeToLog(newLine: "didDisconnectController")
            
            let controller = notification.object as! GCController
            controllers.remove(controller)
            
            //delegate?.inputManager(self, didDisconnect: controller)
        }
    
    func scanPad()
    {
        NotificationCenter.default.addObserver(self,
                                                       selector: #selector(self.didConnectController),
                                                       name: NSNotification.Name.GCControllerDidConnect,
                                                       object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.didDisconnectController),
                                               name: NSNotification.Name.GCControllerDidDisconnect,
                                               object: nil)
        
        GCController.startWirelessControllerDiscovery {}
    }
    
    func updatePad()
    {
        if(m_controller.extendedGamepad == nil)
        {
            m_controller = GCController.controllers()[0]
        }
        else
        {
            //m_controller = GCController()
        }
        
        setControllerInputHandler()
    }
    
    func setControllerInputHandler()
    {
        m_controller.extendedGamepad?.valueChangedHandler =
        {(gamepad: GCExtendedGamepad, element: GCControllerElement) in
            if element == gamepad.dpad
            {
                if gamepad.dpad.up.isPressed
                {
                    nes.m_controllerPorts.pressU()
                }
                else
                {
                    nes.m_controllerPorts.pressU(false)
                }
                
                if gamepad.dpad.down.isPressed
                {
                    nes.m_controllerPorts.pressD()
                }
                else
                {
                    nes.m_controllerPorts.pressD(false)
                }
                
                if gamepad.dpad.left.isPressed
                {
                    nes.m_controllerPorts.pressL()
                }
                else
                {
                    nes.m_controllerPorts.pressL(false)
                }
                
                if gamepad.dpad.right.isPressed
                {
                    nes.m_controllerPorts.pressR()
                }
                else
                {
                    nes.m_controllerPorts.pressR(false)
                }
            }
            
            
            if element == gamepad.buttonA
            {
                if gamepad.buttonA.isPressed
                {
                    nes.m_controllerPorts.pressB()
                }
                else
                {
                    nes.m_controllerPorts.pressB(false)
                }
            }
            
            if element == gamepad.buttonB
            {
                if gamepad.buttonB.isPressed{
                    nes.m_controllerPorts.pressA()
                }
                else
                {
                    nes.m_controllerPorts.pressA(false)
                }
            }
            if element == gamepad.buttonY
            {
                if gamepad.buttonY.isPressed{
                    nes.m_controllerPorts.pressStart()
                }
                else
                {
                    nes.m_controllerPorts.pressStart(false)
                }
            }
            
            if element == gamepad.buttonX
            {
                if gamepad.buttonX.isPressed{
                    nes.m_controllerPorts.pressSelect()
                }
                else
                {
                    nes.m_controllerPorts.pressSelect(false)
                }
            }
            
            if element == gamepad.buttonOptions
            {
                if gamepad.buttonOptions!.isPressed
                {
                    nes.m_controllerPorts.pressSelect()
                }
                else
                {
                    nes.m_controllerPorts.pressSelect(false)
                }
            }
            
            if element == gamepad.buttonMenu
            {
                if gamepad.buttonMenu.isPressed
                {
                    nes.m_controllerPorts.pressStart()
                }
                else
                {
                    nes.m_controllerPorts.pressStart(false)
                }
            }
        }
    }
    
    func getFpsInfo()->String
    {
        return nes.getFpsInfo()
    }
    
    override func didMove(to view: SKView) {
        self.scanPad()
        self.scaleMode = .resizeFill
#if os(iOS)
        self.CX = Int(W/2 + (Int(UIScreen.screenWidth) - W)/2)
        self.CY = Int(UIScreen.GAP)/2+Int(H/2)
#else
#endif
        
        
        rawBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 256*240*4)
        nes.loadRom()
        nes.startRun(iRenderScreen: self)
        
        backgroundColor = .black
    }
    
    var arraySKShapeNode:[SKSpriteNode] = []
    
    var enableDrawBG = true
    var enableDrawSprites = false
    var rawBuffer:UnsafeMutablePointer<UInt8>!
#if os(iOS)
    let W = Int((UIScreen.screenHeight-UIScreen.GAP)*256/240)
    let H = Int((UIScreen.screenHeight-UIScreen.GAP))
#else
#endif
    var CX = 0
    var CY = 0
    var m_bIsBusy = false
    func renderBG()
    {
        if(m_bIsBusy)
        {
            return
        }
        
        m_bIsBusy = true
        //BG
        //var dstArray2Pointer = UnsafeMutableRawPointer(&self.rawBuffer)
        nes.m_renderer.getFrame(dstArray2Pointer: &self.rawBuffer)
        
        
        
        let data = Data(bytes: self.rawBuffer, count: 256*240*4)//Data.init(self.rawBuffer)
        let bgTexture = SKTexture.init(data: data, size: CGSize(width: 256, height: 240))
        bgTexture.filteringMode = .nearest
        let bkNode = SKSpriteNode.init(texture: bgTexture)
        
        //bkNode.size = CGSize(width: 256, height: 240)
        
#if os(iOS)
        bkNode.position = CGPoint.init(x: self.CX, y: self.CY)
        bkNode.size = CGSize(width: W, height: H)
#else
        bkNode.position = CGPoint.init(x: 256/2, y: 240/2)
        bkNode.size = CGSize(width: 256, height: 240)
#endif
        
        
        
        
        //print("W+" + String(W))
        //print("H+" + String(H))
        
        arraySKShapeNode.append(bkNode)
        addChild(bkNode)
        
        m_bIsBusy = false
    }
    
    func renderSprites()
    {
        let spriteObjs = nes.getSpriteObjs()
        for spriteObj in spriteObjs
        {
            let location = CGPoint.init(x: spriteObj.x+4, y: spriteObj.y-4)
            let size = CGSize(width: 8, height: 8)
            let spriteNode = SKSpriteNode.init(texture: spriteObj.getTexture())
            spriteNode.size = size
            spriteNode.position = location
            
            arraySKShapeNode.append(spriteNode)
            addChild(spriteNode)
        }
    }
    
    func renderScreen()
    {
        for sKShapeNode in arraySKShapeNode
        {
            sKShapeNode.removeFromParent()
        }
        
        arraySKShapeNode.removeAll()
        
        if(enableDrawBG)
        {
            self.renderBG()
        }
        
        if(enableDrawSprites)
        {
            self.renderSprites()
        }
    }
    
}

#if os(iOS)
struct GameView: View {
    let scene: GameScene
    var body: some View {
        SpriteView(scene: scene)
                    .frame(width: UIScreen.screenWidth, height: UIScreen.screenHeight)
                    .ignoresSafeArea()
        //Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/).position(x: 0, y: 0)
    }
}

/*
struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        //GameView()
    }
}*/

#else
struct GameView: View {
    let scene: SKScene
    
    
    var body: some View {
        GeometryReader { proxy in
            GameViewRepresentable(scene: scene, proxy: proxy)
        }
        
    }
}

struct GameViewRepresentable: NSViewRepresentable {
    let scene: SKScene
    let proxy: GeometryProxy
    

    class KeyView: SKView {
        override var acceptsFirstResponder: Bool { true }
        override func keyUp(with event: NSEvent) {
            //print(">> key up \(event.charactersIgnoringModifiers ?? "")")
            switch(event.charactersIgnoringModifiers)
            {
            case "a":
                nes.m_controllerPorts.pressL(false)
                break
            case "s":
                nes.m_controllerPorts.pressD(false)
                break
            case "d":
                nes.m_controllerPorts.pressR(false)
                break
            case "w":
                nes.m_controllerPorts.pressU(false)
                break
            
            case "p":
                nes.m_controllerPorts.pressA(false)
                break
                
            case "o":
                nes.m_controllerPorts.pressB(false)
                break
            
            case "n":
                nes.m_controllerPorts.pressSelect(false)
                break
            case "m":
                nes.m_controllerPorts.pressStart(false)
                break
            case .none:
                //print("none")
                break
            case .some(_):
                //print("some")
                break
            }
        }
        override func keyDown(with event: NSEvent) {
            //print(">> key \(event.charactersIgnoringModifiers ?? "")")
            
            switch(event.charactersIgnoringModifiers)
            {
            case "a":
                nes.m_controllerPorts.pressL()
                break
            case "s":
                nes.m_controllerPorts.pressD()
                break
            case "d":
                nes.m_controllerPorts.pressR()
                break
            case "w":
                nes.m_controllerPorts.pressU()
                break
            case "p":
                nes.m_controllerPorts.pressA()
                break
            case "o":
                nes.m_controllerPorts.pressB()
                break
            case "n":
                nes.m_controllerPorts.pressSelect()
                break
            case "m":
                nes.m_controllerPorts.pressStart()
                break
            case .none:
                //print("none")
                break
            case .some(_):
                //print("some")
                break
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    
    
    
    func makeNSView(context: Context) -> SKView {
        scene.size = proxy.size
        context.coordinator.scene = scene

        
        
        let view = KeyView()
        view.presentScene(scene)
        return view
    }

    func updateNSView(_ nsView: SKView, context: Context) {
        context.coordinator.resizeScene(proxy: proxy)
    }

    class Coordinator: NSObject {
        weak var scene: SKScene?

        func resizeScene(proxy: GeometryProxy) {
            scene?.size = proxy.size
        }
    }
}
#endif

