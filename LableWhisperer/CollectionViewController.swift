import UIKit
import AccessionNumbers

class CollectionViewController: UIViewController {
    
    var collection: Collection?
    
    var current_selection: IndexPath?
    
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
        
        self.current_selection = indexPath
        
        let interaction = UIContextMenuInteraction(delegate: self)
        row.addInteraction(interaction)
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
            
            if self.current_selection != nil {
                
                /*
                 Thread 1: "Invalid update: invalid number of rows in section 0. The number of rows contained in an existing section after the update (1) must be equal to the number of rows contained in that section before the update (1), plus or minus the number of rows inserted or deleted from that section (0 inserted, 1 deleted) and plus or minus the number of rows moved into or out of that section (0 moved in, 0 moved out). Table view: <UITableView: 0x7f95f186c000; frame = (0 0; 390 697); clipsToBounds = YES; autoresize = RM+BM; gestureRecognizers = <NSArray: 0x600002e21410>; layer = <CALayer: 0x600002001300>; contentOffset: {0, 0}; contentSize: {390, 44}; adjustedContentInset: {0, 0, 0, 0}; dataSource: <LableWhisperer.CollectionViewController: 0x7f95f0417a20>>"
                 */
                
                let remove_action = UIAction(title: NSLocalizedString("Remove this object", comment: ""),
                                             image: UIImage(systemName: "arrow.down.square")) { action in
                    
                    self.table_view.deleteRows(at: [self.current_selection!], with: .automatic)
                    self.current_selection = nil
                }
                
                
                actions.append(remove_action)
            }
            
            return UIMenu(title: "", children: actions)
        })
    }
    
}
