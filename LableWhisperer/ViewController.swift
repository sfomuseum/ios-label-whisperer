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
    
    @IBOutlet var current_organization: UINavigationItem!
    
    @IBOutlet var current_definition: UITextView!
    
    // var resultsViewController: (UIViewController & RecognizedTextDataSource)?
    var textRecognitionRequest = VNRecognizeTextRequest()
        
    var current: Definition?
    
    var opQueue = OperationQueue()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupNotificationHandlers()
        
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
        
        self.scan_button.isEnabled = false
    }

    // MARK: - Alert Methods
    
    private func showAlert(label: String, message: String){
        
        // TO DO: vibrate
        // https://developer.apple.com/documentation/uikit/uinotificationfeedbackgenerator/2369826-notificationoccurred
        
        // self.app.logger.debug("show alert \(label): \(message)")
        
        let alertController = UIAlertController(
            title: label,
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        self.opQueue.addOperation {
            OperationQueue.main.addOperation({
                self.present(alertController, animated: true, completion: nil)
            })
        }
    }
    
    private func setupNotificationHandlers() -> Result<Void, Error> {
        
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "setCurrentOrganization"),
                                               object: nil,
                                               queue: .main) { (notification) in
            
            guard let def = notification.object as? Definition else {
                self.scan_button.isEnabled = false
                return
            }
            
            self.current = def
            
            // TO DO: save to user prefs
            
            self.current_organization.title = self.current!.organization_name
            
            self.scan_button.isEnabled = true
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            
            do {
            let data = try encoder.encode(self.current!)
            
                self.current_definition.text = String(data: data, encoding: .utf8)!
                
            } catch (let error){
                print("SAD \(error)")
            }
        }
        
        return .success(())
    }
    
    private func showChooseVC() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ChooseViewController") as! ChooseViewController
        // let vc = ChooseViewController()
        print("SHOW")
         present(vc, animated: true, completion: nil)
        
    }
    
    @IBAction func choose(_ sender: UIControl) {
        showChooseVC()
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
            // let vc = DefinitionsViewController()
            let vc = ChooseViewController()
            show(vc, sender: self)
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
            vc.definition = self.current
            //present(vc, animated: true, completion: nil)
            show(vc, sender: self)
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

