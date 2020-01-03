//
//  PhotoCaptureDelegate.swift
//  ColorAnalyzer
//
//  Created by Cesar Lema on 1/31/19.
//  Copyright © 2019 Cesar Lema. All rights reserved.
//
import AVFoundation
import Foundation

class PhotoCaptureProcessor: NSObject {
    override init() {
        print("--------------- initializing photo capture delegta")
        //photoData = Data()
    }
    // does this class need an initializer
    // ---------------- properties ----------------
    var photoData: Data!
  
}

extension PhotoCaptureProcessor: AVCapturePhotoCaptureDelegate
{
    // protocal implementations
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?)
    {
        print("---------- in photo capture delegate didfinishprocessingPhoto")
        self.completionHandler(photoOutput: photo, photoOutput: error)
        print("---------- finished photo capture delegate didfinishprocessingPhoto")
        
    }
    
    /*
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        // implement to save photos to library
    }
    */
    
    // --------------------- inner implementations ---------------------
    
    func completionHandler(photoOutput photo : AVCapturePhoto,photoOutput error: Error?)
    {
        print("---------------in storing photo data")
        if let error = error {
            print("Error capturing photo: \(error)")
        } else {
            photoData = photo.fileDataRepresentation()
        }
        photoData = photo.fileDataRepresentation()
        print("---------------finished storing photo data")
    }
}
