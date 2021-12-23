import UIKit
import AccessionNumbers

class ScannedViewController: UIViewController {
    
    var definition: Definition!
    var matches = [Match]()
        
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
        
        var url: URL?
        
        let m = matches[indexPath.row]

        if definition.object_url != nil {
            
            let object_rsp = definition.ObjectURL(accession_number: m.accession_number)
            
            switch object_rsp {
            case .failure(let error):
                print("Failed to derive object URL for accession number \(m.accession_number), \(error).")
                
            case .success(let u):
                url = u
                showWebViewVC(url: u)
            }
        }
        
        if url == nil {
            print("Failed to derive URL")
            return
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        // dismiss(animated: true)
    }
}

extension ScannedViewController: UITableViewDelegate {
    
}

