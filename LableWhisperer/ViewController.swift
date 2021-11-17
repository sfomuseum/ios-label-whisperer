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
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
        
    // var resultsViewController: (UIViewController & RecognizedTextDataSource)?
    var textRecognitionRequest = VNRecognizeTextRequest()
    
    var accession_numbers: AccessionNumbers!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // START OF load data
        
        var candidates = [Organization]()
        
        if let url = Bundle.main.url(forResource: "sfomuseum", withExtension: "json") {

        var data: Data
        var org: Organization
        
        do {
            data = try Data(contentsOf: url)
        } catch (let error){
            fatalError("Failed to load  from bundle, \(error).")
        }
        
        let decoder = JSONDecoder()
        
        do {
            org = try decoder.decode(Organization.self, from: data)
        } catch (let error){
            fatalError("Failed to load organization, \(error).")
        }
            
            candidates.append(org)
        }
        
        accession_numbers = AccessionNumbers(candidates: candidates)
               
        // END OF load data
        
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
        
        let rsp = self.accession_numbers.ExtractFromText(text: transcript)
        var text = ""
        
        switch rsp {
        case .failure(let error):
            print("Failed to extract accession numbers from text, \(error).")
        case .success(let results):
            for n in results {
                text += "\(n.accession_number) (\(n.organization))\n"
            }
        }
        
        self.scanned_text?.text = text // transcript
    }
}

extension ViewController: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {        
        
        self.activityIndicator.isHidden = false
        self.activityIndicator.startAnimating()
        controller.dismiss(animated: true) {
            DispatchQueue.global(qos: .userInitiated).async {
                for pageNumber in 0 ..< scan.pageCount {
                    let image = scan.imageOfPage(at: pageNumber)
                    self.processImage(image: image)
                }
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                }
            }
        }
    }
}

