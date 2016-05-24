import SwiftyJSON

struct Episode {
    
    let id: Int
    let name: String
    let episodeNumber: Int
    let airDate: String
    let overview: String
    let stillPath: String
    let rating: Double
    let director: [String]
    let writer: [String]
    let guestStars: [String]
    
    static func fromJSONDictionary(json: JSON) -> Episode {
        
        let id = json["id"].intValue
        let name = json["name"].stringValue
        let episodeNumber = json["episode_number"].intValue
        let airDate = json["air_date"].stringValue
        let overview = json["overview"].stringValue
        let stillPath = "http://image.tmdb.org/t/p/w300" + json["still_path"].stringValue
        let rating = json["vote_average"].doubleValue
        
        var directors = [String]()
        for(_, person) in json["crew"] where person["department"] == "Directing" && !directors.contains(person["name"].stringValue){
            directors.append(person["name"].stringValue)
        }
        var writers = [String]()
        for(_, person) in json["crew"] where person["department"] == "Writing" && !writers.contains(person["name"].stringValue) {
            writers.append(person["name"].stringValue)
        }
        
        var guestStars = [String]()
        for(_, person) in json["guest_stars"] where !guestStars.contains(person["name"].stringValue) {
            guestStars.append(person["name"].stringValue)
        }
        
        return Episode(id: id, name: name, episodeNumber: episodeNumber, airDate: airDate, overview: overview, stillPath: stillPath, rating: rating, director: directors, writer: writers, guestStars: guestStars)
    }
}