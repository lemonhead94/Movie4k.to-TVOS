import Foundation
import SwiftyJSON

enum Provider {
    case StreamCloud
    case NowVideo
    case MovShare
    case CloudTime
    case ShareSx
}

protocol ProviderChooserDelegate: class {
    func reloadTableView()
}

class ApplicationStateService {
    
    var selectedMovie: Movie?
    var selectedSerie: TvShow?
    var serieM4kLinks: [(seasonNumber: Int, episodes: [(episodeNumber: Int, url: String)])]?
    var selectedSeason: Season?
    var selectedEpisode: Episode?
    var selectedProvider: Provider = .StreamCloud {
        didSet {
            delegate.reloadTableView()
        }
    }
    var selectedVideoUrl: String?
    
    weak var delegate: ProviderChooserDelegate!
    
}