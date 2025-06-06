"""
File handling module for the Roblox Studio AI Plugin server.
Manages file uploads, storage, and retrieval.
"""
import os
import json
import uuid
import shutil
from typing import Dict, List, Optional, Any, Tuple
from datetime import datetime
from werkzeug.utils import secure_filename
import config

class FileHandler:
    def __init__(self):
        self.uploads_dir = config.config["UPLOADS_DIR"]
        self.ensure_uploads_dir()
        self.metadata_file = os.path.join(self.uploads_dir, "metadata.json")
        self.metadata = self.load_metadata()
    
    def ensure_uploads_dir(self):
        """Ensure the uploads directory exists."""
        os.makedirs(self.uploads_dir, exist_ok=True)
    
    def load_metadata(self) -> Dict[str, Any]:
        """Load file metadata from JSON file."""
        if not os.path.exists(self.metadata_file):
            metadata = {"files": {}}
            self.save_metadata(metadata)
            return metadata
        
        try:
            with open(self.metadata_file, "r") as f:
                return json.load(f)
        except (json.JSONDecodeError, FileNotFoundError):
            metadata = {"files": {}}
            self.save_metadata(metadata)
            return metadata
    
    def save_metadata(self, metadata: Dict[str, Any]) -> None:
        """Save file metadata to JSON file."""
        with open(self.metadata_file, "w") as f:
            json.dump(metadata, f, indent=2)
    
    def save_file(self, file_data: bytes, filename: str, file_type: str, 
                 username: str, description: str = "") -> Tuple[bool, str, Dict[str, Any]]:
        """Save an uploaded file."""
        # Generate a unique ID for the file
        file_id = str(uuid.uuid4())
        
        # Secure the filename
        secure_name = secure_filename(filename)
        
        # Create a directory for the file
        file_dir = os.path.join(self.uploads_dir, file_id)
        os.makedirs(file_dir, exist_ok=True)
        
        # Save the file
        file_path = os.path.join(file_dir, secure_name)
        with open(file_path, "wb") as f:
            f.write(file_data)
        
        # Create metadata
        file_metadata = {
            "id": file_id,
            "filename": secure_name,
            "original_filename": filename,
            "type": file_type,
            "size": len(file_data),
            "uploaded_by": username,
            "uploaded_at": datetime.now().isoformat(),
            "description": description,
            "path": file_path
        }
        
        # Add to metadata
        self.metadata["files"][file_id] = file_metadata
        self.save_metadata(self.metadata)
        
        return True, file_id, file_metadata
    
    def get_file(self, file_id: str) -> Tuple[bool, str, Optional[bytes]]:
        """Get a file by ID."""
        if file_id not in self.metadata["files"]:
            return False, "File not found", None
        
        file_metadata = self.metadata["files"][file_id]
        file_path = file_metadata["path"]
        
        if not os.path.exists(file_path):
            return False, "File not found on disk", None
        
        try:
            with open(file_path, "rb") as f:
                file_data = f.read()
            return True, file_metadata["filename"], file_data
        except Exception as e:
            return False, f"Error reading file: {str(e)}", None
    
    def delete_file(self, file_id: str) -> Tuple[bool, str]:
        """Delete a file by ID."""
        if file_id not in self.metadata["files"]:
            return False, "File not found"
        
        file_metadata = self.metadata["files"][file_id]
        file_dir = os.path.dirname(file_metadata["path"])
        
        try:
            # Remove the file directory
            shutil.rmtree(file_dir)
            
            # Remove from metadata
            del self.metadata["files"][file_id]
            self.save_metadata(self.metadata)
            
            return True, "File deleted"
        except Exception as e:
            return False, f"Error deleting file: {str(e)}"
    
    def list_files(self, username: Optional[str] = None, 
                  file_type: Optional[str] = None) -> List[Dict[str, Any]]:
        """List files with optional filtering."""
        files = list(self.metadata["files"].values())
        
        if username:
            files = [f for f in files if f["uploaded_by"] == username]
        
        if file_type:
            files = [f for f in files if f["type"] == file_type]
        
        # Sort by upload date (newest first)
        files.sort(key=lambda x: x["uploaded_at"], reverse=True)
        
        return files
    
    def get_file_types(self) -> List[str]:
        """Get a list of all file types."""
        return list(set(f["type"] for f in self.metadata["files"].values()))

# Create a singleton instance
file_handler = FileHandler()

