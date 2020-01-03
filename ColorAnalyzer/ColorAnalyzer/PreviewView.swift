//
//  PreviewView.swift
//  ColorAnalyzer
//
//  Created by Cesar Lema on 1/31/19.
//  Copyright © 2019 Cesar Lema. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class PreviewView: UIView
{
    override class var layerClass: AnyClass
    {
        // what happens if return AVCaptureVideoPreviewLayer() instead of return AVCaptureVideoPreviewLayer.self
        return AVCaptureVideoPreviewLayer.self
    }
    
    // getting videopreviewlayer as its own type, not CALayer
    var videoPreviewLayer: AVCaptureVideoPreviewLayer
    {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    var Session: AVCaptureSession?
    {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }
}
