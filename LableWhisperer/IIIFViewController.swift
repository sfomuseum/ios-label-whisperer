import UIKit
import WebKit

class IIIFViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {
    
    @IBOutlet var web_view: WKWebView!
    
    let wk_store = WKWebsiteDataStore.default()
    let wk_pool = WKProcessPool()
    
    var manifest_url: URL?
    var iiif_url: URL?

    var jsCompletionHandler: (Any?, Error?) -> Void = {
        (data, error) in
        
        if let error = error {
            print("JS failure: \(error)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                        
        let root = Bundle.main.resourcePath! + "/www.bundle/"
        
        // Note the file:// -iness of the URL

        let root_url = URL(string: "file://" + root)
        let iiif_url = root_url?.appendingPathComponent("iiif.html")
    
        
        let wk_conf = WKWebViewConfiguration()
        wk_conf.processPool = wk_pool
        wk_conf.websiteDataStore = wk_store
        
        let request = URLRequest(url: iiif_url!)
                
        web_view = WKWebView(frame: .zero, configuration: wk_conf)
        web_view.navigationDelegate = self
        view = web_view
        
        web_view.load(request)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {

        let url = self.manifest_url!.absoluteString
        let init_js = "label_whisperer_iiif_init('\(url)')"
        
        print("INIT \(init_js)")
        self.jsDispatchAsync(jsFunc: init_js)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        ()
    }
    
    @IBAction func close() {
        dismiss(animated: true)
    }
    
    /// Invoke the webView's evaluateJavaScript() method with the application's default completionHandler
    private func jsDispatch(jsFunc: String) {
        
        self.web_view?.evaluateJavaScript(jsFunc, completionHandler: self.jsCompletionHandler)
    }
    
    /// Invoke the application's jsDispatch method ensuring that the operation is performed asynchronously
    private func jsDispatchAsync(jsFunc: String){
        DispatchQueue.main.async {
            self.jsDispatch(jsFunc: jsFunc)
        }
    }
}
    

