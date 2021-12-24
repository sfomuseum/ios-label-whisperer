import UIKit
import AccessionNumbers

class CollectionViewController: UIViewController {
    
    var collection: Collection?
    
    @IBOutlet var table_view: UITableView!
    
    @IBOutlet var close_button: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        table_view.dataSource = self
        table_view.delegate = self
        
        table_view.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }
    
    @IBAction func close() {
        dismiss(animated: true)
    }
}

extension CollectionViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if self.collection == nil{
            return 0
        }
        
        let count_rsp = self.collection?.CountRecords()
        
        switch count_rsp {
        case .failure(let error):
            print("\(error)")
            return 0
        case .success(let count):
            return count
        case .none:
            return 0
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let idx = indexPath.row
        var text = ""
        
        if self.collection != nil {
            
            let record_rsp = self.collection?.RecordFromOffset(offset: idx)
            
            switch record_rsp {
            case .failure(let error):
                print("\(error)")
            case .success(let record):
                text = "\(record.accession_number) (\(record.organization))"
            case .none:
                ()
            }
        }
        
        let cell: UITableViewCell = self.table_view.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel!.text = text
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let row = tableView.cellForRow(at: indexPath) else {
            // To do: alert
            return
        }
        
        print("DO SOMETHING")
        
        tableView.deselectRow(at: indexPath, animated: true)
        // dismiss(animated: true)
    }
}

extension CollectionViewController: UITableViewDelegate {
    
}

// MARK: - Context Menu methods

extension CollectionViewController: UIContextMenuInteractionDelegate  {
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        
        
        
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil,
                                          actionProvider: {
            suggestedActions in
            
            var actions = [UIAction]()                       
            
            if actions.count == 0 {
                return nil
            }
            
            return UIMenu(title: "", children: actions)
        })
    }
    
}
