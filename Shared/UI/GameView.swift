//
//  SwiftUIView.swift
//  NES_EMU
//
//  Created by mio on 2023/7/23.
//

import SwiftUI

import SpriteKit

protocol IRenderScreen
{
    func renderScreen()
}

let nes = Nes.sharedInstance

class GameScene: SKScene,IRenderScreen {
    

    func getFpsInfo()->String
    {
        return nes.getFpsInfo()
    }
    
    override func didMove(to view: SKView) {
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

