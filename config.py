"""
Configuration file for the Roblox Studio AI Plugin server.
Contains API keys, provider settings, and other configuration options.
"""
import os
from typing import Dict, Any, List, Optional

# Default configuration
DEFAULT_CONFIG = {
    # Server settings
    "HOST": "0.0.0.0",
    "PORT": int(os.environ.get("PORT", 5000)),
    "DEBUG": False,
    
    # File paths
    "USERS_FILE": "data/users.json",
    "LOGS_FILE": "data/logs.json",
    "HISTORY_FILE": "data/history.json",
    "UPLOADS_DIR": "data/uploads",
    
    # AI Provider settings
    "DEFAULT_PROVIDER": "openrouter",
    "DEFAULT_MODEL": "mistralai/mistral-7b-instruct:free",
    
    # Provider API keys
    "OPENROUTER_API_KEY": "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",
    "HUGGINGFACE_API_KEY": "",  # Add your Hugging Face API key here
    "OLLAMA_BASE_URL": "http://localhost:11434",  # For self-hosted Ollama
    
    # Rate limiting
    "RATE_LIMIT_ENABLED": True,
    "RATE_LIMIT_DEFAULT": 20,  # requests per minute
    
    # Security
    "REQUIRE_AUTH": True,
    "ADMIN_USERNAMES": ["itsmelotex"],  # Default admin users
}

# Provider configurations
PROVIDERS = {
    "openrouter": {
        "api_base": "https://openrouter.ai/api/v1",
        "api_format": "openai",
        "models": {
            "mistral": "mistralai/mistral-7b-instruct:free",
            "mixtral": "mistralai/mixtral-8x7b:free",
            "gpt4": "openai/gpt-4:free",
            "claude": "anthropic/claude-3-sonnet:free",
            "deepseek": "deepseek/deepseek-r1:free"
        }
    },
    "huggingface": {
        "api_base": "https://api-inference.huggingface.co/models",
        "api_format": "huggingface",
        "models": {
            "mistral": "mistralai/Mistral-7B-Instruct-v0.2",
            "llama2": "meta-llama/Llama-2-7b-chat-hf",
            "codellama": "codellama/CodeLlama-7b-Instruct-hf"
        }
    },
    "ollama": {
        "api_base": "http://localhost:11434/api",
        "api_format": "ollama",
        "models": {
            "llama3": "llama3",
            "mistral": "mistral",
            "codellama": "codellama"
        }
    }
}

# User roles and permissions
ROLES = {
    "Admin": {
        "can_manage_users": True,
        "can_view_logs": True,
        "can_use_all_models": True,
        "can_upload_files": True,
        "can_modify_workspace": True,
        "daily_limit": 1000
    },
    "Developer": {
        "can_manage_users": False,
        "can_view_logs": False,
        "can_use_all_models": True,
        "can_upload_files": True,
        "can_modify_workspace": True,
        "daily_limit": 500
    },
    "Manager": {
        "can_manage_users": True,
        "can_view_logs": True,
        "can_use_all_models": False,
        "can_upload_files": False,
        "can_modify_workspace": False,
        "daily_limit": 200
    },
    "User": {
        "can_manage_users": False,
        "can_view_logs": False,
        "can_use_all_models": False,
        "can_upload_files": False,
        "can_modify_workspace": False,
        "daily_limit": 100
    }
}

# System prompts for different contexts
SYSTEM_PROMPTS = {
    "default": "You are a Roblox Studio assistant. You help users with scripting, game design, and other Roblox development tasks.",
    "scripting": "You are a Roblox Lua scripting expert. Provide clear, efficient, and well-commented code examples.",
    "design": "You are a Roblox game design expert. Help users create engaging and visually appealing games.",
    "debugging": "You are a debugging assistant for Roblox Studio. Help users identify and fix issues in their code and games."
}

# Load environment variables to override defaults
for key in DEFAULT_CONFIG:
    if key in os.environ:
        if isinstance(DEFAULT_CONFIG[key], bool):
            DEFAULT_CONFIG[key] = os.environ[key].lower() == 'true'
        elif isinstance(DEFAULT_CONFIG[key], int):
            DEFAULT_CONFIG[key] = int(os.environ[key])
        else:
            DEFAULT_CONFIG[key] = os.environ[key]

# Export configuration
config = DEFAULT_CONFIG
providers = PROVIDERS
roles = ROLES
system_prompts = SYSTEM_PROMPTS

