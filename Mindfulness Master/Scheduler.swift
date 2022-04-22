////
////  Scheduler.swift
////  Mindfulness Master
////
////  Created by SButz on 4/22/22.
////

import Foundation

class Scheduler: ObservableObject {


    let date: Date = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!
    var timer: Timer?
    var newDayTimer: Timer?
    @Published var mostRecent: Date = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!
    var doneToday: Bool = false


    init() {

//        date = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!
//        mostRecent = date
        setUpTimer()
        setUpNewDayTimer()

    }
    
    func setUpTimer() {
        print("Setting up timer")
        timer = Timer(fire: date, interval: 86400, repeats: true) { timer in
            print("Timer fired!")
            self.mostRecent = Date()
        }
        RunLoop.main.add(timer!, forMode: .common)
        print("Timer added to runloop")
    }
    
    func setUpNewDayTimer() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        let midnight = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: tomorrow!)
        timer = Timer(fire: midnight!, interval: 86400, repeats: true) { timer in
            self.doneToday = false
        }
    }


}
