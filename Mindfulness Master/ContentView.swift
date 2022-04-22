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
            eventStore.sendNotification()
            eventStore.createEvent()
        } else {
            print("Hrv was higher, not scheduling")
        }
    }

    
    var body: some View {
        
        
        VStack {

            
            Spacer().frame(height: 20)
            
            if let healthStore = healthStore {
                Text("Weekly average HRV: " + String(format: "%.4f", healthStore.avgHrv ?? 0) + "ms")
                Text("Latest HRV: " + String(format: "%.4f", healthStore.latestHrv ?? 0) + "ms")
            }
            Spacer().frame(height: 20)
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
            
            Spacer()
            if let eventStore = eventStore {
                Text("Take a break at \(eventStore.recommendation)")
                    .multilineTextAlignment(.center)
                    .padding()
                
            }
            // call eventStore.createEvent()
          

            
            Spacer()
            
        // When timer fires to trigger getting latest HRV values
        }.onReceive(scheduler.$mostRecent) { _ in
            print("Received timer event")
//            print("Received timer event")
//            healthStore.addNewHrv()
//            print("sleeping")
//            sleep(5)
            
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
