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
class GameScene: SKScene,IRenderScreen {
    let nes = Nes.init()
    override func didMove(to view: SKView) {
        
        nes.loadRom()
        nes.startRun(iRenderScreen: self)
        
        backgroundColor = .black
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
    }
    
    var arraySKShapeNode:[SKSpriteNode] = []
    
    
    func getPixel(pos:Int)->[UInt8]
    {
        let y = pos/256
        let x = pos%256
        let dataPix:Color4 = nes.m_renderer.rawColors[x + (239-y)*256]
        return [dataPix.d_r,dataPix.d_g,dataPix.d_b,UInt8(255)]
    }
    
    func renderScreen()
    {
        for sKShapeNode in arraySKShapeNode
        {
            sKShapeNode.removeFromParent()
        }
        
        arraySKShapeNode.removeAll()
        //BG
        
        let width = 256
        let height = 240
        var index = 0
        
        let bytes = stride(from: 0, to: (256 * 240), by: 1).flatMap {
            pos in
            return getPixel(pos: pos)
        }
        
        ///var myData = bytes.withUnsafeBufferPointer {Data(buffer: $0)}
        let data = Data(bytes: bytes)
        let bgTexture = SKTexture.init(data: data, size: CGSize(width: 256, height: 240))
        
        let bkNode = SKSpriteNode.init(texture: bgTexture)
        bkNode.position = CGPoint.init(x: 128, y: 120)
        bkNode.size = CGSize(width: 256, height: 240)
        
        arraySKShapeNode.append(bkNode)
        addChild(bkNode)
        
        let spriteObjs = nes.getSpriteObjs()
        
        for spriteObj in spriteObjs
        {
            let location = CGPoint.init(x: spriteObj.x+4, y: spriteObj.y-4)//event.location(in: self)

            let size = CGSize(width: 8, height: 8)
            let spriteNode = SKSpriteNode.init(texture: spriteObj.getTexture())
            spriteNode.size = size
            spriteNode.position = location

            arraySKShapeNode.append(spriteNode)
            addChild(spriteNode)
        }
    }
    
}


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

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    
    
    
    func makeNSView(context: Context) -> SKView {
        scene.size = proxy.size
        context.coordinator.scene = scene

        
        
        let view = SKView()
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
