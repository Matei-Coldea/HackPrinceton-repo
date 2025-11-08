//
//  LocationTrackingService.swift
//  
//
//  Created by Annabella Rinaldi on 11/8/25.
//
import Foundation
import CoreLocation

// MARK: - Models

struct SpendingLocation: Identifiable, Codable {
    let id: UUID
    let name: String
    let latitude: Double
    let longitude: Double
    let averageSpend: Decimal
    let visitCount: Int
    let lastVisit: Date?
    let spendingCategory: String  // e.g., "retail", "food", "entertainment"
}

struct LocationAlert: Identifiable {
    let id = UUID()
    let location: SpendingLocation
    let distance: Double  // meters
    let message: String
    let riskLevel: RiskLevel
}

enum RiskLevel {
    case low, medium, high
}

// MARK: - Service Protocol

protocol LocationTrackingService {
    /// Returns nearby locations where user tends to overspend
    func getNearbyTriggerLocations(currentLocation: CLLocationCoordinate2D) async throws -> [SpendingLocation]
    
    /// Checks if user is within trigger radius of any spending locations
    func checkProximityAlerts(currentLocation: CLLocationCoordinate2D) async throws -> [LocationAlert]
    
    /// Records a visit to a location for ML analysis
    func recordLocationVisit(location: CLLocationCoordinate2D, spent: Decimal?) async throws
    
    /// Gets all tracked spending locations for the user
    func getAllSpendingLocations() async throws -> [SpendingLocation]
    
    /// Sets up geofences around trigger locations for background monitoring
    /// This enables notifications even when app is closed
    func setupGeofencing() async throws
    
    /// Called when user enters a geofenced location (triggers notification)
    func handleGeofenceEntry(location: SpendingLocation) async
}

// MARK: - Mock Implementation (for frontend testing)

final class MockLocationTrackingService: LocationTrackingService {
    
    func getNearbyTriggerLocations(currentLocation: CLLocationCoordinate2D) async throws -> [SpendingLocation] {
        // TODO: Backend will implement ML-based location analysis
        // This is mock data for frontend development
        return [
            SpendingLocation(
                id: UUID(),
                name: "Target",
                latitude: 40.3573,
                longitude: -74.6672,
                averageSpend: 45.00,
                visitCount: 23,
                lastVisit: Date().addingTimeInterval(-86400 * 3),
                spendingCategory: "retail"
            ),
            SpendingLocation(
                id: UUID(),
                name: "Starbucks",
                latitude: 40.3483,
                longitude: -74.6592,
                averageSpend: 7.50,
                visitCount: 47,
                lastVisit: Date().addingTimeInterval(-86400 * 1),
                spendingCategory: "food"
            ),
            SpendingLocation(
                id: UUID(),
                name: "Whole Foods",
                latitude: 40.3523,
                longitude: -74.6622,
                averageSpend: 62.00,
                visitCount: 15,
                lastVisit: Date().addingTimeInterval(-86400 * 7),
                spendingCategory: "groceries"
            )
        ]
    }
    
    func checkProximityAlerts(currentLocation: CLLocationCoordinate2D) async throws -> [LocationAlert] {
        // TODO: Backend will implement real-time proximity checking
        // Mock: simulate being near Target
        let nearbyLocations = try await getNearbyTriggerLocations(currentLocation: currentLocation)
        
        return nearbyLocations.compactMap { location in
            // Simulate distance calculation (this would be real in production)
            let mockDistance = Double.random(in: 50...500)
            
            if mockDistance < 200 {  // Within 200 meters
                return LocationAlert(
                    location: location,
                    distance: mockDistance,
                    message: generateAlertMessage(for: location, distance: mockDistance),
                    riskLevel: calculateRiskLevel(for: location)
                )
            }
            return nil
        }
    }
    
    func recordLocationVisit(location: CLLocationCoordinate2D, spent: Decimal?) async throws {
        // TODO: Backend will log this for ML training
        print("📍 Location visit recorded: \(location.latitude), \(location.longitude)")
        if let amount = spent {
            print("💰 Amount spent: $\(amount)")
        }
    }
    
    func getAllSpendingLocations() async throws -> [SpendingLocation] {
        // TODO: Backend will fetch from database
        return try await getNearbyTriggerLocations(currentLocation: CLLocationCoordinate2D(latitude: 0, longitude: 0))
    }
    
    func setupGeofencing() async throws {
        // TODO: Backend implements this to set up CoreLocation geofences
        // Steps:
        // 1. Get all user's trigger locations from ML model
        // 2. Create CLCircularRegion for each location (radius: 100-200m)
        // 3. Register regions with CLLocationManager
        // 4. When user enters region, handleGeofenceEntry() gets called
        
        print("📍 Geofencing setup - monitoring \(try await getAllSpendingLocations().count) locations")
    }
    
    func handleGeofenceEntry(location: SpendingLocation) async {
        // TODO: Backend calls this when geofence is triggered
        // This fires even when app is closed/phone is locked
        
        print("🚨 Geofence triggered: \(location.name)")
        
        // Send push notification
        NotificationManager.shared.sendLocationAlert(
            locationName: location.name,
            averageSpend: location.averageSpend,
            riskLevel: calculateRiskLevel(for: location),
            distance: 0
        )
        
        // Log event for ML training
        try? await recordLocationVisit(
            location: CLLocationCoordinate2D(
                latitude: location.latitude,
                longitude: location.longitude
            ),
            spent: nil
        )
    }
    
    // MARK: - Private Helpers
    
    private func generateAlertMessage(for location: SpendingLocation, distance: Double) -> String {
        let distanceText = distance < 100 ? "right next to" : "near"
        return "You're \(distanceText) \(location.name) - avg spend: $\(location.averageSpend)"
    }
    
    private func calculateRiskLevel(for location: SpendingLocation) -> RiskLevel {
        if location.averageSpend > 50 {
            return .high
        } else if location.averageSpend > 20 {
            return .medium
        } else {
            return .low
        }
    }
}
