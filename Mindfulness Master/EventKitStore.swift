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

class EventKitManager: ObservableObject {
    
    var store = EKEventStore()
    @Published var events: [EKEvent] = []
    @Published var recommendation = Date.now // Re-populate this with our recommendation to meditate
    
    init() {
        requestAccessToCalendar()
        requestNotificationsAuthorization()
        todaysEvents()
        sendNotification()
        createEvent()
    }
    
    func requestAccessToCalendar() {
        store.requestAccess(to: .event) { success, error in
            self.store = EKEventStore()
        }
    }
    
    func requestNotificationsAuthorization() {
      UNUserNotificationCenter.current()
        .requestAuthorization(options: [.alert, .sound, .badge]) { success, error in
        }
    }

    func todaysEvents() {
        print("Checking today's events!")
        let calendar = Calendar.autoupdatingCurrent
        let startDate = Date.now
        
        var onDayComponents = DateComponents()
        onDayComponents.hour = 6
        let endDate = calendar.date(byAdding: onDayComponents, to: startDate)!
        
        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        events = store.events(matching: predicate)
        print("Found \(events.count) events")
        
        var cur_event_end = Date.now
        for activity in events {
            if (activity.startDate < Date.now && activity.endDate > Date.now) { // Is this event happening now?
                print("Event ocurring now")
                cur_event_end = activity.endDate
                recommendation = activity.endDate
            } else {
                print("Event not ocurring now")
                if (cur_event_end < (activity.startDate!)) { // Do we have a sufficient gap before it starts?
                    print("Time gap found!")
                    let difference = activity.startDate.timeIntervalSince(cur_event_end) / 60
                    if (difference >= 30) {
                        print("Sufficient time gap found!")
                        recommendation = cur_event_end
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
        recommendation = cur_event_end
        return
    }
    
    func createEvent() {
        let eventStore = EKEventStore()
        let event = EKEvent(eventStore: eventStore)
        event.calendar = eventStore.defaultCalendarForNewEvents
        event.title = "Mindfulness"
        event.startDate = recommendation.addingTimeInterval(900) // add 15 min buffer
        let endDate = Date.init(timeInterval: 900, since: event.startDate)
        event.endDate = endDate
        
        do {
          try eventStore.save(event, span: .thisEvent)
        } catch {
          print("saving event error: \(error)")
        }
    }
    
    func sendNotification() {
        print("Configuring notification")
        
        let content = UNMutableNotificationContent()
        content.title = "Find your calm"
        content.body = "Meditate at \(recommendation)"
    
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let request = UNNotificationRequest(identifier: "meditate", content: content, trigger: trigger)
        let notificationCenter = UNUserNotificationCenter.current()
        
        notificationCenter.add(request) { (error) in
            if error != nil {
                print("idk, panic")
            }
        }
    }
}