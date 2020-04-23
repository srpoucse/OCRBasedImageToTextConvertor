# ImageToTextConvertor
An OCR based Image to Text Convertor that can be used in any iOS App. It supports image to text and PDF to text currently.

# To Integrate 

# 1 - Snap an Image and convert to text
    let convertor: ImageToTextConvertor = ImageToTextConvertor()
    convertor.convert(using: self) { (text, confidence) in
           
    }
    
# 2 - Import a PDF from any Document Based app like Files app and convert to text.
    let convertor: ImageToTextConvertor = ImageToTextConvertor()
    convertor.convert(pdfAtUrl: url) { (text, confidence) in
    }
