//
//  ContentView.swift
//  Shared
//
//  Created by mio on 2021/8/6.
//

import SwiftUI


struct ContentView: View {
    
    @State var labenFps = "FPS"
    @State var scene = GameScene()
    @State var timer = Timer.publish (every: 1, on: .current, in: .common).autoconnect()
    var body: some View {
        
        ZStack {
            GameView(scene: scene).frame(width: 256, height: 240, alignment: .top)
            Text(labenFps).position(x: 20, y: 20).onReceive(timer) { _ in
                updateFps()
            }
#if os(iOS)
            VirtualControllerView()
#else
#endif
        }
        
    }
    
    private func updateFps() {
        //let dateFormatter = DateFormatter()
        //dateFormatter.dateFormat = "HH:mm:ss"
        //let date = Date()
        //let resultString = dateFormatter.string(from: date)
        let fpsInfo = scene.getFpsInfo()
        labenFps = fpsInfo
        //print("current timestamp: \(timestamp)")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
