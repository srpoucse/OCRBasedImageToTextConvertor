//
//  UploadViewController.swift
//  ImageToTextConvertor
//
//  Created by Ratna Paul Saka on 4/22/20.
//  Copyright © 2020 Ratna Paul Saka. All rights reserved.
//

import Foundation
import UIKit
import CoreServices

class UploadViewController: UIViewController {
    
    fileprivate var convertor: ImageToTextConvertor = ImageToTextConvertor()
    @IBOutlet weak var textview: UITextView!
    @IBOutlet weak var confidenceLabel: UILabel!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        
    }
    
    @IBAction func uploadClicked(sender: Any) {
        textview.text = ""
        let picker = UIDocumentPickerViewController(documentTypes: [kUTTypePDF as String], in: .import)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
}

extension UploadViewController: UIDocumentPickerDelegate {
    
    func convertHEIF(at url: URL) -> UIImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
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
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        controller.dismiss(animated: true, completion: nil)
        activityIndicatorView.startAnimating()
        let cgImage = try! convertPDF(at: urls.first!).first!
        let image = UIImage.init(cgImage: cgImage)
        convertor.convert(using: image) { (text, confidence) in
            DispatchQueue.main.async {
                self.activityIndicatorView.stopAnimating()
                self.textview.text = text
                self.confidenceLabel.text = "Confidence = " + String(ceil(confidence * 100)) + "%"
            }
        }
        
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true, completion: nil)
    }

}
