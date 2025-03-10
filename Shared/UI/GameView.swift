//
//  SwiftUIView.swift
//  NES_EMU
//
//  Created by mio on 2023/7/23.
//

import SwiftUI
import SpriteKit

let nes = Nes.sharedInstance

#if os(iOS)
struct GameView: View {
    var body: some View {
        SpriteView(scene: scene)
    }
    let scene: GameScene
}
#else
struct GameView: View {
    var body: some View {
        GeometryReader { proxy in
            GameViewRepresentable(scene: scene, proxy: proxy,window: $window)
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

