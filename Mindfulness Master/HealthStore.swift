//
//  HealthStore.swift
//  Mindfulness Master
//
//  Created by SButz on 4/20/22.
//

import Foundation
import HealthKit

extension Date {
    static func mondayAt12AM() -> Date {
        return Calendar(identifier: .iso8601).date(from: Calendar(identifier: .iso8601).dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
    }
}

class HealthStore {
    
//    private var healthStore: HKHealthStore?
    //var query: HKStatisticsCollectionQuery?
    
//    init() {
//        if HKHealthStore.isHealthDataAvailable() {
//            healthStore = HKHealthStore()
//        }
//    }
    
    init() {
        requestAuthorization()
        sleep(2)
        print("Creating HRV Data")
        createHRVData()
        sleep(2)
        print("Querying HRV Data")
        calculateHRV()
        
    }
    
    private let healthStore = HKHealthStore()
    
    func requestAuthorization() {
        
        let hrvType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!
        
        //guard let healthStore = self.healthStore else { return completion(false) }
        
        print("requesting authorization")
        
        healthStore.requestAuthorization(toShare: [hrvType], read: [hrvType]) { (success, error) in
            print(success)
        }
    }
    
    //func calculateHRV(completion: @escaping (HKStatisticsCollection?) -> Void) {
    func calculateHRV(/*completion: @escaping (Double?) -> Void*/) -> Double? {
        
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        let anchorDate = Date.mondayAt12AM()
        let daily = DateComponents(day: 1)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
//        query = HKStatisticsCollectionQuery(quantityType: hrvType, quantitySamplePredicate: predicate, anchorDate: anchorDate, intervalComponents: daily)
        
        var hrv: Double?
        
        print("Querying...")
        let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (sampleQuery, results, error) in
            guard error == nil else {
                print("Error!", error)
                return
            }
            print(results!)
            let r = results![0]
            print(type(of: r))
            

//            let r = results![0] as! HKQuantitySample
//            hrv = r.quantity.doubleValue(for: .secondUnit(with: .milli))
//            print(hrv)
            //completion(hrv)
            
        }
        
        
//        query!.initialResultsHandler = { query, statisticsCollection, error in
//            //completion(statisticsCollection)
//
//        }
        
//        if let healthStore = self.healthStore, let query = query {
//            healthStore.execute(query)
//        }
        
        healthStore.execute(query)
        sleep(3)

        print("Returning!")
        return hrv

    }

    
    func createHRVData() {

        let hrvType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!
        let testHrv = HKQuantity(unit: .secondUnit(with: .milli), doubleValue: 90.4)
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        let endDate = Date()

        let sample = HKQuantitySample(type: hrvType, quantity: testHrv, start: Date(), end: Date())
        healthStore.save(sample) { success, error in
            if (error != nil) {
                print("Couldn't save", error)
            } else {
                print("No error!", success, error)
            }
        }
        

    }
    
    
}
