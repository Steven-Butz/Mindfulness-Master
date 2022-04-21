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
    
    private var healthStore: HealthStore?
    private var hrv: Double?
    
    init() {
        healthStore = HealthStore()
        
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
