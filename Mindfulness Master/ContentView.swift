//
//  ContentView.swift
//  Mindfulness Master
//
//  Created by SButz on 3/10/22.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        
        VStack {
            

            
                
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                
            
            Text("Hello, world!")
                .padding()
            
            
            
            
            
            
        }
    
    
    
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
