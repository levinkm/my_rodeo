#!/usr/bin/env python3
"""
Network Authentication Script for Sasa Connect Portal
Authenticates devices and maintains history of MAC addresses
"""

import requests
import json
import os
import re
from datetime import datetime
from urllib.parse import parse_qs, urlparse, unquote
import time

class NetworkAuthenticator:
    def __init__(self, config_file="network_auth_config.json"):
        self.config_file = config_file
        self.base_url = "https://portal.sasakonnect.net/"
        self.session = requests.Session()
        self.load_config()
        
    def load_config(self):
        """Load configuration including saved MAC addresses"""
        default_config = {
            "mac_history": [],
            "portal_params": {
                "interface_mode": "true",
                "pagetype": "remote", 
                "wired_auth": "true",
                "interface": "v2012",
                "staIp": "10.12.1.34",
                "staMac": "",  # Will be updated per device
                "url": "http%3A//192.168.7.1/",
                "bas_port": "10443",
                "bas_http_port": "8080"
            }
        }
        
        if os.path.exists(self.config_file):
            try:
                with open(self.config_file, 'r') as f:
                    self.config = json.load(f)
                # Ensure all required keys exist
                for key in default_config:
                    if key not in self.config:
                        self.config[key] = default_config[key]
            except Exception as e:
                print(f"Error loading config: {e}")
                self.config = default_config
        else:
            self.config = default_config
            
    def save_config(self):
        """Save current configuration to file"""
        try:
            with open(self.config_file, 'w') as f:
                json.dump(self.config, f, indent=2)
        except Exception as e:
            print(f"Error saving config: {e}")
            
    def validate_mac_address(self, mac):
        """Validate MAC address format"""
        mac_pattern = r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$'
        return re.match(mac_pattern, mac) is not None
        
    def normalize_mac_address(self, mac):
        """Normalize MAC address to uppercase with colons"""
        mac = mac.replace('-', ':').upper()
        return mac
        
    def add_mac_to_history(self, mac, name=None):
        """Add MAC address to history, maintaining only last 5"""
        mac = self.normalize_mac_address(mac)
        
        if not name:
            name = f"Device_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
            
        # Remove existing entry if it exists
        self.config["mac_history"] = [
            entry for entry in self.config["mac_history"] 
            if entry["mac"] != mac
        ]
        
        # Add new entry at the beginning
        new_entry = {
            "mac": mac,
            "name": name,
            "last_used": datetime.now().isoformat(),
            "auth_count": 1
        }
        
        # Check if this MAC was used before (update auth count)
        for entry in self.config["mac_history"]:
            if entry["mac"] == mac:
                new_entry["auth_count"] = entry.get("auth_count", 0) + 1
                break
                
        self.config["mac_history"].insert(0, new_entry)
        
        # Keep only last 5 entries
        self.config["mac_history"] = self.config["mac_history"][:5]
        self.save_config()
        
    def authenticate_device(self, mac_address, device_name=None):
        """Authenticate a device using its MAC address"""
        if not self.validate_mac_address(mac_address):
            return False, "Invalid MAC address format"
            
        mac_address = self.normalize_mac_address(mac_address)
        
        try:
            # Update portal parameters with the device MAC
            params = self.config["portal_params"].copy()
            params["staMac"] = mac_address
            
            print(f"Authenticating device: {device_name or mac_address}")
            print(f"MAC Address: {mac_address}")
            
            # Make the authentication request
            response = self.session.get(self.base_url, params=params, timeout=30)
            
            if response.status_code == 200:
                # Check if authentication was successful
                # This may need adjustment based on the actual portal response
                if "success" in response.text.lower() or "authenticated" in response.text.lower():
                    print("✓ Authentication successful")
                    self.add_mac_to_history(mac_address, device_name)
                    return True, "Authentication successful"
                elif "already" in response.text.lower():
                    print("✓ Device already authenticated")
                    self.add_mac_to_history(mac_address, device_name)
                    return True, "Device already authenticated"
                else:
                    print("✗ Authentication failed - Check portal response")
                    return False, f"Authentication failed: {response.text[:200]}..."
            else:
                return False, f"HTTP Error: {response.status_code}"
                
        except requests.exceptions.RequestException as e:
            return False, f"Network error: {str(e)}"
        except Exception as e:
            return False, f"Unexpected error: {str(e)}"
            
    def show_mac_history(self):
        """Display the history of authenticated MAC addresses"""
        if not self.config["mac_history"]:
            print("No MAC addresses in history")
            return
            
        print("\n=== MAC Address History (Last 5) ===")
        for i, entry in enumerate(self.config["mac_history"], 1):
            last_used = datetime.fromisoformat(entry["last_used"]).strftime("%Y-%m-%d %H:%M:%S")
            auth_count = entry.get("auth_count", 1)
            print(f"{i}. {entry['name']}")
            print(f"   MAC: {entry['mac']}")
            print(f"   Last Used: {last_used}")
            print(f"   Auth Count: {auth_count}")
            print()
            
    def authenticate_from_history(self, index):
        """Authenticate a device from history by index"""
        if 1 <= index <= len(self.config["mac_history"]):
            entry = self.config["mac_history"][index - 1]
            return self.authenticate_device(entry["mac"], entry["name"])
        else:
            return False, "Invalid history index"

def main():
    """Main function with interactive menu"""
    auth = NetworkAuthenticator()
    
    while True:
        print("\n=== Network Authentication Tool ===")
        print("1. Authenticate new device")
        print("2. Show MAC history")
        print("3. Re-authenticate from history")
        print("4. Exit")
        
        choice = input("\nSelect option (1-4): ").strip()
        
        if choice == "1":
            mac = input("Enter MAC address: ").strip()
            name = input("Enter device name (optional): ").strip() or None
            
            success, message = auth.authenticate_device(mac, name)
            print(f"\n{message}")
            
        elif choice == "2":
            auth.show_mac_history()
            
        elif choice == "3":
            auth.show_mac_history()
            if auth.config["mac_history"]:
                try:
                    index = int(input("Enter device number to re-authenticate: "))
                    success, message = auth.authenticate_from_history(index)
                    print(f"\n{message}")
                except ValueError:
                    print("Invalid input. Please enter a number.")
                    
        elif choice == "4":
            print("Goodbye!")
            break
            
        else:
            print("Invalid choice. Please select 1-4.")

if __name__ == "__main__":
    main()