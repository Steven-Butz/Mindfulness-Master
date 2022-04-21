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
    @Published var recommendation = Date.now // Re-opulate this with our recommendation to meditate
    
    init() {
        requestAccessToCalendar()
        todaysEvents()
  
    }
    
    func requestAccessToCalendar() {
        store.requestAccess(to: .event) { success, error in
            self.store = EKEventStore()
        }
    }
    

    func todaysEvents() {
        print("Checking today's events!")
        let calendar = Calendar.autoupdatingCurrent
        let startDate = Date.now
        
        var onDayComponents = DateComponents()
        onDayComponents.hour = 4
        let endDate = calendar.date(byAdding: onDayComponents, to: startDate)!
        
        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        events = store.events(matching: predicate)
        print("Found \(events.count) events")
        
        var cur_event_end = Date.now
        for activity in events {
            if (activity.startDate < Date.now && activity.endDate > Date.now) { // Is this event happening now?
                print("Event ocurring now, setting cur_event_end: \(cur_event_end)")
                cur_event_end = activity.endDate
                recommendation = cur_event_end
            } else {
                print("Event not ocurring now")
                if (cur_event_end < (activity.startDate!)) { // Do we have a sufficient gap before it starts?
                    print("Time gap found!")
                    let difference = activity.startDate.timeIntervalSince(cur_event_end) / 60
                    print("Difference found: \(difference)")
                    if (difference >= 15) {
                        print("Sufficient time gap found!")
                        recommendation = cur_event_end
                        return
                    } else {
                        print("Insufficient time gap!")
                    }
                }
            }
        }
        print("No good times found!")
        recommendation = Date.now
    }
}
