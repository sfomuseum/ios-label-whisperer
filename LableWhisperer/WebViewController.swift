
import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate {
    
    @IBOutlet var web_view: WKWebView!
    
    @IBOutlet var navbar: UINavigationBar!
    @IBOutlet var close_button: UIBarButtonItem!
    
    let wk_pool = WKProcessPool()
    let wk_store = WKWebsiteDataStore.default()
    
    var url: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        let wk_conf = WKWebViewConfiguration()
        wk_conf.processPool = wk_pool
        wk_conf.websiteDataStore = wk_store
        
        let request = URLRequest(url: url!)
                
        web_view = WKWebView(frame: .zero, configuration: wk_conf)
        // web_view.navigationDelegate = self
        // view = web_view
        
        
        view.addSubview(web_view)
        web_view.load(request)
    }
    
    @IBAction func close() {
        dismiss(animated: true)
    }
}
    
