//
//  ContentView.swift
//  Shared
//
//  Created by mio on 2021/8/6.
//

import SwiftUI
import SpriteKit


struct ContentView: View {
    //@State var timer = Timer.publish (every: 0.1, on: .current, in: .common).autoconnect()
    
    var scene: NESScene {
            let scene = NESScene()
            scene.size = CGSize(width: 256, height: 240)
            scene.scaleMode = .aspectFill
            return scene
        }

    var body: some View {
        SpriteView(scene: scene)
            .frame(width: 256, height: 240)
            //.frame(maxWidth: .infinity, maxHeight: .infinity)
            //.ignoresSafeArea()
    }
    
    //var body: some View {
    //    let scene = NESScene()
    //    view!.presentScene(scene)
        //ScreenCanvasView().frame(width: 256, height: 240).border(Color.purple, width: 0).onReceive(timer) { input in
          //  DataHolder.shared.canvasView?.step()
        //}
    //}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
