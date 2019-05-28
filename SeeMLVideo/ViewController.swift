//
//  ViewController.swift
//  SeeMLVideo
//
//  Created by Jeremy Adam on 27/05/19.
//  Copyright © 2019 Underway. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    
    //UI Element
    @IBOutlet weak var resultLabel1: UILabel!
    @IBOutlet weak var confLabel1: UILabel!
    @IBOutlet weak var modelPickerView: UIPickerView!
    
    
    //Variable
    var modelSelected:MLModel = MLModel()
    let modelCollection:[String:MLModel] =
        [
            "Age - (AgeNet)" : AgeNet().model,
            "Food - (Food101)" : Food101().model,
            "Gender - (GenderNet)" : GenderNet().model,
            "NSFW - (Nudity)" : Nudity().model,
            "Object - (Inceptionv3 Acc:94,4)" : Inceptionv3().model,
            "Object - (MobileNet Acc:89,9)" : MobileNet().model,
            "Object - (Resnet50 Acc:92,2)" : Resnet50().model,
            "Object - (VGG16 Acc:92,6)" : VGG16().model,
            "Pet - (CatDog Acc:98,9)" : cat_dog_20iter_98_95eval_1().model,
            "Scene - (GoogLeNetPlaces Acc:85,4)" : GoogLeNetPlaces().model
            
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //For Picker View Model
        modelPickerView.delegate = self
        modelPickerView.dataSource = self
        
        
        //Default Value of ML Model
        modelSelected = [MLModel](modelCollection.values)[0]
        
        //Video Capture
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {return}
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {return}
        captureSession.addInput(input)

        captureSession.startRunning()
        
        //Capture Sample Layer Only for Detect
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        //Output
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQu"))
        captureSession.addOutput(dataOutput)
        
    }
    
    //Capture Output Video
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuff: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        
        guard let model = try? VNCoreMLModel(for: modelSelected) else {return}
        let request = VNCoreMLRequest(model: model) { (req, err) in
            
            guard let result = req.results as? [VNClassificationObservation] else {return}
            guard let firstRes = result.first else {return}
            
            let finalResult = firstRes.identifier.capitalized.components(separatedBy: ",")[0]
            let finalConfidence = String(format: "%.2f%%",  firstRes.confidence * 100)
            
            
            //TODO: Set Interval Sample Buffer to print Output more Chill
            
            //Print Result if 10% more Confidence
            if firstRes.confidence * 100 > 10 {
                DispatchQueue.main.async {
                    self.printResult(finalResult, finalConfidence)
                }
            }
            
            
            
            print(firstRes.identifier, firstRes.confidence)
            
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuff, options: [:]).perform([request])
    }
    
    //UI Picker View
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return modelCollection.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return [String](modelCollection.keys)[row]
    }
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 30
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        modelSelected = [MLModel](modelCollection.values)[row]
    }
    //


    func printResult(_ res:String, _ conf:String) {
        resultLabel1.text = res
        confLabel1.text = conf
    }
    
    
}

