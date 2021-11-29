//
//  ViewController.swift
//  LableWhisperer
//
//  Created by asc on 11/12/21.
//

import UIKit
import Vision
import VisionKit
import AccessionNumbers

// This is pretty much still a straigh clone of
// https://developer.apple.com/documentation/vision/structuring_recognized_text_on_a_document

class ViewController: UIViewController {

    @IBOutlet var scanned_text: UITextView!
    
    @IBOutlet var scan_button: UIButton!
    @IBOutlet var choose_button: UIButton!
    
    // var resultsViewController: (UIViewController & RecognizedTextDataSource)?
    var textRecognitionRequest = VNRecognizeTextRequest()
        
    var current: Definition?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textRecognitionRequest = VNRecognizeTextRequest(completionHandler: { (request, error) in

            if let results = request.results, !results.isEmpty {
                if let requestResults = request.results as? [VNRecognizedTextObservation] {
			DispatchQueue.main.async {
                        self.addRecognizedText(recognizedText: requestResults)
                    }
                }
            }
        })
        
        textRecognitionRequest.recognitionLevel = .accurate
            textRecognitionRequest.usesLanguageCorrection = true
    }

    
    @IBAction func choose(_ sender: UIControl) {
        let vc = DefinitionsViewController()
        present(vc, animated: true, completion: nil)
        return
    }
    
        @IBAction func scan(_ sender: UIControl) {
            let documentCameraViewController = VNDocumentCameraViewController()
            documentCameraViewController.delegate = self
            present(documentCameraViewController, animated: true)
        }
        
        func processImage(image: UIImage) {
            guard let cgImage = image.cgImage else {
                print("Failed to get cgimage from input image")
                return
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([textRecognitionRequest])
            } catch {
                print(error)
            }
        }

    func addRecognizedText(recognizedText: [VNRecognizedTextObservation]) {
        // Create a full transcript to run analysis on.
        var transcript = ""
        let maximumCandidates = 1
        for observation in recognizedText {
            guard let candidate = observation.topCandidates(maximumCandidates).first else { continue }
            transcript += candidate.string
            transcript += "\n"
        }
        
        guard self.current != nil else {            
            let vc = DefinitionsViewController()
            present(vc, animated: true, completion: nil)
            return
        }
        
        var candidates  = [Definition]()
        candidates.append(self.current!)
        
        let rsp = ExtractFromText(text: transcript, definitions: candidates)
        
        switch rsp {
        case .failure(let error):
            print("Failed to extract accession numbers from text, \(error).")
        case .success(let results):
            let vc = ScannedViewController()
            vc.matches = results
            present(vc, animated: true, completion: nil)
        }
    }
}

extension ViewController: VNDocumentCameraViewControllerDelegate {
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {        
        
        controller.dismiss(animated: true) {
            DispatchQueue.global(qos: .userInitiated).async {
                for pageNumber in 0 ..< scan.pageCount {
                    let image = scan.imageOfPage(at: pageNumber)
                    self.processImage(image: image)
                }
            }
        }
    }
    
}

