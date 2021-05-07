//
//  ExampleApp.swift
//  Example
//
//  Created by JC on 06/05/2021.
//

import SwiftUI
import CohesionKit
import Combine

struct Movie: Identifiable, Decodable {
    var id: Int { episodeId }
    
    let title: String
    let episodeId: Int
    let openingCrawl: String
}

struct FilmPayload: Decodable {
    let results: [Movie]
}

class MovieRepository {
    let identityMap = IdentityMap()
    
    func findMovies() -> AnyPublisher<[Movie], Never> {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        // AnyPublisher<[AnyPublisher<Movie>]>
        // AnyPublisher<Movie>1.CombineLatest(AnyPublisher(movie2))
        // AnyPublisher<[AnyPublisher<T>]>
        // AnyPublisher<[T]>
        let publishers = [identityMap.publisher(Movie.self, id: 2)!]
        let i = Publishers.MergeMany(publishers)
//            .flatMap { $0 }
            .eraseToAnyPublisher()
        
        return URLSession
            .shared
            .dataTaskPublisher(for: URLRequest(url: URL(string: "https://swapi.dev/api/films")!))
            .map(\.data)
            .decode(type: FilmPayload.self, decoder: decoder)
            .map(\.results)
            .replaceError(with: [])
            .flatMap { [identityMap] films in
//                let publishers = films
//                    .map { identityMap.update($0) }
//                    .eraseToAnyPublisher()
                
                return Publishers
                    .MergeMany(films.map { identityMap.update($0) })
                    .collect()
            }
            .eraseToAnyPublisher()
    }
}

class Test: ObservableObject {
    @Published var movies: [Movie] = []
    var repository = MovieRepository()
    
    func onAppear() {
        repository
            .findMovies()
            .receive(on: RunLoop.main)
            .assign(to: &$movies)
    }
    
    func clean() {
        movies.removeAll()
    }
}

@main
struct ExampleApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
