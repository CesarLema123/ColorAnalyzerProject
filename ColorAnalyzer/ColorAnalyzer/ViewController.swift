//
//  ViewController.swift
//  ColorAnalyzer
//
//  Created by Cesar Lema on 1/24/19.
//  Copyright © 2019 Cesar Lema. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {
    
    // -------------------------- Properties -------------------------------
    var cameraSession: AVCaptureSession!
    var defaultVideoDevice: AVCaptureDevice!
    var sessionQueue: DispatchQueue!
    let photoDataOutput = AVCapturePhotoOutput()
    let photoOutput = AVCapturePhotoOutput()
    let photoSetting1 = AVCapturePhotoSettings()
    let captureProcessor1 = PhotoCaptureProcessor()
    var imageCaptured: UIImage!
    //var objectPhotoSetting: AVCapturePhotoSettings!     // depricated atm
    //var objectCaptureProcessor: PhotoCaptureProcessor!     // depricated atm
    // var objectImageCaptured: UIImage!         may need. not sure yet
    var rectCalibrationPressed = false
    let videoOutput = AVCaptureVideoDataOutput()
    let rectVideoReader = VideoReader()
    
    //var photoData: Data!
    
    @IBOutlet weak var PreviewView: PreviewView!
    @IBOutlet var capturedPhotoDisplay: UIImageView!
    @IBOutlet weak var CenterColorDisplay: UIView!
    
    // ---------------------------- UI Actions -----------------------------
    
    @IBAction func setImage(_ sender: UIButton) {
        //---------------- display image in UI ----------------
        convertProcessorPhotoToTypeUIimage()
        //imageCaptured = UIImage(data: captureProcessor1.photoData , scale: 1.0)
        displayCapturedPhoto()
        //capturedPhotoDisplay.image = imageCaptured
        
        //----------------- get center pixel color ------------------
        let centerPixelColor = imageCaptured.getCenterPixelColor()
        //sender.setTitleColor(centerPixelColor, for: .normal)
        CenterColorDisplay.backgroundColor = centerPixelColor
        print("\(String(describing: centerPixelColor.cgColor.components))")
        
        // ---------------- April 5, 2019 edits --------------------
        //var MLmodel = MLConstants()
        //let picker = UIPickerViewDataSource()
        //let MLTestdata = picker.
        //print()
        
        // ------------------------------
    }
    
    @IBAction func cameraButtonPressed(_ sender: UIButton) {
        // cannot run capturePHOTO() and set UIImageview in this same func
        sender.isEnabled=false    // set so button can be pressed only once
        
        print("-----------------in camera button pressed")
        TakePhoto()
        print("-----------------Passed take photo")
        // for single photo stop sessoion after taking photo
        sessionQueue.async {
            self.cameraSession.stopRunning()
        }
        //sender.setTitle("", for: .normal) // makes button invisible -> should transer to another view or delete button
        // convertProcessorPhotoToTypeUIimage()  // cannot do this here
        //displayCapturedPhoto()                   // cannot do this here
    }
    
    @IBAction func startRectCalibrationPressed(_ sender: UIButton) {
        rectCalibrationPressed = true
        sender.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        sender.setTitle("", for: .normal)
    }
    
    
    // ---------------------------- Initializations  -----------------------------
    override func viewWillLayoutSubviews() {
        // 4-15-19 edits------------

        PreviewView.videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        PreviewView.frame = self.view.bounds
        //-------------------------
    }
    
    override func viewDidLoad()    // innner "initialization(s)"
    {
        switch AVCaptureDevice.authorizationStatus(for: .video)
        {
        case .authorized:
            self.setUpCaptureSession()
        
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: {granted in if granted {self.setUpCaptureSession()}})
        
        default:
            return
        }
        
        setUpRectFeed()
        print("---------------- leaving view didload")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print("---------------- Entering ViewDidAppear")
        setUpObjectRect()
    }
    
    
    func setUpCaptureSession()
    {
        cameraSession = AVCaptureSession()
        cameraSession.beginConfiguration()
        
        // ----------------------- selecting for default device ------------------------
        if let rearCameraDevice = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video , position: .back)
        {
            defaultVideoDevice = rearCameraDevice
        }
        else if let rearCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        {
            defaultVideoDevice = rearCameraDevice
        }
        
       // --------------------------- adding input to session ----------------------------
        if let videoDeviceInput = try? AVCaptureDeviceInput.init(device: defaultVideoDevice)
        {
            cameraSession.addInput(videoDeviceInput)
        }
        else{
            return
        }
        
        // --------------------------- adding output to session ----------------------------
        // --------------------------- live video output --------------------------------------
        cameraSession.sessionPreset = .photo
        cameraSession.addOutput(photoOutput) // should check if can add output
        
        // ------------------ image data output/image ---------------------------------
        // do we need this? for what?
        // videoDataOutput.videoSettings =  use default values
        //let photoSetting = AVCapturePhotoSettings()
        //cameraSession.addOutput(photoDataOutput)       // should check if can add
        //videoDataOutput.capturePhoto(with: <#T##AVCapturePhotoSettings#>, delegate: <#T##AVCapturePhotoCaptureDelegate#>)
        
        
        // ----------------- finalize configurations -----------------------
        cameraSession.commitConfiguration()
        
        
        // ------------------ create dispatch queue -------------------------
        PreviewView.Session=cameraSession
        sessionQueue = DispatchQueue(label: "session queue")
        
        sessionQueue.async {
            self.cameraSession.startRunning()
        }
        
        print("----------------------finished setting up")
        // --------------- run the session a queue to prevent blocking ---------------
        //cameraSession.startRunning()
    }

    //--------------------------------- Capturing a photo -------------------------------------------
    // could create a set<> of photoCaptureProcessors to store multiple processsors for each capture in progress
    
    func TakePhoto() {
        print("---------- take photo")
        // Make a new capture delegate
        sessionQueue.async {
            self.photoOutput.capturePhoto(with: self.photoSetting1 , delegate: self.captureProcessor1)
        }
        //self.photoOutput.capturePhoto(with: photoSetting1 , delegate: captureProcessor1)
        print("---------- finished take photo")
    }

    // should clean up photosettings and capture processor
    // ---------------------------- Initializations cont... inititializing object rect -----------------------------
    func setUpRectFeed()
    {
        // cant figure out how to add this code to func setUpObjectRect(), currently messes up func if i do
        cameraSession.beginConfiguration()
        cameraSession.sessionPreset = .medium
        videoOutput.setSampleBufferDelegate(rectVideoReader, queue: rectVideoReader.ReaderQueue)
        cameraSession.addOutput(videoOutput) // should check if can add
        cameraSession.commitConfiguration()
    }
    
    
    func setUpObjectRect()
    {
        /* ---- depricated ------
        cameraSession.beginConfiguration()
        cameraSession.sessionPreset = .medium
        videoOutput.setSampleBufferDelegate(rectVideoReader, queue: rectVideoReader.ReaderQueue)
        cameraSession.addOutput(videoOutput) // should check if can add
        cameraSession.commitConfiguration()
        */
        /*
        var starterRectangleObservation: VNRectangleObservation!
        //var detectedObjectObservation: VNDetectedObjectObservation!
        var starterRectangle: CGRect!
        var frameUI: UIView = UIView()
        */
        var frameUI: UIView = UIView()
        
        sessionQueue.async {
            // still have to better create frameUI's rectangle and display.
            while (self.rectCalibrationPressed != true)  // this while loop finished once got a good iamge(so eventually finished once a picture is taken)
            {
                var starterRectangleObservation: VNRectangleObservation!
                //var detectedObjectObservation: VNDetectedObjectObservation!
                var starterRectangle: CGRect!
                //var frameUI: UIView = UIView()
                
                while(starterRectangle == nil)     // this while loop finished once a seed rectangle is found
                {
                    //frameUI.removeFromSuperview()
                    guard let convertedImageBuffer = CMSampleBufferGetImageBuffer(self.rectVideoReader.currFrame) else { return } // theres always a frame to get, feed always starts before this func
                    let currFrameHandler = VNImageRequestHandler(cvPixelBuffer: convertedImageBuffer , options: [:])
                    let currRectRequest = VNDetectRectanglesRequest()
                    
                    do
                    {
                        try currFrameHandler.perform([currRectRequest])
                        // if perform doesnt find a rect, doesnt add anything to results, and its empty
                        // perform only adds rect to results if finds rect
                    }
                    catch { }
                    
                    if currRectRequest.results?.count != 0
                    {
                        let rectObservation = currRectRequest.results![0] as! VNRectangleObservation
                        starterRectangleObservation = rectObservation
                        let viewWidth = self.PreviewView.frame.size.width               // self.view.frame.size.width
                        let viewHeight =  self.PreviewView.frame.size.height          // self.view.frame.size.height
                        print("\(viewWidth), \(viewHeight)")
                        
                        let frameRect = rectObservation.boundingBox
                        let frameRectOriginWidth = frameRect.origin.y   // displays better if y is used as width/horizontal distance
                        let frameRectOriginHeight = frameRect.origin.x  // displays better if x is used as height/vertical distance
                        let frameRectWidth = frameRect.width
                        let frameRectHeight = frameRect.height
                        print("\(frameRectOriginWidth), \(frameRectOriginHeight), \(frameRectWidth), \(frameRectHeight)")
                        let updatedFrameRect = CGRect(x: viewWidth*frameRectOriginWidth, y: viewHeight*frameRectOriginHeight, width: viewHeight*frameRectWidth, height: viewHeight*frameRectHeight)
                        
                        starterRectangle = updatedFrameRect
                        DispatchQueue.main.async {
                            frameUI = UIView.init(frame: starterRectangle)
                            frameUI.backgroundColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
                            frameUI.alpha = 0.5
                            self.view.addSubview(frameUI)
                        }
                        //self.view.addSubview(frameUI)
                    
                    }
                }
                print("--------------------finished getting starter RECTANGLE")
                // now we GOT the start rect and can track it until user start zooming process
            
                var currentRectangleObservation = starterRectangleObservation!   // seed rect request with new observation each time
                let rectTrackerHandler = VNSequenceRequestHandler()  // have to use a unqie handler for each sequence of tracked images,
                // currently if tracking fails consequtively alot then have to use a new handler and seed image, is there a way use the same tracker?
                var previousTrackWasFailure = false
                var consecutiveTrackerFailureCount = 0   //observation: fine for tracker to fail 1-2 but if its more usually cant track anymore
                var prevZoomFactor: CGFloat = 1.0
            
                while(self.rectCalibrationPressed != true && consecutiveTrackerFailureCount < 5)  // this rectangle is done once picture is taken or lost rectangle tracking
                {
                    if (previousTrackWasFailure)
                    {
                        consecutiveTrackerFailureCount += 1
                    }
                    else
                    {
                        consecutiveTrackerFailureCount = 0
                    }
                    
            
                    guard let convertedImageBuffer = CMSampleBufferGetImageBuffer(self.rectVideoReader.currFrame) else { return } // theres always a frame to get
                    //let rectTrackerHandler = VNSequenceRequestHandler()
                    let rectTrackerRequest = VNTrackRectangleRequest(rectangleObservation: currentRectangleObservation)
                    rectTrackerRequest.trackingLevel = .accurate // or can use .fast, not sure which is better yet
                    
        
                    
                    do
                    {
                        try rectTrackerHandler.perform([rectTrackerRequest], on: convertedImageBuffer)
                        // if perform doesnt find a rect, doesnt add anything to results, and its empty
                        // perform only adds rect to results if finds rect
                    }
                    catch {
                        print("------------------Tracking failed ---------------------------")
                        previousTrackWasFailure = true
                        //print("\(error)")
                        //currentRectangleObservation = starterRectangleObservation!
                        
                    }
              
     
                    if rectTrackerRequest.results != nil
                    {
                        let updatedRectObservation = rectTrackerRequest.results![0] as! VNDetectedObjectObservation   //  VNRectangleObservation
                        print("\(updatedRectObservation.boundingBox)")
                        currentRectangleObservation = updatedRectObservation as! VNRectangleObservation
                        
                        //detectedObjectObservation = updatedRectObservation
                        
                        let viewWidth = self.PreviewView.frame.size.width               // self.view.frame.size.width
                        let viewHeight =  self.PreviewView.frame.size.height          // self.view.frame.size.height
                        print("\(updatedRectObservation.boundingBox)")
                        
                        let frameRect = updatedRectObservation.boundingBox
                        let frameRectOriginWidth = frameRect.origin.y   // displays better if y is used as width/horizontal distance
                        let frameRectOriginHeight = frameRect.origin.x  // displays better if x is used as height/vertical distance
                        let frameRectWidth = frameRect.width
                        let frameRectHeight = frameRect.height
                        print("\(frameRectOriginWidth), \(frameRectOriginHeight), \(frameRectWidth), \(frameRectHeight)")
                        let updatedFrameRect = CGRect(x: viewWidth*frameRectOriginWidth, y: viewHeight*frameRectOriginHeight, width: viewHeight*frameRectWidth, height: viewHeight*frameRectHeight)
                        
                        starterRectangle = updatedFrameRect
                        DispatchQueue.main.async {
                            frameUI.frame = updatedFrameRect
                        }
                        //self.view.addSubview(frameUI)
                        
                        // ---------------- Date: 4/4 test ------------------------
                        // var prevZoomFactor: CGFloat!
                        if(frameRectHeight < viewHeight)
                        {
                            prevZoomFactor += 0.2
                            do
                            {
                                try self.defaultVideoDevice.lockForConfiguration()
                            }
                            catch {
                            }
                            self.defaultVideoDevice.ramp(toVideoZoomFactor: prevZoomFactor, withRate: 0.2)

                            
                            
                            self.defaultVideoDevice.unlockForConfiguration()
                        }
                        
                        // ---------------- 4/4 test ------------------------
                        
                    }
                }
                
                DispatchQueue.main.async {
                    frameUI.removeFromSuperview()
                }
            }
            
        }
        
        /*
        var gotInitialFrame = false
        
        
        guard let convertedImageBuffer = CMSampleBufferGetImageBuffer(rectVideoReader.currFrame) else { return }
        let currFrameHandler = VNImageRequestHandler(cvPixelBuffer: convertedImageBuffer , options: [:])
        let currRectRequest = VNDetectRectanglesRequest()

        do
        {
            try currFrameHandler.perform([currRectRequest])
            // if perform doesnt find a rect, doesnt add anything to results, and its empty
            // perform only adds rect to results if finds rect
        }
        catch
        {
            
        }
        
        let rectObservation = currRectRequest.results![0] as! VNRectangleObservation
        
        let viewWidth = self.PreviewView.frame.size.width               // self.view.frame.size.width
        let viewHeight =  self.PreviewView.frame.size.height          // self.view.frame.size.height
        print("\(viewWidth), \(viewHeight)")
        
        let frameRect = rectObservation.boundingBox
        let frameRectOriginWidth = frameRect.origin.x
        let frameRectOriginHeight = frameRect.origin.y
        let frameRectWidth = frameRect.width
        let frameRectHeight = frameRect.height
        print("\(frameRectOriginWidth), \(frameRectOriginHeight), \(frameRectWidth), \(frameRectHeight)")
        let updatedFrameRect = CGRect(x: viewWidth*frameRectOriginWidth, y: viewHeight*frameRectOriginHeight, width: viewHeight*frameRectWidth, height: viewHeight*frameRectHeight)
        
        var frameUI = UIView.init(frame: updatedFrameRect)
        
        
        frameUI.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        frameUI.alpha = 0.5
        
        
        self.view.addSubview(frameUI)
        frameUI.removeFromSuperview()
        */
        
        
        
        
        /*
        rectVideoReader.ReaderQueue.async {
            
            while(self.rectCalibrationPressed != true)
            {
                /* --------------------------- psuedocode ---------------------------------------
                 Objective: in here we want to chooses the block/Rect to focus on
                 -> 1. get an initial frame or set of about 10 frames
                 ---> create local still image request handler using a frame about every other tenth frame, and run
                 ---> pass in a vn detect rectangle request
                 ---> if return observation is not nill, use in [vn track object request for a sequence of about ten frames]
                 ---> else repeat
                 -> 2. create track rectangle request looking for rect in 10 frames/sequence
                 -> pass request w/ frames into request handler
                 -> get updated rectangle data
                 -> restart, step 2 until user is satisfied with chosen rect,
                 ->
                 ->
                 -> seperately, another while loop, zoom into and focus on frame, use probabilty theory until focused
                 -> can apply probability theory and store multiple frames, -> this can give alot of data to train an ML MODEL if saved frames have (+)uti
                 -> once focused get currect frame/ set of frames for processing
                */
                
                //let readerImage = self.rectVideoReader.uniqueUIImage
                /*
                DispatchQueue.main.async {
                    let rectFrame = CGRect(x: 50, y: 50, width: 50, height: 50)
                    var testImageView = UIImageView()
                    //testImageView.image = readerImage
                    testImageView.frame = rectFrame
                    testImageView.backgroundColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
                    
                    self.view.addSubview(testImageView)
                }
                */
                
                
                
                
                self.rectCalibrationPressed = true           // for testing
            }
        }
        
        // camerasesion.sessionPreset = .photo //   set after done getting rect, actually should  change just before taking a picture, video is continuos
    
    */
    }
    
    func displayRectangleInUI(_ rect: CGRect)
    {
        
    }
    
    
    // ------------------------------- Display Captured Photo (in Phone) -----------------------------
    // convert stored photo data to UIImage
    func convertProcessorPhotoToTypeUIimage()
    {
        print("---------- in convertProcessorPhotoToTypeUIimage")
        imageCaptured = UIImage(data: captureProcessor1.photoData , scale: 1.0)
    }
    
    func displayCapturedPhoto()
    {
        print("in display caputred photo")
        // set camera feed PreviewView to transparant
        //PreviewView.backgroundColor=#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        // doesnt help, the feed still comes through on top of the backgroud/ doesnt affect camera feed
        //capturedPhotoDisplay.backgroundColor=#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        if let imagetaken = imageCaptured
        {
            capturedPhotoDisplay.image = imagetaken
            //capturedPhotoDisplay.sizeToFit()
        }

        
        //capturedPhotoDisplay.setNeedsDisplay()

        // image display is on top of the other views and blocks them, so just set image for now
        
        
        
    }
    
    
    // ---------------------------------  Display RGB value (in Phone) --------------------------------------------
    
}

extension ViewController {
    struct MLConstants{
        //let patternMachineLearningModel = "Insert Model Here"
        let model = try? VNCoreMLModel(for: ImageClassifier().model)
        
    }
}

extension UIImage {
    func getCenterPixelColor() -> UIColor {
        // ------------------- get center pixel color and return --------------------
        let pixelData = self.cgImage!.dataProvider!.data
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData!)
        
        let pixelInfo: Int = ((Int(self.size.width) * (Int(self.size.width)/2)) + (Int(self.size.height)/2) * 4)
        let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
        print("\(Int(self.size.width)/2), \(Int(self.size.height)/2)")
        return UIColor(red: r, green: g, blue: b, alpha: a)
        
        /*
         let pixelData = CGDataProviderCopyData(CGImageGetDataProvider(self.CGImage))
         let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
         
         let pixelInfo: Int = ((Int(self.size.width) * Int(pos.y)) + Int(pos.x)) * 4
         
         let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
         let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
         let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
         let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
         
         return UIColor(red: r, green: g, blue: b, alpha: a)
         */
    }
}



/*
 // create AVCatureDevice
 /*
 if let captureDevice = AVCaptureDevice.default(deviceType: .builtInDualCamera, for: .video, position: .back)
 {
 return captureDevice
 }
 else if let captureDevice = AVCaptureDevice.default(deviceTyoe: .builtInWideAngleCamera, for: .video, position: .back)
 {
 return AVCaptureDevice
 }
 else
 {
 return
 }
 */
 let personalCaptureDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back)
 
 // camera and microphone authorization
 //  -> does device need to be intialized to check for authorization?
 
 // make_ a switch case structure instead of if statements
 if (AVCaptureDevice.authorizationStatus(for: .video) != .authorized)
 {
 AvcrequestAccess()
 }
 var session = AVCaptureSession()
 
*/


/* method #3
 func setUpObjectRect()
 {
 // basically TakePhoto(); should have new TakePhoto() func with parameters of desired photoCaptureProcesser
 print("---------- in setUpObjectRect")
 
 self.objectPhotoSetting = AVCapturePhotoSettings()
 self.objectCaptureProcessor = PhotoCaptureProcessor()
 var rectRequestHandler: VNImageRequestHandler!
 
 sessionQueue.async {
 print("----------start taking photo")
 self.photoOutput.capturePhoto(with: self.objectPhotoSetting , delegate: self.objectCaptureProcessor)
 print("\(String(describing: self.objectCaptureProcessor.photoData))")
 print("---------finish taking photo")
 }
 if let objImageData = objectCaptureProcessor.photoData
 {
 rectRequestHandler = VNImageRequestHandler(data: objImageData , options: [:])
 }
 else
 {
 if let defaultObjImage = UIImage(named: "DefaultRect")!.cgImage
 {
 rectRequestHandler = VNImageRequestHandler(cgImage: defaultObjImage, options: [:])
 }
 }
 
 while(rectCalibrationPressed != true)
 {
 
 // now we have the request handler setup with a image; now we analyze it to find the rect an outline it in the UI
 
 let rectRequest: VNRequest = VNDetectRectanglesRequest()    //     rect request
 
 do { try rectRequestHandler.perform([rectRequest]) }                   // submitting request, getting result
 catch {
 }
 
 let rectObservation = rectRequest.results?[0] as! VNDetectedObjectObservation        //
 var rectFrame = rectObservation.boundingBox
 rectFrame.size = CGSize(width: 100, height: 100)
 print("size: \(rectFrame.size), coord: \(rectFrame.origin)")
 //let rectFrame = CGRect(x: 50, y: 50, width: 50, height: 50)   // sample rect to test
 
 let boxOutline: UIView = UIView(frame: rectFrame)
 boxOutline.backgroundColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
 boxOutline.alpha = 0.5
 self.view.addSubview(boxOutline)
 
 rectCalibrationPressed = true
 }
 
 print("---------- finished setup object Rect")
 print("\(String(describing: self.objectCaptureProcessor.photoData))")
 }
 
 
*/
