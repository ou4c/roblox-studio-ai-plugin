"""
AI Provider module for the Roblox Studio AI Plugin server.
Handles interactions with different AI model providers.
"""
import os
import json
import requests
from typing import Dict, List, Optional, Any, Tuple
import config
import openai

class AIProvider:
    def __init__(self):
        self.providers = config.providers
        self.default_provider = config.config["DEFAULT_PROVIDER"]
        self.default_model = config.config["DEFAULT_MODEL"]
        
        # Set up OpenAI API for OpenRouter
        openai.api_key = config.config["OPENROUTER_API_KEY"]
        openai.api_base = self.providers["openrouter"]["api_base"]
    
    def generate_response(self, provider: str, model: str, messages: List[Dict[str, str]], 
                         system_prompt: Optional[str] = None) -> Tuple[bool, str, Dict[str, Any]]:
        """Generate a response from the specified AI provider and model."""
        if provider not in self.providers:
            return False, f"Provider '{provider}' not supported", {}
        
        if model not in self.providers[provider]["models"].values():
            # Check if it's a shorthand model name
            if model in self.providers[provider]["models"]:
                model = self.providers[provider]["models"][model]
            else:
                return False, f"Model '{model}' not supported by provider '{provider}'", {}
        
        # Add system prompt if provided
        if system_prompt and messages and messages[0]["role"] != "system":
            messages.insert(0, {"role": "system", "content": system_prompt})
        
        # Generate response based on provider
        try:
            if self.providers[provider]["api_format"] == "openai":
                return self._generate_openai_format(provider, model, messages)
            elif self.providers[provider]["api_format"] == "huggingface":
                return self._generate_huggingface_format(provider, model, messages)
            elif self.providers[provider]["api_format"] == "ollama":
                return self._generate_ollama_format(provider, model, messages)
            else:
                return False, f"API format '{self.providers[provider]['api_format']}' not supported", {}
        except Exception as e:
            return False, f"Error generating response: {str(e)}", {}
    
    def _generate_openai_format(self, provider: str, model: str, 
                              messages: List[Dict[str, str]]) -> Tuple[bool, str, Dict[str, Any]]:
        """Generate a response using OpenAI-compatible API format."""
        # Save current API settings
        current_api_key = openai.api_key
        current_api_base = openai.api_base
        
        try:
            # Set API settings for the provider
            if provider == "openrouter":
                openai.api_key = config.config["OPENROUTER_API_KEY"]
            else:
                # For other OpenAI-compatible providers
                openai.api_key = config.config.get(f"{provider.upper()}_API_KEY", "")
            
            openai.api_base = self.providers[provider]["api_base"]
            
            # Generate response
            response = openai.ChatCompletion.create(
                model=model,
                messages=messages,
                temperature=0.7,
                max_tokens=1024
            )
            
            content = response.choices[0].message.content
            return True, content, response
        
        finally:
            # Restore original API settings
            openai.api_key = current_api_key
            openai.api_base = current_api_base
    
    def _generate_huggingface_format(self, provider: str, model: str, 
                                   messages: List[Dict[str, str]]) -> Tuple[bool, str, Dict[str, Any]]:
        """Generate a response using Hugging Face Inference API format."""
        api_key = config.config["HUGGINGFACE_API_KEY"]
        if not api_key:
            return False, "Hugging Face API key not configured", {}
        
        # Convert messages to a single prompt
        prompt = ""
        for message in messages:
            role = message["role"]
            content = message["content"]
            
            if role == "system":
                prompt += f"<|system|>\n{content}\n"
            elif role == "user":
                prompt += f"<|user|>\n{content}\n"
            elif role == "assistant":
                prompt += f"<|assistant|>\n{content}\n"
        
        prompt += "<|assistant|>\n"
        
        # Make API request
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "inputs": prompt,
            "parameters": {
                "max_new_tokens": 1024,
                "temperature": 0.7,
                "return_full_text": False
            }
        }
        
        api_url = f"{self.providers[provider]['api_base']}/{model}"
        response = requests.post(api_url, headers=headers, json=payload)
        
        if response.status_code != 200:
            return False, f"Error from Hugging Face API: {response.text}", {}
        
        result = response.json()
        
        # Extract the generated text
        if isinstance(result, list) and len(result) > 0:
            content = result[0].get("generated_text", "")
            return True, content, result
        
        return False, "Invalid response format from Hugging Face API", {}
    
    def _generate_ollama_format(self, provider: str, model: str, 
                              messages: List[Dict[str, str]]) -> Tuple[bool, str, Dict[str, Any]]:
        """Generate a response using Ollama API format."""
        base_url = config.config["OLLAMA_BASE_URL"]
        
        # Convert messages to Ollama format
        prompt = ""
        for message in messages:
            role = message["role"]
            content = message["content"]
            
            if role == "system":
                prompt += f"System: {content}\n\n"
            elif role == "user":
                prompt += f"User: {content}\n\n"
            elif role == "assistant":
                prompt += f"Assistant: {content}\n\n"
        
        prompt += "Assistant: "
        
        # Make API request
        payload = {
            "model": model,
            "prompt": prompt,
            "stream": False
        }
        
        response = requests.post(f"{base_url}/generate", json=payload)
        
        if response.status_code != 200:
            return False, f"Error from Ollama API: {response.text}", {}
        
        result = response.json()
        content = result.get("response", "")
        
        return True, content, result
    
    def get_available_models(self, provider: Optional[str] = None) -> Dict[str, List[str]]:
        """Get available models for the specified provider or all providers."""
        if provider:
            if provider not in self.providers:
                return {}
            return {provider: list(self.providers[provider]["models"].values())}
        
        return {p: list(self.providers[p]["models"].values()) for p in self.providers}
    
    def get_model_info(self, provider: str, model: str) -> Dict[str, Any]:
        """Get information about a specific model."""
        if provider not in self.providers:
            return {}
        
        # Check if it's a shorthand model name
        if model in self.providers[provider]["models"]:
            model = self.providers[provider]["models"][model]
        
        # For now, return basic info
        return {
            "provider": provider,
            "model": model,
            "api_format": self.providers[provider]["api_format"]
        }

# Create a singleton instance
ai_provider = AIProvider()

