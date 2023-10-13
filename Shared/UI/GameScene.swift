//
//  GameScene.swift
//  NES_EMU
//
//  Created by mio on 2023/8/12.
//

import Foundation
import SpriteKit
import GameController

protocol IRenderScreen
{
    func renderScreen()
}

class GameScene: SKScene,IRenderScreen {
    
    func getFpsInfo()->String
    {
        return nes.getFpsInfo()
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        #if os(iOS)
        #else
        
        DispatchQueue.main.async {
            let viewSize = CGSize.init(width: self.view?.frame.width ?? 256, height: self.view?.frame.height ?? 240)
            self.adjRenderCavansSize(viewSize)
            self.renderBG()
        }
        
        #endif
    }
    
    func adjRenderCavansSize(_ oldSize: CGSize)
    {
        let windowWidth = oldSize.width
        let windowHeight = oldSize.height
        
        if Float(Float(windowWidth)/Float(windowHeight))>Float(256.0/240.0) {
            gameCanvasHeight = Int(windowHeight)
            gameCanvasWidth = gameCanvasHeight*256/240
            
            gameCanvasCenterX = Int(gameCanvasWidth/2 + (Int(windowWidth) - gameCanvasWidth)/2)
            gameCanvasCenterY = Int(gameCanvasHeight/2)
        }
        else {
            gameCanvasWidth = Int(windowWidth)
            gameCanvasHeight = Int(windowWidth*240/256)
            
            gameCanvasCenterX = Int(gameCanvasWidth/2)
            gameCanvasCenterY = Int(gameCanvasHeight/2 + (Int(windowHeight) - gameCanvasHeight)/2)
        }
    }
    
    override func didMove(to view: SKView) {
        self.scanPad()
        self.scaleMode = .resizeFill
#if os(iOS)
        self.gameCanvasCenterX = Int(gameCanvasWidth/2 + (Int(UIScreen.screenWidth) - gameCanvasWidth)/2)
        self.gameCanvasCenterY = Int(UIScreen.GAP)/2+Int(gameCanvasHeight/2)
#else
#endif
        
        rawBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 256*240*4)
        nes.loadRom()
        nes.setRenderScreen(iRenderScreen: self)
        nes.start()
        
        backgroundColor = .black
    }
    
    
    func renderBG() {
        if self.rawBuffer == nil {
            return
        }
        
        if bIsBusy {
            return
        }
        
        bIsBusy = true
        nes.renderer.getFrame(dstArray2Pointer: &self.rawBuffer)
        let data = Data(bytes: self.rawBuffer, count: 256*240*4)//Data.init(self.rawBuffer)
        let bgTexture = SKTexture.init(data: data, size: CGSize(width: 256, height: 240))
        bgTexture.filteringMode = .nearest
        let bkNode = SKSpriteNode.init(texture: bgTexture)
        
#if os(iOS)
        bkNode.position = CGPoint.init(x: gameCanvasCenterX, y: gameCanvasCenterY)
        bkNode.size = CGSize(width: gameCanvasWidth, height: gameCanvasHeight)
#else
        bkNode.position = CGPoint.init(x: gameCanvasCenterX, y: gameCanvasCenterY)
        bkNode.size = CGSize(width: gameCanvasWidth, height: gameCanvasHeight)
#endif
        arraySKShapeNode.append(bkNode)
        addChild(bkNode)
        
        bIsBusy = false
    }
    
    //Current not use.
    func renderSprites() {
        let spriteObjs = nes.getSpriteObjs()
        for spriteObj in spriteObjs {
            let location = CGPoint.init(x: spriteObj.x+4, y: spriteObj.y-4)
            let size = CGSize(width: 8, height: 8)
            let spriteNode = SKSpriteNode.init(texture: spriteObj.getTexture())
            spriteNode.size = size
            spriteNode.position = location
            
            arraySKShapeNode.append(spriteNode)
            addChild(spriteNode)
        }
    }
    
    func renderScreen() {
        for sKShapeNode in arraySKShapeNode {
            sKShapeNode.removeFromParent()
        }
        
        arraySKShapeNode.removeAll()
        
        if enableDrawBG {
            self.renderBG()
        }
        
        //Current not use.
        /*
        if(enableDrawSprites)
        {
            self.renderSprites()
        }*/
    }
    
    
#if os(iOS)
    var gameCanvasWidth = Int((UIScreen.screenHeight-UIScreen.GAP)*256/240)
    var gameCanvasHeight = Int((UIScreen.screenHeight-UIScreen.GAP))
#else
    var gameCanvasWidth = 0
    var gameCanvasHeight = 0
    var window: NSWindow?
#endif

    var gameCanvasCenterX = 0
    var gameCanvasCenterY = 0
    
    
    var arraySKShapeNode:[SKSpriteNode] = []
    var enableDrawBG = true
    var enableDrawSprites = false
    var rawBuffer:UnsafeMutablePointer<UInt8>!
    
    var bIsBusy = false
    var gameController: GCController = GCController()
    
}
