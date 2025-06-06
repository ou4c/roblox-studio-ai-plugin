# Roblox Studio AI Plugin - Client

This is the client-side component of the Roblox Studio AI Plugin. It provides a modern, feature-rich interface for interacting with AI models directly within Roblox Studio.

## Features

- **Modern UI**: Clean, responsive interface with smooth animations and hover effects
- **User Authentication**: Role-based access control with different permission levels
- **Multiple AI Models**: Switch between Mixtral, GPT-4, and Claude models
- **Chat History**: View and continue previous conversations
- **File Management**: Upload and manage files for use in your projects
- **Custom Asset Preview**: Preview assets directly in the plugin
- **Workspace Context**: AI has awareness of your current workspace and selected objects
- **Admin Panel**: Manage users, view logs, and see usage statistics
- **Theme Support**: Toggle between light and dark themes
- **User Profile**: View your avatar, username, and role

## Installation

### Method 1: Install from RBXMX file

1. Download the `ai_plugin.rbxmx` file from this repository
2. In Roblox Studio, go to the "Plugins" tab
3. Click on "Plugins Folder" to open your plugins directory
4. Copy the `ai_plugin.rbxmx` file to this directory
5. Restart Roblox Studio

### Method 2: Install from Plugin Manager

1. In Roblox Studio, go to the "Plugins" tab
2. Click on "Plugin Manager"
3. Search for "AI Studio Assistant"
4. Click "Install"

## Configuration

By default, the plugin connects to the server at `https://web-production-4471.up.railway.app`. If you want to use your own server:

1. Open the `plugin.lua` file
2. Find the line with `local SERVER_URL = "https://web-production-4471.up.railway.app"`
3. Replace the URL with your own server URL
4. Save the file and restart Roblox Studio

## Usage

1. Click on the "AI Studio Assistant" button in the Plugins tab to open the plugin
2. If you're authorized, you'll see the chat interface
3. Type your prompt and click the send button to get a response
4. Use the tabs at the bottom to access different features:
   - **Chat**: Interact with the AI
   - **Files**: Upload and manage files
   - **History**: View and continue previous conversations
   - **Admin**: Manage users and view logs (admin only)
5. Click on your profile icon to access settings and theme options

## Permissions

The plugin supports different user roles with varying permissions:

- **Admin**: Full access to all features, including user management and logs
- **Developer**: Can use all AI models and upload files, but cannot manage users
- **Manager**: Can manage users and view logs, but has limited AI model access
- **User**: Basic access to AI features with limited model selection

## Development

To modify the plugin:

1. Clone this repository
2. Edit the `plugin.lua` file to make your changes
3. Export the plugin as an RBXMX file:
   ```lua
   local plugin = script:GetAttribute("Plugin") or plugin
   plugin:SaveToRoblox()
   ```
4. Test your changes in Roblox Studio

## License

This project is licensed under the MIT License - see the LICENSE file for details.

