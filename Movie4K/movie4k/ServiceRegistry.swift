import Foundation

class ServiceRegistry {
    
    private static var scraper: Movie4KScraperService!
    private static var theMovieDBorg: TheMovieDBorgService!
    private static var applicationState: ApplicationStateService!
    
    static func registerMovie4KScraperService(service: Movie4KScraperService) {
        self.scraper = service
    }
    
    static func registerTheMovieDBorgService(service: TheMovieDBorgService) {
        self.theMovieDBorg = service
    }
    
    static func registerApplicationStateService(service: ApplicationStateService) {
        self.applicationState = service
    }
    
    static func loadMovie4KScraperService() -> Movie4KScraperService {
        return self.scraper
    }
    
    static func loadTheMovieDBorgService() -> TheMovieDBorgService {
        return self.theMovieDBorg
    }
    
    static func loadApplicationStateService() -> ApplicationStateService {
        return self.applicationState
    }
}