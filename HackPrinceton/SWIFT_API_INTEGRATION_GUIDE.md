# Guardian Card API - Swift Integration Guide

> **Complete API documentation for integrating Guardian Card financial guardian system into iOS apps**

## 📋 Table of Contents
- [Overview](#overview)
- [Authentication](#authentication)
- [Base Configuration](#base-configuration)
- [API Endpoints](#api-endpoints)
  - [Health & System](#health--system)
  - [Transaction Scoring](#transaction-scoring)
  - [Guardian Authorization](#guardian-authorization)
  - [Rules Management](#rules-management)
  - [Analytics](#analytics)
  - [Funding Sources](#funding-sources)
  - [Geofencing](#geofencing)
  - [Location Tracking](#location-tracking)
  - [AI Agent Coach](#ai-agent-coach)
- [Data Models](#data-models)
- [Error Handling](#error-handling)
- [LLM Integration Prompts](#llm-integration-prompts)

---

## Overview

Guardian Card API provides intelligent financial guardianship features including:
- 🤖 **AI-powered transaction scoring** - ML models predict spending patterns
- 🛡️ **Smart authorization** - Rule-based transaction approval/decline
- 📊 **Advanced analytics** - Spending insights and category tracking
- 📍 **Geofencing** - Location-based spending controls
- 💳 **Stripe integration** - Real payment processing
- 🧠 **AI Agent Coach** - Conversational spending guidance

**Base URL**: `http://localhost:8000` (update for production)

---

## Authentication

All endpoints (except health checks) require JWT authentication via Supabase.

### Header Format
```
Authorization: Bearer <JWT_TOKEN>
```

### Swift Implementation

```swift
// NetworkManager.swift
class NetworkManager {
    static let shared = NetworkManager()
    private let baseURL = "http://localhost:8000"
    
    var authToken: String?
    
    private var headers: [String: String] {
        var headers = ["Content-Type": "application/json"]
        if let token = authToken {
            headers["Authorization"] = "Bearer \(token)"
        }
        return headers
    }
    
    func setAuthToken(_ token: String) {
        self.authToken = token
    }
}
```

### Authentication Flow
1. User authenticates via Supabase Auth
2. Receive JWT token from Supabase
3. Include token in all API requests
4. Backend automatically creates/fetches user from JWT claims

---

## Base Configuration

### Swift URLSession Setup

```swift
import Foundation

extension NetworkManager {
    func makeRequest<T: Codable>(
        endpoint: String,
        method: String = "GET",
        body: Codable? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.allHTTPHeaderFields = headers
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.requestFailed
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}

enum APIError: Error {
    case invalidURL
    case requestFailed
    case decodingFailed
}
```

---

## API Endpoints

### Health & System

#### GET `/` or `/health`
**Purpose**: Health check endpoint  
**Authentication**: Not required

**Response**:
```json
{
  "status": "ok",
  "message": "Guardian Card Transaction Scoring API is running",
  "endpoints": {
    "transaction_scoring": "/score-transaction",
    "location_check": "/location-check"
  }
}
```

**Swift Implementation**:
```swift
struct HealthResponse: Codable {
    let status: String
    let message: String
    let endpoints: [String: String]
}

func checkHealth() async throws -> HealthResponse {
    try await makeRequest(endpoint: "/health", method: "GET")
}
```

**LLM Prompt**:
```
Create a Swift function that checks the Guardian Card API health status. 
The endpoint is GET /health and returns a JSON with status, message, and available endpoints. 
No authentication required. Use async/await with URLSession.
```

---

### Transaction Scoring

#### POST `/score-transaction`
**Purpose**: Score a transaction using ML model to predict if it's avoidable spending  
**Authentication**: Optional (uses JWT user_id if available)

**Request Body**:
```json
{
  "user_id": "string",          // Optional if authenticated
  "amount": 15.00,              // Required: transaction amount
  "merchant_name": "Starbucks", // Required: merchant name
  "mcc": 5814,                  // Optional: merchant category code
  "timestamp": "2025-01-15T09:30:00",  // Optional: ISO string
  "channel": "offline"          // Optional: "offline" or "online"
}
```

**Response**:
```json
{
  "decision": "BLOCK",           // "ALLOW" or "BLOCK"
  "p_avoid": 0.87,              // Probability (0-1) that purchase is avoidable
  "reason": "You've already spent 150% of your fast food budget",
  "debug": {
    "p_ml": 0.75,               // ML model prediction
    "over_budget_ratio": 1.5,   // Budget utilization
    "threshold": 0.40,          // User's threshold (Saver=40%, Average=60%, Spender=75%)
    "spend_before": 10000,      // Spent in category (cents)
    "spend_after": 25000        // Would be after transaction (cents)
  }
}
```

**Swift Implementation**:
```swift
struct TransactionScoreRequest: Codable {
    let userId: String?
    let amount: Double
    let merchantName: String
    let mcc: Int?
    let timestamp: String?
    let channel: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case amount
        case merchantName = "merchant_name"
        case mcc
        case timestamp
        case channel
    }
}

struct TransactionScoreResponse: Codable {
    let decision: String
    let pAvoid: Double
    let reason: String
    let debug: DebugInfo
    
    enum CodingKeys: String, CodingKey {
        case decision
        case pAvoid = "p_avoid"
        case reason
        case debug
    }
    
    struct DebugInfo: Codable {
        let pMl: Double
        let overBudgetRatio: Double
        let threshold: Double
        let spendBefore: Int
        let spendAfter: Int
        
        enum CodingKeys: String, CodingKey {
            case pMl = "p_ml"
            case overBudgetRatio = "over_budget_ratio"
            case threshold
            case spendBefore = "spend_before"
            case spendAfter = "spend_after"
        }
    }
}

func scoreTransaction(
    amount: Double,
    merchantName: String,
    mcc: Int? = nil
) async throws -> TransactionScoreResponse {
    let request = TransactionScoreRequest(
        userId: nil,
        amount: amount,
        merchantName: merchantName,
        mcc: mcc,
        timestamp: ISO8601DateFormatter().string(from: Date()),
        channel: "offline"
    )
    
    return try await makeRequest(
        endpoint: "/score-transaction",
        method: "POST",
        body: request
    )
}
```

**LLM Prompt**:
```
Implement a Swift function to score a transaction using the Guardian Card API.

Endpoint: POST /score-transaction
Required fields: amount (Double), merchant_name (String)
Optional fields: mcc (Int), timestamp (ISO8601 String), channel (String)

The API returns:
- decision: "ALLOW" or "BLOCK"
- p_avoid: probability the purchase is avoidable (0-1)
- reason: explanation string
- debug: object with ml model details

Use async/await, Codable protocols, and proper snake_case to camelCase mapping.
Handle authentication via Bearer token in headers.
```

---

### Guardian Authorization

#### POST `/guardian/authorize`
**Purpose**: Authorize a transaction against user's guardian rules  
**Authentication**: Required

**Request Body**:
```json
{
  "amount_cents": 5000,         // Required: amount in cents
  "merchant": "Starbucks",      // Required: merchant name
  "category": "fun"             // Optional: spending category
}
```

**Response**:
```json
{
  "decision": "DECLINE",        // "APPROVE" or "DECLINE"
  "reason": "risky",           // "risky", "override", "ok"
  "message": "This looks risky based on your rule."
}
```

**Swift Implementation**:
```swift
struct AuthorizeRequest: Codable {
    let amountCents: Int
    let merchant: String
    let category: String?
    
    enum CodingKeys: String, CodingKey {
        case amountCents = "amount_cents"
        case merchant
        case category
    }
}

struct AuthorizeResponse: Codable {
    let decision: String
    let reason: String
    let message: String?
}

func authorizeTransaction(
    amountCents: Int,
    merchant: String,
    category: String? = nil
) async throws -> AuthorizeResponse {
    let request = AuthorizeRequest(
        amountCents: amountCents,
        merchant: merchant,
        category: category
    )
    
    return try await makeRequest(
        endpoint: "/guardian/authorize",
        method: "POST",
        body: request
    )
}
```

**LLM Prompt**:
```
Create a Swift function to authorize a transaction through Guardian rules.

Endpoint: POST /guardian/authorize
Authentication: Required (Bearer token)
Request: amount_cents (Int), merchant (String), category (String, optional)
Response: decision ("APPROVE" or "DECLINE"), reason (String), message (String, optional)

Use Codable with proper snake_case/camelCase conversion.
Implement async/await with error handling.
```

#### POST `/guardian/override`
**Purpose**: Create a temporary override to allow a declined transaction  
**Authentication**: Required

**Request Body**:
```json
{
  "amount_cents": 5000,
  "merchant": "Starbucks"
}
```

**Response**:
```json
{
  "status": "ok"
}
```

**Swift Implementation**:
```swift
struct OverrideRequest: Codable {
    let amountCents: Int
    let merchant: String
    
    enum CodingKeys: String, CodingKey {
        case amountCents = "amount_cents"
        case merchant
    }
}

struct StatusResponse: Codable {
    let status: String
}

func createOverride(
    amountCents: Int,
    merchant: String
) async throws -> StatusResponse {
    let request = OverrideRequest(
        amountCents: amountCents,
        merchant: merchant
    )
    
    return try await makeRequest(
        endpoint: "/guardian/override",
        method: "POST",
        body: request
    )
}
```

**LLM Prompt**:
```
Implement a Swift function to create a temporary transaction override.

Endpoint: POST /guardian/override
Purpose: Allow a previously declined transaction for 5 minutes
Request: amount_cents (Int), merchant (String)
Response: status ("ok")

This creates a temporary exception that expires in 5 minutes.
Use async/await and Codable protocols.
```

#### POST `/guardian/charge`
**Purpose**: Charge a user's funding source  
**Authentication**: Required

**Request Body**:
```json
{
  "amount_cents": 5000,
  "currency": "usd",
  "funding_source_id": 123      // Optional, uses default if not provided
}
```

**Response**:
```json
{
  "status": "charged",
  "provider": "stripe",
  "payment_intent_id": "pi_xxx",
  "processor_status": "succeeded"
}
```

**Swift Implementation**:
```swift
struct ChargeRequest: Codable {
    let amountCents: Int
    let currency: String
    let fundingSourceId: Int?
    
    enum CodingKeys: String, CodingKey {
        case amountCents = "amount_cents"
        case currency
        case fundingSourceId = "funding_source_id"
    }
}

struct ChargeResponse: Codable {
    let status: String
    let provider: String
    let paymentIntentId: String
    let processorStatus: String
    
    enum CodingKeys: String, CodingKey {
        case status
        case provider
        case paymentIntentId = "payment_intent_id"
        case processorStatus = "processor_status"
    }
}

func chargeCard(
    amountCents: Int,
    fundingSourceId: Int? = nil
) async throws -> ChargeResponse {
    let request = ChargeRequest(
        amountCents: amountCents,
        currency: "usd",
        fundingSourceId: fundingSourceId
    )
    
    return try await makeRequest(
        endpoint: "/guardian/charge",
        method: "POST",
        body: request
    )
}
```

**LLM Prompt**:
```
Create a Swift function to charge a user's payment method via Stripe.

Endpoint: POST /guardian/charge
Request: amount_cents (Int), currency (String, default "usd"), funding_source_id (Int, optional)
Response: status, provider, payment_intent_id, processor_status

Uses authenticated user's default funding source if no ID provided.
Implement with async/await and proper error handling.
```

---

### Rules Management

#### GET `/rules`
**Purpose**: List all guardian rules for authenticated user  
**Authentication**: Required

**Response**:
```json
[
  {
    "id": 1,
    "category": "fun",
    "monthly_limit_cents": 20000
  },
  {
    "id": 2,
    "category": "groceries",
    "monthly_limit_cents": 50000
  }
]
```

**Swift Implementation**:
```swift
struct GuardianRule: Codable, Identifiable {
    let id: Int
    let category: String
    let monthlyLimitCents: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case category
        case monthlyLimitCents = "monthly_limit_cents"
    }
    
    var monthlyLimitDollars: Double {
        Double(monthlyLimitCents) / 100.0
    }
}

func getRules() async throws -> [GuardianRule] {
    try await makeRequest(endpoint: "/rules", method: "GET")
}
```

**LLM Prompt**:
```
Create a Swift function to fetch guardian spending rules.

Endpoint: GET /rules
Authentication: Required
Response: Array of rules with id, category, monthly_limit_cents

Create a Codable struct with:
- Proper snake_case to camelCase mapping
- Computed property to convert cents to dollars
- Conformance to Identifiable for SwiftUI Lists

Use async/await pattern.
```

#### POST `/rules`
**Purpose**: Create or update a guardian rule  
**Authentication**: Required

**Request Body**:
```json
{
  "category": "fun",
  "monthly_limit_cents": 20000
}
```

**Response**:
```json
{
  "id": 1,
  "category": "fun",
  "monthly_limit_cents": 20000
}
```

**Swift Implementation**:
```swift
struct CreateRuleRequest: Codable {
    let category: String
    let monthlyLimitCents: Int
    
    enum CodingKeys: String, CodingKey {
        case category
        case monthlyLimitCents = "monthly_limit_cents"
    }
}

func createOrUpdateRule(
    category: String,
    monthlyLimitCents: Int
) async throws -> GuardianRule {
    let request = CreateRuleRequest(
        category: category,
        monthlyLimitCents: monthlyLimitCents
    )
    
    return try await makeRequest(
        endpoint: "/rules",
        method: "POST",
        body: request
    )
}
```

**LLM Prompt**:
```
Implement a Swift function to create or update a spending rule.

Endpoint: POST /rules
Request: category (String, lowercase), monthly_limit_cents (Int >= 0)
Response: Created/updated rule object

If rule exists for category, updates it. Otherwise creates new.
Common categories: "fun", "groceries", "entertainment", "clothing"

Use async/await and Codable protocols.
```

---

### Analytics

#### GET `/analytics/summary`
**Purpose**: Get spending summary for a time period  
**Authentication**: Required

**Query Parameters**:
- `range`: Optional - "7d", "30d" (default), "mtd", or "90d"

**Response**:
```json
{
  "range": {
    "start": "2025-01-01T00:00:00",
    "end": "2025-01-31T23:59:59"
  },
  "spend_cents": 125000,
  "charge_count": 45,
  "auth_events": 50,
  "risky_rate": 0.12,
  "override_rate": 0.04
}
```

**Swift Implementation**:
```swift
enum TimeRange: String {
    case sevenDays = "7d"
    case thirtyDays = "30d"
    case monthToDate = "mtd"
    case ninetyDays = "90d"
}

struct AnalyticsSummary: Codable {
    let range: DateRange
    let spendCents: Int
    let chargeCount: Int
    let authEvents: Int
    let riskyRate: Double
    let overrideRate: Double
    
    enum CodingKeys: String, CodingKey {
        case range
        case spendCents = "spend_cents"
        case chargeCount = "charge_count"
        case authEvents = "auth_events"
        case riskyRate = "risky_rate"
        case overrideRate = "override_rate"
    }
    
    struct DateRange: Codable {
        let start: String
        let end: String
    }
    
    var spendDollars: Double {
        Double(spendCents) / 100.0
    }
}

func getAnalyticsSummary(range: TimeRange = .thirtyDays) async throws -> AnalyticsSummary {
    try await makeRequest(
        endpoint: "/analytics/summary?range=\(range.rawValue)",
        method: "GET"
    )
}
```

**LLM Prompt**:
```
Create a Swift function to fetch spending analytics summary.

Endpoint: GET /analytics/summary?range={7d|30d|mtd|90d}
Response: 
- range: start/end dates
- spend_cents: total spending
- charge_count: number of charges
- auth_events: authorization attempts
- risky_rate: percentage flagged as risky
- override_rate: percentage manually overridden

Create an enum for time ranges and proper Codable models.
Include computed property for dollars conversion.
```

#### GET `/analytics/by-category`
**Purpose**: Get spending breakdown by category  
**Authentication**: Required

**Query Parameters**:
- `range`: Optional - "7d", "30d" (default), "mtd", or "90d"

**Response**:
```json
[
  {
    "category": "groceries",
    "spend_cents": 45000,
    "count": 12
  },
  {
    "category": "fun",
    "spend_cents": 30000,
    "count": 8
  }
]
```

**Swift Implementation**:
```swift
struct CategorySpending: Codable, Identifiable {
    let category: String
    let spendCents: Int
    let count: Int
    
    var id: String { category }
    
    enum CodingKeys: String, CodingKey {
        case category
        case spendCents = "spend_cents"
        case count
    }
    
    var spendDollars: Double {
        Double(spendCents) / 100.0
    }
}

func getSpendingByCategory(range: TimeRange = .thirtyDays) async throws -> [CategorySpending] {
    try await makeRequest(
        endpoint: "/analytics/by-category?range=\(range.rawValue)",
        method: "GET"
    )
}
```

**LLM Prompt**:
```
Implement a Swift function to get spending breakdown by category.

Endpoint: GET /analytics/by-category?range={range}
Response: Array of category spending with:
- category: name
- spend_cents: total spent
- count: number of transactions

Sorted by spend_cents descending.
Create SwiftUI-friendly model with Identifiable conformance.
```

#### GET `/analytics/timeseries`
**Purpose**: Get daily spending over time  
**Authentication**: Required

**Response**:
```json
[
  {
    "day": "2025-01-01T00:00:00",
    "spend_cents": 12000
  },
  {
    "day": "2025-01-02T00:00:00",
    "spend_cents": 8500
  }
]
```

**Swift Implementation**:
```swift
struct DailySpending: Codable, Identifiable {
    let day: String
    let spendCents: Int
    
    var id: String { day }
    
    enum CodingKeys: String, CodingKey {
        case day
        case spendCents = "spend_cents"
    }
    
    var date: Date? {
        ISO8601DateFormatter().date(from: day)
    }
    
    var spendDollars: Double {
        Double(spendCents) / 100.0
    }
}

func getSpendingTimeseries(range: TimeRange = .thirtyDays) async throws -> [DailySpending] {
    try await makeRequest(
        endpoint: "/analytics/timeseries?range=\(range.rawValue)",
        method: "GET"
    )
}
```

**LLM Prompt**:
```
Create a Swift function for daily spending time series data.

Endpoint: GET /analytics/timeseries?range={range}
Response: Array of daily spending with day (ISO8601) and spend_cents

Ordered chronologically by day.
Include Date parsing helper and dollar conversion.
Perfect for charting in SwiftUI with Swift Charts.
```

#### GET `/analytics/merchants`
**Purpose**: Get top merchants by spending  
**Authentication**: Required

**Response**:
```json
[
  {
    "merchant": "Whole Foods",
    "spend_cents": 25000,
    "count": 8
  },
  {
    "merchant": "Starbucks",
    "spend_cents": 12000,
    "count": 15
  }
]
```

**Swift Implementation**:
```swift
struct MerchantSpending: Codable, Identifiable {
    let merchant: String
    let spendCents: Int
    let count: Int
    
    var id: String { merchant }
    
    enum CodingKeys: String, CodingKey {
        case merchant
        case spendCents = "spend_cents"
        case count
    }
    
    var spendDollars: Double {
        Double(spendCents) / 100.0
    }
}

func getTopMerchants(range: TimeRange = .thirtyDays) async throws -> [MerchantSpending] {
    try await makeRequest(
        endpoint: "/analytics/merchants?range=\(range.rawValue)",
        method: "GET"
    )
}
```

**LLM Prompt**:
```
Implement a Swift function to get top merchants by spending.

Endpoint: GET /analytics/merchants?range={range}
Response: Top 10 merchants with:
- merchant: name
- spend_cents: total
- count: transaction count

Sorted by spend descending, limited to 10 results.
Use Codable and Identifiable for SwiftUI compatibility.
```

#### GET `/analytics/rules-progress`
**Purpose**: Get monthly budget progress for all rules  
**Authentication**: Required

**Response**:
```json
[
  {
    "category": "fun",
    "limit_cents": 20000,
    "spent_mtd_cents": 15000,
    "remaining_cents": 5000,
    "utilization": 0.75
  }
]
```

**Swift Implementation**:
```swift
struct RuleProgress: Codable, Identifiable {
    let category: String
    let limitCents: Int
    let spentMtdCents: Int
    let remainingCents: Int?
    let utilization: Double?
    
    var id: String { category }
    
    enum CodingKeys: String, CodingKey {
        case category
        case limitCents = "limit_cents"
        case spentMtdCents = "spent_mtd_cents"
        case remainingCents = "remaining_cents"
        case utilization
    }
    
    var limitDollars: Double { Double(limitCents) / 100.0 }
    var spentDollars: Double { Double(spentMtdCents) / 100.0 }
    var remainingDollars: Double? {
        remainingCents.map { Double($0) / 100.0 }
    }
    var utilizationPercent: Double? {
        utilization.map { $0 * 100 }
    }
}

func getRulesProgress() async throws -> [RuleProgress] {
    try await makeRequest(endpoint: "/analytics/rules-progress", method: "GET")
}
```

**LLM Prompt**:
```
Create a Swift function to track monthly budget progress.

Endpoint: GET /analytics/rules-progress
Response: Array of rule progress for current month with:
- category: rule category
- limit_cents: monthly limit
- spent_mtd_cents: spent month-to-date
- remaining_cents: remaining budget (nullable)
- utilization: fraction spent 0-1 (nullable)

Include computed properties for dollar conversions and percentage.
Great for progress bars and budget tracking UI.
```

#### POST `/analytics/assess-purchase`
**Purpose**: AI assessment of a potential purchase  
**Authentication**: Required

**Request Body**:
```json
{
  "amount_cents": 15000,
  "merchant": "Steam Games",
  "category": "fun"
}
```

**Response**:
```json
{
  "input": {
    "amount_cents": 15000,
    "merchant": "Steam Games",
    "category": "fun"
  },
  "existing_rule": {
    "category": "fun",
    "monthly_limit_cents": 20000
  },
  "metrics": {
    "spent_mtd_cents": 12000,
    "spent_7d_cents": 5000,
    "count_7d": 3,
    "limit_cents": 20000,
    "remaining_cents": 8000
  },
  "assessment": {
    "should_block": true,
    "block_reason": "large_fraction",
    "should_create_rule": false,
    "suggested_rule": null,
    "rationale": "amount (15000¢) exceeds 50% of limit (20000¢) for category 'fun'."
  }
}
```

**Swift Implementation**:
```swift
struct AssessPurchaseRequest: Codable {
    let amountCents: Int
    let merchant: String
    let category: String?
    
    enum CodingKeys: String, CodingKey {
        case amountCents = "amount_cents"
        case merchant
        case category
    }
}

struct PurchaseAssessment: Codable {
    let input: InputData
    let existingRule: RuleData?
    let metrics: MetricsData
    let assessment: AssessmentData
    
    enum CodingKeys: String, CodingKey {
        case input
        case existingRule = "existing_rule"
        case metrics
        case assessment
    }
    
    struct InputData: Codable {
        let amountCents: Int
        let merchant: String
        let category: String
        
        enum CodingKeys: String, CodingKey {
            case amountCents = "amount_cents"
            case merchant, category
        }
    }
    
    struct RuleData: Codable {
        let category: String
        let monthlyLimitCents: Int?
        
        enum CodingKeys: String, CodingKey {
            case category
            case monthlyLimitCents = "monthly_limit_cents"
        }
    }
    
    struct MetricsData: Codable {
        let spentMtdCents: Int
        let spent7dCents: Int
        let count7d: Int
        let limitCents: Int?
        let remainingCents: Int?
        
        enum CodingKeys: String, CodingKey {
            case spentMtdCents = "spent_mtd_cents"
            case spent7dCents = "spent_7d_cents"
            case count7d = "count_7d"
            case limitCents = "limit_cents"
            case remainingCents = "remaining_cents"
        }
    }
    
    struct AssessmentData: Codable {
        let shouldBlock: Bool
        let blockReason: String
        let shouldCreateRule: Bool
        let suggestedRule: SuggestedRule?
        let rationale: String
        
        enum CodingKeys: String, CodingKey {
            case shouldBlock = "should_block"
            case blockReason = "block_reason"
            case shouldCreateRule = "should_create_rule"
            case suggestedRule = "suggested_rule"
            case rationale
        }
        
        struct SuggestedRule: Codable {
            let category: String
            let monthlyLimitCents: Int
            
            enum CodingKeys: String, CodingKey {
                case category
                case monthlyLimitCents = "monthly_limit_cents"
            }
        }
    }
}

func assessPurchase(
    amountCents: Int,
    merchant: String,
    category: String? = nil
) async throws -> PurchaseAssessment {
    let request = AssessPurchaseRequest(
        amountCents: amountCents,
        merchant: merchant,
        category: category
    )
    
    return try await makeRequest(
        endpoint: "/analytics/assess-purchase",
        method: "POST",
        body: request
    )
}
```

**LLM Prompt**:
```
Create a comprehensive Swift implementation for AI purchase assessment.

Endpoint: POST /analytics/assess-purchase
Request: amount_cents, merchant, category (optional)

Response includes:
1. input: echoed back
2. existing_rule: current rule if exists
3. metrics: spending data (MTD, 7d, counts)
4. assessment: AI decision with:
   - should_block: boolean
   - block_reason: "exceeds_limit" | "large_fraction" | "none"
   - should_create_rule: suggests creating new rule
   - suggested_rule: recommended limit (nullable)
   - rationale: human-readable explanation

This is perfect for "should I buy this?" feature in UI.
Use nested Codable structs with proper snake_case conversion.
```

---

### Funding Sources

#### POST `/funding/cards/intent`
**Purpose**: Create Stripe SetupIntent for adding a card  
**Authentication**: Required

**Response**:
```json
{
  "clientSecret": "seti_xxx_secret_xxx"
}
```

**Swift Implementation**:
```swift
struct SetupIntentResponse: Codable {
    let clientSecret: String
}

func createCardSetupIntent() async throws -> SetupIntentResponse {
    try await makeRequest(
        endpoint: "/funding/cards/intent",
        method: "POST"
    )
}
```

**LLM Prompt**:
```
Implement a Swift function to create a Stripe SetupIntent for adding cards.

Endpoint: POST /funding/cards/intent
Response: clientSecret (String)

Use this clientSecret with Stripe iOS SDK to collect card details.
After card collection, call /funding/cards/confirm to save.
```

#### POST `/funding/cards/confirm`
**Purpose**: Confirm and save a payment method  
**Authentication**: Required

**Request Body**:
```json
{
  "payment_method_id": "pm_xxx",
  "label": "My Visa Card"
}
```

**Response**:
```json
{
  "status": "ok",
  "funding_source_id": 1
}
```

**Swift Implementation**:
```swift
struct ConfirmCardRequest: Codable {
    let paymentMethodId: String
    let label: String
    
    enum CodingKeys: String, CodingKey {
        case paymentMethodId = "payment_method_id"
        case label
    }
}

struct ConfirmCardResponse: Codable {
    let status: String
    let fundingSourceId: Int
    
    enum CodingKeys: String, CodingKey {
        case status
        case fundingSourceId = "funding_source_id"
    }
}

func confirmCard(
    paymentMethodId: String,
    label: String = "Card"
) async throws -> ConfirmCardResponse {
    let request = ConfirmCardRequest(
        paymentMethodId: paymentMethodId,
        label: label
    )
    
    return try await makeRequest(
        endpoint: "/funding/cards/confirm",
        method: "POST",
        body: request
    )
}
```

**LLM Prompt**:
```
Create a Swift function to confirm and save a Stripe payment method.

Endpoint: POST /funding/cards/confirm
Request: payment_method_id (from Stripe SDK), label (String)
Response: status, funding_source_id

Call after successfully collecting card via Stripe SDK.
First card added becomes default funding source automatically.
```

#### GET `/funding/default`
**Purpose**: Get user's default funding source  
**Authentication**: Required

**Response**:
```json
{
  "id": 1,
  "label": "My Visa Card",
  "provider": "stripe",
  "type": "card",
  "external_id": "pm_xxx",
  "created_at": "2025-01-15T10:00:00"
}
```

**Swift Implementation**:
```swift
struct FundingSource: Codable, Identifiable {
    let id: Int
    let label: String
    let provider: String
    let type: String
    let externalId: String
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, label, provider, type
        case externalId = "external_id"
        case createdAt = "created_at"
    }
    
    var isStripe: Bool { provider == "stripe" }
    var isMock: Bool { provider == "mock" }
}

func getDefaultFundingSource() async throws -> FundingSource {
    try await makeRequest(endpoint: "/funding/default", method: "GET")
}
```

**LLM Prompt**:
```
Implement a Swift function to fetch the default payment method.

Endpoint: GET /funding/default
Response: FundingSource with id, label, provider, type, external_id, created_at

Returns 404 if no funding source exists.
Provider can be "stripe" or "mock" (for testing).
```

---

### Geofencing

#### POST `/rules/geofence`
**Purpose**: Create a location-based spending rule  
**Authentication**: Required

**Request Body**:
```json
{
  "name": "Shopping Mall",
  "latitude": 40.7128,
  "longitude": -74.0060,
  "radius_m": 500,
  "category": "fun",
  "policy": "block"
}
```

**Response**:
```json
{
  "id": 1,
  "status": "created"
}
```

**Swift Implementation**:
```swift
import CoreLocation

struct CreateGeofenceRequest: Codable {
    let name: String
    let latitude: Double
    let longitude: Double
    let radiusM: Int
    let category: String?
    let policy: String
    
    enum CodingKeys: String, CodingKey {
        case name, latitude, longitude
        case radiusM = "radius_m"
        case category, policy
    }
}

struct CreateGeofenceResponse: Codable {
    let id: Int
    let status: String
}

enum GeofencePolicy: String {
    case block
    case warn
}

func createGeofence(
    name: String,
    coordinate: CLLocationCoordinate2D,
    radiusMeters: Int,
    category: String? = nil,
    policy: GeofencePolicy = .block
) async throws -> CreateGeofenceResponse {
    let request = CreateGeofenceRequest(
        name: name,
        latitude: coordinate.latitude,
        longitude: coordinate.longitude,
        radiusM: radiusMeters,
        category: category?.lowercased(),
        policy: policy.rawValue
    )
    
    return try await makeRequest(
        endpoint: "/rules/geofence",
        method: "POST",
        body: request
    )
}
```

**LLM Prompt**:
```
Create a Swift function to set up geofence spending rules.

Endpoint: POST /rules/geofence
Request:
- name: geofence label
- latitude, longitude: center coordinates
- radius_m: radius in meters
- category: optional spending category filter
- policy: "block" or "warn"

Use CoreLocation CLLocationCoordinate2D for coordinates.
"block" declines transactions, "warn" allows but flags them.
Category filter applies geofence only to that spending type.
```

#### GET `/rules/geofence`
**Purpose**: List all geofences  
**Authentication**: Required

**Response**:
```json
[
  {
    "id": 1,
    "name": "Shopping Mall",
    "latitude": 40.7128,
    "longitude": -74.0060,
    "radius_m": 500,
    "category": "fun",
    "policy": "block"
  }
]
```

**Swift Implementation**:
```swift
struct Geofence: Codable, Identifiable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let radiusM: Int
    let category: String?
    let policy: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude
        case radiusM = "radius_m"
        case category, policy
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var radiusMeters: CLLocationDistance {
        CLLocationDistance(radiusM)
    }
}

func getGeofences() async throws -> [Geofence] {
    try await makeRequest(endpoint: "/rules/geofence", method: "GET")
}
```

**LLM Prompt**:
```
Implement a Swift function to fetch all geofence rules.

Endpoint: GET /rules/geofence
Response: Array of geofences

Add computed properties to convert:
- lat/lon to CLLocationCoordinate2D
- radius_m to CLLocationDistance

Perfect for displaying on MapKit views.
```

#### DELETE `/rules/geofence/{id}`
**Purpose**: Delete a geofence rule  
**Authentication**: Required

**Response**:
```json
{
  "status": "deleted"
}
```

**Swift Implementation**:
```swift
func deleteGeofence(id: Int) async throws -> StatusResponse {
    try await makeRequest(
        endpoint: "/rules/geofence/\(id)",
        method: "DELETE"
    )
}
```

**LLM Prompt**:
```
Create a Swift function to delete a geofence rule.

Endpoint: DELETE /rules/geofence/{id}
Response: status ("deleted")
Returns 404 if geofence not found or doesn't belong to user.
```

---

### Location Tracking

#### POST `/location/update`
**Purpose**: Update user's current location  
**Authentication**: Required

**Request Body**:
```json
{
  "latitude": 40.7128,
  "longitude": -74.0060,
  "accuracy_m": 10.5
}
```

**Response**:
```json
{
  "status": "ok",
  "ts": "2025-01-15T10:30:00"
}
```

**Swift Implementation**:
```swift
struct LocationUpdate: Codable {
    let latitude: Double
    let longitude: Double
    let accuracyM: Double?
    
    enum CodingKeys: String, CodingKey {
        case latitude, longitude
        case accuracyM = "accuracy_m"
    }
}

struct LocationUpdateResponse: Codable {
    let status: String
    let ts: String
}

func updateLocation(
    coordinate: CLLocationCoordinate2D,
    accuracy: CLLocationAccuracy? = nil
) async throws -> LocationUpdateResponse {
    let request = LocationUpdate(
        latitude: coordinate.latitude,
        longitude: coordinate.longitude,
        accuracyM: accuracy
    )
    
    return try await makeRequest(
        endpoint: "/location/update",
        method: "POST",
        body: request
    )
}
```

**LLM Prompt**:
```
Implement Swift location tracking with CoreLocation.

Endpoint: POST /location/update
Request: latitude, longitude, accuracy_m (optional)
Response: status, timestamp

Integrate with CLLocationManager to send updates.
Store pings for behavioral analysis (e.g., loitering detection).
Consider batching updates to reduce API calls.
```

#### GET/POST `/location-check`
**Purpose**: Check if location triggers geo-guardian alerts  
**Authentication**: Optional

**Query Params (GET) or Body (POST)**:
```json
{
  "user_id": "test_user",
  "lat": 40.7128,
  "lon": -74.0060
}
```

**Response (OK)**:
```json
{
  "decision": "ok"
}
```

**Response (BLOCKED)**:
```json
{
  "decision": "block",
  "stats": {
    "recent_stationary_pings_near_restaurants": 5,
    "window_minutes": 15
  },
  "notifications": [
    {
      "type": "behavior",
      "code": "RESTAURANT_STATIONARY_TOO_LONG",
      "severity": "warning"
    }
  ]
}
```

**Swift Implementation**:
```swift
struct LocationCheckRequest: Codable {
    let userId: String?
    let lat: Double
    let lon: Double
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case lat, lon
    }
}

struct LocationCheckResponse: Codable {
    let decision: String
    let stats: Stats?
    let notifications: [Notification]?
    
    struct Stats: Codable {
        let recentStationaryPingsNearRestaurants: Int?
        let windowMinutes: Int?
        
        enum CodingKeys: String, CodingKey {
            case recentStationaryPingsNearRestaurants = "recent_stationary_pings_near_restaurants"
            case windowMinutes = "window_minutes"
        }
    }
    
    struct Notification: Codable {
        let type: String
        let code: String
        let severity: String
    }
    
    var isBlocked: Bool { decision == "block" }
    var isOK: Bool { decision == "ok" }
}

func checkLocation(
    coordinate: CLLocationCoordinate2D
) async throws -> LocationCheckResponse {
    let request = LocationCheckRequest(
        userId: nil,
        lat: coordinate.latitude,
        lon: coordinate.longitude
    )
    
    return try await makeRequest(
        endpoint: "/location-check",
        method: "POST",
        body: request
    )
}
```

**LLM Prompt**:
```
Create a Swift function for geo-guardian location checking.

Endpoint: GET or POST /location-check
Request: lat, lon (user_id optional if authenticated)
Response: 
- decision: "ok" or "block"
- stats: stationary ping counts (if blocked)
- notifications: warning details

Detects suspicious patterns like:
- Loitering near restaurants
- Stationary too long at merchant locations
- Helps prevent impulsive spending

Returns "ok" if no concerns, "block" with details if flagged.
```

---

### AI Agent Coach

#### POST `/agent/coach`
**Purpose**: Get AI-powered spending guidance  
**Authentication**: Required

**Request Body**:
```json
{
  "amount_cents": 15000,
  "merchant": "Steam Games",
  "category": "fun"
}
```

**Response**:
```json
{
  "result": "BLOCK",
  "message": "I'd advise against this purchase. You've already spent $120 of your $200 monthly 'fun' budget, and this $150 purchase would put you over. Consider waiting until next month or reducing your spending goal."
}
```

**Swift Implementation**:
```swift
struct AgentCoachRequest: Codable {
    let amountCents: Int
    let merchant: String
    let category: String?
    
    enum CodingKeys: String, CodingKey {
        case amountCents = "amount_cents"
        case merchant
        case category
    }
}

struct AgentCoachResponse: Codable {
    let result: String
    let message: String
    
    var shouldProceed: Bool {
        result == "ALLOW" || result == "APPROVE"
    }
    
    var shouldBlock: Bool {
        result == "BLOCK" || result == "DECLINE"
    }
}

func getCoachAdvice(
    amountCents: Int,
    merchant: String,
    category: String? = nil
) async throws -> AgentCoachResponse {
    let request = AgentCoachRequest(
        amountCents: amountCents,
        merchant: merchant,
        category: category
    )
    
    return try await makeRequest(
        endpoint: "/agent/coach",
        method: "POST",
        body: request
    )
}
```

**LLM Prompt**:
```
Implement a Swift function for AI spending coach.

Endpoint: POST /agent/coach
Request: amount_cents, merchant, category (optional)
Response:
- result: "ALLOW" or "BLOCK"
- message: personalized guidance

The AI agent:
1. Analyzes spending patterns
2. Checks rules and budgets
3. Provides conversational advice
4. Considers user's financial goals

Perfect for "Ask my coach" feature before purchases.
Returns human-friendly explanations, not just yes/no.
```

---

## Data Models

### Common Swift Models

```swift
// MARK: - Common Response Types

struct StatusResponse: Codable {
    let status: String
}

struct ErrorResponse: Codable {
    let error: String
    let message: String?
}

// MARK: - Money Helpers

extension Int {
    var asDollars: Double {
        Double(self) / 100.0
    }
}

extension Double {
    var asCents: Int {
        Int(self * 100)
    }
}

// MARK: - Date Helpers

extension ISO8601DateFormatter {
    static let apiFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
```

### Category Constants

```swift
enum SpendingCategory: String, CaseIterable {
    case rentBills = "rent_bills"
    case groceries = "groceries"
    case fastFood = "fast_food"
    case alcohol = "alcohol"
    case clothing = "clothing"
    case electronics = "electronics"
    case pharmacyHealth = "pharmacy_health"
    case transport = "transport"
    case subscription = "subscription"
    case miscOnline = "misc_online"
    case fun = "fun"
    case entertainment = "entertainment"
    
    var displayName: String {
        switch self {
        case .rentBills: return "Rent & Bills"
        case .groceries: return "Groceries"
        case .fastFood: return "Fast Food"
        case .alcohol: return "Alcohol"
        case .clothing: return "Clothing"
        case .electronics: return "Electronics"
        case .pharmacyHealth: return "Pharmacy & Health"
        case .transport: return "Transport"
        case .subscription: return "Subscriptions"
        case .miscOnline: return "Online Shopping"
        case .fun: return "Fun"
        case .entertainment: return "Entertainment"
        }
    }
    
    var icon: String {
        switch self {
        case .rentBills: return "house.fill"
        case .groceries: return "cart.fill"
        case .fastFood: return "fork.knife"
        case .alcohol: return "wineglass.fill"
        case .clothing: return "tshirt.fill"
        case .electronics: return "laptopcomputer"
        case .pharmacyHealth: return "cross.case.fill"
        case .transport: return "car.fill"
        case .subscription: return "repeat"
        case .miscOnline: return "bag.fill"
        case .fun: return "gamecontroller.fill"
        case .entertainment: return "tv.fill"
        }
    }
}
```

---

## Error Handling

### Comprehensive Error Handling

```swift
enum GuardianAPIError: LocalizedError {
    case invalidURL
    case unauthorized
    case notFound
    case serverError(Int)
    case decodingFailed(Error)
    case networkError(Error)
    case missingAuthToken
    case validationError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .unauthorized:
            return "Authentication required. Please sign in."
        case .notFound:
            return "Resource not found"
        case .serverError(let code):
            return "Server error: \(code)"
        case .decodingFailed(let error):
            return "Failed to parse response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .missingAuthToken:
            return "Authentication token missing"
        case .validationError(let message):
            return "Validation error: \(message)"
        }
    }
}

// Enhanced makeRequest with error handling
extension NetworkManager {
    func makeRequest<T: Codable>(
        endpoint: String,
        method: String = "GET",
        body: Codable? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw GuardianAPIError.invalidURL
        }
        
        guard authToken != nil || endpoint == "/health" else {
            throw GuardianAPIError.missingAuthToken
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.allHTTPHeaderFields = headers
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GuardianAPIError.networkError(URLError(.badServerResponse))
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    return try JSONDecoder().decode(T.self, from: data)
                } catch {
                    throw GuardianAPIError.decodingFailed(error)
                }
            case 401:
                throw GuardianAPIError.unauthorized
            case 404:
                throw GuardianAPIError.notFound
            case 400...499:
                // Try to decode error message
                if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                    throw GuardianAPIError.validationError(errorResponse.error)
                }
                throw GuardianAPIError.serverError(httpResponse.statusCode)
            default:
                throw GuardianAPIError.serverError(httpResponse.statusCode)
            }
        } catch let error as GuardianAPIError {
            throw error
        } catch {
            throw GuardianAPIError.networkError(error)
        }
    }
}
```

### SwiftUI Error Display

```swift
struct ErrorAlertModifier: ViewModifier {
    @Binding var error: GuardianAPIError?
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK") {
                    error = nil
                }
            } message: {
                Text(error?.errorDescription ?? "Unknown error occurred")
            }
    }
}

extension View {
    func guardianErrorAlert(_ error: Binding<GuardianAPIError?>) -> some View {
        modifier(ErrorAlertModifier(error: error))
    }
}

// Usage in View
struct ContentView: View {
    @State private var error: GuardianAPIError?
    
    var body: some View {
        VStack {
            // Your content
        }
        .guardianErrorAlert($error)
        .task {
            do {
                let summary = try await NetworkManager.shared.getAnalyticsSummary()
            } catch let error as GuardianAPIError {
                self.error = error
            } catch {
                self.error = .networkError(error)
            }
        }
    }
}
```

---

## LLM Integration Prompts

### Complete Integration Prompt

```
I need to integrate the Guardian Card API into my iOS app using Swift and SwiftUI.

API Base URL: http://localhost:8000
Authentication: JWT Bearer token from Supabase

Please create a complete NetworkManager class with the following features:

1. Core Endpoints:
   - Transaction scoring: POST /score-transaction
   - Authorization: POST /guardian/authorize
   - Rules management: GET/POST /rules
   - Analytics: GET /analytics/summary, /analytics/by-category, /analytics/timeseries
   - Geofencing: GET/POST/DELETE /rules/geofence
   - AI Coach: POST /agent/coach

2. Requirements:
   - Use async/await with URLSession
   - Proper Codable models with snake_case ↔ camelCase conversion
   - Bearer token authentication
   - Comprehensive error handling
   - Money helpers (cents ↔ dollars)
   - SwiftUI-friendly (Identifiable, ObservableObject)

3. Models needed:
   - TransactionScoreRequest/Response
   - GuardianRule
   - AnalyticsSummary
   - CategorySpending
   - Geofence with CLLocationCoordinate2D
   - AgentCoachResponse

4. Helper utilities:
   - SpendingCategory enum with SF Symbols
   - Currency conversion (cents/dollars)
   - ISO8601 date parsing
   - Error alert modifier for SwiftUI

Please generate production-ready code with proper error handling and documentation.
```

### Specific Feature Prompts

#### Transaction Scoring UI
```
Create a SwiftUI view that shows transaction scoring before purchase.

Features:
- Amount input (TextField with currency formatting)
- Merchant name input
- Category picker
- "Check Purchase" button
- Result card showing:
  - Decision (ALLOW/BLOCK) with color coding
  - Avoidability probability as progress bar
  - Reason text
  - Debug details in expandable section

Use Guardian Card API: POST /score-transaction
Show loading state during API call.
Use proper error handling with alerts.
```

#### Budget Progress Dashboard
```
Create a SwiftUI dashboard showing budget progress.

Fetch from: GET /analytics/rules-progress

Display:
- List of categories with:
  - Category icon (SF Symbols)
  - Progress bar (spent vs limit)
  - Dollar amounts and percentage
  - Color: green (<70%), yellow (70-90%), red (>90%)
- Pull to refresh
- Empty state if no rules

Use SwiftUI List with custom cells.
Implement with async/await and proper loading states.
```

#### Geofence Map View
```
Create a geofence management view with MapKit.

Features:
1. Map showing all geofences as circle overlays
2. User's current location
3. Add geofence:
   - Long press on map
   - Sheet with: name, radius slider, category picker, policy (block/warn)
   - POST /rules/geofence
4. Delete geofence (swipe action)
   - DELETE /rules/geofence/{id}

Use CLLocationManager for current location.
Fetch geofences: GET /rules/geofence
Convert API lat/lon to CLLocationCoordinate2D.
```

#### AI Coach Chat Interface
```
Create a chat-like interface for spending advice.

UI:
- Message bubbles (user questions, AI responses)
- Input field for amount and merchant
- Quick action buttons for common queries
- Loading indicator while AI thinks

API: POST /agent/coach
Request: amount_cents, merchant, category
Response: result (ALLOW/BLOCK), message (conversational)

Style AI messages with color based on result:
- Green for ALLOW with encouraging message
- Red for BLOCK with helpful alternatives
- Use SF Symbols for emoji-like reactions
```

#### Spending Analytics Charts
```
Create analytics dashboard with Swift Charts (iOS 16+).

Charts needed:
1. Spending over time (line chart)
   - Data: GET /analytics/timeseries
   - X: dates, Y: daily spend
   
2. Category breakdown (pie/donut chart)
   - Data: GET /analytics/by-category
   - Segments by category with colors
   
3. Top merchants (bar chart)
   - Data: GET /analytics/merchants
   - Horizontal bars sorted by spend

Add:
- Time range picker (7d, 30d, MTD, 90d)
- Pull to refresh
- Smooth animations
- Interactive tooltips
```

#### Stripe Card Setup Flow
```
Implement Stripe card addition with native iOS UI.

Flow:
1. Call POST /funding/cards/intent to get clientSecret
2. Present Stripe CardFormView (using Stripe iOS SDK)
3. On success, get payment_method_id
4. Call POST /funding/cards/confirm with PM ID
5. Update UI to show new funding source

Use Stripe iOS SDK: https://stripe.com/docs/payments/setup-intents/ios
Handle errors gracefully with user-friendly messages.
Show success animation on completion.
```

---

## Testing Guide

### Manual Testing with Postman/Insomnia

Import this collection to test all endpoints:

```json
{
  "name": "Guardian Card API",
  "auth": {
    "type": "bearer",
    "bearer": "{{JWT_TOKEN}}"
  },
  "variable": {
    "baseUrl": "http://localhost:8000"
  }
}
```

### Swift Testing Examples

```swift
import XCTest

class GuardianAPITests: XCTestCase {
    var networkManager: NetworkManager!
    
    override func setUp() {
        super.setUp()
        networkManager = NetworkManager.shared
        networkManager.baseURL = "http://localhost:8000"
        networkManager.setAuthToken("test_token_here")
    }
    
    func testHealthCheck() async throws {
        let health: HealthResponse = try await networkManager.makeRequest(
            endpoint: "/health",
            method: "GET"
        )
        XCTAssertEqual(health.status, "ok")
    }
    
    func testTransactionScoring() async throws {
        let response: TransactionScoreResponse = try await networkManager.scoreTransaction(
            amount: 15.0,
            merchantName: "Starbucks",
            mcc: 5814
        )
        XCTAssertTrue(["ALLOW", "BLOCK"].contains(response.decision))
        XCTAssertTrue(response.pAvoid >= 0 && response.pAvoid <= 1)
    }
    
    func testGetRules() async throws {
        let rules: [GuardianRule] = try await networkManager.getRules()
        // Should not throw
        XCTAssertNotNil(rules)
    }
}
```

---

## Best Practices

### 1. **Authentication Management**
```swift
// Store token securely in Keychain
import Security

class KeychainManager {
    static func saveToken(_ token: String) {
        let data = token.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "guardianAuthToken",
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func loadToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "guardianAuthToken",
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
```

### 2. **Request Caching**
```swift
// Cache analytics data to reduce API calls
actor AnalyticsCache {
    private var cache: [String: (data: Any, timestamp: Date)] = [:]
    private let cacheDuration: TimeInterval = 300 // 5 minutes
    
    func get<T>(_ key: String) -> T? {
        guard let cached = cache[key],
              Date().timeIntervalSince(cached.timestamp) < cacheDuration else {
            return nil
        }
        return cached.data as? T
    }
    
    func set<T>(_ key: String, value: T) {
        cache[key] = (value, Date())
    }
}
```

### 3. **Offline Support**
```swift
// Queue requests when offline
class OfflineQueue {
    private var queue: [PendingRequest] = []
    
    struct PendingRequest: Codable {
        let endpoint: String
        let method: String
        let body: Data?
        let timestamp: Date
    }
    
    func add(_ request: PendingRequest) {
        queue.append(request)
        saveToUserDefaults()
    }
    
    func processQueue() async {
        for request in queue {
            // Retry requests
        }
    }
}
```

### 4. **Rate Limiting**
```swift
// Prevent API spam
actor RateLimiter {
    private var lastRequest: [String: Date] = [:]
    private let minInterval: TimeInterval = 1.0
    
    func canMakeRequest(to endpoint: String) -> Bool {
        guard let last = lastRequest[endpoint] else { return true }
        return Date().timeIntervalSince(last) >= minInterval
    }
    
    func recordRequest(to endpoint: String) {
        lastRequest[endpoint] = Date()
    }
}
```

---

## Production Checklist

- [ ] Update base URL to production server
- [ ] Implement Keychain storage for auth tokens
- [ ] Add request caching for analytics
- [ ] Implement retry logic for failed requests
- [ ] Add offline queue for critical actions
- [ ] Set up error logging (Sentry, Firebase)
- [ ] Implement rate limiting
- [ ] Add request/response logging (debug only)
- [ ] Test with various network conditions
- [ ] Handle token expiration and refresh
- [ ] Add request timeouts
- [ ] Implement proper SSL pinning
- [ ] Add analytics tracking
- [ ] Test with real Stripe card flows
- [ ] Implement biometric auth for sensitive operations

---

## Support & Resources

- **API Documentation**: See `API_EXAMPLES.md`
- **Data Flow**: See `DATA_FLOW_EXPLAINED.md`
- **Stripe iOS SDK**: https://stripe.com/docs/payments/setup-intents/ios
- **SwiftUI**: https://developer.apple.com/xcode/swiftui/
- **Async/Await**: https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html

---

**Built for HackPrinceton** 🚀

*Last updated: January 2025*

