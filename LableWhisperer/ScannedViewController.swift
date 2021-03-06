import UIKit
import AccessionNumbers

class ScannedViewController: UIViewController {
    
    var collection: Collection?
    var definition: Definition!
    var matches = [Match]()
    
    var current_match: Match!
    
    @IBOutlet var cancel_button: UIButton!
    @IBOutlet var table_view: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        table_view.dataSource = self
        table_view.delegate = self
        
        table_view.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    @IBAction func cancel() {
        dismiss(animated: true)
    }
    
    // MARK: - View Controller methods
    
    private func showWebViewVC(url: URL) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "WebViewController") as! WebViewController
        vc.url = url
        show(vc, sender: self)
    }
    
    private func showIIIFViewVC(url: URL) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "IIIFViewController") as! IIIFViewController
        vc.manifest_url = url
        show(vc, sender: self)
    }
}

extension ScannedViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matches.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let idx = indexPath.row
        let m = self.matches[idx]
        
        
        let cell: UITableViewCell = self.table_view.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel!.text = "\(m.accession_number) (\(m.organization))"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let row = tableView.cellForRow(at: indexPath) else {
            // To do: alert
            return
        }
        
        self.current_match = matches[indexPath.row]
        
        let interaction = UIContextMenuInteraction(delegate: self)
        row.addInteraction(interaction)
    }
}

extension ScannedViewController: UITableViewDelegate {
    
}

// MARK: - Context Menu methods

extension ScannedViewController: UIContextMenuInteractionDelegate  {
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        
        let organization_url = self.definition.organization_url
        let accession_number = self.current_match.accession_number
        
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil,
                                          actionProvider: {
            suggestedActions in
            
            var actions = [UIAction]()
            
            // Collect object action
            
            if self.collection != nil {
                
                let collectAction =
                UIAction(title: NSLocalizedString("Collect this object", comment: ""),
                         image: UIImage(systemName: "arrow.up.square")) { action in
                    
                    let record = NewCollectionRecord(organization: organization_url, accession_number: accession_number)                    
                    let collect_rsp = self.collection?.Collect(record: record)
                    
                    // To do: Feedback, one way or another
                    
                    switch collect_rsp {
                    case .failure(let error):
                        print("SAD \(error)")
                    case .success:
                        print("OKAY")
                    case .none: // Why does this need to be here? Is this new...?
                        ()
                    }
                }
                
                actions.append(collectAction)
            }
            
            // Open webpage action
            
            if self.definition.object_url != nil {
                
                let object_rsp = self.definition.ObjectURL(accession_number: accession_number)
                
                switch object_rsp {
                case .failure(let error):
                    print("Failed to derive object URL for accession number \(accession_number), \(error).")
                    
                case .success(let url):
                    
                    let openAction =
                    UIAction(title: NSLocalizedString("Open webpage", comment: ""),
                             image: UIImage(systemName: "arrow.up.square")) { action in
                        self.showWebViewVC(url: url)
                    }
                    
                    actions.append(openAction)
                }
            }
            
            // oEmbed action
                        
            // IIIF action
            
            if self.definition.iiif_manifest != nil {
                
                let iiif_rsp = self.definition.IIIFManifest(accession_number: accession_number)
                
                switch iiif_rsp {
                case .failure(let error):
                    print("Failed to derive IIIF manifest URL for accession number \(accession_number), \(error).")
                    
                case .success(let url):
                    
                    let openAction =
                    UIAction(title: NSLocalizedString("Open IIIF image", comment: ""),
                             image: UIImage(systemName: "arrow.up.square")) { action in
                        self.showIIIFViewVC(url: url)
                    }
                    
                    actions.append(openAction)
                }
            }
            
            if actions.count == 0 {
                return nil
            }
            
            return UIMenu(title: "", children: actions)
        })
    }
    
}
