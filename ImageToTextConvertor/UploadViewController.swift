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

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        controller.dismiss(animated: true, completion: nil)
        guard let url = urls.first else {
            return
        }
        activityIndicatorView.startAnimating()
        convertor.convert(pdfAtUrl: url) { (text, confidence) in
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
