//ARKit Version...
//  MyCustomARView+ML.swift
//  SIGNSlate
//
//  Created by Stephanie Joubert on 09/09/2022.


import Vision
import ARKit

extension MyCustomARView: ARSessionDelegate {
    var handPoseRequestComputed: VNDetectHumanHandPoseRequest {
        let request = VNDetectHumanHandPoseRequest { request, error in
            if let error = error {
                fatalError(error.localizedDescription)
            }
            
            if let observations = (request.results as? [VNDetectedObjectObservation])?.first {
                print(observations)
            }
            
        }
        request.maximumHandCount = 1
        request.revision = VNDetectHumanHandPoseRequestRevision1
        return request
    }
    
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        frameCounter += 1
        if frameCounter % handPosePredictionInterwal == 0 {
        
        let pixelBuffer = frame.capturedImage

        let handPoseRequest = VNDetectHumanHandPoseRequest()
        handPoseRequest.maximumHandCount = 1
        handPoseRequest.revision = VNDetectHumanHandPoseRequestRevision1
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        
        do {
            try handler.perform([handPoseRequest])
        } catch let error {
            print(error.localizedDescription)
        }
        
        guard let handPose = handPoseRequest.results?.first else {
            return
        }
        
        
           // guard let keypointsMultiArray = try? //handPose.keypointsMultiArray()
                    guard let keypointsMultiArray = try? MLMultiArray(shape:[60,3,21], dataType:MLMultiArrayDataType.float32) else {
                        fatalError("Unexpected runtime error. MLMultiArray")
                    }
           // else { fatalError() }
            
//            var model: newhandaction_1
            var model: handsonly
            do {
                model = try handsonly(configuration: MLModelConfiguration())
            } catch let error {
                fatalError(error.localizedDescription)
            }
        
            do {
                let handPosePrediction = try model.prediction(poses: keypointsMultiArray)
//                let confidence = handPosePrediction.labelProbabilities[handPosePrediction.label]!
                let confidence = handPosePrediction.labelProbabilities[handPosePrediction.label] ?? 0
                
                let sorted = handPosePrediction.labelProbabilities.keys.sorted { key1, key2 in
                    return Double(handPosePrediction.labelProbabilities[key1]!) > Double(handPosePrediction.labelProbabilities[key2]!)
                }
                sorted.forEach{ print("\($0)", confidence) }
                print("Latest Prediction " + handPosePrediction.label)
                print(confidence)
                if (Double(confidence) <= 0.8) /*|| handPosePrediction.label == "other"*/ {
                    return
                }
                self.delegate?.didReturnedResponse(with: confidence, word: handPosePrediction.label)
               
                
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
}
