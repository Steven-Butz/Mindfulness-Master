//
//  ContentView.swift
//  Mindfulness Master
//
//  Created by SButz on 3/10/22.
//

import SwiftUI
import HealthKit
import EventKit

struct ContentView: View {
    
    @StateObject var store = EventKitManager()
    
    var body: some View {
        
        VStack {
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)

            Text("Take a break at \(store.recommendation)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
