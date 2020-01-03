//
//  VideoReaderDelegate.swift
//  ColorAnalyzer
//
//  Created by Cesar Lema on 3/4/19.
//  Copyright © 2019 Cesar Lema. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class VideoReader: NSObject
{
    override init() {
        super.init()
    }
    
    let ReaderQueue = DispatchQueue(label: "")
    // can use class properties to asign a uniqe label
    var currFrame: CMSampleBuffer!
    //var frames = [CMSampleBuffer]()
    
    //var uniqueUIImage: UIImage!
    //var uniqueFrame = false
    /*
    func getUIImage () -> UIImage?
    {
        var computedUIImage: UIImage!
        
        ReaderQueue.async
        {
            if let frame = self.currFrame
            {
                guard let imageBuffer = CMSampleBufferGetImageBuffer(frame) else{ return }
                let newCIImage = CIImage(cvImageBuffer: imageBuffer)
                let context = CIContext()
                guard let newCGImage = context.createCGImage(newCIImage, from: newCIImage.extent) else { return }
                computedUIImage = UIImage(cgImage: newCGImage)
            }
        }
        
        return computedUIImage
        
    }
    */
}

extension VideoReader: AVCaptureVideoDataOutputSampleBufferDelegate
{
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("--------------- got a frame")
        currFrame = sampleBuffer
        
        /*
        if self.uniqueFrame == false
        {
            print("-------------- Uniqueframe set")
            currFrame = sampleBuffer
            uniqueFrame = true
        }
        */
        // if frames.length != 10 { add sampleBuffer}
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("--------------- dropped a frame")
    }
}
