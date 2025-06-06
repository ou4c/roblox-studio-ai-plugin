"""
Main application file for the Roblox Studio AI Plugin server.
Provides API endpoints for the Roblox Studio plugin.
"""
import os
import json
import uuid
from typing import Dict, List, Optional, Any
from datetime import datetime
from flask import Flask, request, jsonify, send_file
from werkzeug.utils import secure_filename
import config
from auth import auth_manager
from logger import log_manager
from ai_provider import ai_provider
from file_handler import file_handler

# Create Flask app
app = Flask(__name__)

# Ensure data directories exist
os.makedirs(os.path.dirname(config.config["USERS_FILE"]), exist_ok=True)
os.makedirs(os.path.dirname(config.config["LOGS_FILE"]), exist_ok=True)
os.makedirs(os.path.dirname(config.config["HISTORY_FILE"]), exist_ok=True)
os.makedirs(config.config["UPLOADS_DIR"], exist_ok=True)

# Helper function to get conversation ID or create a new one
def get_conversation_id(username: str, conversation_id: Optional[str] = None) -> str:
    """Get a conversation ID or create a new one."""
    if conversation_id:
        return conversation_id
    return f"{username}-{uuid.uuid4()}"

@app.route("/")
def index():
    """Root endpoint."""
    return jsonify({
        "name": "Roblox Studio AI Plugin Server",
        "version": "2.0.0",
        "status": "running"
    })

@app.route("/auth_check", methods=["POST"])
def auth_check():
    """Check if a user is authorized and return their role information."""
    data = request.json
    username = data.get("username", "").strip()
    
    if not username:
        return jsonify({"error": "missing_username", "message": "Username is required"}), 400
    
    if not auth_manager.is_authorized(username):
        return jsonify({
            "authorized": False,
            "message": "Access denied. You are not on the authorized list."
        }), 403
    
    # Record login
    auth_manager.record_login(username)
    
    # Get user information
    user = auth_manager.get_user(username)
    role = user.get("role", "User")
    
    # Get permissions for the role
    permissions = config.roles.get(role, {})
    
    return jsonify({
        "authorized": True,
        "username": username,
        "role": role,
        "permissions": permissions,
        "message": f"Welcome, {username}! You are authorized as {role}."
    })

@app.route("/generate", methods=["POST"])
def generate():
    """Generate a response from the AI model."""
    data = request.json
    username = data.get("username", "").strip()
    prompt = data.get("prompt", "").strip()
    workspace_context = data.get("workspace", "").strip()
    model = data.get("model", config.config["DEFAULT_MODEL"])
    provider = data.get("provider", config.config["DEFAULT_PROVIDER"])
    system_prompt_key = data.get("system_prompt", "default")
    conversation_id = data.get("conversation_id")
    
    # Check authorization
    if not auth_manager.is_authorized(username):
        return jsonify({
            "error": "unauthorized",
            "message": "Access denied. You are not on the authorized list."
        }), 403
    
    # Check if prompt is provided
    if not prompt:
        return jsonify({
            "error": "no_prompt",
            "message": "No prompt provided."
        }), 400
    
    # Record request and check rate limits
    success, message = auth_manager.record_request(username)
    if not success:
        return jsonify({
            "error": "rate_limit",
            "message": message
        }), 429
    
    # Get or create conversation ID
    conversation_id = get_conversation_id(username, conversation_id)
    
    # Get conversation history
    conversation = log_manager.get_conversation(username, conversation_id)
    
    # Prepare messages for the AI
    messages = []
    
    # Add system prompt
    system_prompt = config.system_prompts.get(system_prompt_key, config.system_prompts["default"])
    if workspace_context:
        system_prompt += f"\n\nWorkspace Context:\n{workspace_context}"
    
    messages.append({"role": "system", "content": system_prompt})
    
    # Add conversation history (up to last 10 messages)
    for message in conversation[-10:]:
        messages.append({
            "role": message["role"],
            "content": message["content"]
        })
    
    # Add current prompt
    messages.append({"role": "user", "content": prompt})
    
    # Generate response
    success, content, response_data = ai_provider.generate_response(
        provider, model, messages
    )
    
    if not success:
        return jsonify({
            "error": "generation_error",
            "message": content
        }), 500
    
    # Log the request
    log_manager.log_request(
        username=username,
        model=model,
        prompt=prompt,
        response=content,
        context_used=bool(workspace_context),
        files_used=[]
    )
    
    # Add to conversation history
    log_manager.add_to_history(username, conversation_id, "user", prompt)
    log_manager.add_to_history(username, conversation_id, "assistant", content)
    
    return jsonify({
        "code": content,
        "conversation_id": conversation_id
    })

@app.route("/add_user", methods=["POST"])
def add_user():
    """Add a user to the authorized list."""
    data = request.json
    username = data.get("username", "").strip()
    role = data.get("role", "User").strip()
    admin_username = data.get("admin_username", "").strip()
    
    # Check if admin username is provided and authorized
    if admin_username:
        if not auth_manager.is_authorized(admin_username):
            return jsonify({
                "error": "unauthorized",
                "message": "Admin access denied."
            }), 403
        
        # Check if admin has permission to manage users
        if not auth_manager.check_permission(admin_username, "can_manage_users"):
            return jsonify({
                "error": "permission_denied",
                "message": "You don't have permission to manage users."
            }), 403
    
    # Add user
    success, message = auth_manager.add_user(username, role)
    
    if not success:
        return jsonify({
            "error": "add_user_failed",
            "message": message
        }), 400
    
    return jsonify({
        "message": message
    })

@app.route("/remove_user", methods=["POST"])
def remove_user():
    """Remove a user from the authorized list."""
    data = request.json
    username = data.get("username", "").strip()
    admin_username = data.get("admin_username", "").strip()
    
    # Check if admin username is provided and authorized
    if admin_username:
        if not auth_manager.is_authorized(admin_username):
            return jsonify({
                "error": "unauthorized",
                "message": "Admin access denied."
            }), 403
        
        # Check if admin has permission to manage users
        if not auth_manager.check_permission(admin_username, "can_manage_users"):
            return jsonify({
                "error": "permission_denied",
                "message": "You don't have permission to manage users."
            }), 403
    
    # Remove user
    success, message = auth_manager.remove_user(username)
    
    if not success:
        return jsonify({
            "error": "remove_user_failed",
            "message": message
        }), 404
    
    return jsonify({
        "message": message
    })

@app.route("/update_user", methods=["POST"])
def update_user():
    """Update a user's role."""
    data = request.json
    username = data.get("username", "").strip()
    role = data.get("role", "").strip()
    admin_username = data.get("admin_username", "").strip()
    
    # Check if admin username is provided and authorized
    if not admin_username:
        return jsonify({
            "error": "missing_admin",
            "message": "Admin username is required."
        }), 400
    
    if not auth_manager.is_authorized(admin_username):
        return jsonify({
            "error": "unauthorized",
            "message": "Admin access denied."
        }), 403
    
    # Check if admin has permission to manage users
    if not auth_manager.check_permission(admin_username, "can_manage_users"):
        return jsonify({
            "error": "permission_denied",
            "message": "You don't have permission to manage users."
        }), 403
    
    # Update user
    success, message = auth_manager.update_user(username, role)
    
    if not success:
        return jsonify({
            "error": "update_user_failed",
            "message": message
        }), 400
    
    return jsonify({
        "message": message
    })

@app.route("/list_users", methods=["GET"])
def list_users():
    """List all authorized users."""
    admin_username = request.args.get("admin_username", "").strip()
    
    # Check if admin username is provided and authorized
    if not admin_username:
        return jsonify({
            "error": "missing_admin",
            "message": "Admin username is required."
        }), 400
    
    if not auth_manager.is_authorized(admin_username):
        return jsonify({
            "error": "unauthorized",
            "message": "Admin access denied."
        }), 403
    
    # Check if admin has permission to manage users
    if not auth_manager.check_permission(admin_username, "can_manage_users"):
        return jsonify({
            "error": "permission_denied",
            "message": "You don't have permission to manage users."
        }), 403
    
    # List users
    users = auth_manager.list_users()
    
    return jsonify({
        "users": users
    })

@app.route("/get_logs", methods=["GET"])
def get_logs():
    """Get usage logs."""
    admin_username = request.args.get("admin_username", "").strip()
    username_filter = request.args.get("username", "").strip()
    limit = int(request.args.get("limit", 100))
    offset = int(request.args.get("offset", 0))
    
    # Check if admin username is provided and authorized
    if not admin_username:
        return jsonify({
            "error": "missing_admin",
            "message": "Admin username is required."
        }), 400
    
    if not auth_manager.is_authorized(admin_username):
        return jsonify({
            "error": "unauthorized",
            "message": "Admin access denied."
        }), 403
    
    # Check if admin has permission to view logs
    if not auth_manager.check_permission(admin_username, "can_view_logs"):
        return jsonify({
            "error": "permission_denied",
            "message": "You don't have permission to view logs."
        }), 403
    
    # Get logs
    logs = log_manager.get_logs(
        username=username_filter if username_filter else None,
        limit=limit,
        offset=offset
    )
    
    return jsonify({
        "logs": logs,
        "total": len(logs),
        "limit": limit,
        "offset": offset
    })

@app.route("/get_usage_stats", methods=["GET"])
def get_usage_stats():
    """Get usage statistics."""
    admin_username = request.args.get("admin_username", "").strip()
    
    # Check if admin username is provided and authorized
    if not admin_username:
        return jsonify({
            "error": "missing_admin",
            "message": "Admin username is required."
        }), 400
    
    if not auth_manager.is_authorized(admin_username):
        return jsonify({
            "error": "unauthorized",
            "message": "Admin access denied."
        }), 403
    
    # Check if admin has permission to view logs
    if not auth_manager.check_permission(admin_username, "can_view_logs"):
        return jsonify({
            "error": "permission_denied",
            "message": "You don't have permission to view logs."
        }), 403
    
    # Get usage stats
    stats = log_manager.get_usage_stats()
    
    return jsonify(stats)

@app.route("/get_conversation", methods=["GET"])
def get_conversation():
    """Get a conversation history."""
    username = request.args.get("username", "").strip()
    conversation_id = request.args.get("conversation_id", "").strip()
    
    # Check authorization
    if not auth_manager.is_authorized(username):
        return jsonify({
            "error": "unauthorized",
            "message": "Access denied."
        }), 403
    
    # Get conversation
    conversation = log_manager.get_conversation(username, conversation_id)
    
    return jsonify({
        "conversation": conversation,
        "conversation_id": conversation_id
    })

@app.route("/get_user_conversations", methods=["GET"])
def get_user_conversations():
    """Get all conversations for a user."""
    username = request.args.get("username", "").strip()
    
    # Check authorization
    if not auth_manager.is_authorized(username):
        return jsonify({
            "error": "unauthorized",
            "message": "Access denied."
        }), 403
    
    # Get conversations
    conversations = log_manager.get_user_conversations(username)
    
    # Format the response
    result = []
    for conversation_id, messages in conversations.items():
        if not messages:
            continue
        
        # Get the first and last message timestamps
        first_timestamp = datetime.fromisoformat(messages[0]["timestamp"])
        last_timestamp = datetime.fromisoformat(messages[-1]["timestamp"])
        
        # Get a preview of the conversation (first user message)
        preview = ""
        for message in messages:
            if message["role"] == "user":
                preview = message["content"]
                break
        
        result.append({
            "conversation_id": conversation_id,
            "message_count": len(messages),
            "first_timestamp": messages[0]["timestamp"],
            "last_timestamp": messages[-1]["timestamp"],
            "preview": preview[:100] + "..." if len(preview) > 100 else preview
        })
    
    # Sort by last timestamp (newest first)
    result.sort(key=lambda x: x["last_timestamp"], reverse=True)
    
    return jsonify({
        "conversations": result
    })

@app.route("/clear_conversation", methods=["POST"])
def clear_conversation():
    """Clear a conversation history."""
    data = request.json
    username = data.get("username", "").strip()
    conversation_id = data.get("conversation_id", "").strip()
    
    # Check authorization
    if not auth_manager.is_authorized(username):
        return jsonify({
            "error": "unauthorized",
            "message": "Access denied."
        }), 403
    
    # Clear conversation
    success = log_manager.clear_conversation(username, conversation_id)
    
    if not success:
        return jsonify({
            "error": "clear_failed",
            "message": "Failed to clear conversation."
        }), 400
    
    return jsonify({
        "message": "Conversation cleared."
    })

@app.route("/upload_file", methods=["POST"])
def upload_file():
    """Upload a file."""
    # Check if the post request has the file part
    if "file" not in request.files:
        return jsonify({
            "error": "no_file",
            "message": "No file part in the request."
        }), 400
    
    file = request.files["file"]
    username = request.form.get("username", "").strip()
    file_type = request.form.get("type", "unknown").strip()
    description = request.form.get("description", "").strip()
    
    # Check if file is selected
    if file.filename == "":
        return jsonify({
            "error": "no_file_selected",
            "message": "No file selected."
        }), 400
    
    # Check authorization
    if not auth_manager.is_authorized(username):
        return jsonify({
            "error": "unauthorized",
            "message": "Access denied."
        }), 403
    
    # Check if user has permission to upload files
    if not auth_manager.check_permission(username, "can_upload_files"):
        return jsonify({
            "error": "permission_denied",
            "message": "You don't have permission to upload files."
        }), 403
    
    # Save file
    file_data = file.read()
    success, file_id, file_metadata = file_handler.save_file(
        file_data=file_data,
        filename=file.filename,
        file_type=file_type,
        username=username,
        description=description
    )
    
    if not success:
        return jsonify({
            "error": "upload_failed",
            "message": file_id
        }), 500
    
    return jsonify({
        "message": "File uploaded successfully.",
        "file_id": file_id,
        "metadata": file_metadata
    })

@app.route("/get_file/<file_id>", methods=["GET"])
def get_file(file_id):
    """Get a file by ID."""
    username = request.args.get("username", "").strip()
    
    # Check authorization
    if not auth_manager.is_authorized(username):
        return jsonify({
            "error": "unauthorized",
            "message": "Access denied."
        }), 403
    
    # Get file
    success, filename, file_data = file_handler.get_file(file_id)
    
    if not success:
        return jsonify({
            "error": "file_not_found",
            "message": filename
        }), 404
    
    # Create a temporary file to send
    temp_file_path = os.path.join("/tmp", filename)
    with open(temp_file_path, "wb") as f:
        f.write(file_data)
    
    return send_file(
        temp_file_path,
        as_attachment=True,
        download_name=filename
    )

@app.route("/delete_file", methods=["POST"])
def delete_file():
    """Delete a file by ID."""
    data = request.json
    file_id = data.get("file_id", "").strip()
    username = data.get("username", "").strip()
    
    # Check authorization
    if not auth_manager.is_authorized(username):
        return jsonify({
            "error": "unauthorized",
            "message": "Access denied."
        }), 403
    
    # Check if user has permission to upload files
    if not auth_manager.check_permission(username, "can_upload_files"):
        return jsonify({
            "error": "permission_denied",
            "message": "You don't have permission to manage files."
        }), 403
    
    # Delete file
    success, message = file_handler.delete_file(file_id)
    
    if not success:
        return jsonify({
            "error": "delete_failed",
            "message": message
        }), 400
    
    return jsonify({
        "message": message
    })

@app.route("/list_files", methods=["GET"])
def list_files():
    """List files with optional filtering."""
    username = request.args.get("username", "").strip()
    file_type = request.args.get("type", "").strip()
    
    # Check authorization
    if not auth_manager.is_authorized(username):
        return jsonify({
            "error": "unauthorized",
            "message": "Access denied."
        }), 403
    
    # List files
    files = file_handler.list_files(
        username=username if username else None,
        file_type=file_type if file_type else None
    )
    
    return jsonify({
        "files": files
    })

@app.route("/get_models", methods=["GET"])
def get_models():
    """Get available AI models."""
    provider = request.args.get("provider", "").strip()
    
    # Get models
    models = ai_provider.get_available_models(
        provider=provider if provider else None
    )
    
    return jsonify({
        "models": models
    })

if __name__ == "__main__":
    # Run the Flask app
    app.run(
        host=config.config["HOST"],
        port=config.config["PORT"],
        debug=config.config["DEBUG"]
    )

