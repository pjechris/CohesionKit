//
//  ContentView.swift
//  Example
//
//  Created by JC on 06/05/2021.
//

import SwiftUI

struct ContentView: View {
    @StateObject var test = Test()

    var body: some View {
        List {
            ForEach(test.movies) { movie in
                VStack {
                    Text(movie.title)
                    Text(movie.openingCrawl)
                }
            }
        }
        .onAppear(perform: test.onAppear)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
