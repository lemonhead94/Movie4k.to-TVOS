import SwiftyJSON
import Alamofire

struct Movie {
    
    let id: Int
    let name: String
    let overview: String
    let rating: String
    let posterPath: String
    let backdropPath: String
    var cast: [String]?
    var director: [String]?
    var writer: [String]?
    var genres: [String]?
    var runtime: String?
    var releaseYear: String?
    
    var m4kName: String?
    var m4kQuality: String?
    var m4kStartUrl: String?
    
    static func fromJSONDictionary(json: JSON) -> Movie {
        
        let id = json["id"].intValue
        let title = json["title"].stringValue
        let overview = json["overview"].stringValue
        let rating = json["vote_average"].stringValue
        let posterPath = "http://image.tmdb.org/t/p/w500" + json["poster_path"].stringValue
        let backdropPath = "http://image.tmdb.org/t/p/w1920" + json["backdrop_path"].stringValue

        return Movie(id: id, name: title, overview: overview, rating: rating, posterPath: posterPath, backdropPath: backdropPath, cast: nil, director: nil, writer: nil, genres: nil, runtime: nil, releaseYear: nil, m4kName: nil, m4kQuality: nil, m4kStartUrl: nil)
    }
    
}