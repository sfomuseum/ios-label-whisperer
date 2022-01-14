import UIKit
import AccessionNumbers

class ChooseOrganizationViewController: UIViewController {
    
    let app = UIApplication.shared.delegate as! AppDelegate
    var definitions = [Definition]()
    
    @IBOutlet var choose_button: UIButton!
    @IBOutlet var table_view: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        table_view.dataSource = self
        table_view.delegate = self
        
        table_view.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        if definitions.count == 0 {
                    
            let def_rsp = app.definition_files.Load()
        
            switch def_rsp {
            case .failure(let error):
                fatalError("Failed to load definitions, \(error).")
            case .success(let defs):
                
                let sorted = defs.sorted {
                    $0.organization_name < $1.organization_name
                }
                
                definitions = sorted
            }
            
        }
    }
    
    @IBAction func cancel() {
        dismiss(animated: true)
    }
    
}

extension ChooseOrganizationViewController: UITableViewDataSource {
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return definitions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let def = self.definitions[ indexPath.row ]
        
        let cell: UITableViewCell = self.table_view.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = def.organization_name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // TBD... maybe do context menus here? maybe not, though
        // It seems like unnecessary fluff
        
        /*
        guard let row = tableView.cellForRow(at: indexPath) else {
            return
        }
        
        let interaction = UIContextMenuInteraction(delegate: self)
        row.addInteraction(interaction)
        return
        */
        
        let def = definitions[indexPath.row]

        NotificationCenter.default.post(name: Notification.Name("setCurrentOrganization"), object: def)
        
        tableView.deselectRow(at: indexPath, animated: true)
                dismiss(animated: true)
    }
}

extension ChooseOrganizationViewController: UITableViewDelegate {
    
}
