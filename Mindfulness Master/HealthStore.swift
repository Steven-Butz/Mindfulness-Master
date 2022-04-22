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


@MainActor class HealthStore: ObservableObject {

    
//  if HKHealthStore.isHealthDataAvailable() {
//            healthStore = HKHealthStore()
//  }
    
    public var authorized: Bool = false
    private let healthStore = HKHealthStore()
    @Published var avgHrv: Double?
    @Published var latestHrv: Double?
    //@Published var avgHrv: Double?
    
    init() {
        
        requestAuthorization { success in
            print(success)
            print(type(of: success))
            guard success else {
                print("Not authorized")
                return
            }
            print("succeeded authorizing")
            self.authorized = true
            
            self.hrvInit { success in
                guard success else {
                    print("Could not initialize")
                    return
                }
                print("Hrv data initialized")
                self.getAvgHRV { avg in
                    print("Updating healthstore's avg")
                    DispatchQueue.main.async {
                        self.avgHrv = avg
                        print(self.avgHrv)
                    }
                    
                    
                }
                self.getLatestHRV { latest in
                    print("Updating healthstore's latest")
                    DispatchQueue.main.async {
                        self.latestHrv = latest
                        print(self.latestHrv)
                    }
                    
                }
                //self.calculateHRV()
                //self.currentHRV()
            }
            
        }
        
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        if self.authorized {
            completion(true)
            return
        }
        let hrvType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!
        
        //guard let healthStore = self.healthStore else { return completion(false) }
        
        print("requesting authorization")
        
        healthStore.requestAuthorization(toShare: [hrvType], read: [hrvType]) { (success, error) in
            completion(success)
        }
    }
    
    func getAvgHRV(completion: @escaping (Double?) -> Void) {
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: [])
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        var hrv: Double?
        
        print("Querying avg...")
        
        let query = HKStatisticsQuery(quantityType: hrvType, quantitySamplePredicate: predicate, options: .discreteAverage) {
            ( query, avg, error ) in
            guard error == nil else {
                print("Error!", error)
                return
            }
            print("StatisticsQuery:")
            print(type(of: avg!.averageQuantity()!))
            print(avg!.averageQuantity()!)
            hrv = avg!.averageQuantity()?.doubleValue(for: .secondUnit(with: .milli))
            completion(hrv)
        }
        healthStore.execute(query)
        
    }
    
    func getLatestHRV(completion: @escaping (Double?) -> Void) {
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: [])
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) {
            ( sampleQuery, result, error ) in
            guard error == nil else {
                print("Error!", error)
                return
            }
            print("SampleQuery:")
            let r: HKDiscreteQuantitySample = result![0] as! HKDiscreteQuantitySample
            let latest: Double? = r.quantity.doubleValue(for: .secondUnit(with: .milli))
            completion(latest)
        }
        healthStore.execute(query)
    }
    
    
    
    //func calculateHRV(completion: @escaping (HKStatisticsCollection?) -> Void) {
    func calculateHRV(/*completion: @escaping (Double?) -> Void*/) -> Double? {
        
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        let anchorDate = Date.mondayAt12AM()
        let daily = DateComponents(day: 1)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: [])
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        
//        query = HKStatisticsCollectionQuery(quantityType: hrvType, quantitySamplePredicate: predicate, anchorDate: anchorDate, intervalComponents: daily)
        
        var hrv: Double?
        
        print("Querying...")
        
        // Query using Sample
        // Returns an array of results (of type HKDiscreteQuantitySample) over time period
        // Can iterate array to get values ( r.quantity )
        // Index 0 is most recent
        // Likely most useful for reading newest value
        let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (sampleQuery, results, error) in
            guard error == nil else {
                print("Error!", error)
                return
            }
            print("SampleQuery:")
            print(type(of:results!))
            print(results!)
//            let r = results![0] as! HKDiscreteQuantitySample
//            print(type(of: r))
//            print(r.quantity)
            for r in results! as! [HKDiscreteQuantitySample] {
                print(type(of: r))
                print(r.quantity)
            }

        }
        healthStore.execute(query)
        
        // Query using Quantity Series Sample
        // Returns once for EACH matching value (one completion function call for each HRV value)
        // Each value is of type HKQuantity
        // Prints oldest to newest
        let query2 = HKQuantitySeriesSampleQuery(quantityType: hrvType, predicate: predicate) {
            ( query, quantity, interval, quantitySample, done, error ) in
            guard error == nil else {
                print("Error!", error)
                return
            }
            print("QuantitySeriesSampleQuery:")
            print(type(of:quantity!))
            print(quantity!)

        }
        
        // Query using Statistics to get average over a time period
        // Returns average as an HKQuantity
        // Likely most useful for average
        let query3 = HKStatisticsQuery(quantityType: hrvType, quantitySamplePredicate: predicate, options: .discreteAverage) {
            ( query, avg, error ) in
            guard error == nil else {
                print("Error!", error)
                return
            }
            print("StatisticsQuery:")
            print(type(of: avg!.averageQuantity()!))
            print(avg!.averageQuantity()!)
        }
        
//        query!.initialResultsHandler = { query, statisticsCollection, error in
//            //completion(statisticsCollection)
//
//        }
        
        healthStore.execute(query)
        healthStore.execute(query2)
        healthStore.execute(query3)

        sleep(1)
        print("Returning!")
        return hrv

    }
    
    func currentHRV() -> Double? {
        
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return 0
    }

    // For initializing HRV values for demo / testing
    // TODO? get to only run if there are no values currently in Health Store
    func hrvInit(completion: @escaping (Bool) -> Void) {

        print("Initializing hrv values")
        let hrvType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!
        
//        for i in 6...0 {
//
//        }
        
        var testHrvQuantities: [HKQuantity] = []
        var startDates: [Date] = []
        var samples: [HKQuantitySample] = []
        
        for i in 0...6 {
            testHrvQuantities.append(HKQuantity(unit: .secondUnit(with: .milli), doubleValue: 60 + Double.random(in: 0...40)))
            startDates.append(Calendar.current.date(byAdding: .day, value: (i - 6), to: Date())!)
            samples.append(HKQuantitySample(type: hrvType, quantity: testHrvQuantities[i], start: startDates[i], end: startDates[i]))
        }
        
//        let testHrv = HKQuantity(unit: .secondUnit(with: .milli), doubleValue: 90.4)
//        let testHrv2 = HKQuantity(unit: .secondUnit(with: .milli), doubleValue: 95)
//        let testHrv3 = HKQuantity(unit: .secondUnit(with: .milli), doubleValue: 99.69)
//
//        let startDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
//        let startDate2 = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
//
//
//        let sample = HKQuantitySample(type: hrvType, quantity: testHrv, start: startDate, end: startDate)
//        let sample2 = HKQuantitySample(type: hrvType, quantity: testHrv2, start: startDate2, end: startDate2)
//        let sample3 = HKQuantitySample(type: hrvType, quantity: testHrv3, start: Date(), end: Date())
        
        for s in samples {
            healthStore.save(s) { success, error in
                if (error != nil) {
                    print("Couldn't save sample ", samples.firstIndex(of: s)!)
                    completion(success)
                }
            }
        }

        completion(true)
        
//        healthStore.save(sample) { success, error in
//            if (error != nil)
//                print("Couldn't save", error)
//            }
//        }
//        healthStore.save(sample2) { success, error in
//            if (error != nil) {
//                print("Couldn't save", error)
//            }
//        }
//        healthStore.save(sample3) { success, error in
//            if (error != nil) {
//                print("Couldn't save", error)
//            }
//            completion(success)
//        }
        

    }
    
    
}
