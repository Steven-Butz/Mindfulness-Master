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
    
    private let healthStore: HealthStore?
    /* @StateObject */ 
    private let eventStore: EventKitManager?
    @State private var avgHRV: Double?
    @State private var latestHRV: Double?
    
    init() {
        eventStore = EventKitManager() // Call this when we detect HRV event
    // it will compute recommendation time and send notification
      
        healthStore = HealthStore()
//        healthStore!.hrvInit { success in
//            guard success else {
//                print("Could not initialize")
//                return
//            }
////            healthStore!.avgHRV { hrv in
////                print(type(of: hrv))
////                print(hrv)
////
////            }
//
//        }
//        healthStore!.avgHRV { hrv in
//            if let hrv = hrv {
//                avgHRV = hrv
//            } else {
//                print("avgHRV is nil")
//            }
        //}
        
    }

    private func updateAvgHrv(avg: Double?) -> Void {
        if let avg = avg {
            avgHRV = avg
        }
    }
    
    private func updateLatestHrv(latest: Double?) -> Void {
        if let latest = latest {
            latestHRV = latest
        }
    }
    
    
    
    private func updateUIFromStatistics(statisticsCollection: HKStatisticsCollection) {
        
        //statisticsCollection.statistics()
        
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let endDate = Date()
        
        statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
            
//            let count = statistics.averageQuantity()?.doubleValue(for: .secondUnit(with: .milli))
//
        }
    }

    
    var body: some View {
        
        VStack {
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
            
          
            Text("Take a break at \(eventStore.recommendation)")
            
            Text("Average HRV is " + String(format: "%f", avgHRV ?? 0))
                .onAppear {
                    
                    if let healthStore = healthStore {
                        healthStore.avgHRV { hrv in
                            if let hrv = hrv {
                                print("Successful query in ContentView")
                                print(hrv)
                                updateAvgHrv(avg: hrv)
                            }

                        }
                    }
                }
            
            Text("Latest HRV is " + String(format: "%f", latestHRV ?? 0))
                .onAppear {
                    if let healthStore = healthStore {
                        healthStore.latestHRV { hrv in
                            if let hrv = hrv {
                                print("Successful latest query in CV")
                                print(hrv)
                                updateLatestHrv(latest: hrv)
                                
                            }
                        }
                    }
                }
            
            
            
            
//            Text(String(hrv!))
//                .padding()
            
            
//                .onAppear {
//                    if let healthStore = healthStore {
//                        healthStore.requestAuthorization { success in
//                            if success {
//                                healthStore.calculateHRV { statisticsCollection in
//                                    if let statisticsCollection = statisticsCollection {
//                                        //update UI
//                                        updateUIFromStatistics(statisticsCollection: statisticsCollection)
//                                    }
//
//                                }
//                            }
//                        }
//                    }
//                }
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
