//
//  ContentView.swift
//  Shared
//
//  Created by mio on 2021/8/6.
//

import SwiftUI
#if os(iOS)
extension UIScreen{
    static let screenWidth = UIScreen.main.bounds.size.width
    static let screenHeight = UIScreen.main.bounds.size.height
    static let screenSize = UIScreen.main.bounds.size
    static let GAP:CGFloat = 70.0
}
#else
#endif

struct ContentView: View {
    
    var body: some View {
        
        ZStack {
#if os(iOS)
                
                GameView(scene: scene).frame(width: nil, height: nil,alignment: .top).overlay(
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                scene.didChangeSize(geometry.size)
                            }
                            .onChange(of: geometry.size) { _ in
                                scene.didChangeSize(geometry.size)
                            }
                    }
                )
                
                VStack {
                    HStack {
                        Spacer()
                        Text(labenFps).onReceive(timer) { _ in
                            updateFps()
                        }
                    }
                    Spacer()
                }
                .foregroundStyle(.white)
                
                VirtualControllerView()
#else
                GameView(scene: scene).frame(width: nil, height: nil,alignment: .top)
                
            if #available(macOS 12.0, *) {
                VStack {
                    HStack {
                        Spacer()
                        Text(labenFps).onReceive(timer) { _ in
                            updateFps()
                        }
                    }
                    Spacer()
                }
                .foregroundStyle(.white)
            }
#endif
        }.background(Color.black)
        
    }
    
    private func updateFps() {
        let fpsInfo = scene.getFpsInfo()
        labenFps = fpsInfo
    }
    
    @State var labenFps = "FPS"
    @State var scene = GameScene()
    @State var timer = Timer.publish (every: 1, on: .current, in: .common).autoconnect()
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
