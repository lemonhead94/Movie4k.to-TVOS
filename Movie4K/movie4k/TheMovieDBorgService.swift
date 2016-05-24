import Foundation
import Alamofire
import SwiftyJSON
import PromiseKit

enum TheMovieDBorgServiceError: ErrorType {
    case NothingFoundOnTheMovieDBorg
}

class TheMovieDBorgService {
    
    private let baseUrl: String = "http://api.themoviedb.org/3"
    private let searchUrl: String = "/search/multi?"
    private let apiKey: String!
    private var languageQuery: String = ""
    private var query: String = "&query="
    var currentLanguage: Language {
        didSet {
            switch currentLanguage {
                case .English:
                    self.languageQuery = "&language=en"
                case .German:
                    self.languageQuery = "&language=de"
            }
        }
    }
    
    private var alamoFireManager : Alamofire.Manager?
    
    init(manager: Alamofire.Manager, apiKey: String, language: Language) {
        self.alamoFireManager = manager
        self.apiKey = "api_key=" + apiKey
        self.currentLanguage = language
        switch language {
            case .English:
                self.languageQuery = "&language=en"
            case .German:
                self.languageQuery = "&language=de"
        }
    }
    
    func search(searchText: String) -> Promise<JSON> {
        
        let url = (baseUrl + searchUrl + apiKey + languageQuery + query + searchText).stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        
        return Promise { fulfill, reject in
            alamoFireManager!.request(.GET, url).responseJSON { response in
                switch response.result {
                    case .Success(let data):
                        if let results = JSON(data)["results"].first?.1 {
                            fulfill(results)
                        } else {
                            reject(TheMovieDBorgServiceError.NothingFoundOnTheMovieDBorg)
                        }
                    case .Failure(let error):
                        reject(error)
                }
            }
        }
    }
    
    func search(originalM4Ktitle: String!, m4Kurl: String, searchText: String!) -> Promise<(originalM4Ktitle: String, m4Kurl: String, data: JSON?)> {
        let url = (baseUrl + searchUrl + apiKey + languageQuery + query + searchText).stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        return Promise { fulfill, reject in
            alamoFireManager!.request(.GET, url).responseJSON { response in
                switch response.result {
                case .Success(let data):
                    if let results = JSON(data)["results"].first?.1 {
                        fulfill((originalM4Ktitle: originalM4Ktitle, m4Kurl: m4Kurl, data: results))
                    } else {
                        fulfill((originalM4Ktitle: originalM4Ktitle, m4Kurl: m4Kurl, data: nil))
                    }
                case .Failure(let error):
                    reject(error)
                }
            }
        }
    }
    
    func loadSeasonDetailsForTvShowId(id: Int) -> Promise<JSON> {
        let url = baseUrl + "/tv/" + "\(id)?" + apiKey + languageQuery
        return Promise { fulfill, reject in
            alamoFireManager!.request(.GET, url).responseJSON { response in
                switch response.result {
                    case .Success(let data):
                        fulfill(JSON(data))
                    case .Failure(let error):
                        reject(error)
                }
            }
        }
    }
    
    func loadEpisodeDetailsForTvShowId(id: Int, seasonNumber: Int) -> Promise<JSON> {
        
        let url = baseUrl + "/tv/" + "\(id)" + "/season/" + "\(seasonNumber)?" + apiKey + languageQuery
        return Promise { fulfill, reject in
            alamoFireManager!.request(.GET, url).responseJSON { response in
                switch response.result {
                    case .Success(let data):
                        fulfill(JSON(data))
                    case .Failure(let error):
                        reject(error)
                }
            }
        }
    }
    
    func loadMovieDetails(id: String) -> Promise<(runtimeMin: String, genres: [String], releaseYear: String)> {
        
        let url = (baseUrl + "/movie/\(id)?" + apiKey).stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        
        return Promise { fulfill, reject in
            alamoFireManager!.request(.GET, url).responseJSON { response in
                switch response.result {
                case .Success(let data):
                    
                    let json = JSON(data)
                    
                    let runtimeMin = "\(json["runtime"].intValue)"
                    var genres = [String]()
                    for genre in json["genres"].arrayValue {
                        genres.append(genre["name"].stringValue)
                    }
                    
                    let releaseYear: String!
                    if json["release_date"].stringValue != "" {
                        releaseYear = (json["release_date"].stringValue as NSString).substringToIndex(4)
                    } else {
                        releaseYear = ""
                    }
                    
                    fulfill((runtimeMin: runtimeMin, genres: genres, releaseYear: releaseYear))
                case .Failure(let error):
                    reject(error)
                }
            }
        }
    }
    
    func loadMovieCredits(id: String) -> Promise<(cast: [String], directors: [String], writers: [String])> {
        
        let url = (baseUrl + "/movie/\(id)/credits?" + apiKey).stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        
        return Promise { fulfill, reject in
            alamoFireManager!.request(.GET, url).responseJSON { response in
                switch response.result {
                    case .Success(let data):
                        
                        let json = JSON(data)

                        var cast = [String]()
                        for actors in json["cast"].arrayValue {
                            cast.append(actors["name"].stringValue)
                        }
                        
                        var directors = [String]()
                        var writers = [String]()
                        for member in json["crew"].arrayValue {
                            
                            if member["department"].stringValue == "Directing" {
                                directors.append(member["name"].stringValue)
                            }
                            if member["department"].stringValue == "Writing" {
                                writers.append(member["name"].stringValue)
                            }
                        }
                        
                        fulfill((cast: cast, directors: directors, writers: writers))
                    case .Failure(let error):
                        reject(error)
                }
            }
        }
    }
}