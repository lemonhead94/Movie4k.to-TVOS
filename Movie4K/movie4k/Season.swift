import SwiftyJSON

struct Season {
    
    let id: Int
    let seasonNumber: Int
    let airDate: String
    let posterPath: String
    var episodes: [Episode]?
    
    static func fromJSONDictionary(json: JSON) -> Season {
        
        let id = json["id"].intValue
        let seasonNumber = json["season_number"].intValue
        let airDate = json["air_date"].stringValue
        let posterPath = "http://image.tmdb.org/t/p/w500" + json["poster_path"].stringValue
        
        return Season(id: id, seasonNumber: seasonNumber, airDate: airDate, posterPath: posterPath, episodes: nil)
    }
    
}