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
            
            //self.renderBG()
            //self.renderScreen()
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
        
        //skSpriteNodeBG.node?.position = CGPoint.init(x: gameCanvasCenterX, y: gameCanvasCenterY)
        //skSpriteNodeBG.node?.size = CGSize.init(width: windowWidth, height: windowHeight)
    }
    
    override func didMove(to view: SKView) {
        
        rawBgShapePack = UnsafeMutablePointer<SKSpriteNodePack>.allocate(capacity: 32*30*MemoryLayout<SKSpriteNodePack>.stride)
        var index = 0
        for y in 0 ..< 30 {
            for x in 0 ..< 32 {
                let realX = x*8
                let realY = (y)*8
                let location = CGPoint.init(x: realX+4, y: realY-4)
                let size = CGSize(width: 8, height: 8)
                
                let spriteNodePack = SKSpriteNodePack()
                let spriteNode = SKSpriteNode.init()
                spriteNode.size = size
                spriteNode.position = location
                
                spriteNodePack.node = spriteNode
            
                let sprite8x8 = nes.getBgSprite8x8s(index: index)
                spriteNodePack.sprite8x8 = sprite8x8
                rawBgShapePack[index] = spriteNodePack
                index += 1
                //.append(spriteNodePack)
                addChild(spriteNode)
            }
        }
        
        
        
        self.scanPad()
        self.scaleMode = .resizeFill
#if os(iOS)
        self.gameCanvasCenterX = Int(gameCanvasWidth/2 + (Int(UIScreen.screenWidth) - gameCanvasWidth)/2)
        self.gameCanvasCenterY = Int(UIScreen.GAP)/2+Int(gameCanvasHeight/2)
#else
#endif
        
        //skSpriteNodeBG = SKSpriteNodeBG()
        //spriteNodeBG = SKSpriteNode.init()
        //skSpriteNodeBG.node = spriteNodeBG
        //addChild(spriteNodeBG!)
        
        rawBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 256*240*4)
        nes.loadRom()
        nes.setRenderScreen(iRenderScreen: self)
        nes.start()
        
        backgroundColor = .black
    }
    
    var spriteNodeBG:SKSpriteNode!
    
    let frameLimitTime:Double = 1/30
    var lastTime:TimeInterval = 0
    override func update(_ currentTime: TimeInterval) {
        
        let dateDiff = currentTime - lastTime
        if dateDiff < self.frameLimitTime {
        }
        else {
            lastTime = currentTime
            self.renderScreen()
        }
        
    }
    
    func renderBG()
    {
        if(self.rawBuffer == nil)
        {
            return
        }
        
        if(bIsBusy)
        {
            return
        }
        
        bIsBusy = true
        nes.renderer.getFrame(dstArray2Pointer: &self.rawBuffer)
        let data = Data(bytes: self.rawBuffer, count: 256*240*4)//Data.init(self.rawBuffer)
        let bgTexture = SKTexture.init(data: data, size: CGSize(width: 256, height: 240))
        bgTexture.filteringMode = .nearest

        //skSpriteNodeBG.node?.texture = bgTexture
        
#if os(iOS)
        //skSpriteNodeBG.node?.position = CGPoint.init(x: gameCanvasCenterX, y: gameCanvasCenterY)
        //skSpriteNodeBG.node?.size = CGSize(width: gameCanvasWidth, height: gameCanvasHeight)
#else
        //skSpriteNodeBG.node?.position = CGPoint.init(x: gameCanvasCenterX, y: gameCanvasCenterY)
        //skSpriteNodeBG.node?.size = CGSize(width: gameCanvasWidth, height: gameCanvasHeight)
#endif
        
        
        bIsBusy = false
    }
    
    func renderSprites() {
        let spriteObjs = nes.tempSpriteObjs
        for spriteObj in spriteObjs {
            
            let spriteHeight = spriteObj.height
            let location = CGPoint.init(x: spriteObj.x+4, y: 240-spriteObj.y-spriteHeight/2-8)
            let size = CGSize(width: 8, height: spriteHeight)
            let spriteNode = SKSpriteNode.init(texture: spriteObj.getTexture())
            spriteNode.size = size
            spriteNode.position = location
            
            self.arraySKShapeNode.append(spriteNode)
            self.addChild(spriteNode)
        }
    }
    
    func renderBGTiles() {
        //TODO
        //let spriteObjs = nes.getBGSpriteObjs()
        
        //if arraySKShapeBGNode.count == 0 {
        //    return
        //}
        
        //for index in 0 ..< 960 {
        //    let bgShapePack = rawBgShapePack[index]
        //    bgShapePack.fillColor()
        //}
    }
    
    func renderScreen() {
        //bIsBusy = true
        if(bIsBusy)
        {
            return
        }
        
        bIsBusy = true
        
        
        for sKShapeNode in arraySKShapeNode
        {
            sKShapeNode.removeFromParent()
        }
        arraySKShapeNode.removeAll()
        
        if(enableDrawBG)
        {
            //TODO
            //self.renderBGTiles()
        }
        
        if(enableDrawSprites)
        {
            self.renderSprites()
        }
        
        bIsBusy = false
        
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
    var enableDrawSprites = true
    var rawBuffer:UnsafeMutablePointer<UInt8>!
    
    var bIsBusy = false
    var gameController: GCController = GCController()
    
    var rawBgShapePack:UnsafeMutablePointer<SKSpriteNodePack>!
    var arraySKShapeBGNode:[SKSpriteNodePack] = []
    //var skSpriteNodeBG:SKSpriteNodeBG!
}

class SKSpriteNodeBG : NSObject {
    var node:SKSpriteNode?
    var sprite8x8:Sprite8x8?
    
    func fillColor() {
        //node?.texture = sprite8x8?.getTexture()
    }
}

class SKSpriteNodePack : NSObject {
    var node:SKSpriteNode?
    var sprite8x8:Sprite8x8?
    
    func fillColor() {
        //node?.texture = sprite8x8?.getTexture()
    }
}
