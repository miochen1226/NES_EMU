//
//  WatchGameScene.swift
//  NES_EMU
//
//  Created by miochen on 2026/2/12.
//

import Foundation
import SpriteKit
#if os(iOS)
import GameController
#elseif os(watchOS)
import WatchKit
#endif

protocol IRenderScreen {
    func renderScreen()
}

class GameScene: SKScene, IRenderScreen {
    
    var bgSKSpriteNode: SKSpriteNode?
    
    func getFpsInfo() -> String {
        return nes.getFpsInfo()
    }
    
    override func sceneDidLoad() {
        let bufferSize = 256*240*4
        self.rawBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        let data = Data(bytes: self.rawBuffer, count: bufferSize)
        let bgTexture = SKTexture(data: data, size: CGSize(width: 256, height: 240))
        bgTexture.filteringMode = .nearest
        bgSKSpriteNode = SKSpriteNode(texture: bgTexture)
        if let bgSKSpriteNode = bgSKSpriteNode {
            self.addChild(bgSKSpriteNode)
        }
    }
    
    // MARK: - 布局防递归标志
    private var isUpdatingLayout = false
    var screenSize: CGSize = .zero
    // 尺寸变化时只调整画布节点，不触发纹理渲染
    
    func handleSizeChange(_ viewSize: CGSize) {
        self.backgroundColor = .white
        self.adjRenderCanvasSize(viewSize)
        self.bgSKSpriteNode?.position = CGPoint(x: viewSize.width/2, y: viewSize.height/2)//CGSize.init(width: viewSize.width, height: viewSize.height)
        self.bgSKSpriteNode?.size = viewSize
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        // 防止递归调用
//        if screenSize.width > oldSize.width {
//            return
//        }
        print(oldSize)
        screenSize = oldSize
//        guard !isUpdatingLayout else { return }
        guard oldSize.width > 200 else { return }//, oldSize.height > 0 else { return }
//        print(oldSize)
//        isUpdatingLayout = true
//        defer { isUpdatingLayout = false }
        
        //self.adjRenderCanvasSize(oldSize)
    }
    
    func adjRenderCanvasSize(_ viewSize: CGSize) {
        let windowWidth = viewSize.width
        let windowHeight = viewSize.height
        
        // 注意：不要设置 self.size = viewSize
        if self.size == viewSize {
            return
        }
        
        //self.size = viewSize
        scaleMode = .resizeFill
        //会使场景自动适应视图大小
        
        if windowWidth / windowHeight > 256.0 / 240.0 {
            // 宽屏模式：高度撑满，宽度按比例计算
            gameCanvasHeight = Int(windowHeight)
            gameCanvasWidth = gameCanvasHeight * 256 / 240
            
            let halfCanvasWidth = gameCanvasWidth / 2
            let canvasWidthFloat = CGFloat(gameCanvasWidth)
            let extraXOffset = Int((windowWidth - canvasWidthFloat) / 2)
            gameCanvasCenterX = halfCanvasWidth + extraXOffset
            gameCanvasCenterY = gameCanvasHeight / 2
        } else {
            // 窄屏模式：宽度撑满，高度按比例计算
            gameCanvasWidth = Int(windowWidth)
            gameCanvasHeight = Int(windowWidth * 240 / 256)
            
            gameCanvasCenterX = gameCanvasWidth / 2
            let halfCanvasHeight = gameCanvasHeight / 2
            let canvasHeightFloat = CGFloat(gameCanvasHeight)
            let extraYOffset = Int((windowHeight - canvasHeightFloat) / 2)
            gameCanvasCenterY = halfCanvasHeight + extraYOffset
        }
        
        //bgSKSpriteNode?.position = CGPoint(x: gameCanvasCenterX, y: gameCanvasCenterY)
        //bgSKSpriteNode?.size = CGSize(width: gameCanvasWidth, height: gameCanvasHeight)
    }
    
    // MARK: - 平台特定的初始化入口
    #if os(iOS)
    override func didMove(to view: SKView) {
        self.scanPad()
        self.scaleMode = .resizeFill
        
        self.gameCanvasCenterX = Int(gameCanvasWidth/2 + (Int(UIScreen.screenWidth) - gameCanvasWidth)/2)
        self.gameCanvasCenterY = Int(UIScreen.GAP)/2 + Int(gameCanvasHeight/2)
        
        nes.loadRom()
        nes.setRenderScreen(iRenderScreen: self)
        nes.start()
        backgroundColor = .black
    }
    #elseif os(watchOS)
    // watchOS 初始化方法（由 GameView 的 .onAppear 调用）
    func didAppearInSKScene() {
        self.scanPad()
        self.scaleMode = .aspectFill
        
        // 初始尺寸将由 GeometryReader 传入并触发 didChangeSize
        // 因此这里不再设置中心点，等待真实尺寸回调
        
        nes.loadRom()
        nes.setRenderScreen(iRenderScreen: self)
        nes.start()
        backgroundColor = .black
    }
    #endif
    
    func renderBG() {
        guard rawBuffer != nil, !bIsBusy else { return }
        bIsBusy = true
        nes.renderer.getFrame(dstArray2Pointer: &self.rawBuffer)
        let data = Data(bytes: self.rawBuffer, count: 256*240*4)
        let bgTexture = SKTexture(data: data, size: CGSize(width: 256, height: 240))
        bgSKSpriteNode?.texture = bgTexture
        bIsBusy = false
    }
    
    func renderScreen() {
        self.renderBG()
    }
    
    // MARK: - 平台特定属性
    #if os(iOS)
    var gameCanvasWidth = Int((UIScreen.screenHeight - UIScreen.GAP) * 256 / 240)
    var gameCanvasHeight = Int((UIScreen.screenHeight - UIScreen.GAP))
    #elseif os(watchOS)
    // watchOS 初始值设为 0，等待 didChangeSize 设置真实值
    var gameCanvasWidth = 0
    var gameCanvasHeight = 0
    #else
    var gameCanvasWidth = 0
    var gameCanvasHeight = 0
    var window: NSWindow?
    #endif

    var gameCanvasCenterX = 0
    var gameCanvasCenterY = 0
    
    var enableDrawBG = true
    var enableDrawSprites = false
    var rawBuffer: UnsafeMutablePointer<UInt8>!
    var bIsBusy = false
    
    #if os(iOS)
    var gameController: GCController = GCController()
    #endif
    
    #if os(watchOS)
    func scanPad() {
        print("watchOS: No game controller available")
    }
    #endifß
}
