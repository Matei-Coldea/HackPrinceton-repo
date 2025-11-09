//
//  Tab.swift
//  guardian
//
//  Created by Islom Shamsiev on 2025/11/8.
//

import SwiftUI
import Combine
import CoreLocation
import UserNotifications

struct Tab: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var notificationManager = NotificationManager()
    @State private var showPermissionSheet = false
    @State private var locationPermissionGranted = false
    @State private var notificationPermissionGranted = false
    @State private var permissionsGranted = false
    
    var body: some View {
        ZStack {
            if permissionsGranted {
                // Show main app after permissions are granted
                Tabb()
                    .transition(.opacity)
            } else {
                // Show dimmed main app while permission sheet is showing
                Tabb()
                    .opacity(showPermissionSheet ? 0.3 : 1.0)
                    .disabled(showPermissionSheet)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: permissionsGranted)
        .animation(.easeInOut(duration: 0.3), value: showPermissionSheet)
        .sheet(isPresented: $showPermissionSheet) {
            PermissionSheetView(
                locationManager: locationManager,
                notificationManager: notificationManager,
                locationPermissionGranted: $locationPermissionGranted,
                notificationPermissionGranted: $notificationPermissionGranted,
                isPresented: $showPermissionSheet,
                onPermissionsGranted: {
                    permissionsGranted = true
                    startLocationMonitoring()
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled()
        }
        .onAppear {
            checkPermissions()
        }
        .onChange(of: locationManager.authorizationStatus) { _ in
            checkPermissions()
        }
        .onChange(of: notificationManager.authorizationStatus) { _ in
            checkPermissions()
        }
    }
    
    private func checkPermissions() {
        // Only accept "Always" for location (prefer always over when in use)
        let locationStatus = locationManager.authorizationStatus
        locationPermissionGranted = locationStatus == .authorizedAlways
        
        // If user only has "When In Use", we still need to request "Always"
        if locationStatus == .authorizedWhenInUse {
            locationPermissionGranted = false
        }
        
        notificationManager.checkAuthorizationStatus { granted in
            notificationPermissionGranted = granted
            // Show sheet if either permission is not granted
            if !locationPermissionGranted || !granted {
                showPermissionSheet = true
            } else {
                // Both permissions granted, proceed to main app
                if !permissionsGranted {
                    permissionsGranted = true
                    // Start location-based notification monitoring
                    startLocationMonitoring()
                }
            }
        }
    }
    
    private func startLocationMonitoring() {
        // Send a test notification when permissions are granted
        LocationNotificationService.shared.sendTestNotification()
        print("✅ Sent test notification")
    }
}

struct PermissionSheetView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var notificationManager: NotificationManager
    @Binding var locationPermissionGranted: Bool
    @Binding var notificationPermissionGranted: Bool
    @Binding var isPresented: Bool
    var onPermissionsGranted: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Text("Enable Features")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Help us provide you with better financial insights")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)
            .padding(.bottom, 30)
            
            // Permission cards
            VStack(spacing: 16) {
                // Location Permission
                PermissionCard(
                    icon: "location.fill",
                    iconColor: .blue,
                    title: "Location Services",
                    description: "Allow location access to provide location-based financial insights and recommendations.",
                    isGranted: locationPermissionGranted,
                    action: {
                        requestLocationPermission()
                    }
                )
                
                // Notification Permission
                PermissionCard(
                    icon: "bell.fill",
                    iconColor: .orange,
                    title: "Notifications",
                    description: "Get notified about important financial updates, bill reminders, and personalized insights.",
                    isGranted: notificationPermissionGranted,
                    action: {
                        requestNotificationPermission()
                    }
                )
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Continue button
            Button {
                if locationPermissionGranted && notificationPermissionGranted {
                    isPresented = false
                    onPermissionsGranted?()
                }
            } label: {
                HStack {
                    Text("Continue")
                        .font(.callout)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(.primary)
            .disabled(!locationPermissionGranted || !notificationPermissionGranted)
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .onChange(of: locationManager.authorizationStatus) { newStatus in
            // Only accept "Always" permission
            let isGranted = newStatus == .authorizedAlways
            locationPermissionGranted = isGranted
            print("📍 Permission sheet: Location status changed to \(isGranted ? "granted (Always)" : "not granted")")
        }
        .onChange(of: notificationManager.authorizationStatus) { newStatus in
            notificationPermissionGranted = newStatus == .authorized
        }
        .onAppear {
            // Check initial status when sheet appears - only accept "Always"
            let locationStatus = locationManager.authorizationStatus
            locationPermissionGranted = locationStatus == .authorizedAlways
            print("📍 Permission sheet appeared. Location status: \(locationStatus == .authorizedAlways ? "Always" : "not Always")")
            
            notificationManager.checkAuthorizationStatus { granted in
                notificationPermissionGranted = granted
            }
        }
    }
    
    private func requestLocationPermission() {
        print("📍 Requesting location permission from permission sheet...")
        locationManager.requestPermission()
        // Manually check status after a delay to catch the update
        // The delegate method should handle it, but this ensures UI updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let isGranted = locationManager.authorizationStatus == .authorizedAlways
            locationPermissionGranted = isGranted
            print("📍 Permission sheet: Location granted = \(isGranted)")
        }
    }
    
    private func requestNotificationPermission() {
        notificationManager.requestPermission()
    }
}

struct PermissionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(iconColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if isGranted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title3)
                    }
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Action button
            if !isGranted {
                Button {
                    action()
                } label: {
                    Text("Allow")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(iconColor)
                        )
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isGranted ? Color.green.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}

// Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }
    
    func requestPermission() {
        // Ensure we're on the main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // Check current status first
            let currentStatus = self.manager.authorizationStatus
            print("📍 Current location status before request: \(self.statusString(currentStatus))")
            
            if currentStatus == .notDetermined {
                // Request "Always" permission - iOS will show "When In Use" first, then "Always"
                self.manager.requestAlwaysAuthorization()
                print("📍 Requesting Always location permission...")
                // Also check status after a brief delay to catch immediate updates
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    guard let self = self else { return }
                    let newStatus = self.manager.authorizationStatus
                    print("📍 Location status after request: \(self.statusString(newStatus))")
                    self.authorizationStatus = newStatus
                }
            } else if currentStatus == .authorizedWhenInUse {
                // User already granted "When In Use" - upgrade to "Always"
                print("📍 Upgrading from When In Use to Always...")
                self.manager.requestAlwaysAuthorization()
                // Check status after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    guard let self = self else { return }
                    let newStatus = self.manager.authorizationStatus
                    print("📍 Location status after upgrade: \(self.statusString(newStatus))")
                    self.authorizationStatus = newStatus
                }
            } else {
                // Already authorized always, denied, or restricted
                print("📍 Location status is already: \(self.statusString(currentStatus))")
                self.authorizationStatus = currentStatus
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let newStatus = manager.authorizationStatus
            // Always update the status, even if it's the same, to trigger onChange
            self.authorizationStatus = newStatus
            print("📍 Location authorization changed to: \(self.statusString(newStatus))")
        }
    }
    
    private func statusString(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorizedAlways: return "authorizedAlways"
        case .authorizedWhenInUse: return "authorizedWhenInUse"
        @unknown default: return "unknown"
        }
    }
}

// Notification Manager
class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        checkAuthorizationStatus { [weak self] _ in
            // Status will be updated in checkAuthorizationStatus
        }
    }
    
    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                // Refresh the status after requesting
                self?.checkAuthorizationStatus { _ in }
            }
        }
    }
}

#Preview {
    Tab()
}
