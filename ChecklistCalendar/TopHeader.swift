//
//  TopHeader.swift
//  ChecklistCalendar
//
//  Created by Jessica Estes on 5/17/26.
//
import SwiftUI

struct TopHeader: View {
    
    var body: some View {
        HStack{
            Text("Saturday")
                .font(.largeTitle)
                .bold()
        Spacer()
            Text("APR 2026 >")
                .font(.headline)
            
        }
    }
}

#Preview {
    ContentView()
}
