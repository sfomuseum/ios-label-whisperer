import UIKit
import AccessionNumbers

class ScannedViewController: UITableViewController {
    
    var matches = [Match]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("HELLO \(self.matches)")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // https://developer.apple.com/documentation/foundation/indexpath
        // self.tableView.scrollToRow(at: idx_path, at: .top, animated: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.post(name: Notification.Name("tableViewDisappearing"), object: nil)
    }
    
    // MARK: - Segue Methods
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        /*
        if let id = segue.identifier {
         
        }
         */
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matches.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        
        guard cell.imageView != nil else {
            return cell
        }
        
        cell.imageView?.image = nil
        cell.textLabel?.text = ""
        
        let idx = indexPath.row
        let match = matches[idx]
        
        cell.textLabel?.text = match.accession_number
        
        func completion (im: UIImage?) -> Void {
            // cell.textLabel?.text = titles[indexPath.row]
        }
        
        // match.load(to: view, with: completion)
        return cell
}
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        NotificationCenter.default.post(name: Notification.Name("setCurrentPage"), object: indexPath.row)
        dismiss(animated: true)
    }
    
}
