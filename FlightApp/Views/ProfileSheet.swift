//
//  ProfileSheet.swift
//  FlightApp
//
//  Created by Kush Shah on 1/31/25.
//

import SwiftUI

struct ProfileSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("John Appleseed")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Gold Member")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                
                Section("Travel Stats") {
                    StatRow(icon: "airplane", title: "Flights", value: "24")
                    StatRow(icon: "map", title: "Countries", value: "8")
                    StatRow(icon: "globe", title: "Miles", value: "47,892")
                }
                
                Section("Settings") {
                    NavigationLink {
                        Text("Airlines")
                    } label: {
                        Label("Airlines", systemImage: "airplane.circle.fill")
                    }
                    
                    NavigationLink {
                        Text("Points Programs")
                    } label: {
                        Label("Points Programs", systemImage: "star.circle.fill")
                    }
                    
                    NavigationLink {
                        Text("Notifications")
                    } label: {
                        Label("Notifications", systemImage: "bell.circle.fill")
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StatRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}
