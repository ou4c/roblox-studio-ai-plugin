# Roblox Studio AI Plugin

A powerful AI assistant plugin for Roblox Studio with user authentication, multiple AI models, and a modern UI.

## Features

- **Username Authentication**: Based on Roblox username with role-based permissions
- **Usage Logging**: Tracks usage per prompt, model, and timestamp
- **Modern UI**: Clean, responsive interface with smooth animations and hover effects
- **AI Model Switching**: Support for Mixtral, GPT-4, Claude, and other models
- **File/Object Upload**: Upload and manage files, effects, and models
- **Custom Asset Preview**: Preview assets directly in the plugin
- **Workspace Explorer Context**: AI has awareness of your workspace and selected objects
- **Admin Panel**: Manage users, view logs, and see usage statistics
- **Theme Support**: Toggle between dark and light themes
- **Chat History**: View and continue previous conversations
- **User Profile**: View your avatar, username, and role

## Repository Structure

```
roblox_studio_ai_plugin/
├── app.py                # Main Flask application
├── auth.py               # Authentication module
├── ai_provider.py        # AI provider integration
├── logger.py             # Logging module
├── file_handler.py       # File handling module
├── config.py             # Configuration file
├── requirements.txt      # Python dependencies
├── Procfile              # For deployment
├── data/                 # Data directory
│   ├── uploads/          # Uploaded files directory
│   ├── users.json        # User data
│   ├── logs.json         # Usage logs
│   └── history.json      # Chat history
└── client/               # Client-side code
    ├── plugin.lua        # Main plugin script
    └── README.md         # Client documentation
```

## Quick Deployment to Railway

This repository is structured for easy deployment to Railway. Follow these steps:

1. **Fork this repository** to your GitHub account

2. **Sign up for Railway**:
   - Go to [Railway](https://railway.app/) and sign up with your GitHub account
   - Authorize Railway to access your repositories

3. **Create a New Project**:
   - Click on "New Project" in the Railway dashboard
   - Select "Deploy from GitHub repo"
   - Choose your forked repository from the list

4. **Configure Environment Variables**:
   - Click on your newly created project
   - Go to the "Variables" tab
   - Add the following environment variables:
     ```
     PORT=5000
     OPENROUTER_API_KEY=your-api-key-here
     ```
   - (Optional) Add `HUGGINGFACE_API_KEY` if you want to use Hugging Face models

5. **Deploy the Project**:
   - Railway will automatically deploy your project based on the repository
   - Wait for the deployment to complete

6. **Get Your Domain**:
   - Once deployed, go to the "Settings" tab
   - Find the "Domains" section
   - Railway provides a default domain (e.g., `your-app-name.up.railway.app`)
   - You can also configure a custom domain if desired

## Setting Up the Plugin

1. **Update the Server URL**:
   - Open the `client/plugin.lua` file
   - Find the line that defines the server URL:
     ```lua
     local SERVER_URL = "https://web-production-4471.up.railway.app"
     ```
   - Replace it with your Railway domain:
     ```lua
     local SERVER_URL = "https://your-app-name.up.railway.app"
     ```

2. **Export the Plugin**:
   - Save the modified `plugin.lua` file
   - Create a new script in Roblox Studio
   - Copy the contents of `plugin.lua` into the script
   - Save the script as a plugin

3. **Add Authorized Users**:
   - By default, the plugin uses the `data/users.json` file for authentication
   - You can add users through the admin panel once logged in as an admin
   - The default admin user is "YourRobloxUsername" - make sure to change this to your actual Roblox username in the `data/users.json` file

## AI Model Configuration

The plugin supports multiple AI providers:

- **OpenRouter**: Default provider with access to various models (free tier available)
  - Sign up at [OpenRouter](https://openrouter.ai/)
  - Get your API key and add it to the environment variables

- **Hugging Face**: Alternative provider with thousands of open-source models
  - Sign up at [Hugging Face](https://huggingface.co/)
  - Get your API token and add it to the environment variables

- **Ollama**: Self-hosted option for unlimited usage
  - See the deployment guide for setup instructions

## Detailed Documentation

For more detailed instructions, refer to the `deployment_guide.pdf` file in this repository.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

