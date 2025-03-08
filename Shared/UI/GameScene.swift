//
//  GameScene.swift
//  NES_EMU
//
//  Created by mio on 2023/8/12.
//

import Foundation
import SpriteKit
import GameController

protocol IRenderScreen {
    func renderScreen()
}

class GameScene: SKScene, IRenderScreen {
    
    var bgSKShapeNode: SKSpriteNode?
    
    func getFpsInfo() -> String {
        return nes.getFpsInfo()
    }
    
    override func sceneDidLoad() {
        let bufferSize = 256*240*4
        self.rawBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        let data = Data(bytes: self.rawBuffer, count: bufferSize)
        let bgTexture = SKTexture.init(data: data, size: CGSize(width: 256, height: 240))
        bgTexture.filteringMode = .nearest
        bgSKShapeNode = SKSpriteNode.init(texture: bgTexture)
        if let bgSKShapeNode = bgSKShapeNode {
            self.addChild(bgSKShapeNode)
        }
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        DispatchQueue.main.async { [self] in
            if let view = self.view {
                let viewSize = CGSize.init(width: view.frame.width, height: view.frame.height)
                self.adjRenderCavansSize(viewSize)
                self.renderBG()
            }
        }
    }
    
    func adjRenderCavansSize(_ oldSize: CGSize) {
        let windowWidth = oldSize.width
        let windowHeight = oldSize.height
        
        self.size = oldSize
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
        
        if let bgSKShapeNode = self.bgSKShapeNode {
            //bgSKShapeNode.inputView?.frame = CGRect(x: gameCanvasCenterX , y: gameCanvasCenterY, width: gameCanvasWidth, height: gameCanvasHeight)
            bgSKShapeNode.position = CGPoint.init(x: gameCanvasCenterX, y: gameCanvasCenterY)
            bgSKShapeNode.size = CGSize(width: gameCanvasWidth, height: gameCanvasHeight)
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

        bgSKShapeNode?.texture = bgTexture
        
        bIsBusy = false
    }
    
    func renderScreen() {
        self.renderBG()
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
    
    var enableDrawBG = true
    var enableDrawSprites = false
    var rawBuffer:UnsafeMutablePointer<UInt8>!
    
    var bIsBusy = false
    var gameController: GCController = GCController()
    
}
