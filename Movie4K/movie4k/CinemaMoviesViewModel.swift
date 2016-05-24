import Foundation

class CinemaMoviesViewModel {
    
    private (set) var cinemaMovies = [Movie]()
    
    func addCinemaMovie(cinemaMovie: Movie){
        self.cinemaMovies.append(cinemaMovie)
    }
    
    func removeAll() {
        self.cinemaMovies.removeAll()
    }
    
}