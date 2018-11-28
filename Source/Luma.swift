//
//  Luma.swift
//  Luma Face
//
//  Created by Hexagons on 2018-11-24.
//  Copyright © 2018 Hexagons. All rights reserved.
//

import UIKit
import Pixels
import Pixels3D
import ARKit

class Luma: PIXDelegate, ARMirror {
    
//    static let light = Luma()
    
//    var renderCallbacks: [(pix: PIX, callback: () -> ())] = []
    
    var finalPix: PIX!
    
    var view: UIView {
        return finalPix.view
    }
    
    init(frame: CGRect) {
        
        let polygonPix = PolygonPIX(res: PIX.Res(autoScaleSize: frame.size))
        polygonPix.color = LiveColor.white.withAlpha(of: 0.1)
        polygonPix.bgColor = .clear
        
        let object3dPix = Object3DPIX()
        object3dPix
        
        finalPix = polygonPix
        finalPix.view.frame = frame
        finalPix.view.checker = false
        
    }
    
    func didUpdate(geo: ARFaceGeometry) {
        
    }
    
    
//    func flipY(image: UIImage, callback: @escaping (UIImage) -> ()) {
//        print("flipY >>>")
//        let imagePix = ImagePIX()
//        imagePix.name = "flipy:image"
//        imagePix.image = image
//        let flipPix = imagePix._flipY()
//        flipPix.delegate = self
//        renderCallbacks.append((pix: flipPix, callback: {
//            guard let finalImage = flipPix.renderedImage else {
//                print("flipY: no img")
//                return
//            }
//            print("flipY <<<")
//            callback(finalImage)
//        }))
//    }
    
    static func flipImage(_ image: UIImage) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        let bitmap = UIGraphicsGetCurrentContext()!
        
//        bitmap.translateBy(x: 0, y: image.size.height / 2)
//        bitmap.scaleBy(x: 1.0, y: -1.0)
//
//        bitmap.translateBy(x: 0, y: -image.size.height / 2)
        bitmap.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    func pixResChanged(_ pix: PIX, to res: PIX.Res) {}
    
    func pixDidRender(_ pix: PIX) {
//        print("luma: render: \(pix.name ?? "-")")
//        for (i, renderCallback) in renderCallbacks.enumerated() {
//            if renderCallback.pix == pix {
//                renderCallback.callback()
//                renderCallbacks.remove(at: i)
//                break
//            }
//        }
    }
    
}