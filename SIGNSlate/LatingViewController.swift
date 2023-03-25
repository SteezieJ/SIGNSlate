//
//  LatingViewController.swift
//  SIGNSlate
//
//  Created by Stefanie Joubert on 21/08/2022.
//

import UIKit
import AVKit
import Vision
import ARKit
import RealityKit
struct CombineModel {
    var handPose:String?
    var facePose:String?
}
class LatingViewController: UIViewController {
    
    
    
    
   // @IBOutlet weak var UICameraView: UIImageView!
    @IBOutlet var emoText: UILabel!
    @IBOutlet weak var displayText: UILabel!
    @IBOutlet var cameraView: CameraPreview!
    
    var handPosePredictionInterwal = 60
    var combineWords = [CombineModel]()
    var currentUniqID:String?
    var frameCounter: Int = 1 {
           didSet {
               // Framecounter has to be updated on the basis of interval.
               if frameCounter == 6 {
                   frameCounter = 1
               }
           }
       }
    var handPosePredictionInterwal2 = 5
    var posesWindow: [VNHumanHandPoseObservation] = []
    @IBOutlet var sceneView: MyCustomARView!
    {
        didSet{
            sceneView.delegate = self
        }
    }
    var currentDate:Date?
    var arrOfWords = [String]()
    var arrOfAllHandPoses = [String]()
    var arrOfAllFacePoses = [String]()
    var lastPredicted:String?
    @IBOutlet var currentWordText: UILabel!
    var arrOfMulties:[MLMultiArray] = []
    //    override func viewDidLoad() {
    //        super.viewDidLoad()
    //        title = "Now interpreting"
    
    
    
    //after classifying above 80%accuracy send text to array then display array in string here
    //        displayText.text = "output array text"
    
    /****************************************************************/
    
    
    
    
    
    // AVCapture variables to hold sequence data
    var session: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    //var videoDataOutput: AVCaptureVideoDataOutput?
    //var videoDataOutputQueue: DispatchQueue?
    
    var captureDevice: AVCaptureDevice?
    var captureDeviceResolution: CGSize = CGSize()
    
    // Layer UI for drawing Vision results
    var rootLayer: CALayer?
    var detectionOverlayLayer: CALayer?
    var detectedFaceRectangleShapeLayer: CAShapeLayer?
    var detectedFaceLandmarksShapeLayer: CAShapeLayer?
    
    var detectedHandLandmarkShapeLayer: CAShapeLayer?

    
    
    // Vision requests
    private var detectionRequests: [VNDetectFaceRectanglesRequest]?
    private var trackingRequests: [VNTrackObjectRequest]?
    private var detectionHandsRequests: [VNHumanHandPoseObservation]?
    
    lazy var sequenceRequestHandler = VNSequenceRequestHandler()
    
    
    //MARK: AVProperties
    var captureSession: AVCaptureSession?
    let videoDataOutputQueue = DispatchQueue(
      label: "CameraFeedOutput",
      qos: .userInteractive
    )
    
    let handPoseRequest: VNDetectHumanHandPoseRequest = {
      let request = VNDetectHumanHandPoseRequest()
      request.maximumHandCount = 2
      return request
    }()
    
    var faceDetectionRequest : VNDetectFaceRectanglesRequest!
    var buffer: CVPixelBuffer!
    var devicePosition: AVCaptureDevice.Position = .front
    // MARK: UIViewController overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: handleFaces)
        //self.session = self.setupAVCaptureSession()
        
        //self.prepareVisionRequest()
        
       // self.session?.startRunning()
        
        displayText.text = "output array text"
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        do {
            if captureSession == nil {
                try setupAVSession()
                cameraView.previewLayer.session = captureSession
                cameraView.previewLayer.videoGravity = .resizeAspectFill
            }
            captureSession?.startRunning()
        } catch {
            print(error.localizedDescription)
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // Ensure that the interface stays locked in Portrait.
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    // Ensure that the interface stays locked in Portrait.
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    //MARK: -  Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "resultsView"
        {
            let controller = segue.destination as! ResultsViewController
            controller.passedArrOfFacesigns = arrOfAllFacePoses
            controller.passedArrOfHandsigns = arrOfAllHandPoses
            controller.passedArrOfCombinedSigns = combineWords
        }
    }

    // MARK: AVCapture Setup
    
    /// - Tag: CreateCaptureSession
    fileprivate func setupAVCaptureSession() -> AVCaptureSession? {
        let captureSession = AVCaptureSession()
        do {
            let inputDevice = try self.configureFrontCamera(for: captureSession)
            self.configureVideoDataOutput(for: inputDevice.device, resolution: inputDevice.resolution, captureSession: captureSession)
            self.designatePreviewLayer(for: captureSession)
            return captureSession
        } catch let executionError as NSError {
            self.presentError(executionError)
        } catch {
            self.presentErrorAlert(message: "An unexpected failure has occured")
        }
        
        self.teardownAVCapture()
        
        return nil
    }
    
    /// - Tag: ConfigureDeviceResolution
    fileprivate func highestResolution420Format(for device: AVCaptureDevice) -> (format: AVCaptureDevice.Format, resolution: CGSize)? {
        var highestResolutionFormat: AVCaptureDevice.Format? = nil
        var highestResolutionDimensions = CMVideoDimensions(width: 0, height: 0)
        
        for format in device.formats {
            let deviceFormat = format as AVCaptureDevice.Format
            
            let deviceFormatDescription = deviceFormat.formatDescription
            if CMFormatDescriptionGetMediaSubType(deviceFormatDescription) == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange {
                let candidateDimensions = CMVideoFormatDescriptionGetDimensions(deviceFormatDescription)
                if (highestResolutionFormat == nil) || (candidateDimensions.width > highestResolutionDimensions.width) {
                    highestResolutionFormat = deviceFormat
                    highestResolutionDimensions = candidateDimensions
                }
            }
        }
        
        if highestResolutionFormat != nil {
            let resolution = CGSize(width: CGFloat(highestResolutionDimensions.width), height: CGFloat(highestResolutionDimensions.height))
            return (highestResolutionFormat!, resolution)
        }
        
        return nil
    }
    
    fileprivate func configureFrontCamera(for captureSession: AVCaptureSession) throws -> (device: AVCaptureDevice, resolution: CGSize) {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)
        
        if let device = deviceDiscoverySession.devices.first {
            if let deviceInput = try? AVCaptureDeviceInput(device: device) {
                if captureSession.canAddInput(deviceInput) {
                    captureSession.addInput(deviceInput)
                }
                
                if let highestResolution = self.highestResolution420Format(for: device) {
                    try device.lockForConfiguration()
                    device.activeFormat = highestResolution.format
                    device.unlockForConfiguration()
                    
                    return (device, highestResolution.resolution)
                }
            }
        }
        
        throw NSError(domain: "ViewController", code: 1, userInfo: nil)
    }
    
    /// - Tag: CreateSerialDispatchQueue
    fileprivate func configureVideoDataOutput(for inputDevice: AVCaptureDevice, resolution: CGSize, captureSession: AVCaptureSession) {
        
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        
        // Create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured.
        // A serial dispatch queue must be used to guarantee that video frames will be delivered in order.
        let videoDataOutputQueue = DispatchQueue(label: "com.example.apple-samplecode.VisionFaceTrack")
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }
        
        videoDataOutput.connection(with: .video)?.isEnabled = true
        
        if let captureConnection = videoDataOutput.connection(with: AVMediaType.video) {
            if captureConnection.isCameraIntrinsicMatrixDeliverySupported {
                captureConnection.isCameraIntrinsicMatrixDeliveryEnabled = true
            }
        }
        
        //self.videoDataOutput = videoDataOutput
        //self.videoDataOutputQueue = videoDataOutputQueue
        
        self.captureDevice = inputDevice
        self.captureDeviceResolution = resolution
    }
    
    /// - Tag: DesignatePreviewLayer
    fileprivate func designatePreviewLayer(for captureSession: AVCaptureSession) {
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer = videoPreviewLayer
        
        videoPreviewLayer.name = "CameraPreview"
        videoPreviewLayer.backgroundColor = UIColor.black.cgColor
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        /*if let previewRootLayer = self.UICameraView?.layer {
            self.rootLayer = previewRootLayer
            
            previewRootLayer.masksToBounds = true
            videoPreviewLayer.frame = previewRootLayer.bounds
            previewRootLayer.addSublayer(videoPreviewLayer)
        }*/
    }
    
    // Removes infrastructure for AVCapture as part of cleanup.
    fileprivate func teardownAVCapture() {
       // self.videoDataOutput = nil
      //  self.videoDataOutputQueue = nil
        
        if let previewLayer = self.previewLayer {
            previewLayer.removeFromSuperlayer()
            self.previewLayer = nil
        }
    }
    
    // MARK: Helper Methods for Error Presentation
    
    fileprivate func presentErrorAlert(withTitle title: String = "Unexpected Failure", message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        self.present(alertController, animated: true)
    }
    
    fileprivate func presentError(_ error: NSError) {
        self.presentErrorAlert(withTitle: "Failed with error \(error.code)", message: error.localizedDescription)
    }
    
    // MARK: Helper Methods for Handling Device Orientation & EXIF
    
    fileprivate func radiansForDegrees(_ degrees: CGFloat) -> CGFloat {
        return CGFloat(Double(degrees) * Double.pi / 180.0)
    }
    
    func exifOrientationForDeviceOrientation(_ deviceOrientation: UIDeviceOrientation) -> CGImagePropertyOrientation {
        
        switch deviceOrientation {
        case .portraitUpsideDown:
            return .rightMirrored
            
        case .landscapeLeft:
            return .downMirrored
            
        case .landscapeRight:
            return .upMirrored
            
        default:
            return .leftMirrored
        }
    }
    
    func exifOrientationForCurrentDeviceOrientation() -> CGImagePropertyOrientation {
        return exifOrientationForDeviceOrientation(UIDevice.current.orientation)
    }
    
    
    
    
    
    
    // MARK: Performing Vision Requests
    
    /// - Tag: WriteCompletionHandler
    fileprivate func prepareVisionRequest() {
        
        //self.trackingRequests = []
        var requests = [VNTrackObjectRequest]()
//        var requests2 = [VNImageRequestHandler]()
        
        let faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: { (request, error) in
            
            if error != nil {
                print("FaceDetection error: \(String(describing: error)).")
            }
            
            guard let faceDetectionRequest = request as? VNDetectFaceRectanglesRequest,
                  let results = faceDetectionRequest.results as? [VNFaceObservation] else {
                return
            }
            DispatchQueue.main.async {
                // Add the observations to the tracking list
                for observation in results {
                    let faceTrackingRequest = VNTrackObjectRequest(detectedObjectObservation: observation)
                    requests.append(faceTrackingRequest)
                }
                self.trackingRequests = requests
            }
        })
        
//        VNHumanHandPoseObservation
//        VNSequenceRequestHandler
//        VNDetectHumanHandPoseRequest
        
        //added for hands
  
//        let handPoseRequest: VNDetectHumanHandPoseRequest = {
//          // 1
//            let request = VNDetectHumanHandPoseRequest)
//          
//          // 2
//          request.maximumHandCount = 2
//          return request
//        }()
//        
//        func processPoints(_ fingerTips: [CGPoint]) {
//          // Convert points from AVFoundation coordinates to UIKit coordinates.
//          let convertedPoints = fingerTips.map {
//            cameraView.previewLayer.layerPointConverted(fromCaptureDevicePoint: $0)
//          }
//          pointsProcessorHandler?(convertedPoints)
//        }
        
        
        
        
        
        
        // Start with detection.  Find face, then track it.
        //self.detectionRequests = [faceDetectionRequest]
        
        self.sequenceRequestHandler = VNSequenceRequestHandler()
        
        //self.setupVisionDrawingLayers()
    }

    
    fileprivate func updateLayerGeometry() {
        guard let overlayLayer = self.detectionOverlayLayer,
              let rootLayer = self.rootLayer,
              let previewLayer = self.previewLayer
        else {
            return
        }
        
        CATransaction.setValue(NSNumber(value: true), forKey: kCATransactionDisableActions)
        
        let videoPreviewRect = previewLayer.layerRectConverted(fromMetadataOutputRect: CGRect(x: 0, y: 0, width: 1, height: 1))
        
        var rotation: CGFloat
        var scaleX: CGFloat
        var scaleY: CGFloat
        
        // Rotate the layer into screen orientation.
        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            rotation = 180
            scaleX = videoPreviewRect.width / captureDeviceResolution.width
            scaleY = videoPreviewRect.height / captureDeviceResolution.height
            
        case .landscapeLeft:
            rotation = 90
            scaleX = videoPreviewRect.height / captureDeviceResolution.width
            scaleY = scaleX
            
        case .landscapeRight:
            rotation = -90
            scaleX = videoPreviewRect.height / captureDeviceResolution.width
            scaleY = scaleX
            
        default:
            rotation = 0
            scaleX = videoPreviewRect.width / captureDeviceResolution.width
            scaleY = videoPreviewRect.height / captureDeviceResolution.height
        }
        
        // Scale and mirror the image to ensure upright presentation.
        let affineTransform = CGAffineTransform(rotationAngle: radiansForDegrees(rotation))
            .scaledBy(x: scaleX, y: -scaleY)
        overlayLayer.setAffineTransform(affineTransform)
        
        // Cover entire screen UI.
        let rootLayerBounds = rootLayer.bounds
        overlayLayer.position = CGPoint(x: rootLayerBounds.midX, y: rootLayerBounds.midY)
    }
    
    fileprivate func addPoints(in landmarkRegion: VNFaceLandmarkRegion2D, to path: CGMutablePath, applying affineTransform: CGAffineTransform, closingWhenComplete closePath: Bool) {
        let pointCount = landmarkRegion.pointCount
        if pointCount > 1 {
            let points: [CGPoint] = landmarkRegion.normalizedPoints
            path.move(to: points[0], transform: affineTransform)
            path.addLines(between: points, transform: affineTransform)
            if closePath {
                path.addLine(to: points[0], transform: affineTransform)
                path.closeSubpath()
            }
        }
    }
    
    fileprivate func addIndicators(to faceRectanglePath: CGMutablePath, faceLandmarksPath: CGMutablePath, for faceObservation: VNFaceObservation) {
        let displaySize = self.captureDeviceResolution
        
        let faceBounds = VNImageRectForNormalizedRect(faceObservation.boundingBox, Int(displaySize.width), Int(displaySize.height))
        faceRectanglePath.addRect(faceBounds)
        
        if let landmarks = faceObservation.landmarks {
            // Landmarks are relative to -- and normalized within --- face bounds
            let affineTransform = CGAffineTransform(translationX: faceBounds.origin.x, y: faceBounds.origin.y)
                .scaledBy(x: faceBounds.size.width, y: faceBounds.size.height)
            
            // Treat eyebrows and lines as open-ended regions when drawing paths.
            let openLandmarkRegions: [VNFaceLandmarkRegion2D?] = [
                landmarks.leftEyebrow,
                landmarks.rightEyebrow,
                landmarks.faceContour,
                landmarks.noseCrest,
                landmarks.medianLine
            ]
            for openLandmarkRegion in openLandmarkRegions where openLandmarkRegion != nil {
                self.addPoints(in: openLandmarkRegion!, to: faceLandmarksPath, applying: affineTransform, closingWhenComplete: false)
            }
            
            // Draw eyes, lips, and nose as closed regions.
            let closedLandmarkRegions: [VNFaceLandmarkRegion2D?] = [
                landmarks.leftEye,
                landmarks.rightEye,
                landmarks.outerLips,
                landmarks.innerLips,
                landmarks.nose
            ]
            for closedLandmarkRegion in closedLandmarkRegions where closedLandmarkRegion != nil {
                self.addPoints(in: closedLandmarkRegion!, to: faceLandmarksPath, applying: affineTransform, closingWhenComplete: true)
            }
        }
    }
    
    /// - Tag: DrawPaths
    fileprivate func drawFaceObservations(_ faceObservations: [VNFaceObservation]) {
        guard let faceRectangleShapeLayer = self.detectedFaceRectangleShapeLayer,
              let faceLandmarksShapeLayer = self.detectedFaceLandmarksShapeLayer
        else {
            return
        }
        
        CATransaction.begin()
        
        CATransaction.setValue(NSNumber(value: true), forKey: kCATransactionDisableActions)
        
        let faceRectanglePath = CGMutablePath()
        let faceLandmarksPath = CGMutablePath()
        
        for faceObservation in faceObservations {
            self.addIndicators(to: faceRectanglePath,
                               faceLandmarksPath: faceLandmarksPath,
                               for: faceObservation)
        }
        
        faceRectangleShapeLayer.path = faceRectanglePath
        faceLandmarksShapeLayer.path = faceLandmarksPath
        
        self.updateLayerGeometry()
        
        CATransaction.commit()
    }
    
    
    

    
    var delegate: SendResultsDelegate?
    
    @IBAction func cameraRotate(_ sender: Any) {
        updateCamera()
    }
    
    @IBAction func stopPressed(_ sender: Any) {
        
        self.performSegue(withIdentifier: "resultsView", sender: nil)
        /*let resstring: String = arrOfWords.joined(separator: " ")
        print("Stop interpreting...")
        print("del", resstring)
        delegate?.SendHandResults(text: "pizza")//WordsArray: self.arrOfWords*/
       
//        guard let vc = storyboard?.instantiateViewController(withIdentifier: "Resultsboard") as? ResultsViewController else {
//            print("unable to get storyboard")
//            return
//        }
//        vc.textstring = resstring
//        present(vc, animated: true)
//    }
  
    
    
//     func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//       if segue.identifier == "ResultsBoard" {
//           let vc = segue.destination as! ResultsViewController
//           vc.textstring = "pizza"
//       }
    }

      
    
}

protocol SendResultsDelegate : AnyObject { //Anyobject
    func SendHandResults(text: String?)
}

//extension LatingViewController: StopDelegate {
//
//}




extension LatingViewController: MyCustomARViewDelegate {
    func didReturnedResponse(with confidence: Double, word: String) {
        DispatchQueue.main.async {
            //if (self.lastPredicted ?? "") != word {
            self.currentDate = Date()
            self.lastPredicted = word
            if self.arrOfWords.count == 10 {
                self.arrOfWords.removeFirst()
            }
            self.arrOfWords.append(word)
            self.displayText.text = self.arrOfWords.joined(separator: " ")
            self.currentWordText.text = word//String.init(format: "%0.1f", confidence)
            
            self.arrOfAllHandPoses.append(word)
            self.delegate?.SendHandResults(text: self.arrOfWords.joined(separator: " "))
            /*} else {
             print("Repeated Prediction Skipping --" + word)
             self.currentWordText.text = word
             }*/
        }
    }
    func didReturnedEmoResponse(with confidence: Double, word: String) {
        DispatchQueue.main.async {
            
            if word != "" {
                if let date = self.currentDate, (Date().timeIntervalSince(date) * 1000) < 250 {
                    let model = CombineModel(handPose: self.lastPredicted, facePose: word)
                    self.combineWords.append(model)
                }
                
                self.arrOfAllFacePoses.append(word)
                self.emoText.text = word
            }
        }
    }
}
