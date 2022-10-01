//
//  MyCustomARView.swift
//  SIGNSlate
//
//  Created by Sanjay Thakkar on 09/09/2022.
//


import RealityKit
import UIKit
import ARKit

protocol MyCustomARViewDelegate {
    func didReturnedResponse(with confidence:Double, word:String)
}

class MyCustomARView: ARView {
    var posesWindow: [VNHumanHandPoseObservation] = []
    let dispatchQueueML = DispatchQueue(label: "com.ss.dispatchqueueml") // A Serial Queue
    var frameCounter: Int = 1 {
        didSet {
            // Framecounter has to be updated on the basis of interval.
            if frameCounter == 61 {
                frameCounter = 1
            }
        }
    }
    var delegate: MyCustomARViewDelegate?
    // Interval on which the predictions should be triggered.
    var handPosePredictionInterwal = 60
    
    required init() {
        //Setting up the view frame.
        super.init(frame: CGRect.init(x: 0, y: 88, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height - 250 - mainSafeAreaInsets!.bottom))
        session.delegate = self
        //Configurations on which the camera tracking the back camera.
        let configuration = ARWorldTrackingConfiguration()
        session.run(configuration)
        
    }
    
    @MainActor @objc required dynamic init(frame frameRect: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }
    
    @MainActor @objc required dynamic convenience init?(coder decoder: NSCoder) {
        self.init()
    }
    
    
    
}
