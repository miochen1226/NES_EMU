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
    
    /*
    func initScene()->GameScene
    {
        nes.loadRom()
        nes.startRun(iRenderScreen: self)
        
        backgroundColor = .black
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        return self
    }*/
    
    func getFpsInfo()->String
    {
        return nes.getFpsInfo()
    }
    
    override func didMove(to view: SKView) {
        self.scaleMode = .resizeFill
        buffer.removeAll()
        for _ in 0..<256
        {
            for _ in 0..<240
            {
                buffer.append(0)
                buffer.append(0)
                buffer.append(0)
                buffer.append(0)
            }
        }
        
        nes.loadRom()
        nes.startRun(iRenderScreen: self)
        
        backgroundColor = .black
        //physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
    }
    
    var arraySKShapeNode:[SKSpriteNode] = []
    
    /*
    func getBgPixel(pos:Int)->[UInt8]
    {
        //let y = pos/256
        //let x = pos%256
        //let dataPix:Color4 = nes.m_renderer.GetPixel(x + (239-y)*256)
        
        let dataPix:Color4 = nes.m_renderer.GetPixel(pos)
        return [dataPix.d_r,dataPix.d_g,dataPix.d_b,UInt8(255)]
        //return [UInt8(drand48()*255),UInt8(drand48()*255),UInt8(drand48()*255),UInt8(255)]
    }
    */
    
    var enableDrawBG = true
    var enableDrawSprites = false
    var buffer:[UInt8] = []
    
    func getPixelColor(_ pos:Int,dataArray:[Color4])->[UInt8]
    {
        let color4 = dataArray[pos]
        if(color4 == nil)
        {
            return [0,0,0,0]
        }
        else
        {
            return dataArray[pos].getRgba()
        }
    }
    
    var m_bIsBusy = false
    func renderBG()
    {
        if(m_bIsBusy)
        {
            return
        }
        
        m_bIsBusy = true
        //BG
        var dstArray2Pointer = UnsafeMutablePointer<UInt8>(&self.buffer)
        nes.m_renderer.getFrame(dstArray2Pointer: &dstArray2Pointer)
        
        //let dataArray:[Color4] = Array<Color4>(UnsafeBufferPointer<UInt8>(start: buffer, count: 256*240*4))
                   
        /*
        var bytesBG:[UInt8] = []
        
        print(dataArray.count)
        for index in 0..<256*240-1
        {
            bytesBG.append(dataArray[index].d_r)
            bytesBG.append(dataArray[index].d_g)
            bytesBG.append(dataArray[index].d_b)
            bytesBG.append(dataArray[index].d_a)
        }
        */
        let data = Data.init(buffer)
        
        /*
        let bytes = stride(from: 0, to: (width * height), by: 1).flatMap {
            pos in
            return getPixelColor(pos,dataArray: dataArray)
        }
        */
        //let data = Data.init(bytes)
        let bgTexture = SKTexture.init(data: data, size: CGSize(width: 256, height: 240))
        bgTexture.filteringMode = .nearest
        let bkNode = SKSpriteNode.init(texture: bgTexture)
        bkNode.position = CGPoint.init(x: 128, y: 120)
        bkNode.size = CGSize(width: 256, height: 240)
        
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
                    .frame(width: 256, height: 240)
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
            print(">> key up \(event.charactersIgnoringModifiers ?? "")")
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
                print("none")
                break
            case .some(_):
                print("some")
                break
            }
        }
        override func keyDown(with event: NSEvent) {
            print(">> key \(event.charactersIgnoringModifiers ?? "")")
            
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
                print("none")
                break
            case .some(_):
                print("some")
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

