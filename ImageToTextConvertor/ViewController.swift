//
//  ViewController.swift
//  ImageToTextConvertor
//
//  Created by Ratna Paul Saka on 4/22/20.
//  Copyright © 2020 Ratna Paul Saka. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var textview: UITextView!
    @IBOutlet weak var confidenceLabel: UILabel!

    var convertor: ImageToTextConvertor = ImageToTextConvertor()

    override func viewDidLoad() {
        super.viewDidLoad()
        confidenceLabel.text = ""
        self.textview.contentSize = CGSize.init(width: self.textview.bounds.size.width, height: self.textview.bounds.size.height * 2)
    }
    
    @IBAction func scanClicked(_ sender: Any) {
        self.convertor.convert(using: self) { (text, confidence) in
            DispatchQueue.main.async {
                self.textview.text = text
                self.confidenceLabel.text = "Confidence = " + String(confidence)
            }
        }
    }
}

