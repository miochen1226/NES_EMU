//
//  ContentView.swift
//  Shared
//
//  Created by mio on 2021/8/6.
//

import SwiftUI


struct ContentView: View {
    //@State var timer = Timer.publish (every: 0.01, on: .current, in: .common).autoconnect()
    var body: some View {
        GameView(scene: GameScene()).frame(width: 256, height: 240, alignment: .center)
        /*
        ScreenCanvasView().frame(width: 256, height: 240).border(Color.purple, width: 0).onReceive(timer) { input in
            DataHolder.shared.canvasView?.step()
        }*/
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
