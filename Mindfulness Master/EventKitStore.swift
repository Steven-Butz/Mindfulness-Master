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
    @Published var recommendation : Date?
    
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

    func todaysEvents() -> Bool {
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
            
            // If already added an event on a previous run of the app
            if (activity.title == "Mindfulness") {
                print("Already added today")
                self.recommendation = activity.startDate
                return false
            }
            
            if (activity.startDate < Date.now && activity.endDate > Date.now) { // Is this event happening now?
                cur_event_end = activity.endDate
                print(cur_event_end)
                //recommendation = activity.endDate

            } else {    // Event not happening now
                if (cur_event_end < (activity.startDate!)) { // Do we have a sufficient gap before it starts?
                    let difference = activity.startDate.timeIntervalSince(cur_event_end) / 60
                    if (difference >= 30) {
                        print("Sufficient time gap found! Making recommendation")
                        recommendation = cur_event_end.addingTimeInterval(900) // add 15 min buffer
                        print(recommendation)
                        return true
                    } else {
                        cur_event_end = activity.endDate
                    }
                }
                // No time gap between previous event and current event
                cur_event_end = activity.endDate
            }
        }
        print("Gap found, making recommendation")
        self.recommendation = cur_event_end.addingTimeInterval(900) // add 15 min buffer
        print(self.recommendation)

        return true
    }
    
    func createEvent() {
        //let eventStore = EKEventStore()
        let event = EKEvent(eventStore: store)
        event.calendar = store.defaultCalendarForNewEvents
        event.title = "Mindfulness"
        event.startDate = recommendation!
        let endDate = Date.init(timeInterval: 900, since: event.startDate)
        event.endDate = endDate
        
        do {
          try store.save(event, span: .thisEvent)
        } catch {
          print("saving event error: \(error)")
        }
    }
    
    func sendNotification() {
        
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
}
