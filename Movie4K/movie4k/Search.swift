import SwiftyJSON

struct Search {
    
    let m4kTitle: String
    let posterPath: String?
    let url: String
    let mediaType: String?
    
    static func fromJSONDictionary(m4kTitle: String, url: String, json: JSON) -> Search {
        let posterPath = "http://image.tmdb.org/t/p/w500" + json["poster_path"].stringValue
        let mediaType = json["media_type"].stringValue
        
        return Search(m4kTitle: m4kTitle, posterPath: posterPath, url: url, mediaType: mediaType)
    }
    
}