//
//  ContentView.swift
//  Mindfulness Master
//
//  Created by SButz on 3/10/22.
//

import SwiftUI
import HealthKit
import EventKit
import UserNotifications

struct ContentView: View {
    
    @StateObject var eventStore: EventKitManager = EventKitManager()
    @StateObject var healthStore: HealthStore = HealthStore()
    @StateObject var scheduler: Scheduler = Scheduler()
    


//    init() {
//
//    }

    
    private func compareHrv() {
        print("Comparing Hrv")
        if healthStore.latestHrv! < healthStore.avgHrv! {
            guard scheduler.doneToday == false else {
                print("Already scheduled!")
                return
            }
            print("Scheduling event")
            scheduler.doneToday = true
            print("Hrv was lower, triggering new eventStore calls")
            eventStore.todaysEvents()
            eventStore.createEvent()
            eventStore.sendNotification()
            
        } else {
            print("Hrv was higher, not scheduling")
        }
    }

    
    var body: some View {
        
        ZStack {

            Color(red: 0.229, green: 0.531, blue: 0.996)
                .ignoresSafeArea()
            
        
        VStack {

            
            Spacer().frame(height: 40)
            
            if let healthStore = healthStore {
                
                HStack {
                    Text("Weekly Average HRV: ")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.white)
                    Text(String(format: "%.2f", healthStore.avgHrv ?? 0) + " ms")
                        .font(.title2)
                        .fontWeight(.black)
                        .foregroundColor(Color(hue: 1.0, saturation: 0.996, brightness: 0.844))
                    
                }
                
                
                Spacer().frame(height: 10)
                
                HStack {
                    Text("Latest HRV: ")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.white)
                    Text(String(format: "%.2f", healthStore.avgHrv ?? 0) + " ms")
                        .font(.title2)
                        .fontWeight(.black)
                        .foregroundColor(Color(hue: 1.0, saturation: 0.996, brightness: 0.844))
                    
                }
                .padding(.leading, 98)
                
            }
            
            Spacer().frame(height: 35)
            
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            if let eventStore = eventStore {
                if eventStore.recommendation != nil {
                    Text("Take a break at \(eventStore.recommendation!)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding()
                        .foregroundColor(Color.white)
                } else {
                    Text("No current recommendation")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding()
                        .foregroundColor(Color.white)
                }
            }
            // call eventStore.createEvent()
          

            
            Spacer()
            
        // When timer fires to trigger getting latest HRV values
        }.onReceive(scheduler.$timerFire) { _ in
            if (scheduler.initialFire) {
                scheduler.initialFire = false
                return
            }
            
            guard healthStore.authorized == true else {
                return
            }
            
            healthStore.getAvgHRV{ avg in
                healthStore.getLatestHRV { latest in
                    print("Checking if latest is new")
                    if latest != nil {
                        print("Comparing latest to avg")
                        compareHrv()
                    } else {
                        print("Latest was nil")
                    }
                }
            }
        }
        
    }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
