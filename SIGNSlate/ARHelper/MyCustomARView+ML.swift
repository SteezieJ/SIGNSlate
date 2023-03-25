//
//  MyCustomARView+ML.swift
//  SIGNSlate
//
//  Created by Stefanie Joubert on 09/09/2022.
//


import Vision
import ARKit

extension MyCustomARView: ARSessionDelegate {
    var handPoseRequestComputed: VNDetectHumanHandPoseRequest {
        
        let request = VNDetectHumanHandPoseRequest { request, error in
            if let error = error {
                fatalError(error.localizedDescription)
            }
            
            guard let observations = request.results as? [VNHumanHandPoseObservation] else {
            return
        }
        
        
         
           // else { fatalError() }
            if let result = observations.first{
                self.storeObservation(result)
                //3.5 initialize and analyze
                self.labelActionType()
            }
            
        }
        
        request.maximumHandCount = 2
        request.revision = VNDetectHumanHandPoseRequestRevision1
        return request
    }
    var model:babymsasl {
        var model: babymsasl
        do {
            model = try babymsasl(configuration: MLModelConfiguration())
        } catch let error {
            fatalError(error.localizedDescription)
        }
        return model
    }
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {

            for anch in anchors
            {
                
                guard let imageAnchor = anch as? ARImageAnchor else { return }

                if(imageAnchor.isTracked)
                {

                    //if(myAnchor.anchorIdentifier == imageAnchor.identifier)
                   // {
                        debugPrint(imageAnchor.identifier)        // <-- THIS NEVER HAPPENS
                   // }
                    
                   // myAnchor?.isEnabled = true        // works

                }
                else
                {
                   // myAnchor?.isEnabled = false       // also works
                }
                
                
            }
        }
    
    fileprivate func getCMSampleBuffer(pixelBufferr: CVPixelBuffer) -> CMSampleBuffer {
        var pixelBuffer : CVPixelBuffer? = pixelBufferr
        CVPixelBufferCreate(kCFAllocatorDefault, 320, 400, kCVPixelFormatType_32BGRA, nil, &pixelBuffer)

        var info = CMSampleTimingInfo()
        info.presentationTimeStamp = CMTime.zero
        info.duration = CMTime.invalid
        info.decodeTimeStamp = CMTime.invalid


        var formatDesc: CMFormatDescription? = nil
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer!, formatDescriptionOut: &formatDesc)

        var sampleBuffer: CMSampleBuffer? = nil

        CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault,
                                                 imageBuffer: pixelBuffer!,
                                                 formatDescription: formatDesc!,
                                                 sampleTiming: &info,
                                                 sampleBufferOut: &sampleBuffer);

        return sampleBuffer!
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        //frameCounter += 1
        //if frameCounter % handPosePredictionInterwal == 0 {
        dispatchQueueML.async {
            guard let pixelBuffer = session.currentFrame?.capturedImage else { return }
            //let sample = self.getCMSampleBuffer(pixelBufferr: pixelBuffer)
     //  handPoseRequestComputed
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
           
        
        do {
            try handler.perform([self.handPoseRequestComputed])
        } catch let error {
            print(error.localizedDescription)
        }
        
//            guard let observations = self.handPoseRequestComputed.results else {
//            return
//        }
//
//
//
//           // else { fatalError() }
//            if let result = observations.first{
//                self.storeObservation(result)
//                //3.5 initialize and analyze
//                self.labelActionType()
//            }
            
        
            /*do {
                let handPosePrediction = try self.model.prediction(poses: keypointsMultiArray)
                let confidence = handPosePrediction.labelProbabilities[handPosePrediction.label]!
                let sorted = handPosePrediction.labelProbabilities.keys.sorted { key1, key2 in
                    return Double(handPosePrediction.labelProbabilities[key1]!) > Double(handPosePrediction.labelProbabilities[key2]!)
                }
                sorted.forEach{ print("\($0)") }
                print("Latest Prediction " + handPosePrediction.label)
                print(confidence)
                if (handPosePrediction.label == "other") {
                    if Double(handPosePrediction.labelProbabilities[sorted[1]]!) < 9 {
                        print("it's other")
                    } else {
                        self.delegate?.didReturnedResponse(with: confidence, word: sorted.count > 1 ? sorted[1] : sorted[0])
                    }
                } else if (Double(handPosePrediction.labelProbabilities[sorted[1]]!) < 9) {
                    print("ignoring with other...\( handPosePrediction.labelProbabilities[sorted[1]]!)")
                    return
                } else {
                    self.delegate?.didReturnedResponse(with: confidence, word: sorted.count > 1 ? sorted[1] : sorted[0])
                }
                
            } catch let error {
                print(error.localizedDescription)
            }*/
        }
        //}
    }
    func storeObservation(_ observation: VNHumanHandPoseObservation){
        //3.4 add into posesWindow (always use 30 frames)
        if posesWindow.count >= handPosePredictionInterwal {
            posesWindow.removeFirst()
        }
        posesWindow.append(observation)
    }
    func labelActionType(){
        //3.5 initialize 1. the ML model 2. to identify the actions 3. prediction result
        guard let actionClassifier = try? babymsasl(configuration: MLModelConfiguration()) else {
            return
        }
        guard let poseMultiArray = prepareInputWithObservations(posesWindow) else {
            return
        }
        guard let predictions = try? actionClassifier.prediction(poses: poseMultiArray) else {
            return
        }
        /*let label = predictions.label
        let confidence = predictions.labelProbabilities[label] ?? 0
        if confidence <= 0.9 {
            return
        }*/
        var confi:Double = 0
        var currentKey = ""
        predictions.labelProbabilities.forEach { key, value in
            if let value1 = predictions.labelProbabilities[key], confi < value1, key != "other" {
                currentKey = key
                confi = value1
            }
        }
        let sorted = predictions.labelProbabilities.keys.sorted { key1, key2 in
            return Float(predictions.labelProbabilities[key1]!) >= Float(predictions.labelProbabilities[key2]!)
        }
        sorted.forEach{ print("\($0) confidence \(predictions.labelProbabilities[$0]!)") }
        self.delegate?.didReturnedResponse(with: confi, word: currentKey)
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
}
