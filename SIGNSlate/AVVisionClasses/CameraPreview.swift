//
//  CameraPreaview.swift
//  SIGNSlate
//
//  Created by Sanjay Thakkar on 2022/9/23.
//

import UIKit
import AVFoundation



class CameraPreview: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

