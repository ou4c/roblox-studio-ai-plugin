"""
Authentication module for the Roblox Studio AI Plugin server.
Handles user management, authentication, and permissions.
"""
import os
import json
import time
from typing import Dict, List, Optional, Any, Tuple
from datetime import datetime
import config

class AuthManager:
    def __init__(self):
        self.users_file = config.config["USERS_FILE"]
        self.users = {}
        self.ensure_data_dir()
        self.load_users()
    
    def ensure_data_dir(self):
        """Ensure the data directory exists."""
        os.makedirs(os.path.dirname(self.users_file), exist_ok=True)
    
    def load_users(self) -> Dict[str, Any]:
        """Load users from the JSON file."""
        if not os.path.exists(self.users_file):
            # Create default users file with admin user
            default_users = {
                user: {
                    "username": user,
                    "role": "Admin",
                    "added_on": datetime.now().isoformat(),
                    "last_login": None,
                    "request_count": 0,
                    "daily_limit": config.roles["Admin"]["daily_limit"],
                    "daily_used": 0,
                    "last_reset": datetime.now().isoformat()
                } for user in config.config["ADMIN_USERNAMES"]
            }
            self.save_users(default_users)
            self.users = default_users
            return default_users
        
        try:
            with open(self.users_file, "r") as f:
                self.users = json.load(f)
                return self.users
        except (json.JSONDecodeError, FileNotFoundError):
            # If file is corrupted or doesn't exist, create a new one
            default_users = {
                user: {
                    "username": user,
                    "role": "Admin",
                    "added_on": datetime.now().isoformat(),
                    "last_login": None,
                    "request_count": 0,
                    "daily_limit": config.roles["Admin"]["daily_limit"],
                    "daily_used": 0,
                    "last_reset": datetime.now().isoformat()
                } for user in config.config["ADMIN_USERNAMES"]
            }
            self.save_users(default_users)
            self.users = default_users
            return default_users
    
    def save_users(self, users: Dict[str, Any]) -> None:
        """Save users to the JSON file."""
        self.ensure_data_dir()
        with open(self.users_file, "w") as f:
            json.dump(users, f, indent=2)
    
    def is_authorized(self, username: str) -> bool:
        """Check if a user is authorized."""
        return username in self.users
    
    def get_user(self, username: str) -> Optional[Dict[str, Any]]:
        """Get user information."""
        return self.users.get(username)
    
    def add_user(self, username: str, role: str = "User") -> Tuple[bool, str]:
        """Add a new user."""
        if not username:
            return False, "Username cannot be empty"
        
        if username in self.users:
            return False, f"User '{username}' already exists"
        
        if role not in config.roles:
            return False, f"Invalid role: {role}"
        
        self.users[username] = {
            "username": username,
            "role": role,
            "added_on": datetime.now().isoformat(),
            "last_login": None,
            "request_count": 0,
            "daily_limit": config.roles[role]["daily_limit"],
            "daily_used": 0,
            "last_reset": datetime.now().isoformat()
        }
        
        self.save_users(self.users)
        return True, f"User '{username}' added with role '{role}'"
    
    def remove_user(self, username: str) -> Tuple[bool, str]:
        """Remove a user."""
        if username not in self.users:
            return False, f"User '{username}' not found"
        
        del self.users[username]
        self.save_users(self.users)
        return True, f"User '{username}' removed"
    
    def update_user(self, username: str, role: Optional[str] = None) -> Tuple[bool, str]:
        """Update user information."""
        if username not in self.users:
            return False, f"User '{username}' not found"
        
        if role is not None:
            if role not in config.roles:
                return False, f"Invalid role: {role}"
            self.users[username]["role"] = role
            self.users[username]["daily_limit"] = config.roles[role]["daily_limit"]
        
        self.save_users(self.users)
        return True, f"User '{username}' updated"
    
    def list_users(self) -> List[Dict[str, Any]]:
        """List all users."""
        return [user for user in self.users.values()]
    
    def record_login(self, username: str) -> None:
        """Record user login."""
        if username in self.users:
            self.users[username]["last_login"] = datetime.now().isoformat()
            self.save_users(self.users)
    
    def record_request(self, username: str) -> Tuple[bool, str]:
        """Record a user request and check rate limits."""
        if username not in self.users:
            return False, "User not found"
        
        user = self.users[username]
        
        # Check if we need to reset daily usage
        last_reset = datetime.fromisoformat(user["last_reset"])
        now = datetime.now()
        if last_reset.date() < now.date():
            user["daily_used"] = 0
            user["last_reset"] = now.isoformat()
        
        # Check daily limit
        if user["daily_used"] >= user["daily_limit"]:
            return False, "Daily request limit reached"
        
        # Record the request
        user["request_count"] += 1
        user["daily_used"] += 1
        self.save_users(self.users)
        
        return True, "Request recorded"
    
    def check_permission(self, username: str, permission: str) -> bool:
        """Check if a user has a specific permission."""
        if username not in self.users:
            return False
        
        user_role = self.users[username]["role"]
        if user_role not in config.roles:
            return False
        
        return config.roles[user_role].get(permission, False)

# Create a singleton instance
auth_manager = AuthManager()

