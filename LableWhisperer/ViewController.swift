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
    
    let app = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet var scanned_text: UITextView!
    
    @IBOutlet var scan_button: UIButton!
    @IBOutlet var choose_button: UIButton!
    
    @IBOutlet var collection_button: UIButton!
    @IBOutlet var current_organization: UINavigationItem!
    
    @IBOutlet var current_definition: UITextView!
    
    // var resultsViewController: (UIViewController & RecognizedTextDataSource)?
    var textRecognitionRequest = VNRecognizeTextRequest()
    
    var collection: Collection?
    var current: Definition?
    
    var opQueue = OperationQueue()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            collection = try SQLiteCollection()
        } catch (let error) {
            // To do: Alert or at least notify
            print("NO COLLECTION BECAUSE: \(error)")
        }
        
        // For debugging
        
        /*
        if collection != nil {            
            let org = "https://collection.sfomuseum.org"
            let num = "2005.132.013.008"
            let record = NewCollectionRecord(organization: org, accession_number: num)
            self.collection?.Collect(record: record)
            
        }
        */
        
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

        // Preload last selected definition
        
        let current = UserDefaults.standard.value(forKey: "current_definition") as? String
        
        if current != nil {

            let def_rsp = app.definition_files.LoadFromOrganizationURL(organization_url: current!)
            
            switch def_rsp {
            case .failure(let error):
                print("Failed to load definition file for \(current), \(error)")
            case .success(let def):
                self.current = def
                self.showDefinition(definition: def)
            }
        }
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
    
    private func showDefinition(definition: Definition) {
        
        self.current_organization.title = definition.organization_name
                
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(definition)
            self.current_definition.text = String(data: data, encoding: .utf8)!
            
        } catch (let error){
            print("SAD \(error)")
            return
        }
        
        self.scan_button.isEnabled = true
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
            
            UserDefaults.standard.setValue(def.organization_url, forKey:"current_definition")
            let sync = UserDefaults.standard.synchronize()
            
            if !sync {
                print("Failed to synchronize user defaults")
            }
            
            self.showDefinition(definition: def)
    
            /*
            let def2 = UserDefaults.standard.value(forKey: "current_definition") as? String
            print("WHAT", def2)
            */
        }
        
        return .success(())
    }
    
    private func showIIIFVCDebug() {
        let url = URL(string: "https://collection.sfomuseum.org/objects/1511943407/manifest/")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "IIIFViewController") as! IIIFViewController
        vc.manifest_url = url!
        show(vc, sender: self)
    }
    
    private func showChooseVC() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ChooseOrganizationViewController") as! ChooseOrganizationViewController
        show(vc, sender: self)
    }
    
    private func showScannedVC(results: [Match]){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "ScannedViewController") as! ScannedViewController
        vc.matches = results
        vc.definition = self.current
        vc.collection = self.collection
        show(vc, sender: self)
    }
    
    private func showCollectionVC(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CollectionViewController") as! CollectionViewController
        vc.collection = self.collection
        show(vc, sender: self)
    }
    
    @IBAction func choose(_ sender: UIControl) {
        showChooseVC()
    }
    
    @IBAction func collection(_ sender: UIControl) {
        showCollectionVC()
    }
    
    @IBAction func scan(_ sender: UIControl) {
        
        //showIIIFVCDebug()
        //return
        
        let documentCameraViewController = VNDocumentCameraViewController()
        documentCameraViewController.delegate = self
        present(documentCameraViewController, animated: true)
    }
    
    // MARK: - Image Processing methods
    
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
            showChooseVC()
            return
        }
        
        var candidates  = [Definition]()
        candidates.append(self.current!)
        
        let rsp = ExtractFromText(text: transcript, definitions: candidates)
        
        switch rsp {
        case .failure(let error):
            print("Failed to extract accession numbers from text, \(error).")
        case .success(let results):
            showScannedVC(results: results)
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

