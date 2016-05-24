import UIKit
import Alamofire
import SVProgressHUD

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let defaults = NSUserDefaults.standardUserDefaults()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // load config from persisted Settings.plist
        if firstLaunch() {
            if let path = NSBundle.mainBundle().pathForResource("Settings", ofType: "plist"), dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] {
                defaults.setObject(dict["apiKey"], forKey: "apiKey")
                defaults.setDouble(dict["timeoutIntervalForRequestsInSeconds"] as! Double, forKey: "timeoutIntervalForRequestsInSeconds")
                defaults.setObject(dict["language"], forKey: "language")
                defaults.synchronize()
            }
        }
        
        // Alamofire Config
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.timeoutIntervalForRequest = defaults.doubleForKey("timeoutIntervalForRequestsInSeconds")
        configuration.timeoutIntervalForResource = defaults.doubleForKey("timeoutIntervalForRequestsInSeconds")
        let manager = Alamofire.Manager(configuration: configuration)
        
        let language: Language = Language(rawValue: defaults.stringForKey("language")!)!
        let scraper = Movie4KScraperService(manager: manager, language: language)
        ServiceRegistry.registerMovie4KScraperService(scraper)
        let theMovieDBorg = TheMovieDBorgService(manager: manager, apiKey: defaults.stringForKey("apiKey")!, language: language)
        ServiceRegistry.registerTheMovieDBorgService(theMovieDBorg)
        let applicationState = ApplicationStateService()
        ServiceRegistry.registerApplicationStateService(applicationState)
        
        // changed source SVProgressHUD.m: updateHUDFrame -> hudWidth and hudHeight to 300
        // change for TVOS times 3
        SVProgressHUD.setRingNoTextRadius(54.0)
        SVProgressHUD.setRingRadius(54.0)
        SVProgressHUD.setCornerRadius(42.0)
        SVProgressHUD.setRingThickness(6.0)
        
        searchContainerInTabBarHack()
        
        return true
    }
    
    private func searchContainerInTabBarHack() {
        
        let tabBarController = self.window?.rootViewController as! UITabBarController
        var controllersInTabs = tabBarController.viewControllers!
        
        let resultsController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier(SearchResultsViewController.storyboardIdentifier) as! SearchResultsViewController
        let searchController = UISearchController(searchResultsController: resultsController)
        
        searchController.searchResultsUpdater = resultsController
        searchController.obscuresBackgroundDuringPresentation = true
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchBar.placeholder = "SEARCHBAR_PLACEHOLDER".localized
        
        let searchContainerViewController = UISearchContainerViewController(searchController: searchController)
        
        let navController = UINavigationController(rootViewController: searchContainerViewController)
        navController.title = "SEARCH_NAV_CONTROLLER_TITLE".localized
        
        controllersInTabs.insert(navController, atIndex: 2)
        tabBarController.viewControllers = controllersInTabs
    }
    
    func firstLaunch() -> Bool {
        if defaults.stringForKey("firstLaunch") != nil {
            return true
        } else {
            defaults.setBool(true, forKey: "firstLaunch")
            return false
        }
    }

}

