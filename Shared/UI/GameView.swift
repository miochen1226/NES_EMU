//
//  GameView.swift
//  NES_EMU
//
//  Created by mio on 2023/7/23.
//

import SwiftUI
import SpriteKit
import CoreMotion
internal import Combine

let nes = Nes.sharedInstance

#if os(iOS)
struct GameView: View {
    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
    }
    let scene: GameScene
}


#elseif os(watchOS)
struct GameView: View {
    let scene: GameScene
    @StateObject private var motionManager = MotionManager()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                SpriteView(scene: scene)
                    .frame(width: geometry.size.width, height: geometry.size.width * 0.75)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2 + 5) // 稍微往下移 5 像素，避開頂部按鈕
                    .onAppear {
                        scene.size = CGSize(width: geometry.size.width, height: geometry.size.width * 0.75)
                        scene.scaleMode = .aspectFill
                        scene.didAppearInSKScene()
                        motionManager.startMonitoring(nes: nes)
                    }
                
                // 2. 控制層
                VStack {
                    // 頂部：將兩個功能鍵靠左放置，完全避開右側時間
                    HStack(spacing: 10) {
                        GameButton(title: "SEL", color: .gray,
                                   onPress: { nes.controllerPorts.pressSelect() },
                                   onRelease: { nes.controllerPorts.pressSelect(false) })
                            .frame(width: 45, height: 25) // 縮小尺寸
                        
                        GameButton(title: "STA", color: .gray,
                                   onPress: { nes.controllerPorts.pressStart() },
                                   onRelease: { nes.controllerPorts.pressStart(false) })
                            .frame(width: 45, height: 25)
                        
                        Spacer() // 把所有東西推向左邊
                    }
                    .padding(.top, 12) // 避開最頂部圓角
                    .padding(.horizontal, 10)
                    
                    Spacer()
                    
                    // 底部：A/B 按鈕維持原樣或稍微往內靠
                    HStack {
                        GameButton(title: "B", color: .red,
                                   onPress: { nes.controllerPorts.pressB() },
                                   onRelease: { nes.controllerPorts.pressB(false) })
                        Spacer()
                        GameButton(title: "A", color: .blue,
                                   onPress: { nes.controllerPorts.pressA() },
                                   onRelease: { nes.controllerPorts.pressA(false) })
                    }
                    .padding(.bottom, 10)
                    .padding(.horizontal, 10)
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}



struct GameButton: View {
    let title: String
    let color: Color
    let onPress: () -> Void
    let onRelease: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Text(title)
            .font(.system(size: title.count > 1 ? 12 : 24, weight: .bold))
            .foregroundColor(.white)
            .frame(width: title.count > 1 ? nil : 60,
                   height: title.count > 1 ? 30 : 60)
            .padding(.horizontal, title.count > 1 ? 8 : 0)
            .padding(.vertical, title.count > 1 ? 4 : 0)
            .background(color.opacity(isPressed ? 1.0 : 0.6))
            .cornerRadius(title.count > 1 ? 8 : 30)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            onPress()
                            WKInterfaceDevice.current().play(.click)
                        }
                    }
                    .onEnded { _ in
                        if isPressed {
                            isPressed = false
                            onRelease()
                        }
                    }
            )
    }
}

// 運動管理器
class MotionManager: NSObject, ObservableObject {
    private let motionManager = CMMotionManager()
    private var nes: Nes?
    private var lastDirection = Set<Direction>()
    
    @Published var isCalibrating = false
    @Published var currentRoll: Double = 0
    @Published var currentPitch: Double = 0
    
    enum Direction {
        case up, down, left, right
    }
    
    override init() {
        super.init()
    }
    
    func startMonitoring(nes: Nes) {
        self.nes = nes
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion not available")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 1/60
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            if let error = error {
                print("Motion error: \(error.localizedDescription)")
                return
            }
            
            guard let motion = motion else { return }
            self?.processMotion(motion)
        }
    }
    
    func stopMonitoring() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    private func processMotion(_ motion: CMDeviceMotion) {
        let roll = motion.attitude.roll    // 左右傾斜
        let pitch = motion.attitude.pitch   // 前後傾斜
        
        // 更新發布的屬性（用於 UI 顯示）
        DispatchQueue.main.async {
            self.currentRoll = roll
            self.currentPitch = pitch
        }
        
        let threshold = 0.25  // 傾斜觸發門檻
        
        var currentDirection = Set<Direction>()
        
        // 根據傾斜角度決定方向（支援對角線）
        if pitch > threshold {
            currentDirection.insert(.up)
        }
        if pitch < -threshold {
            currentDirection.insert(.down)
        }
        if roll > threshold {
            currentDirection.insert(.right)
        }
        if roll < -threshold {
            currentDirection.insert(.left)
        }
        
        // 處理按下的方向
        for direction in currentDirection {
            if !lastDirection.contains(direction) {
                pressDirection(direction)
            }
        }
        
        // 處理釋放的方向
        for direction in lastDirection {
            if !currentDirection.contains(direction) {
                releaseDirection(direction)
            }
        }
        
        lastDirection = currentDirection
    }
    
    private func pressDirection(_ direction: Direction) {
        guard let nes = nes else { return }
        switch direction {
        case .up:
            nes.controllerPorts.pressU()
        case .down:
            nes.controllerPorts.pressD()
        case .left:
            nes.controllerPorts.pressL()
        case .right:
            nes.controllerPorts.pressR()
        }
    }
    
    private func releaseDirection(_ direction: Direction) {
        guard let nes = nes else { return }
        switch direction {
        case .up:
            nes.controllerPorts.pressU(false)
        case .down:
            nes.controllerPorts.pressD(false)
        case .left:
            nes.controllerPorts.pressL(false)
        case .right:
            nes.controllerPorts.pressR(false)
        }
    }
}

#else
// macOS 實現（保持不變）
struct GameView: View {
    var body: some View {
        GeometryReader { proxy in
            GameViewRepresentable(scene: scene, proxy: proxy, window: $window)
        }
    }
    
    let scene: GameScene
    @State private var window: NSWindow?
}

struct GameViewRepresentable: NSViewRepresentable {
    class KeyView: SKView {
        override var acceptsFirstResponder: Bool { true }
        override func keyUp(with event: NSEvent) {
            switch(event.charactersIgnoringModifiers)
            {
            case "a":
                nes.pressL(false)
                break
            case "s":
                nes.pressD(false)
                break
            case "d":
                nes.pressR(false)
                break
            case "w":
                nes.pressU(false)
                break
            
            case "p":
                nes.pressA(false)
                break
                
            case "o":
                nes.pressB(false)
                break
            
            case "n":
                nes.pressSelect(false)
                break
            case "m":
                nes.pressStart(false)
                break
            case .none:
                break
            case .some(_):
                break
            }
        }
        
        override func keyDown(with event: NSEvent) {
            switch(event.charactersIgnoringModifiers)
            {
            case "1":
                nes.saveState()
                break
            case "2":
                nes.loadState()
                break
            case "a":
                nes.pressL()
                break
            case "s":
                nes.pressD()
                break
            case "d":
                nes.pressR()
                break
            case "w":
                nes.pressU()
                break
            case "p":
                nes.pressA()
                break
            case "o":
                nes.pressB()
                break
            case "n":
                nes.pressSelect()
                break
            case "m":
                nes.pressStart()
                break
            case .none:
                break
            case .some(_):
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
        DispatchQueue.main.async {
            self.window = view.window
            view.window?.title = "NES"
        }
        
        view.presentScene(scene)
        return view
    }

    func updateNSView(_ nsView: SKView, context: Context) {
        context.coordinator.resizeScene(proxy: proxy)
    }

    class Coordinator: NSObject {
        weak var scene: GameScene?

        func resizeScene(proxy: GeometryProxy) {
            scene?.size = proxy.size
        }
    }
    
    let scene: GameScene
    let proxy: GeometryProxy
    @Binding var window: NSWindow?
}
#endif
