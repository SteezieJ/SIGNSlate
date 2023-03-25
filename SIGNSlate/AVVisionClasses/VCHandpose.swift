//
//  VCVision.swift
//  SIGNSlate
//
//  Created by Stefanie Joubert on 2022/9/23.
//

import UIKit
import AVFoundation
import Vision


extension LatingViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
       
        let handPoseRequest1 = VNDetectHumanHandPoseRequest()
        handPoseRequest1.maximumHandCount = 2
        handPoseRequest1.revision = VNDetectHumanHandPoseRequestRevision1
        //let model = try! VNCoreMLModel(for: handaction__1(configuration: MLModelConfiguration()).model)
        //let request = VNCoreMLRequest(model: model)
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up)
        
        //let pixelBuff = CMSampleBufferGetImageBuffer(sampleBuffer)!
        //let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuff, orientation: .up)
        //let image = UIImage(pixelBuffer: pixelBuff)!
        
        do {
            try handler.perform([handPoseRequest1])
        } catch let error {
            print(error.localizedDescription)
        }
        
        if handPoseRequest1.results != nil {
            for resultIn in  handPoseRequest1.results! {
                arrOfMulties.append(try! resultIn.keypointsMultiArray())
                if arrOfMulties.count == 60 {
                    let newMulti = MLMultiArray(concatenating: arrOfMulties, axis: 0, dataType: .float32)
                    processModelData(keypointsMultiArray: newMulti)
                    arrOfMulties.removeFirst()
                }
            }
        }
        frameCounter += 1
        if frameCounter % handPosePredictionInterwal2 != 0 {
            return
        }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
        let exifOrientation = CGImagePropertyOrientation(rawValue: exifOrientationFromDeviceOrientation()) else { return }
        var requestOptions: [VNImageOption : Any] = [:]
        buffer = pixelBuffer
        
        if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
            requestOptions = [.cameraIntrinsics : cameraIntrinsicData]
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: requestOptions)
        
        do {
            try imageRequestHandler.perform([faceDetectionRequest])
        }
            
        catch {
            print(error)
        }
 
    }
    func exifOrientationFromDeviceOrientation() -> UInt32 {
        enum DeviceOrientation: UInt32 {
            case top0ColLeft = 1
            case top0ColRight = 2
            case bottom0ColRight = 3
            case bottom0ColLeft = 4
            case left0ColTop = 5
            case right0ColTop = 6
            case right0ColBottom = 7
            case left0ColBottom = 8
        }
        var exifOrientation: DeviceOrientation
        
        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            exifOrientation = .left0ColBottom
        case .landscapeLeft:
            exifOrientation = devicePosition == .front ? .bottom0ColRight : .top0ColLeft
        case .landscapeRight:
            exifOrientation = devicePosition == .front ? .top0ColLeft : .bottom0ColRight
        default:
            exifOrientation = .right0ColTop
        }
        return exifOrientation.rawValue
    }
    func processModelData(keypointsMultiArray:MLMultiArray) {
               
        //MARK: -  Hand Model
        var model: babymsasl
         do {
             model = try babymsasl(configuration: MLModelConfiguration())
         } catch let error {
             fatalError(error.localizedDescription)
         }
   
        do {
            let handPosePrediction = try model.prediction(poses: keypointsMultiArray)
            let confidence = handPosePrediction.labelProbabilities[handPosePrediction.label]!
            let sorted = handPosePrediction.labelProbabilities.keys.sorted { key1, key2 in
                return Double(handPosePrediction.labelProbabilities[key1]!) > Double(handPosePrediction.labelProbabilities[key2]!)
            }
            sorted.forEach{ print("\($0) confidence \(handPosePrediction.labelProbabilities[$0]!)") }
            
            print("Latest Prediction " + handPosePrediction.label)
            if (handPosePrediction.label == "other") {
                if Double(handPosePrediction.labelProbabilities[sorted[1]]!) == 0 {
                    print("it's other \(Double(handPosePrediction.labelProbabilities[sorted[1]]!))")
                } else {
                    DispatchQueue.main.async {
                        self.didReturnedResponse(with: confidence, word: sorted.count > 1 ? sorted[1] : sorted[0])
                    }
                }
            } else if (confidence == 0) {
                print("ignoring with other...\( handPosePrediction.labelProbabilities[sorted[1]]!)")
                return
            } else if (confidence > 0.7){
                DispatchQueue.main.async {
                self.didReturnedResponse(with: confidence, word: handPosePrediction.label)
                }
            }
           
            print(confidence)
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    
    func handleFaces(request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            
            //perform all the UI updates on the main queue
            guard let results1 = request.results as? [VNFaceObservation] else { return }
           // self.previewView.removeMask()
            
            for face in results1 {
                //self.previewView.drawFaceboundingBox(face: face)
                
                let a = CIImage.init(cvImageBuffer: self.buffer).rotate
                let b = a.cropImage(toFace: face)
                let c = UIImage(ciImage: b)
//                let haha = c.pixelBuffer(width: 224, height: 224)
                let haha = c.pixelBuffer(width: 299, height: 299)//pixelBuffer(width: 299, height: 299)

                
                //MARK: -  Face Model

                var model: EmotionClassificator

                 do {
                     model = try EmotionClassificator(configuration: MLModelConfiguration())

                 } catch let error {
                     fatalError(error.localizedDescription)
                 }
                let input = EmotionClassificatorInput(image: haha!)
                guard let emotionresult = try? model.prediction(input: input) else{
                    fatalError()
                }
              
                let confidence = emotionresult.classLabelProbs[emotionresult.classLabel]!
                let sorted = emotionresult.classLabelProbs.keys.sorted { key1, key2 in
                    return Double(emotionresult.classLabelProbs[key1]!) > Double(emotionresult.classLabelProbs[key2]!)
                }
               // sorted.forEach{ print("Emo : \($0) confidence \(emotionresult.classLabelProbs[$0]!)") }
                if confidence > 0.75 {
                    self.didReturnedEmoResponse(with: confidence, word: emotionresult.classLabel)
                } else {
                    self.didReturnedEmoResponse(with: confidence, word: " ")
                }
                print("Latest Face Prediction " + emotionresult.classLabel)
            }
        }
    }
    
    func storeObservation(_ observation: VNHumanHandPoseObservation){
        //3.4 add into posesWindow (always use 30 frames)
        if posesWindow.count >= handPosePredictionInterwal {
            posesWindow.removeFirst()
        }
        posesWindow.append(observation)
    }
   
    func prepareInputWithObservations(_ observations: [VNHumanHandPoseObservation]) -> MLMultiArray? {
        let numAvailableFrames = observations.count
        let observationsNeeded = handPosePredictionInterwal
        var multiArrayBuffer = [MLMultiArray]()
        
        for frameIndex in 0 ..< min(numAvailableFrames, observationsNeeded){
            let pose = observations[frameIndex]
            do {
                let oneFrameMultiArray = try pose.keypointsMultiArray()
                multiArrayBuffer.append(oneFrameMultiArray)
            } catch {
                continue
            }
        }
        
        if numAvailableFrames < observationsNeeded {
            for _ in 0 ..< (observationsNeeded-numAvailableFrames){
                do {
                    let oneFrameMultiArray = try MLMultiArray(shape: [1, 3, 21], dataType: .double)
                    try resetMultiArray(oneFrameMultiArray)
                    multiArrayBuffer.append(oneFrameMultiArray)
                } catch {
                    continue
                }
            }
        }
        
        return MLMultiArray(concatenating: [MLMultiArray](multiArrayBuffer), axis: 0, dataType: .float32)
    }
    func resetMultiArray(_ predictionWindow: MLMultiArray, with value: Double = 0.0) throws {
        let pointer = try UnsafeMutableBufferPointer<Double>(predictionWindow)
        pointer.initialize(repeating: value)
    }
    
    /*func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        /*frameCounter += 1
        if frameCounter % handPosePredictionInterwal != 0 {
            return
        }*/
        let handPoseRequest1 = VNDetectHumanHandPoseRequest()
        handPoseRequest1.maximumHandCount = 2
        handPoseRequest1.revision = VNDetectHumanHandPoseRequestRevision1
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .right, options: [:])
        
        
        do {
            try handler.perform([handPoseRequest1])
        } catch let error {
            print(error.localizedDescription)
        }
        
        guard let handPose = handPoseRequest1.results?.first else {
            return
        }
        
        
        guard let keypointsMultiArray = try? MLMultiArray(shape:[60,3,21], dataType:MLMultiArrayDataType.float32) else {
            fatalError("Unexpected runtime error. MLMultiArray")
        }
            // Previous Model
           /* var model: newhandaction_1
            do {
                model = try newhandaction_1(configuration: MLModelConfiguration())
            } catch let error {
                fatalError(error.localizedDescription)
            }*/
            // New Model
            var model: handsonly1
             do {
                 model = try handsonly1(configuration: MLModelConfiguration())
             } catch let error {
                 fatalError(error.localizedDescription)
             }
       
            do {
                let handPosePrediction = try model.prediction(poses: keypointsMultiArray)
                let confidence = handPosePrediction.labelProbabilities[handPosePrediction.label]!
                let sorted = handPosePrediction.labelProbabilities.keys.sorted { key1, key2 in
                    return Double(handPosePrediction.labelProbabilities[key1]!) > Double(handPosePrediction.labelProbabilities[key2]!)
                }
                sorted.forEach{ print("\($0) confidence \(handPosePrediction.labelProbabilities[$0]!)") }
                
                print("Latest Prediction " + handPosePrediction.label)
                if (handPosePrediction.label == "other") {
                    if Double(handPosePrediction.labelProbabilities[sorted[1]]!) == 0 {
                        print("it's other \(Double(handPosePrediction.labelProbabilities[sorted[1]]!))")
                    } else {
                        DispatchQueue.main.async {
                            self.didReturnedResponse(with: confidence, word: sorted.count > 1 ? sorted[1] : sorted[0])
                        }
                    }
                } else if (confidence == 0) {
                    print("ignoring with other...\( handPosePrediction.labelProbabilities[sorted[1]]!)")
                    return
                } else {
                    DispatchQueue.main.async {
                    self.didReturnedResponse(with: confidence, word: handPosePrediction.label)
                    }
                }
               
                print(confidence)
            } catch let error {
                print(error.localizedDescription)
            }
    }*/
    
    /*func processPoints(_ fingerTips: [CGPoint]) -> [CGPoint]{
        let convertedPoints = fingerTips.map {
            cameraView.previewLayer.layerPointConverted(fromCaptureDevicePoint: $0)
        }
        return convertedPoints
    }*/
    
}

