import UIKit
import AccessionNumbers

class DefinitionsViewController: UITableViewController {
    
    var definitions = [Definition]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // This is important - it is necessary to prevent "unable to dequeue
        // a cell with identifier" errors even though the identifier is set
        // in the storyboard. Dunno...
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "definitionCell")
        
        if definitions.count == 0 {
                    
            let def_rsp = self.loadDefinitionFiles()
        
            switch def_rsp {
            case .failure(let error):
                fatalError("Failed to load definitions, \(error).")
            case .success(let defs):
                definitions = defs
            }
            
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // https://developer.apple.com/documentation/foundation/indexpath
        // self.tableView.scrollToRow(at: idx_path, at: .top, animated: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        // NotificationCenter.default.post(name: Notification.Name("tableViewDisappearing"), object: nil)
    }
    
    // MARK: - Definitions methods
    
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
    
    // MARK: - Segue Methods
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // if let id = segue.identifier {
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return definitions.count
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
       let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            
        let idx = indexPath.row
        let m = self.definitions[idx]
        
        cell.textLabel!.text = "\(m.organization_name) (\(m.organization_url))"
        
        // TO DO: on select segue back to ViewController with selection
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
                dismiss(animated: true)
    }
    
}
