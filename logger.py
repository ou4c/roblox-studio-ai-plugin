"""
Logging module for the Roblox Studio AI Plugin server.
Handles request logging, chat history, and usage statistics.
"""
import os
import json
import time
from typing import Dict, List, Optional, Any
from datetime import datetime
import config

class LogManager:
    def __init__(self):
        self.logs_file = config.config["LOGS_FILE"]
        self.history_file = config.config["HISTORY_FILE"]
        self.logs = {"logs": []}
        self.history = {"conversations": {}}
        self.ensure_data_dir()
        self.load_logs()
        self.load_history()
    
    def ensure_data_dir(self):
        """Ensure the data directory exists."""
        os.makedirs(os.path.dirname(self.logs_file), exist_ok=True)
        os.makedirs(os.path.dirname(self.history_file), exist_ok=True)
    
    def load_logs(self) -> Dict[str, List[Dict[str, Any]]]:
        """Load logs from the JSON file."""
        if not os.path.exists(self.logs_file):
            self.save_logs(self.logs)
            return self.logs
        
        try:
            with open(self.logs_file, "r") as f:
                self.logs = json.load(f)
                return self.logs
        except (json.JSONDecodeError, FileNotFoundError):
            self.logs = {"logs": []}
            self.save_logs(self.logs)
            return self.logs
    
    def save_logs(self, logs: Dict[str, List[Dict[str, Any]]]) -> None:
        """Save logs to the JSON file."""
        self.ensure_data_dir()
        with open(self.logs_file, "w") as f:
            json.dump(logs, f, indent=2)
    
    def load_history(self) -> Dict[str, Dict[str, List[Dict[str, Any]]]]:
        """Load chat history from the JSON file."""
        if not os.path.exists(self.history_file):
            self.save_history(self.history)
            return self.history
        
        try:
            with open(self.history_file, "r") as f:
                self.history = json.load(f)
                return self.history
        except (json.JSONDecodeError, FileNotFoundError):
            self.history = {"conversations": {}}
            self.save_history(self.history)
            return self.history
    
    def save_history(self, history: Dict[str, Dict[str, List[Dict[str, Any]]]]) -> None:
        """Save chat history to the JSON file."""
        self.ensure_data_dir()
        with open(self.history_file, "w") as f:
            json.dump(history, f, indent=2)
    
    def log_request(self, username: str, model: str, prompt: str, response: str, 
                   context_used: bool = False, files_used: List[str] = None) -> None:
        """Log a request."""
        if files_used is None:
            files_used = []
        
        log_entry = {
            "timestamp": datetime.now().isoformat(),
            "username": username,
            "model": model,
            "prompt": prompt,
            "response": response,
            "context_used": context_used,
            "files_used": files_used
        }
        
        self.logs["logs"].append(log_entry)
        self.save_logs(self.logs)
    
    def add_to_history(self, username: str, conversation_id: str, 
                      role: str, content: str) -> None:
        """Add a message to the chat history."""
        if username not in self.history["conversations"]:
            self.history["conversations"][username] = {}
        
        if conversation_id not in self.history["conversations"][username]:
            self.history["conversations"][username][conversation_id] = []
        
        message = {
            "timestamp": datetime.now().isoformat(),
            "role": role,
            "content": content
        }
        
        self.history["conversations"][username][conversation_id].append(message)
        self.save_history(self.history)
    
    def get_conversation(self, username: str, conversation_id: str) -> List[Dict[str, Any]]:
        """Get a specific conversation."""
        if username not in self.history["conversations"]:
            return []
        
        if conversation_id not in self.history["conversations"][username]:
            return []
        
        return self.history["conversations"][username][conversation_id]
    
    def get_user_conversations(self, username: str) -> Dict[str, List[Dict[str, Any]]]:
        """Get all conversations for a user."""
        if username not in self.history["conversations"]:
            return {}
        
        return self.history["conversations"][username]
    
    def clear_conversation(self, username: str, conversation_id: str) -> bool:
        """Clear a specific conversation."""
        if username not in self.history["conversations"]:
            return False
        
        if conversation_id not in self.history["conversations"][username]:
            return False
        
        self.history["conversations"][username][conversation_id] = []
        self.save_history(self.history)
        return True
    
    def get_logs(self, username: Optional[str] = None, 
                limit: int = 100, offset: int = 0) -> List[Dict[str, Any]]:
        """Get logs with optional filtering."""
        logs = self.logs["logs"]
        
        if username:
            logs = [log for log in logs if log["username"] == username]
        
        # Sort by timestamp (newest first)
        logs.sort(key=lambda x: x["timestamp"], reverse=True)
        
        # Apply pagination
        return logs[offset:offset + limit]
    
    def get_usage_stats(self) -> Dict[str, Any]:
        """Get usage statistics."""
        logs = self.logs["logs"]
        
        # Get total request count
        total_requests = len(logs)
        
        # Get requests per model
        model_counts = {}
        for log in logs:
            model = log["model"]
            if model not in model_counts:
                model_counts[model] = 0
            model_counts[model] += 1
        
        # Get requests per user
        user_counts = {}
        for log in logs:
            username = log["username"]
            if username not in user_counts:
                user_counts[username] = 0
            user_counts[username] += 1
        
        # Get requests per day
        day_counts = {}
        for log in logs:
            day = datetime.fromisoformat(log["timestamp"]).strftime("%Y-%m-%d")
            if day not in day_counts:
                day_counts[day] = 0
            day_counts[day] += 1
        
        return {
            "total_requests": total_requests,
            "model_counts": model_counts,
            "user_counts": user_counts,
            "day_counts": day_counts
        }

# Create a singleton instance
log_manager = LogManager()

