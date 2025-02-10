////
////  ExpandableFlightCard.swift
////  FlightApp
////
////  Created by Kush Shah on 2/9/25.
////
//
//import SwiftUI
//
//struct ExpandableFlightCard: View {
//    @StateObject private var viewModel = FlightViewModel()
//    @State private var isExpanded = false
//    @Binding var showBottomBar: Bool
//    
//    let flightNumber: String
//    
//    var body: some View {
//        GeometryReader { geometry in
//            VStack(spacing: 0) {
//                Spacer()
//                
//                VStack {
//                    // Pull indicator
//                    Rectangle()
//                        .fill(.white.opacity(0.2))
//                        .frame(width: 48, height: 4)
//                        .cornerRadius(2)
//                        .padding(.top, 12)
//                        .padding(.bottom, 24)
//                    
//                    // Main content
//                    VStack(spacing: 20) {
//                        // Flight header
//                        HStack {
//                            HStack(spacing: 12) {
//                                Image(systemName: "airplane")
//                                    .font(.system(size: 24))
//                                    .foregroundColor(.white.opacity(0.8))
//                                    .rotationEffect(.degrees(45))
//                                
//                                VStack(alignment: .leading) {
//                                    if let info = viewModel.flightInfo {
//                                        Text("\(info.origin.code) → \(info.destination.code)")
//                                            .font(.title3)
//                                            .fontWeight(.semibold)
//                                        Text(flightNumber)
//                                            .foregroundColor(.white.opacity(0.8))
//                                    } else {
//                                        Text("Loading...")
//                                    }
//                                }
//                            }
//                            
//                            Spacer()
//                            
//                            if let info = viewModel.flightInfo {
//                                HStack {
//                                    Image(systemName: "clock")
//                                    Text(timeRemaining(from: info.departureTime, to: info.arrivalTime))
//                                }
//                                .foregroundColor(.white.opacity(0.8))
//                            }
//                        }
//                        
//                        if isExpanded {
//                            // Quick actions grid
//                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
//                                QuickActionButton(
//                                    icon: "person.2.fill",
//                                    title: "3 friends",
//                                    color: .blue
//                                ) {
//                                    print("Friends tapped")
//                                }
//                                
//                                QuickActionButton(
//                                    icon: "globe",
//                                    title: "Route stats",
//                                    color: .orange
//                                ) {
//                                    print("Route stats tapped")
//                                }
//                                
//                                QuickActionButton(
//                                    icon: "mappin",
//                                    title: "Destination",
//                                    color: .purple
//                                ) {
//                                    print("Destination tapped")
//                                }
//                            }
//                            
//                            // Progress visualization
//                            FlightProgressView(flightInfo: viewModel.flightInfo)
//                        }
//                    }
//                    .padding(.horizontal)
//                }
//                .foregroundColor(.white)
//                .frame(maxWidth: .infinity)
//                .background(
//                    LinearGradient(
//                        gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue]),
//                        startPoint: .top,
//                        endPoint: .bottom
//                    )
//                )
//                .clipShape(RoundedRectangle(cornerRadius: 32))
//                .frame(height: isExpanded ? geometry.size.height * 0.8 : 140)
//                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
//                .gesture(
//                    DragGesture()
//                        .onEnded { value in
//                            if value.translation.height < -50 {
//                                withAnimation {
//                                    isExpanded = true
//                                    showBottomBar = false
//                                }
//                            } else if value.translation.height > 50 {
//                                withAnimation {
//                                    isExpanded = false
//                                    showBottomBar = true
//                                }
//                            }
//                        }
//                )
//                .onTapGesture {
//                    withAnimation {
//                        isExpanded.toggle()
//                        showBottomBar.toggle()
//                    }
//                }
//            }
//        }
//    }
//    
//    private func timeRemaining(from departure: Date, to arrival: Date) -> String {
//        let remaining = arrival.timeIntervalSince(departure)
//        let hours = Int(remaining) / 3600
//        let minutes = Int(remaining) / 60 % 60
//        return "\(hours)h \(minutes)m left"
//    }
//}
//
//struct QuickActionButton: View {
//    let icon: String
//    let title: String
//    let color: Color
//    let action: () -> Void
//    
//    var body: some View {
//        Button(action: action) {
//            VStack(spacing: 8) {
//                Image(systemName: icon)
//                    .font(.system(size: 24))
//                Text(title)
//                    .font(.system(size: 14, weight: .medium))
//            }
//            .foregroundColor(.white)
//            .frame(width: 100, height: 100)
//            .background(color)
//            .cornerRadius(20)
//        }
//    }
//}
//
//struct FlightProgressView: View {
//    let flightInfo: FlightInfo?
//    
//    var body: some View {
//        VStack(spacing: 12) {
//            // Progress bar
//            HStack(spacing: 0) {
//                Rectangle()
//                    .fill(.white.opacity(0.8))
//                    .frame(maxWidth: .infinity)
//                
//                Image(systemName: "airplane.circle.fill")
//                    .font(.system(size: 24))
//                    .foregroundColor(.white)
//                    .rotationEffect(.degrees(45))
//                    .padding(.horizontal, 16)
//                
//                Rectangle()
//                    .fill(.white.opacity(0.2))
//                    .frame(maxWidth: .infinity)
//            }
//            
//            // Times
//            if let info = flightInfo {
//                HStack {
//                    Text(formatTime(info.departureTime))
//                    Spacer()
//                    Text(formatTime(info.arrivalTime))
//                }
//                .font(.caption)
//                .foregroundColor(.white.opacity(0.8))
//            }
//        }
//        .padding()
//        .background(.white.opacity(0.1))
//        .clipShape(RoundedRectangle(cornerRadius: 16))
//    }
//    
//    private func formatTime(_ date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "h:mm a"
//        return formatter.string(from: date)
//    }
//}
////
////#Preview {
////    ExpandableFlightCard(flightNumber: "UA837")
////}
