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
    
    func convert(pdfAtUrl: URL, completionHandler: @escaping T)  {
        self.completionHandler = completionHandler
        guard let cgImage = try? convertPDF(at: pdfAtUrl).first else {
            completionHandler("Failed converting PDF to text.", 0.0)
            return
        }
        let image = UIImage.init(cgImage: cgImage)
        processImage(image)
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

extension ImageToTextConvertor {
    func convertPDF(at sourceURL: URL, dpi: CGFloat = 200) throws -> [CGImage] {
           let pdfDocument = CGPDFDocument(sourceURL as CFURL)!
           let colorSpace = CGColorSpaceCreateDeviceRGB()
           let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue
           var imgs = [CGImage]()
           
           DispatchQueue.concurrentPerform(iterations: pdfDocument.numberOfPages) { i in
               // Page number starts at 1, not 0
               let pdfPage = pdfDocument.page(at: i + 1)!

               let mediaBoxRect = pdfPage.getBoxRect(.mediaBox)
               let scale = dpi / 72.0
               let width = Int(mediaBoxRect.width * scale)
               let height = Int(mediaBoxRect.height * scale)

               let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo)!
               context.interpolationQuality = .high
               context.setFillColor(UIColor.white.cgColor)
               context.fill(CGRect(x: 0, y: 0, width: width, height: height))
               context.scaleBy(x: scale, y: scale)
               context.drawPDFPage(pdfPage)

               let image = context.makeImage()!
               imgs.append(image)
           }
           return imgs
       }
}
