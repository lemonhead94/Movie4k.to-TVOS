import Foundation
import UIKit

class SomeViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
}