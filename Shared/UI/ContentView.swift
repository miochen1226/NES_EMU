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
            GameView(scene: scene).frame(width: UIScreen.screenWidth, height: UIScreen.screenHeight, alignment: .top)
            VirtualControllerView()
#else
            GameView(scene: scene).frame(width: nil, height: nil,alignment: .top)
            
            Text(labenFps).position(x: 40, y: 20).onReceive(timer) { _ in
                updateFps()
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
