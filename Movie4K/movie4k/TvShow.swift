import SwiftyJSON

struct TvShow {
    
    let id: Int
    let name: String
    let overview: String
    let rating: String
    let posterPath: String
    let backdropPath: String
    let genres: [String]
    let directors: [String]
    let totalNumberOfSeasons: Int
    let totalNumberOfEpisodes: Int
    let status: String
    var seasons: [Season]?
    
    var m4kName: String?
    var m4kStartUrl: String?
    
    static func fromJSONDictionary(json: JSON) -> TvShow {
        
        let id = json["id"].intValue
        let name = json["name"].stringValue
        let overview = json["overview"].stringValue
        let rating = json["vote_average"].stringValue
        let posterPath = "http://image.tmdb.org/t/p/w500" + json["poster_path"].stringValue
        let backdropPath = "http://image.tmdb.org/t/p/w1920" + json["backdrop_path"].stringValue
        
        var genres = [String]()
        for (_, genre) in json["genres"] {
            genres.append(genre["name"].stringValue)
        }
        
        var directors = [String]()
        for (_, director) in json["created_by"] {
            directors.append(director["name"].stringValue)
        }
        
        let totalNumberOfSeasons = json["number_of_seasons"].intValue
        let totalNumberOfEpisodes = json["number_of_episodes"].intValue
        let status = json["status"].stringValue
        
        return TvShow(id: id, name: name, overview: overview, rating: rating, posterPath: posterPath, backdropPath: backdropPath, genres: genres, directors: directors, totalNumberOfSeasons: totalNumberOfSeasons, totalNumberOfEpisodes: totalNumberOfEpisodes, status: status, seasons: nil, m4kName: nil, m4kStartUrl: nil)
    }

}