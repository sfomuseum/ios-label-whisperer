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
            
    // var resultsViewController: (UIViewController & RecognizedTextDataSource)?
    var textRecognitionRequest = VNRecognizeTextRequest()
        
    var candidates = [Definition]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let def_rsp = self.loadDefinitionFiles()
        
        switch def_rsp {
        case .failure(let error):
            fatalError("Failed to load definitions, \(error).")
        case .success(let defs):
            candidates = defs
        }
        
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

    private func listDefinitionFiles() -> Result<[URL], Error> {
        
        let data = Bundle.main.resourcePath! + "/data.bundle/"
        let root = URL(string: data)
        
        var directoryContents: [URL]
        
        do {
            directoryContents = try FileManager.default.contentsOfDirectory(at: root!, includingPropertiesForKeys: nil)
        } catch (let error) {
            return .failure(error)
        }
        
        let definitions = directoryContents.filter({ $0.pathExtension == "json" })
        return .success(definitions)
    }
    
    private func loadDefinitionFiles() -> Result<[Definition], Error> {
        
        var definitions = [Definition]()
        var urls: [URL]
        
        let list_rsp = self.listDefinitionFiles()
                
        switch list_rsp {
        case .failure(let error):
            return .failure(error)
        case .success(let results):
            urls = results
        }
        
        // TO DO: This, but asynchronously
        
        for u in urls {
            
            let def_rsp = self.loadDefinitionFromURL(url: u)
            
            switch def_rsp {
            case .failure(let error):
                return .failure(error)
            case .success(let def):
                definitions.append(def)
            }
        }
        
        return .success(definitions)
    }
    
    private func loadDefinitionFromURL(url: URL) -> Result<Definition, Error> {
             
        var data: Data
        var def: Definition
        
        do {
            data = try Data(contentsOf: url)
        } catch (let error){
            return .failure(error)
        }
        
        let decoder = JSONDecoder()
        
        do {
            def = try decoder.decode(Definition.self, from: data)
        } catch (let error){
            return .failure(error)
        }
        
        return .success(def)
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
        
        let rsp = ExtractFromText(text: transcript, definitions: self.candidates)
        
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
        
        // self.activityIndicator.isHidden = false
        // self.activityIndicator.startAnimating()
        controller.dismiss(animated: true) {
            DispatchQueue.global(qos: .userInitiated).async {
                for pageNumber in 0 ..< scan.pageCount {
                    let image = scan.imageOfPage(at: pageNumber)
                    self.processImage(image: image)
                }
                /*
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.isHidden = true
                }
                */
            }
        }
    }
}

