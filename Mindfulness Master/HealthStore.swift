//
//  HealthStore.swift
//  Mindfulness Master
//
//  Created by SButz on 4/20/22.
//

import Foundation
import HealthKit


class HealthStore: ObservableObject {

    
//  if HKHealthStore.isHealthDataAvailable() {
//            healthStore = HKHealthStore()
//  }
    
    public var authorized: Bool = false
    private let healthStore = HKHealthStore()
    @Published var avgHrv: Double?
    @Published var latestHrv: Double?
    
    init() {
        
        requestAuthorization { success in
            guard success else {
                print("Not authorized")
                return
            }
            self.authorized = true

            self.hrvInit { success in
                guard success else {
                    print("Could not initialize")
                    return
                }
                print("Hrv data initialized")
                self.getAvgHRV { avg in
//                    DispatchQueue.main.async {
//                        self.avgHrv = avg
//                        print(self.avgHrv)
//                    }

                }
                self.getLatestHRV { latest in
                    guard latest != nil else {
                        return
                    }
//                    DispatchQueue.main.async {
//                        self.latestHrv = latest
//                        print(self.latestHrv)
//                    }

                }
                self.delayAdd()
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
                
        let query = HKStatisticsQuery(quantityType: hrvType, quantitySamplePredicate: predicate, options: .discreteAverage) {
            ( query, avg, error ) in
            guard error == nil else {
                print("Error!", error)
                return
            }
            hrv = avg!.averageQuantity()?.doubleValue(for: .secondUnit(with: .milli))
            DispatchQueue.main.async {
                self.avgHrv = hrv
                completion(hrv)
            }
            //self.avgHrv = hrv
            //completion(hrv)
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
            let r: HKDiscreteQuantitySample = result![0] as! HKDiscreteQuantitySample
            
            let latest: Double? = r.quantity.doubleValue(for: .secondUnit(with: .milli))
            
            // If latest HRV isn't new:
            guard latest != self.latestHrv else {
                completion(nil)
                return
            }
            
            DispatchQueue.main.async {
                self.latestHrv = latest
                completion(latest)
            }
            //completion(latest)
        }
        healthStore.execute(query)
    }
    

    // For initializing HRV values for demo / testing
    // TODO? get to only run if there are no values currently in Health Store
    func hrvInit(completion: @escaping (Bool) -> Void) {

        print("Initializing hrv values")
        let hrvType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!
        
        var testHrvQuantities: [HKQuantity] = []
        var startDates: [Date] = []
        var samples: [HKQuantitySample] = []
        
        for i in 0...6 {
            testHrvQuantities.append(HKQuantity(unit: .secondUnit(with: .milli), doubleValue: 60 + Double.random(in: 0...40)))
            startDates.append(Calendar.current.date(byAdding: .day, value: (i - 6), to: Date())!)
            samples.append(HKQuantitySample(type: hrvType, quantity: testHrvQuantities[i], start: startDates[i], end: startDates[i]))
        }
        
        for s in samples {
            healthStore.save(s) { success, error in
                if (error != nil) {
                    print("Couldn't save sample ", samples.firstIndex(of: s)!)
                    completion(success)
                }
            }
        }

        completion(true)

    }
    
    func delayAdd() {
        let soon = Calendar.current.date(byAdding: .second, value: 10, to: Date())
        let timer = Timer(fire: soon!, interval: 30, repeats: false) { timer in
            print("Data timer fired!!!!!!!!!!")
            self.addNewHrv()
        }
        RunLoop.main.add(timer, forMode: .common)
    }
    
    func addNewHrv() {
        print("Adding new Hrv")
        
        let hrvType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRateVariabilitySDNN)!
        
        let testHrvQuantity: HKQuantity = HKQuantity(unit: .secondUnit(with: .milli), doubleValue: 60)
        let startDate: Date = Date()
        let sample: HKQuantitySample = HKQuantitySample(type: hrvType, quantity: testHrvQuantity, start: startDate, end: startDate)
    
        healthStore.save(sample) { success, error in
            if (error != nil) {
                print("Couldn't save sample ")
            } else {
                print("Saved new Hrv")
            }
        }
        
    }
    
    
}
