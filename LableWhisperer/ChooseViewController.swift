import UIKit


class ChooseViewController: UIViewController {

    @IBOutlet var choose_button: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("HELLO")
        

    }
    
    override func viewDidAppear(_ animated: Bool){
        print("APPEAR")
    }
    
    @IBAction func cancel() {
        dismiss(animated: true)
    }
}
