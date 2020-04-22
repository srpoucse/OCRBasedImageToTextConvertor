//
//  ImageToTextConvertor.swift
//  ImageToTextConvertor
//
//  Created by Ratna Paul Saka on 4/22/20.
//  Copyright © 2020 Ratna Paul Saka. All rights reserved.
//

import Foundation
import UIKit
import Vision
import VisionKit

@objc class ImageToTextConvertor: NSObject {
    
    typealias T = (String, Float) -> ()
    
    var textRecognitionRequest: VNRecognizeTextRequest = VNRecognizeTextRequest()
    private let textRecognitionWorkQueue = DispatchQueue(label: "MyVisionScannerQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    var completionHandler: T = {_, _ in }
   
    override init() {
        super.init()
        setupTextRecognitionRequest()
    }
    
    func convert(using image: UIImage, completionHandler: @escaping T)  {
        self.completionHandler = completionHandler
        processImage(image)
    }
    
    func convert(using viewController: UIViewController, completionHandler: @escaping T)  {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = self
        viewController.present(scannerViewController, animated: true)
        self.completionHandler = completionHandler
    }
    
    fileprivate func processImage(_ image: UIImage) {
        recognizeTextInImage(image)
    }
    
    private func recognizeTextInImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        textRecognitionWorkQueue.async {
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try requestHandler.perform([self.textRecognitionRequest])
            } catch {
                print(error)
            }
        }
    }
       
    private func setupTextRecognitionRequest() {
        textRecognitionRequest = VNRecognizeTextRequest { (request, error) in
              guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
              var confidence: Float = 0
              var detectedText = ""
              for observation in observations {
                  guard let topCandidate = observation.topCandidates(1).first else { return }
                  print("text \(topCandidate.string) has confidence \(topCandidate.confidence)")
                  confidence += topCandidate.confidence
                  detectedText += topCandidate.string
                  detectedText += "\n"
               }
            self.completionHandler(detectedText, confidence / Float(observations.count))
       }
       textRecognitionRequest.recognitionLevel = .accurate
    }
    
    fileprivate func compressedImage(_ originalImage: UIImage) -> UIImage {
        guard let imageData = originalImage.jpegData(compressionQuality: 1),
            let reloadedImage = UIImage(data: imageData) else {
                return originalImage
        }
        return reloadedImage
    }
}


extension ImageToTextConvertor: VNDocumentCameraViewControllerDelegate {
    
     // The client is responsible for dismissing the document camera in these callbacks.
     // The delegate will receive one of the following calls, depending whether the user saves or cancels, or if the session fails.
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        guard scan.pageCount >= 1 else {
            controller.dismiss(animated: true)
            return
        }
        
        controller.dismiss(animated: true)
 
        for i in 0..<scan.pageCount  {
            let originalImage = scan.imageOfPage(at: i)
            let newImage = compressedImage(originalImage)
            processImage(newImage)
        }
    }
    
     // The delegate will receive this call when the user cancels.
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        completionHandler("", 0.0)
        controller.dismiss(animated: true)
    }

     
     // The delegate will receive this call when the user is unable to scan, with the following error.
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        completionHandler("Failed converting image to text.", 0.0)
        controller.dismiss(animated: true)
    }
    
}
