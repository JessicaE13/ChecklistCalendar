//
//  ContentView.swift
//  ChecklistCalendar
//
//  Created by Jessica Estes on 4/11/26.
//

import SwiftUI

// MARK: - Main View
struct ContentView: View {
    
    var body: some View {
        ZStack {
            Color("BackgroundColor").ignoresSafeArea()
            VStack(){
                TopHeader()
                    .padding(8)
                DateHeader()
                    .padding(8)
                ItemList()
                    .padding(.top, 8)
                Spacer()
            }
            .padding()
        }
    
    }
}



struct DateHeader: View {
    
    var body: some View {
        HStack{
           
            VStack{
                Text("Sun")
                    .font(.caption)
                Text("11")
                  
            }
            Spacer()
            VStack{
                Text("Mon")
                    .font(.caption)
                Text("12")
           
            }
            Spacer()
            VStack{
                Text("Tue")
                    .font(.caption)
                Text("13")
                   
            }
            Spacer()
            VStack{
                Text("Wed")
                    .font(.caption)
                Text("14")
                
            }
            Spacer()
            VStack{
                Text("Thu")
                    .font(.caption)
                Text("15")
                
            }
            Spacer()
            VStack{
                Text("Fri")
                    .font(.caption)
                Text("16")
                
            }
            Spacer()
            VStack{
                Text("Sat")
                    .font(.caption)
                Text("17")
          
            }
         
        }
    }
}

struct ItemList: View {
    let corner: CGFloat = 16
    let fontSize: Font = .title2
    
    var body: some View {
        LazyVStack{
            HStack {
                Image(systemName: "sunrise")
                    .font(fontSize)
                    .padding(.trailing, 8)
                VStack (alignment: .leading){
                    
                    Text("Event")
                    Text("Location")
                        .font(.caption2)
                
                }
                Spacer()
                Image(systemName: "circle")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: corner)
                    .fill(Color("ItemBackgroundColor"))
            )
            .padding(.vertical, 0)
            
            
            HStack {
                Image(systemName: "calendar")
                    .font(.title)
                    .padding(.trailing, 8)
                VStack (alignment: .leading){
                    
                    Text("Event")
                    Text("Location")
                        .font(.caption2)
                    
                }
                Spacer()
                Image(systemName: "circle")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: corner)
                    .fill(Color("ItemBackgroundColor"))
            )
            .padding(.vertical, 0)
            
            HStack {
                Image(systemName: "checkmark")
                    .font(.title)
                    .padding(.trailing, 8)
                VStack (alignment: .leading){
                    
                    Text("Event")
                    Text("Location")
                        .font(.caption2)
                
                }
                Spacer()
                Image(systemName: "circle")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: corner)
                    .fill(Color("ItemBackgroundColor"))
            )
            .padding(.vertical, 0)
            
            
        }
        
    }
}

#Preview {
    ContentView()
}
