#!/usr/bin/env python3
"""
Test script for merged HackPrinceton features.

Tests the new ML-based transaction scoring and geo-guardian endpoints.
Run this after starting the Flask server to verify the merge was successful.

Usage:
    python test_merged_features.py
"""

import requests
import json
from datetime import datetime

BASE_URL = "http://localhost:5000"


def print_result(test_name, response):
    """Print test results in a formatted way."""
    print(f"\n{'='*60}")
    print(f"TEST: {test_name}")
    print(f"{'='*60}")
    print(f"Status Code: {response.status_code}")
    print(f"Response:")
    print(json.dumps(response.json(), indent=2))


def test_health_check():
    """Test health check endpoint."""
    response = requests.get(f"{BASE_URL}/health")
    print_result("Health Check", response)
    return response.status_code == 200


def test_transaction_scoring_allow():
    """Test transaction scoring - should ALLOW."""
    data = {
        "user_id": "u1",
        "amount": 15.0,
        "merchant_name": "Whole Foods",
        "mcc": 5411,
        "timestamp": datetime.utcnow().isoformat(),
        "channel": "offline"
    }
    response = requests.post(f"{BASE_URL}/score-transaction", json=data)
    print_result("Transaction Scoring (Groceries - Should ALLOW)", response)
    return response.status_code == 200


def test_transaction_scoring_block():
    """Test transaction scoring - might BLOCK."""
    data = {
        "user_id": "u1",
        "amount": 150.0,
        "merchant_name": "Total Wine",
        "mcc": 5921,
        "timestamp": datetime.utcnow().isoformat(),
        "channel": "offline"
    }
    response = requests.post(f"{BASE_URL}/score-transaction", json=data)
    print_result("Transaction Scoring (Alcohol - Might BLOCK)", response)
    return response.status_code == 200


def test_location_check_ok():
    """Test location check - should be OK."""
    params = {
        "user_id": "u1",
        "lat": 40.0,
        "lon": -74.0
    }
    response = requests.get(f"{BASE_URL}/location-check", params=params)
    print_result("Location Check (Random Location - Should be OK)", response)
    return response.status_code == 200


def test_location_check_near_restaurant():
    """Test location check near a restaurant."""
    # Using coordinates from mock_restaurants.csv if it exists
    params = {
        "user_id": "u1",
        "lat": 40.712800,
        "lon": -74.006000
    }
    response = requests.get(f"{BASE_URL}/location-check", params=params)
    print_result("Location Check (Near Restaurant)", response)
    return response.status_code == 200


def test_missing_params():
    """Test error handling with missing parameters."""
    data = {
        "user_id": "u1",
        "amount": 50.0
        # Missing merchant_name
    }
    response = requests.post(f"{BASE_URL}/score-transaction", json=data)
    print_result("Error Handling (Missing Params)", response)
    return response.status_code == 400


def run_all_tests():
    """Run all tests and report results."""
    print("\n" + "="*60)
    print("TESTING MERGED HACKPRINCETON FEATURES")
    print("="*60)
    print(f"\nBase URL: {BASE_URL}")
    print("Make sure the Flask server is running!")
    print("\nStarting tests...\n")
    
    tests = [
        ("Health Check", test_health_check),
        ("Transaction Scoring (Allow)", test_transaction_scoring_allow),
        ("Transaction Scoring (Block)", test_transaction_scoring_block),
        ("Location Check (OK)", test_location_check_ok),
        ("Location Check (Restaurant)", test_location_check_near_restaurant),
        ("Error Handling", test_missing_params),
    ]
    
    results = []
    for test_name, test_func in tests:
        try:
            passed = test_func()
            results.append((test_name, passed))
        except requests.exceptions.ConnectionError:
            print(f"\n❌ ERROR: Could not connect to {BASE_URL}")
            print("Make sure the Flask server is running!")
            return
        except Exception as e:
            print(f"\n❌ ERROR in {test_name}: {str(e)}")
            results.append((test_name, False))
    
    # Print summary
    print("\n" + "="*60)
    print("TEST SUMMARY")
    print("="*60)
    
    for test_name, passed in results:
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status} - {test_name}")
    
    passed_count = sum(1 for _, passed in results if passed)
    total_count = len(results)
    
    print(f"\nTotal: {passed_count}/{total_count} tests passed")
    
    if passed_count == total_count:
        print("\n🎉 All tests passed! The merge was successful!")
    else:
        print("\n⚠️  Some tests failed. Check the output above for details.")


if __name__ == "__main__":
    run_all_tests()


