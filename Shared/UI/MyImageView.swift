//
//  MyImageView.swift
//  NES_EMU
//
//  Created by mio on 2021/8/14.
//

import Foundation
import SwiftUI

extension NSObject {
    func RGB(r:CGFloat, g:CGFloat, b:CGFloat, alpha:CGFloat? = 1) -> NSColor {
        return NSColor(red: r/255, green: g/255, blue: b/255, alpha: alpha!)
    }
}

class DataHolder{
    static var shared:DataHolder = DataHolder.init()
    var chartView:ChartView?
}
class ChartView: NSView {
    var nes:Nes?
    var data: [Color4] {
        didSet {
            self.needsDisplay = true //<-- Here
        }
    }
    
    //let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    init(data: [Color4]) {
        self.data = data
        print("\(data)")
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = .white
        DataHolder.shared.chartView = self
    }
    
    func step()
    {
        nes?.step()
        data = nes!.m_renderer.rawColors
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func draw(_ dirtyRect: NSRect) {
        
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current else { return }
        context.saveGraphicsState()
        
        if data.count > 0 {
            //detect data present on ChartView
            let ctx = context.cgContext
            
            for y in 0...239
            {
                for x in 0...255
                {
                    let color4 = data[x + (239-y)*256]
                    let r = color4.d_r
                    let g = color4.d_g
                    let b = color4.d_b
                    let color = RGB(r: CGFloat(r), g: CGFloat(g), b: CGFloat(b)).cgColor
                    ctx.setFillColor(color)
                    ctx.fillEllipse(in: CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
            //ctx.setFillColor(NSColor.green.cgColor)
            //ctx.fillEllipse(in: CGRect(x: 10, y: 10, width: 10, height: 10))
        }
        
        context.restoreGraphicsState()
    }
}

struct MyImageView: NSViewRepresentable
{
    
    typealias NSViewType = ChartView
    let nes = Nes.init()
    func updateNSView(_ nsView: ChartView, context: Context) {
        nes.loadRom()
        
        for _ in 0...60*20
        {
            nes.step()
        }
        nsView.data = nes.m_renderer.rawColors
        nsView.nes = nes
    }
    
    @State var chartView:ChartView!
    
    func step()
    {
        nes.step()
        chartView?.data = nes.m_renderer.rawColors
    }
    
    var data: [Color4] = [Color4()]
    
    func makeNSView(context: NSViewRepresentableContext<Self>) -> ChartView {
        //ChartView(data: data)
        return ChartView(data: data)
    }
}
