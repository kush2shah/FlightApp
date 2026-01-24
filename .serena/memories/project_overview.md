# FlightApp Project Overview

## Purpose
FlightApp is a personal iOS flight tracking application built with SwiftUI that integrates multiple aviation APIs (FlightAware AeroAPI, Amadeus, Seats.aero). It serves as a learning project combining travel enthusiasm with iOS development, AI-assisted development practices, and real-world API integration.

## Key Learning Goals
- iOS Development with Swift/SwiftUI and industry-grade APIs
- AI-Assisted Development workflows
- Industry API Integration (FlightAware AeroAPI, Amadeus, Seats.aero)
- App Store Connect submission process
- Product prioritization for rapid delivery

## Main Features
- **Real-time Flight Tracking**: Live flight status, departure/arrival times, progress tracking
- **Interactive Route Maps**: Visual flight paths with waypoints using MapKit
- **Comprehensive Flight Details**: Aircraft information, airports, delays
- **Route Visualization**: Enhanced mapping with VOR/DME/NDB navigation points
- **International Waypoint Database**: 31,774+ waypoints with ARINC 424 support
- **Cash Price Comparison**: Amadeus API integration for flight pricing
- **Award Availability**: Seats.aero integration for mileage redemption options
- **Intelligent Airport Search**: Fuzzy search with smart ranking and context-aware suggestions
- **Liquid Glass UI Design**: Premium glass morphism effects with airline branding
- **Haptic Feedback**: Aggressive, experience-defining haptic patterns throughout the app

## Current Development Status
- **Current Branch**: `route-visibility`
- **Main Branch**: `main`
- Recent work includes Amadeus cash price integration, liquid glass route search, and enhanced route experience
- App is in active development with focus on comparing cash vs. award prices

## Recent Major Features
- Amadeus API service with OAuth2 authentication and caching
- FlightOffer data models for pricing information
- CashPriceCard component for displaying flight options
- UnifiedSearchBar with intelligent airport search
- Airport search service with fuzzy matching and smart ranking
- Tracked flights store for saving favorite routes
