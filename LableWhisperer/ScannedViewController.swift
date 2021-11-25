import UIKit
import AccessionNumbers

class ScannedViewController: UITableViewController {
    
    var matches = [Match]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // This is important - it is necessary to prevent "unable to dequeue
        // a cell with identifier" errors even though the identifier is set
        // in the storyboard. Dunno...
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // https://developer.apple.com/documentation/foundation/indexpath
        // self.tableView.scrollToRow(at: idx_path, at: .top, animated: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        // NotificationCenter.default.post(name: Notification.Name("tableViewDisappearing"), object: nil)
    }
    
    // MARK: - Segue Methods
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // if let id = segue.identifier {
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matches.count
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
       let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            
        let idx = indexPath.row
        let m = self.matches[idx]
        
        cell.textLabel!.text = "\(m.accession_number) (\(m.organization))"
        return cell
    }    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
                dismiss(animated: true)
    }
    
}
