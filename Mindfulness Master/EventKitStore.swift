//
//  EventKitStore.swift
//  Mindfulness Master
//
//  Created by William Groover on 4/20/22.
//

import EventKit
import Combine
import Foundation
import SwiftUI

@MainActor
class EventKitManager: ObservableObject {
    
    var store = EKEventStore()
    var authorized: Bool = false
    @Published var events: [EKEvent] = []
    @Published var recommendation : Date? // Re-populate this with our recommendation to meditate
    
    init() {
        requestAccessToCalendar { success in
            guard success == true else {
                print("Could not authorize calendar")
                return
            }
            self.requestNotificationsAuthorization { success in
                guard success == true else {
                    print("Could not authorize notifications")
                    return
                }
                self.authorized = true
                
                self.demoEvents()
            }
//            DispatchQueue.main.async {
//                self.todaysEvents()
//                self.sendNotification()
//                self.createEvent()
//            }
            
        }
    }
    
    func requestAccessToCalendar(completion: @escaping (Bool?) -> Void) {
        if self.authorized {
            completion(true)
            return
        }
        store.requestAccess(to: .event) { success, error in
            self.store = EKEventStore()
            guard error == nil else {
                print("Could not authorize calendar")
                return
            }
            completion(success)
        }
    }
    
    func requestNotificationsAuthorization(completion: @escaping (Bool?) -> Void) {
        if self.authorized {
            completion(true)
            return
        }
        UNUserNotificationCenter.current()
        .requestAuthorization(options: [.alert, .sound, .badge]) { success, error in
            guard error == nil else {
                print("Could not authorize notifications")
                return
            }
            completion(success)
        }
    }

    func todaysEvents() {
        print("Checking today's events!")
        let calendar = Calendar.autoupdatingCurrent
        
        let midnight = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!
        
//        var onDayComponents = DateComponents()
//        onDayComponents.hour = 6
//        let endDate = calendar.date(byAdding: onDayComponents, to: startDate)!
        
        let predicate = store.predicateForEvents(withStart: Date(), end: midnight, calendars: nil)
        events = store.events(matching: predicate)
        print("Found \(events.count) events")
        
        var cur_event_end = Date.now
        for activity in events {
            if (activity.isAllDay) {
                continue
            }
            if (activity.startDate < Date.now && activity.endDate > Date.now) { // Is this event happening now?
                print("Event ocurring now")
                cur_event_end = activity.endDate
                print(cur_event_end)
                //recommendation = activity.endDate

            } else {
                print("Event not ocurring now")
                if (cur_event_end < (activity.startDate!)) { // Do we have a sufficient gap before it starts?
                    print("Time gap found!")
                    let difference = activity.startDate.timeIntervalSince(cur_event_end) / 60
                    if (difference >= 30) {
                        print("Sufficient time gap found! Updating recommendation")
                        recommendation = cur_event_end
                        print(recommendation)
                        return
                    } else {
                        print("Insufficient time gap!")
                        cur_event_end = activity.endDate
                    }
                }
                // No time gap between previous event and current event
                cur_event_end = activity.endDate
            }
        }
        print("Exited loop")
        print(cur_event_end)
        self.recommendation = cur_event_end
        print(self.recommendation)

        
        return
    }
    
    func createEvent() {
        //let eventStore = EKEventStore()
        let event = EKEvent(eventStore: store)
        event.calendar = store.defaultCalendarForNewEvents
        event.title = "Mindfulness"
        event.startDate = recommendation!.addingTimeInterval(900) // add 15 min buffer
        let endDate = Date.init(timeInterval: 900, since: event.startDate)
        event.endDate = endDate
        
        do {
          try store.save(event, span: .thisEvent)
        } catch {
          print("saving event error: \(error)")
        }
    }
    
    func sendNotification() {
        print("Configuring notification")
        
        let content = UNMutableNotificationContent()
        content.title = "Find your calm"
        content.body = "Meditate at \(recommendation!)"
        
        let interval = recommendation!.timeIntervalSince(Date.now)
    
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: "meditate", content: content, trigger: trigger)
        let notificationCenter = UNUserNotificationCenter.current()
        
        notificationCenter.add(request) { (error) in
            if error != nil {
                print("idk, panic")
            }
        }
    }
    
//    Add calendar events for demo
    func demoEvents() {
        
        let calendar = Calendar.autoupdatingCurrent
        
        let midnight = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!
        
//        var onDayComponents = DateComponents()
//        onDayComponents.hour = 6
//        let endDate = calendar.date(byAdding: onDayComponents, to: startDate)!
        
        let predicate = store.predicateForEvents(withStart: Date(), end: midnight, calendars: nil)
        let e = store.events(matching: predicate)

        if (e.isEmpty || (e.count == 1 && e[0].isAllDay)) {
            print("Adding demo events")
            
            let event = EKEvent(eventStore: store)
            event.calendar = store.defaultCalendarForNewEvents
            event.title = "Class"
            event.startDate = Date()
            event.endDate = Calendar.current.date(byAdding: .minute, value: 50, to: Date())
            
            do {
              try store.save(event, span: .thisEvent)
            } catch {
              print("saving event error: \(error)")
            }
            
            let event2 = EKEvent(eventStore: store)
            event2.calendar = store.defaultCalendarForNewEvents
            event2.title = "Work out"
            event2.startDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())
            event2.endDate = Calendar.current.date(byAdding: .hour, value: 2, to: Date())
            
            do {
              try store.save(event2, span: .thisEvent)
            } catch {
              print("saving event error: \(error)")
            }
            print("Added demo events")
        }
        

    }
    
}
