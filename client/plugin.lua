--[[
    Roblox Studio AI Plugin
    Enhanced version with modern UI, animations, and advanced features
]]

-- Services
local plugin = script:GetAttribute("Plugin") or plugin
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local StudioService = game:GetService("StudioService")
local Selection = game:GetService("Selection")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local InsertService = game:GetService("InsertService")
local RunService = game:GetService("RunService")

-- Constants
local PLUGIN_NAME = "AI Studio Assistant"
local PLUGIN_VERSION = "2.0.0"
local SERVER_URL = "https://web-production-4471.up.railway.app" -- Replace with your actual server URL
local DEFAULT_MODEL = "mistralai/mistral-7b-instruct:free"
local DEFAULT_PROVIDER = "openrouter"
local ANIMATION_DURATION = 0.3
local ANIMATION_EASING_STYLE = Enum.EasingStyle.Quint
local ANIMATION_EASING_DIRECTION = Enum.EasingDirection.Out

-- Theme Colors
local THEME = {
    Light = {
        Background = Color3.fromRGB(240, 240, 240),
        BackgroundSecondary = Color3.fromRGB(250, 250, 250),
        Text = Color3.fromRGB(30, 30, 30),
        TextSecondary = Color3.fromRGB(100, 100, 100),
        Primary = Color3.fromRGB(0, 122, 255),
        Secondary = Color3.fromRGB(142, 142, 147),
        Success = Color3.fromRGB(52, 199, 89),
        Warning = Color3.fromRGB(255, 149, 0),
        Error = Color3.fromRGB(255, 59, 48),
        Border = Color3.fromRGB(220, 220, 220),
        Shadow = Color3.fromRGB(0, 0, 0),
        ShadowTransparency = 0.9
    },
    Dark = {
        Background = Color3.fromRGB(30, 30, 30),
        BackgroundSecondary = Color3.fromRGB(40, 40, 40),
        Text = Color3.fromRGB(240, 240, 240),
        TextSecondary = Color3.fromRGB(180, 180, 180),
        Primary = Color3.fromRGB(10, 132, 255),
        Secondary = Color3.fromRGB(142, 142, 147),
        Success = Color3.fromRGB(48, 209, 88),
        Warning = Color3.fromRGB(255, 159, 10),
        Error = Color3.fromRGB(255, 69, 58),
        Border = Color3.fromRGB(60, 60, 60),
        Shadow = Color3.fromRGB(0, 0, 0),
        ShadowTransparency = 0.7
    }
}

-- State
local State = {
    CurrentTheme = "Dark",
    IsAuthorized = false,
    Username = "",
    Role = "",
    Permissions = {},
    CurrentModel = DEFAULT_MODEL,
    CurrentProvider = DEFAULT_PROVIDER,
    CurrentConversationId = nil,
    ChatHistory = {},
    IsLoading = false,
    CurrentTab = "Chat",
    AvailableModels = {},
    UploadedFiles = {},
    UsersList = {},
    LogsList = {},
    UsageStats = {},
    SelectedAssetId = nil,
    WorkspaceContext = "",
    SelectedObject = nil,
    IsMenuOpen = false,
    IsDragging = false,
    DragStartPos = nil,
    DragStartOffset = nil
}

-- UI Elements (will be populated during creation)
local UI = {
    Widget = nil,
    MainFrame = nil,
    TabButtons = {},
    TabContents = {},
    ChatTab = {},
    FilesTab = {},
    AdminTab = {},
    HistoryTab = {},
    ProfileMenu = {},
    ThemeToggle = nil,
    LoadingOverlay = nil,
    Notifications = {}
}

-- Helper Functions
local function CreateTween(instance, properties, duration, easingStyle, easingDirection)
    local tween = TweenService:Create(
        instance,
        TweenInfo.new(duration or ANIMATION_DURATION, easingStyle or ANIMATION_EASING_STYLE, easingDirection or ANIMATION_EASING_DIRECTION),
        properties
    )
    return tween
end

local function AnimateProperty(instance, property, value, duration, easingStyle, easingDirection)
    local properties = {}
    properties[property] = value
    local tween = CreateTween(instance, properties, duration, easingStyle, easingDirection)
    tween:Play()
    return tween
end

local function ApplyTheme(themeName)
    State.CurrentTheme = themeName
    local theme = THEME[themeName]
    
    -- Apply theme to all UI elements
    -- This will be implemented when UI elements are created
end

local function ShowNotification(message, notificationType, duration)
    notificationType = notificationType or "info"
    duration = duration or 3
    
    -- Create notification UI
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 300, 0, 60)
    notification.Position = UDim2.new(1, -320, 1, 20)
    notification.AnchorPoint = Vector2.new(0, 1)
    notification.BackgroundColor3 = THEME[State.CurrentTheme].BackgroundSecondary
    notification.BorderSizePixel = 0
    notification.Parent = UI.Widget
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = notification
    
    -- Add shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = THEME[State.CurrentTheme].Shadow
    shadow.ImageTransparency = THEME[State.CurrentTheme].ShadowTransparency
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.ZIndex = notification.ZIndex - 1
    shadow.Parent = notification
    
    -- Add icon based on type
    local iconMap = {
        info = "rbxassetid://6031071053",
        success = "rbxassetid://6031068420",
        warning = "rbxassetid://6031071057",
        error = "rbxassetid://6031071054"
    }
    
    local colorMap = {
        info = THEME[State.CurrentTheme].Primary,
        success = THEME[State.CurrentTheme].Success,
        warning = THEME[State.CurrentTheme].Warning,
        error = THEME[State.CurrentTheme].Error
    }
    
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 24, 0, 24)
    icon.Position = UDim2.new(0, 16, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = iconMap[notificationType] or iconMap.info
    icon.ImageColor3 = colorMap[notificationType] or colorMap.info
    icon.Parent = notification
    
    -- Add message text
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -60, 1, 0)
    text.Position = UDim2.new(0, 50, 0, 0)
    text.BackgroundTransparency = 1
    text.Font = Enum.Font.Gotham
    text.TextSize = 14
    text.TextColor3 = THEME[State.CurrentTheme].Text
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextYAlignment = Enum.TextYAlignment.Center
    text.Text = message
    text.TextWrapped = true
    text.Parent = notification
    
    -- Animate in
    notification.Position = UDim2.new(1, 20, 1, -20)
    AnimateProperty(notification, "Position", UDim2.new(1, -20, 1, -20), 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    
    -- Add to notifications list
    table.insert(UI.Notifications, notification)
    
    -- Remove after duration
    delay(duration, function()
        -- Animate out
        local outTween = AnimateProperty(notification, "Position", UDim2.new(1, 20, 1, -20), 0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        outTween.Completed:Connect(function()
            -- Remove from list
            for i, notif in ipairs(UI.Notifications) do
                if notif == notification then
                    table.remove(UI.Notifications, i)
                    break
                end
            end
            
            -- Destroy
            notification:Destroy()
        end)
    end)
    
    return notification
end

local function ShowLoading(show, message)
    if show then
        if not UI.LoadingOverlay then
            -- Create loading overlay
            UI.LoadingOverlay = Instance.new("Frame")
            UI.LoadingOverlay.Size = UDim2.new(1, 0, 1, 0)
            UI.LoadingOverlay.BackgroundColor3 = THEME[State.CurrentTheme].Background
            UI.LoadingOverlay.BackgroundTransparency = 0.5
            UI.LoadingOverlay.ZIndex = 100
            UI.LoadingOverlay.Parent = UI.MainFrame
            
            -- Create loading spinner
            local spinner = Instance.new("ImageLabel")
            spinner.Size = UDim2.new(0, 40, 0, 40)
            spinner.Position = UDim2.new(0.5, 0, 0.5, -20)
            spinner.AnchorPoint = Vector2.new(0.5, 0.5)
            spinner.BackgroundTransparency = 1
            spinner.Image = "rbxassetid://4560909609"
            spinner.ImageColor3 = THEME[State.CurrentTheme].Primary
            spinner.ZIndex = 101
            spinner.Parent = UI.LoadingOverlay
            
            -- Create loading text
            local text = Instance.new("TextLabel")
            text.Size = UDim2.new(0, 200, 0, 20)
            text.Position = UDim2.new(0.5, 0, 0.5, 20)
            text.AnchorPoint = Vector2.new(0.5, 0.5)
            text.BackgroundTransparency = 1
            text.Font = Enum.Font.Gotham
            text.TextSize = 14
            text.TextColor3 = THEME[State.CurrentTheme].Text
            text.Text = message or "Loading..."
            text.ZIndex = 101
            text.Parent = UI.LoadingOverlay
            
            -- Animate spinner
            local spinnerRotation = 0
            local spinnerConnection = RunService.Heartbeat:Connect(function(dt)
                spinnerRotation = spinnerRotation + dt * 2
                spinner.Rotation = spinnerRotation * 180
            end)
            
            -- Store connection for cleanup
            UI.LoadingOverlay:SetAttribute("SpinnerConnection", spinnerConnection)
            
            -- Animate in
            UI.LoadingOverlay.BackgroundTransparency = 1
            AnimateProperty(UI.LoadingOverlay, "BackgroundTransparency", 0.5)
        else
            -- Update message if provided
            if message then
                local text = UI.LoadingOverlay:FindFirstChildOfClass("TextLabel")
                if text then
                    text.Text = message
                end
            end
        end
    else
        if UI.LoadingOverlay then
            -- Get spinner connection
            local spinnerConnection = UI.LoadingOverlay:GetAttribute("SpinnerConnection")
            if spinnerConnection then
                spinnerConnection:Disconnect()
            end
            
            -- Animate out
            local outTween = AnimateProperty(UI.LoadingOverlay, "BackgroundTransparency", 1)
            outTween.Completed:Connect(function()
                UI.LoadingOverlay:Destroy()
                UI.LoadingOverlay = nil
            end)
        end
    end
    
    State.IsLoading = show
end

-- API Functions
local function MakeRequest(endpoint, method, data, callback)
    State.IsLoading = true
    ShowLoading(true)
    
    local success, response = pcall(function()
        local requestMethod = method or "GET"
        local url = SERVER_URL .. endpoint
        
        if requestMethod == "GET" then
            if data then
                local queryString = "?"
                for key, value in pairs(data) do
                    queryString = queryString .. HttpService:UrlEncode(key) .. "=" .. HttpService:UrlEncode(value) .. "&"
                end
                url = url .. queryString:sub(1, -2)
            end
            return HttpService:GetAsync(url)
        else
            return HttpService:PostAsync(url, HttpService:JSONEncode(data or {}), Enum.HttpContentType.ApplicationJson)
        end
    end)
    
    ShowLoading(false)
    State.IsLoading = false
    
    if success then
        local decoded = HttpService:JSONDecode(response)
        if callback then
            callback(true, decoded)
        end
        return true, decoded
    else
        if callback then
            callback(false, {error = "request_failed", message = tostring(response)})
        end
        ShowNotification("Request failed: " .. tostring(response), "error")
        return false, {error = "request_failed", message = tostring(response)}
    end
end

local function CheckAuthorization(callback)
    local username = Players.LocalPlayer.Name
    
    MakeRequest("/auth_check", "POST", {
        username = username
    }, function(success, response)
        if success and response.authorized then
            State.IsAuthorized = true
            State.Username = username
            State.Role = response.role
            State.Permissions = response.permissions
            
            if callback then
                callback(true)
            end
            
            ShowNotification("Welcome, " .. username .. "! You are authorized as " .. response.role .. ".", "success")
        else
            State.IsAuthorized = false
            
            if callback then
                callback(false)
            end
            
            ShowNotification("Access denied. You are not authorized to use this plugin.", "error")
        end
    end)
end

local function GenerateResponse(prompt, callback)
    if not State.IsAuthorized then
        ShowNotification("You are not authorized to use this plugin.", "error")
        return
    end
    
    -- Get workspace context
    local workspaceContext = ""
    for _, obj in ipairs(game.Workspace:GetChildren()) do
        workspaceContext = workspaceContext .. obj.Name .. " (" .. obj.ClassName .. ")\n"
    end
    
    -- Add selected object context if available
    if State.SelectedObject then
        workspaceContext = workspaceContext .. "\nSelected Object: " .. State.SelectedObject.Name .. " (" .. State.SelectedObject.ClassName .. ")\n"
        
        -- Add properties for selected object
        workspaceContext = workspaceContext .. "Properties:\n"
        for _, property in ipairs({"Position", "Size", "Orientation", "Anchored", "CanCollide", "Transparency"}) do
            pcall(function()
                workspaceContext = workspaceContext .. "  " .. property .. ": " .. tostring(State.SelectedObject[property]) .. "\n"
            end)
        end
        
        -- Add script source if it's a script
        if State.SelectedObject:IsA("LuaSourceContainer") then
            workspaceContext = workspaceContext .. "\nScript Source:\n" .. State.SelectedObject.Source:sub(1, 500)
            if #State.SelectedObject.Source > 500 then
                workspaceContext = workspaceContext .. "...(truncated)"
            end
        end
    end
    
    MakeRequest("/generate", "POST", {
        username = State.Username,
        prompt = prompt,
        workspace = workspaceContext,
        model = State.CurrentModel,
        provider = State.CurrentProvider,
        conversation_id = State.CurrentConversationId
    }, function(success, response)
        if success and response.code then
            -- Store conversation ID
            State.CurrentConversationId = response.conversation_id
            
            -- Add to chat history
            table.insert(State.ChatHistory, {
                role = "user",
                content = prompt,
                timestamp = os.time()
            })
            
            table.insert(State.ChatHistory, {
                role = "assistant",
                content = response.code,
                timestamp = os.time()
            })
            
            -- Update chat UI
            UpdateChatUI()
            
            if callback then
                callback(true, response.code)
            end
        else
            ShowNotification("Failed to generate response: " .. (response.message or "Unknown error"), "error")
            
            if callback then
                callback(false, response.message or "Unknown error")
            end
        end
    end)
end

local function GetConversationHistory(callback)
    if not State.IsAuthorized then
        return
    end
    
    MakeRequest("/get_user_conversations", "GET", {
        username = State.Username
    }, function(success, response)
        if success and response.conversations then
            if callback then
                callback(response.conversations)
            end
        else
            ShowNotification("Failed to get conversation history", "error")
        end
    end)
end

local function GetConversation(conversationId, callback)
    if not State.IsAuthorized then
        return
    end
    
    MakeRequest("/get_conversation", "GET", {
        username = State.Username,
        conversation_id = conversationId
    }, function(success, response)
        if success and response.conversation then
            State.ChatHistory = response.conversation
            State.CurrentConversationId = conversationId
            
            -- Update chat UI
            UpdateChatUI()
            
            if callback then
                callback(response.conversation)
            end
        else
            ShowNotification("Failed to get conversation", "error")
        end
    end)
end

local function ClearConversation(callback)
    if not State.IsAuthorized or not State.CurrentConversationId then
        return
    end
    
    MakeRequest("/clear_conversation", "POST", {
        username = State.Username,
        conversation_id = State.CurrentConversationId
    }, function(success, response)
        if success then
            State.ChatHistory = {}
            
            -- Update chat UI
            UpdateChatUI()
            
            ShowNotification("Conversation cleared", "success")
            
            if callback then
                callback(true)
            end
        else
            ShowNotification("Failed to clear conversation", "error")
            
            if callback then
                callback(false)
            end
        end
    end)
end

local function GetAvailableModels(callback)
    MakeRequest("/get_models", "GET", {}, function(success, response)
        if success and response.models then
            State.AvailableModels = response.models
            
            if callback then
                callback(response.models)
            end
        else
            ShowNotification("Failed to get available models", "error")
        end
    end)
end

local function ListUsers(callback)
    if not State.IsAuthorized or not State.Permissions.can_manage_users then
        return
    end
    
    MakeRequest("/list_users", "GET", {
        admin_username = State.Username
    }, function(success, response)
        if success and response.users then
            State.UsersList = response.users
            
            if callback then
                callback(response.users)
            end
        else
            ShowNotification("Failed to list users", "error")
        end
    end)
end

local function AddUser(username, role, callback)
    if not State.IsAuthorized or not State.Permissions.can_manage_users then
        return
    end
    
    MakeRequest("/add_user", "POST", {
        username = username,
        role = role,
        admin_username = State.Username
    }, function(success, response)
        if success then
            ShowNotification("User added: " .. username, "success")
            
            -- Refresh user list
            ListUsers()
            
            if callback then
                callback(true)
            end
        else
            ShowNotification("Failed to add user: " .. (response.message or "Unknown error"), "error")
            
            if callback then
                callback(false)
            end
        end
    end)
end

local function RemoveUser(username, callback)
    if not State.IsAuthorized or not State.Permissions.can_manage_users then
        return
    end
    
    MakeRequest("/remove_user", "POST", {
        username = username,
        admin_username = State.Username
    }, function(success, response)
        if success then
            ShowNotification("User removed: " .. username, "success")
            
            -- Refresh user list
            ListUsers()
            
            if callback then
                callback(true)
            end
        else
            ShowNotification("Failed to remove user: " .. (response.message or "Unknown error"), "error")
            
            if callback then
                callback(false)
            end
        end
    end)
end

local function UpdateUser(username, role, callback)
    if not State.IsAuthorized or not State.Permissions.can_manage_users then
        return
    end
    
    MakeRequest("/update_user", "POST", {
        username = username,
        role = role,
        admin_username = State.Username
    }, function(success, response)
        if success then
            ShowNotification("User updated: " .. username, "success")
            
            -- Refresh user list
            ListUsers()
            
            if callback then
                callback(true)
            end
        else
            ShowNotification("Failed to update user: " .. (response.message or "Unknown error"), "error")
            
            if callback then
                callback(false)
            end
        end
    end)
end

local function GetLogs(callback)
    if not State.IsAuthorized or not State.Permissions.can_view_logs then
        return
    end
    
    MakeRequest("/get_logs", "GET", {
        admin_username = State.Username
    }, function(success, response)
        if success and response.logs then
            State.LogsList = response.logs
            
            if callback then
                callback(response.logs)
            end
        else
            ShowNotification("Failed to get logs", "error")
        end
    end)
end

local function GetUsageStats(callback)
    if not State.IsAuthorized or not State.Permissions.can_view_logs then
        return
    end
    
    MakeRequest("/get_usage_stats", "GET", {
        admin_username = State.Username
    }, function(success, response)
        if success then
            State.UsageStats = response
            
            if callback then
                callback(response)
            end
        else
            ShowNotification("Failed to get usage statistics", "error")
        end
    end)
end

local function ListFiles(callback)
    if not State.IsAuthorized then
        return
    end
    
    MakeRequest("/list_files", "GET", {
        username = State.Username
    }, function(success, response)
        if success and response.files then
            State.UploadedFiles = response.files
            
            if callback then
                callback(response.files)
            end
        else
            ShowNotification("Failed to list files", "error")
        end
    end)
end

-- UI Update Functions
local function UpdateChatUI()
    -- This will be implemented when UI elements are created
end

-- UI Creation Functions
local function CreateUI()
    -- Create widget
    local widgetInfo = DockWidgetPluginGuiInfo.new(
        Enum.InitialDockState.Float,
        true,
        false,
        500,
        600,
        300,
        200
    )
    
    UI.Widget = plugin:CreateDockWidgetPluginGui("AIAssistantGui", widgetInfo)
    UI.Widget.Title = PLUGIN_NAME
    UI.Widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Create main frame
    UI.MainFrame = Instance.new("Frame")
    UI.MainFrame.Size = UDim2.new(1, 0, 1, 0)
    UI.MainFrame.BackgroundColor3 = THEME[State.CurrentTheme].Background
    UI.MainFrame.BorderSizePixel = 0
    UI.MainFrame.Parent = UI.Widget
    
    -- Create UI components
    CreateHeader()
    CreateTabs()
    CreateChatTab()
    CreateFilesTab()
    CreateAdminTab()
    CreateHistoryTab()
    CreateProfileMenu()
    
    -- Apply initial theme
    ApplyTheme(State.CurrentTheme)
    
    -- Show initial tab
    ShowTab("Chat")
end

local function CreateHeader()
    -- Header container
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = THEME[State.CurrentTheme].BackgroundSecondary
    header.BorderSizePixel = 0
    header.Parent = UI.MainFrame
    
    -- Add shadow
    local shadow = Instance.new("Frame")
    shadow.Size = UDim2.new(1, 0, 0, 4)
    shadow.Position = UDim2.new(0, 0, 1, 0)
    shadow.BackgroundColor3 = THEME[State.CurrentTheme].Shadow
    shadow.BackgroundTransparency = 0.9
    shadow.BorderSizePixel = 0
    shadow.ZIndex = 2
    shadow.Parent = header
    
    -- Logo
    local logo = Instance.new("ImageLabel")
    logo.Size = UDim2.new(0, 30, 0, 30)
    logo.Position = UDim2.new(0, 15, 0.5, 0)
    logo.AnchorPoint = Vector2.new(0, 0.5)
    logo.BackgroundTransparency = 1
    logo.Image = "rbxassetid://6034925618" -- Replace with your logo asset ID
    logo.Parent = header
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 200, 0, 30)
    title.Position = UDim2.new(0, 55, 0.5, 0)
    title.AnchorPoint = Vector2.new(0, 0.5)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextColor3 = THEME[State.CurrentTheme].Text
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = PLUGIN_NAME
    title.Parent = header
    
    -- Profile button
    local profileButton = Instance.new("ImageButton")
    profileButton.Size = UDim2.new(0, 30, 0, 30)
    profileButton.Position = UDim2.new(1, -15, 0.5, 0)
    profileButton.AnchorPoint = Vector2.new(1, 0.5)
    profileButton.BackgroundTransparency = 1
    profileButton.Image = "rbxassetid://3926307971"
    profileButton.ImageRectOffset = Vector2.new(124, 44)
    profileButton.ImageRectSize = Vector2.new(36, 36)
    profileButton.ImageColor3 = THEME[State.CurrentTheme].Primary
    profileButton.Parent = header
    
    -- Theme toggle
    local themeToggle = Instance.new("ImageButton")
    themeToggle.Size = UDim2.new(0, 30, 0, 30)
    themeToggle.Position = UDim2.new(1, -55, 0.5, 0)
    themeToggle.AnchorPoint = Vector2.new(1, 0.5)
    themeToggle.BackgroundTransparency = 1
    themeToggle.Image = "rbxassetid://3926305904"
    themeToggle.ImageRectOffset = Vector2.new(116, 4)
    themeToggle.ImageRectSize = Vector2.new(24, 24)
    themeToggle.ImageColor3 = THEME[State.CurrentTheme].Primary
    themeToggle.Parent = header
    
    -- Store references
    UI.ProfileButton = profileButton
    UI.ThemeToggle = themeToggle
    
    -- Add hover effects
    profileButton.MouseEnter:Connect(function()
        AnimateProperty(profileButton, "ImageColor3", THEME[State.CurrentTheme].Secondary)
    end)
    
    profileButton.MouseLeave:Connect(function()
        AnimateProperty(profileButton, "ImageColor3", THEME[State.CurrentTheme].Primary)
    end)
    
    themeToggle.MouseEnter:Connect(function()
        AnimateProperty(themeToggle, "ImageColor3", THEME[State.CurrentTheme].Secondary)
    end)
    
    themeToggle.MouseLeave:Connect(function()
        AnimateProperty(themeToggle, "ImageColor3", THEME[State.CurrentTheme].Primary)
    end)
    
    -- Add click handlers
    profileButton.MouseButton1Click:Connect(function()
        ToggleProfileMenu()
    end)
    
    themeToggle.MouseButton1Click:Connect(function()
        ToggleTheme()
    end)
end

local function CreateTabs()
    -- Tabs container
    local tabsContainer = Instance.new("Frame")
    tabsContainer.Size = UDim2.new(1, 0, 0, 40)
    tabsContainer.Position = UDim2.new(0, 0, 0, 50)
    tabsContainer.BackgroundColor3 = THEME[State.CurrentTheme].Background
    tabsContainer.BorderSizePixel = 0
    tabsContainer.Parent = UI.MainFrame
    
    -- Tab buttons
    local tabData = {
        {name = "Chat", icon = "rbxassetid://3926305904", iconOffset = Vector2.new(964, 324), iconSize = Vector2.new(36, 36)},
        {name = "Files", icon = "rbxassetid://3926305904", iconOffset = Vector2.new(124, 564), iconSize = Vector2.new(36, 36)},
        {name = "History", icon = "rbxassetid://3926307971", iconOffset = Vector2.new(764, 764), iconSize = Vector2.new(36, 36)},
        {name = "Admin", icon = "rbxassetid://3926305904", iconOffset = Vector2.new(4, 844), iconSize = Vector2.new(36, 36)}
    }
    
    local tabWidth = 1 / #tabData
    
    for i, tab in ipairs(tabData) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(tabWidth, 0, 1, 0)
        button.Position = UDim2.new(tabWidth * (i - 1), 0, 0, 0)
        button.BackgroundTransparency = 1
        button.Font = Enum.Font.Gotham
        button.TextSize = 14
        button.TextColor3 = THEME[State.CurrentTheme].TextSecondary
        button.Text = ""
        button.Parent = tabsContainer
        
        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.new(0, 20, 0, 20)
        icon.Position = UDim2.new(0.5, 0, 0.5, -10)
        icon.AnchorPoint = Vector2.new(0.5, 0.5)
        icon.BackgroundTransparency = 1
        icon.Image = tab.icon
        icon.ImageRectOffset = tab.iconOffset
        icon.ImageRectSize = tab.iconSize
        icon.ImageColor3 = THEME[State.CurrentTheme].TextSecondary
        icon.Parent = button
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 14)
        label.Position = UDim2.new(0, 0, 0.5, 5)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.Gotham
        label.TextSize = 10
        label.TextColor3 = THEME[State.CurrentTheme].TextSecondary
        label.Text = tab.name
        label.Parent = button
        
        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0.6, 0, 0, 2)
        indicator.Position = UDim2.new(0.2, 0, 1, -2)
        indicator.BackgroundColor3 = THEME[State.CurrentTheme].Primary
        indicator.BorderSizePixel = 0
        indicator.Visible = false
        indicator.Parent = button
        
        -- Store references
        UI.TabButtons[tab.name] = {
            Button = button,
            Icon = icon,
            Label = label,
            Indicator = indicator
        }
        
        -- Add hover effects
        button.MouseEnter:Connect(function()
            if State.CurrentTab ~= tab.name then
                AnimateProperty(icon, "ImageColor3", THEME[State.CurrentTheme].Text)
                AnimateProperty(label, "TextColor3", THEME[State.CurrentTheme].Text)
            end
        end)
        
        button.MouseLeave:Connect(function()
            if State.CurrentTab ~= tab.name then
                AnimateProperty(icon, "ImageColor3", THEME[State.CurrentTheme].TextSecondary)
                AnimateProperty(label, "TextColor3", THEME[State.CurrentTheme].TextSecondary)
            end
        end)
        
        -- Add click handler
        button.MouseButton1Click:Connect(function()
            ShowTab(tab.name)
        end)
    end
    
    -- Tab contents container
    local contentsContainer = Instance.new("Frame")
    contentsContainer.Size = UDim2.new(1, 0, 1, -90)
    contentsContainer.Position = UDim2.new(0, 0, 0, 90)
    contentsContainer.BackgroundTransparency = 1
    contentsContainer.Parent = UI.MainFrame
    
    -- Create tab content frames
    for _, tab in ipairs(tabData) do
        local content = Instance.new("Frame")
        content.Size = UDim2.new(1, 0, 1, 0)
        content.BackgroundTransparency = 1
        content.Visible = false
        content.Parent = contentsContainer
        
        UI.TabContents[tab.name] = content
    end
end

local function ShowTab(tabName)
    -- Hide all tabs
    for name, content in pairs(UI.TabContents) do
        content.Visible = false
        
        local tabButton = UI.TabButtons[name]
        if tabButton then
            AnimateProperty(tabButton.Icon, "ImageColor3", THEME[State.CurrentTheme].TextSecondary)
            AnimateProperty(tabButton.Label, "TextColor3", THEME[State.CurrentTheme].TextSecondary)
            tabButton.Indicator.Visible = false
        end
    end
    
    -- Show selected tab
    if UI.TabContents[tabName] then
        UI.TabContents[tabName].Visible = true
        
        local tabButton = UI.TabButtons[tabName]
        if tabButton then
            AnimateProperty(tabButton.Icon, "ImageColor3", THEME[State.CurrentTheme].Primary)
            AnimateProperty(tabButton.Label, "TextColor3", THEME[State.CurrentTheme].Primary)
            tabButton.Indicator.Visible = true
        end
        
        State.CurrentTab = tabName
    end
    
    -- Load tab-specific data
    if tabName == "History" then
        GetConversationHistory()
    elseif tabName == "Admin" and State.Permissions.can_manage_users then
        ListUsers()
        GetLogs()
        GetUsageStats()
    elseif tabName == "Files" then
        ListFiles()
    end
end

local function CreateChatTab()
    local content = UI.TabContents["Chat"]
    
    -- Chat messages container
    local messagesScroll = Instance.new("ScrollingFrame")
    messagesScroll.Size = UDim2.new(1, 0, 1, -100)
    messagesScroll.BackgroundTransparency = 1
    messagesScroll.BorderSizePixel = 0
    messagesScroll.ScrollBarThickness = 4
    messagesScroll.ScrollBarImageColor3 = THEME[State.CurrentTheme].Secondary
    messagesScroll.Parent = content
    
    local messagesLayout = Instance.new("UIListLayout")
    messagesLayout.SortOrder = Enum.SortOrder.LayoutOrder
    messagesLayout.Padding = UDim.new(0, 10)
    messagesLayout.Parent = messagesScroll
    
    local messagesPadding = Instance.new("UIPadding")
    messagesPadding.PaddingTop = UDim.new(0, 10)
    messagesPadding.PaddingBottom = UDim.new(0, 10)
    messagesPadding.PaddingLeft = UDim.new(0, 10)
    messagesPadding.PaddingRight = UDim.new(0, 10)
    messagesPadding.Parent = messagesScroll
    
    -- Input container
    local inputContainer = Instance.new("Frame")
    inputContainer.Size = UDim2.new(1, 0, 0, 100)
    inputContainer.Position = UDim2.new(0, 0, 1, -100)
    inputContainer.BackgroundColor3 = THEME[State.CurrentTheme].BackgroundSecondary
    inputContainer.BorderSizePixel = 0
    inputContainer.Parent = content
    
    local inputPadding = Instance.new("UIPadding")
    inputPadding.PaddingTop = UDim.new(0, 10)
    inputPadding.PaddingBottom = UDim.new(0, 10)
    inputPadding.PaddingLeft = UDim.new(0, 10)
    inputPadding.PaddingRight = UDim.new(0, 10)
    inputPadding.Parent = inputContainer
    
    -- Input text box
    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(1, -80, 1, -20)
    inputBox.Position = UDim2.new(0, 0, 0, 0)
    inputBox.BackgroundColor3 = THEME[State.CurrentTheme].Background
    inputBox.TextColor3 = THEME[State.CurrentTheme].Text
    inputBox.PlaceholderColor3 = THEME[State.CurrentTheme].TextSecondary
    inputBox.PlaceholderText = "Ask me anything about Roblox Studio..."
    inputBox.Font = Enum.Font.Gotham
    inputBox.TextSize = 14
    inputBox.TextXAlignment = Enum.TextXAlignment.Left
    inputBox.TextYAlignment = Enum.TextYAlignment.Top
    inputBox.ClearTextOnFocus = false
    inputBox.MultiLine = true
    inputBox.TextWrapped = true
    inputBox.Parent = inputContainer
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = inputBox
    
    -- Send button
    local sendButton = Instance.new("TextButton")
    sendButton.Size = UDim2.new(0, 60, 0, 60)
    sendButton.Position = UDim2.new(1, -60, 0, 10)
    sendButton.BackgroundColor3 = THEME[State.CurrentTheme].Primary
    sendButton.Text = ""
    sendButton.Parent = inputContainer
    
    -- Add corner radius
    local sendCorner = Instance.new("UICorner")
    sendCorner.CornerRadius = UDim.new(0, 8)
    sendCorner.Parent = sendButton
    
    -- Send icon
    local sendIcon = Instance.new("ImageLabel")
    sendIcon.Size = UDim2.new(0, 24, 0, 24)
    sendIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    sendIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    sendIcon.BackgroundTransparency = 1
    sendIcon.Image = "rbxassetid://3926305904"
    sendIcon.ImageRectOffset = Vector2.new(924, 884)
    sendIcon.ImageRectSize = Vector2.new(36, 36)
    sendIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    sendIcon.Parent = sendButton
    
    -- Model selector
    local modelSelector = Instance.new("TextButton")
    modelSelector.Size = UDim2.new(0, 120, 0, 30)
    modelSelector.Position = UDim2.new(0, 10, 0, -40)
    modelSelector.BackgroundColor3 = THEME[State.CurrentTheme].BackgroundSecondary
    modelSelector.TextColor3 = THEME[State.CurrentTheme].Text
    modelSelector.Font = Enum.Font.Gotham
    modelSelector.TextSize = 12
    modelSelector.Text = "Model: Mistral"
    modelSelector.Parent = inputContainer
    
    -- Add corner radius
    local modelCorner = Instance.new("UICorner")
    modelCorner.CornerRadius = UDim.new(0, 6)
    modelCorner.Parent = modelSelector
    
    -- Clear button
    local clearButton = Instance.new("TextButton")
    clearButton.Size = UDim2.new(0, 80, 0, 30)
    clearButton.Position = UDim2.new(1, -90, 0, -40)
    clearButton.BackgroundColor3 = THEME[State.CurrentTheme].Error
    clearButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearButton.Font = Enum.Font.Gotham
    clearButton.TextSize = 12
    clearButton.Text = "Clear Chat"
    clearButton.Parent = inputContainer
    
    -- Add corner radius
    local clearCorner = Instance.new("UICorner")
    clearCorner.CornerRadius = UDim.new(0, 6)
    clearCorner.Parent = clearButton
    
    -- Store references
    UI.ChatTab.MessagesScroll = messagesScroll
    UI.ChatTab.InputBox = inputBox
    UI.ChatTab.SendButton = sendButton
    UI.ChatTab.ModelSelector = modelSelector
    UI.ChatTab.ClearButton = clearButton
    
    -- Add hover effects
    sendButton.MouseEnter:Connect(function()
        AnimateProperty(sendButton, "BackgroundColor3", THEME[State.CurrentTheme].Secondary)
    end)
    
    sendButton.MouseLeave:Connect(function()
        AnimateProperty(sendButton, "BackgroundColor3", THEME[State.CurrentTheme].Primary)
    end)
    
    modelSelector.MouseEnter:Connect(function()
        AnimateProperty(modelSelector, "BackgroundColor3", THEME[State.CurrentTheme].Border)
    end)
    
    modelSelector.MouseLeave:Connect(function()
        AnimateProperty(modelSelector, "BackgroundColor3", THEME[State.CurrentTheme].BackgroundSecondary)
    end)
    
    clearButton.MouseEnter:Connect(function()
        AnimateProperty(clearButton, "BackgroundColor3", Color3.fromRGB(255, 100, 100))
    end)
    
    clearButton.MouseLeave:Connect(function()
        AnimateProperty(clearButton, "BackgroundColor3", THEME[State.CurrentTheme].Error)
    end)
    
    -- Add click handlers
    sendButton.MouseButton1Click:Connect(function()
        local prompt = inputBox.Text
        if prompt and prompt:gsub("%s", "") ~= "" then
            inputBox.Text = ""
            GenerateResponse(prompt)
        end
    end)
    
    modelSelector.MouseButton1Click:Connect(function()
        -- Toggle between models
        local models = {
            ["mistralai/mistral-7b-instruct:free"] = "Mistral",
            ["openai/gpt-4:free"] = "GPT-4",
            ["anthropic/claude-3-sonnet:free"] = "Claude"
        }
        
        local nextModels = {
            ["mistralai/mistral-7b-instruct:free"] = "openai/gpt-4:free",
            ["openai/gpt-4:free"] = "anthropic/claude-3-sonnet:free",
            ["anthropic/claude-3-sonnet:free"] = "mistralai/mistral-7b-instruct:free"
        }
        
        State.CurrentModel = nextModels[State.CurrentModel] or "mistralai/mistral-7b-instruct:free"
        modelSelector.Text = "Model: " .. (models[State.CurrentModel] or "Mistral")
    end)
    
    clearButton.MouseButton1Click:Connect(function()
        ClearConversation()
    end)
    
    -- Update function for chat UI
    function UpdateChatUI()
        -- Clear existing messages
        for _, child in ipairs(messagesScroll:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        -- Add messages
        for i, message in ipairs(State.ChatHistory) do
            local isUser = message.role == "user"
            
            local messageFrame = Instance.new("Frame")
            messageFrame.Size = UDim2.new(1, 0, 0, 0) -- Auto-size
            messageFrame.AutomaticSize = Enum.AutomaticSize.Y
            messageFrame.BackgroundTransparency = 1
            messageFrame.LayoutOrder = i
            messageFrame.Parent = messagesScroll
            
            local bubbleFrame = Instance.new("Frame")
            bubbleFrame.Size = UDim2.new(0.8, 0, 0, 0) -- Auto-size
            bubbleFrame.AutomaticSize = Enum.AutomaticSize.Y
            bubbleFrame.Position = isUser and UDim2.new(1, 0, 0, 0) or UDim2.new(0, 0, 0, 0)
            bubbleFrame.AnchorPoint = isUser and Vector2.new(1, 0) or Vector2.new(0, 0)
            bubbleFrame.BackgroundColor3 = isUser and THEME[State.CurrentTheme].Primary or THEME[State.CurrentTheme].BackgroundSecondary
            bubbleFrame.Parent = messageFrame
            
            -- Add corner radius
            local bubbleCorner = Instance.new("UICorner")
            bubbleCorner.CornerRadius = UDim.new(0, 12)
            bubbleCorner.Parent = bubbleFrame
            
            -- Add padding
            local bubblePadding = Instance.new("UIPadding")
            bubblePadding.PaddingTop = UDim.new(0, 10)
            bubblePadding.PaddingBottom = UDim.new(0, 10)
            bubblePadding.PaddingLeft = UDim.new(0, 10)
            bubblePadding.PaddingRight = UDim.new(0, 10)
            bubblePadding.Parent = bubbleFrame
            
            -- Message text
            local messageText = Instance.new("TextLabel")
            messageText.Size = UDim2.new(1, 0, 0, 0) -- Auto-size
            messageText.AutomaticSize = Enum.AutomaticSize.Y
            messageText.BackgroundTransparency = 1
            messageText.Font = Enum.Font.Gotham
            messageText.TextSize = 14
            messageText.TextColor3 = isUser and Color3.fromRGB(255, 255, 255) or THEME[State.CurrentTheme].Text
            messageText.TextXAlignment = Enum.TextXAlignment.Left
            messageText.TextYAlignment = Enum.TextYAlignment.Top
            messageText.TextWrapped = true
            messageText.Text = message.content
            messageText.Parent = bubbleFrame
        end
        
        -- Scroll to bottom
        messagesScroll.CanvasPosition = Vector2.new(0, messagesScroll.CanvasSize.Y.Offset)
    end
end

-- Initialize plugin
local function Initialize()
    -- Create toolbar button
    local toolbar = plugin:CreateToolbar(PLUGIN_NAME)
    local button = toolbar:CreateButton(
        PLUGIN_NAME,
        "Open " .. PLUGIN_NAME,
        "rbxassetid://6034925618" -- Replace with your icon asset ID
    )
    
    -- Create UI
    CreateUI()
    
    -- Connect button click
    button.Click:Connect(function()
        UI.Widget.Enabled = not UI.Widget.Enabled
        
        if UI.Widget.Enabled then
            -- Check authorization when opened
            CheckAuthorization()
        end
    end)
    
    -- Connect selection changed event
    Selection.SelectionChanged:Connect(function()
        local selected = Selection:Get()
        if #selected > 0 then
            State.SelectedObject = selected[1]
        else
            State.SelectedObject = nil
        end
    end)
    
    -- Initial state
    UI.Widget.Enabled = false
end

-- Start the plugin
Initialize()


-- Continue implementing UI components

local function CreateFilesTab()
    local content = UI.TabContents["Files"]
    
    -- Files container
    local filesContainer = Instance.new("ScrollingFrame")
    filesContainer.Size = UDim2.new(1, 0, 1, -60)
    filesContainer.BackgroundTransparency = 1
    filesContainer.BorderSizePixel = 0
    filesContainer.ScrollBarThickness = 4
    filesContainer.ScrollBarImageColor3 = THEME[State.CurrentTheme].Secondary
    filesContainer.Parent = content
    
    local filesLayout = Instance.new("UIGridLayout")
    filesLayout.CellSize = UDim2.new(0, 100, 0, 120)
    filesLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    filesLayout.SortOrder = Enum.SortOrder.Name
    filesLayout.Parent = filesContainer
    
    local filesPadding = Instance.new("UIPadding")
    filesPadding.PaddingTop = UDim.new(0, 10)
    filesPadding.PaddingBottom = UDim.new(0, 10)
    filesPadding.PaddingLeft = UDim.new(0, 10)
    filesPadding.PaddingRight = UDim.new(0, 10)
    filesPadding.Parent = filesContainer
    
    -- Upload button
    local uploadButton = Instance.new("TextButton")
    uploadButton.Size = UDim2.new(0, 120, 0, 40)
    uploadButton.Position = UDim2.new(0, 10, 1, -50)
    uploadButton.BackgroundColor3 = THEME[State.CurrentTheme].Primary
    uploadButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    uploadButton.Font = Enum.Font.GothamBold
    uploadButton.TextSize = 14
    uploadButton.Text = "Upload File"
    uploadButton.Parent = content
    
    -- Add corner radius
    local uploadCorner = Instance.new("UICorner")
    uploadCorner.CornerRadius = UDim.new(0, 8)
    uploadCorner.Parent = uploadButton
    
    -- Filter dropdown
    local filterButton = Instance.new("TextButton")
    filterButton.Size = UDim2.new(0, 120, 0, 40)
    filterButton.Position = UDim2.new(1, -130, 1, -50)
    filterButton.BackgroundColor3 = THEME[State.CurrentTheme].BackgroundSecondary
    filterButton.TextColor3 = THEME[State.CurrentTheme].Text
    filterButton.Font = Enum.Font.Gotham
    filterButton.TextSize = 14
    filterButton.Text = "Filter: All"
    filterButton.Parent = content
    
    -- Add corner radius
    local filterCorner = Instance.new("UICorner")
    filterCorner.CornerRadius = UDim.new(0, 8)
    filterCorner.Parent = filterButton
    
    -- Store references
    UI.FilesTab.FilesContainer = filesContainer
    UI.FilesTab.UploadButton = uploadButton
    UI.FilesTab.FilterButton = filterButton
    
    -- Add hover effects
    uploadButton.MouseEnter:Connect(function()
        AnimateProperty(uploadButton, "BackgroundColor3", THEME[State.CurrentTheme].Secondary)
    end)
    
    uploadButton.MouseLeave:Connect(function()
        AnimateProperty(uploadButton, "BackgroundColor3", THEME[State.CurrentTheme].Primary)
    end)
    
    filterButton.MouseEnter:Connect(function()
        AnimateProperty(filterButton, "BackgroundColor3", THEME[State.CurrentTheme].Border)
    end)
    
    filterButton.MouseLeave:Connect(function()
        AnimateProperty(filterButton, "BackgroundColor3", THEME[State.CurrentTheme].BackgroundSecondary)
    end)
    
    -- Add click handlers
    uploadButton.MouseButton1Click:Connect(function()
        -- Open file dialog
        local file = plugin:PromptImportFile({"rbxm", "rbxmx", "lua", "txt", "json"})
        if file then
            -- Show loading
            ShowLoading(true, "Uploading file...")
            
            -- Import the file
            local imported = game:GetObjects(file:GetTemporaryId())
            if #imported > 0 then
                -- Show success
                ShowLoading(false)
                ShowNotification("File imported successfully", "success")
                
                -- Add to workspace
                imported[1].Parent = game.Workspace
                
                -- Select the imported object
                Selection:Set({imported[1]})
            else
                -- Show error
                ShowLoading(false)
                ShowNotification("Failed to import file", "error")
            end
        end
    end)
    
    filterButton.MouseButton1Click:Connect(function()
        -- Toggle between filter options
        local filters = {"All", "Models", "Scripts", "Images"}
        local currentFilter = filterButton.Text:match("Filter: (.+)") or "All"
        local nextIndex = (table.find(filters, currentFilter) or 0) % #filters + 1
        local nextFilter = filters[nextIndex]
        
        filterButton.Text = "Filter: " .. nextFilter
        
        -- Apply filter
        UpdateFilesUI(nextFilter)
    end)
    
    -- Function to update files UI
    function UpdateFilesUI(filter)
        filter = filter or "All"
        
        -- Clear existing files
        for _, child in ipairs(filesContainer:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        -- Filter files
        local filteredFiles = {}
        for _, file in ipairs(State.UploadedFiles) do
            if filter == "All" or string.lower(file.type) == string.lower(filter) then
                table.insert(filteredFiles, file)
            end
        end
        
        -- Add files
        for _, file in ipairs(filteredFiles) do
            local fileFrame = Instance.new("Frame")
            fileFrame.Size = UDim2.new(0, 100, 0, 120)
            fileFrame.BackgroundColor3 = THEME[State.CurrentTheme].BackgroundSecondary
            fileFrame.Parent = filesContainer
            
            -- Add corner radius
            local fileCorner = Instance.new("UICorner")
            fileCorner.CornerRadius = UDim.new(0, 8)
            fileCorner.Parent = fileFrame
            
            -- File icon
            local iconMap = {
                model = "rbxassetid://6022668955",
                script = "rbxassetid://6022668883",
                image = "rbxassetid://6022668916",
                unknown = "rbxassetid://6022668945"
            }
            
            local fileIcon = Instance.new("ImageLabel")
            fileIcon.Size = UDim2.new(0, 50, 0, 50)
            fileIcon.Position = UDim2.new(0.5, 0, 0, 10)
            fileIcon.AnchorPoint = Vector2.new(0.5, 0)
            fileIcon.BackgroundTransparency = 1
            fileIcon.Image = iconMap[string.lower(file.type)] or iconMap.unknown
            fileIcon.Parent = fileFrame
            
            -- File name
            local fileName = Instance.new("TextLabel")
            fileName.Size = UDim2.new(1, -10, 0, 40)
            fileName.Position = UDim2.new(0, 5, 0, 65)
            fileName.BackgroundTransparency = 1
            fileName.Font = Enum.Font.Gotham
            fileName.TextSize = 12
            fileName.TextColor3 = THEME[State.CurrentTheme].Text
            fileName.TextWrapped = true
            fileName.Text = file.filename
            fileName.Parent = fileFrame
            
            -- Add hover effect
            fileFrame.MouseEnter:Connect(function()
                AnimateProperty(fileFrame, "BackgroundColor3", THEME[State.CurrentTheme].Border)
            end)
            
            fileFrame.MouseLeave:Connect(function()
                AnimateProperty(fileFrame, "BackgroundColor3", THEME[State.CurrentTheme].BackgroundSecondary)
            end)
        end
    end
end

local function CreateAdminTab()
    local content = UI.TabContents["Admin"]
    
    -- Admin tabs
    local adminTabs = {"Users", "Logs", "Stats"}
    local adminTabButtons = {}
    local adminTabContents = {}
    
    -- Create tab buttons
    for i, tabName in ipairs(adminTabs) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1/#adminTabs, 0, 0, 40)
        button.Position = UDim2.new((i-1)/#adminTabs, 0, 0, 0)
        button.BackgroundColor3 = THEME[State.CurrentTheme].BackgroundSecondary
        button.TextColor3 = THEME[State.CurrentTheme].TextSecondary
        button.Font = Enum.Font.GothamBold
        button.TextSize = 14
        button.Text = tabName
        button.Parent = content
        
        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0.8, 0, 0, 2)
        indicator.Position = UDim2.new(0.1, 0, 1, -2)
        indicator.BackgroundColor3 = THEME[State.CurrentTheme].Primary
        indicator.BorderSizePixel = 0
        indicator.Visible = i == 1
        indicator.Parent = button
        
        adminTabButtons[tabName] = {
            Button = button,
            Indicator = indicator
        }
        
        -- Create tab content
        local tabContent = Instance.new("Frame")
        tabContent.Size = UDim2.new(1, 0, 1, -40)
        tabContent.Position = UDim2.new(0, 0, 0, 40)
        tabContent.BackgroundTransparency = 1
        tabContent.Visible = i == 1
        tabContent.Parent = content
        
        adminTabContents[tabName] = tabContent
        
        -- Add hover effects
        button.MouseEnter:Connect(function()
            if not indicator.Visible then
                AnimateProperty(button, "TextColor3", THEME[State.CurrentTheme].Text)
            end
        end)
        
        button.MouseLeave:Connect(function()
            if not indicator.Visible then
                AnimateProperty(button, "TextColor3", THEME[State.CurrentTheme].TextSecondary)
            end
        end)
        
        -- Add click handler
        button.MouseButton1Click:Connect(function()
            -- Hide all tabs
            for _, tabName in ipairs(adminTabs) do
                adminTabContents[tabName].Visible = false
                adminTabButtons[tabName].Indicator.Visible = false
                AnimateProperty(adminTabButtons[tabName].Button, "TextColor3", THEME[State.CurrentTheme].TextSecondary)
            end
            
            -- Show selected tab
            tabContent.Visible = true
            indicator.Visible = true
            AnimateProperty(button, "TextColor3", THEME[State.CurrentTheme].Primary)
        end)
    end
    
    -- Create Users tab content
    local usersContent = adminTabContents["Users"]
    
    -- Users list
    local usersList = Instance.new("ScrollingFrame")
    usersList.Size = UDim2.new(1, 0, 1, -60)
    usersList.BackgroundTransparency = 1
    usersList.BorderSizePixel = 0
    usersList.ScrollBarThickness = 4
    usersList.ScrollBarImageColor3 = THEME[State.CurrentTheme].Secondary
    usersList.Parent = usersContent
    
    local usersLayout = Instance.new("UIListLayout")
    usersLayout.SortOrder = Enum.SortOrder.LayoutOrder
    usersLayout.Padding = UDim.new(0, 5)
    usersLayout.Parent = usersList
    
    local usersPadding = Instance.new("UIPadding")
    usersPadding.PaddingTop = UDim.new(0, 10)
    usersPadding.PaddingBottom = UDim.new(0, 10)
    usersPadding.PaddingLeft = UDim.new(0, 10)
    usersPadding.PaddingRight = UDim.new(0, 10)
    usersPadding.Parent = usersList
    
    -- Add user input
    local userInput = Instance.new("TextBox")
    userInput.Size = UDim2.new(0.6, -10, 0, 40)
    userInput.Position = UDim2.new(0, 10, 1, -50)
    userInput.BackgroundColor3 = THEME[State.CurrentTheme].Background
    userInput.TextColor3 = THEME[State.CurrentTheme].Text
    userInput.PlaceholderColor3 = THEME[State.CurrentTheme].TextSecondary
    userInput.PlaceholderText = "Enter username..."
    userInput.Font = Enum.Font.Gotham
    userInput.TextSize = 14
    userInput.TextXAlignment = Enum.TextXAlignment.Left
    userInput.ClearTextOnFocus = false
    userInput.Parent = usersContent
    
    -- Add corner radius
    local userInputCorner = Instance.new("UICorner")
    userInputCorner.CornerRadius = UDim.new(0, 8)
    userInputCorner.Parent = userInput
    
    -- Add padding
    local userInputPadding = Instance.new("UIPadding")
    userInputPadding.PaddingLeft = UDim.new(0, 10)
    userInputPadding.PaddingRight = UDim.new(0, 10)
    userInputPadding.Parent = userInput
    
    -- Add user button
    local addUserButton = Instance.new("TextButton")
    addUserButton.Size = UDim2.new(0.4, -10, 0, 40)
    addUserButton.Position = UDim2.new(0.6, 10, 1, -50)
    addUserButton.BackgroundColor3 = THEME[State.CurrentTheme].Primary
    addUserButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    addUserButton.Font = Enum.Font.GothamBold
    addUserButton.TextSize = 14
    addUserButton.Text = "Add User"
    addUserButton.Parent = usersContent
    
    -- Add corner radius
    local addUserCorner = Instance.new("UICorner")
    addUserCorner.CornerRadius = UDim.new(0, 8)
    addUserCorner.Parent = addUserButton
    
    -- Store references
    UI.AdminTab.UsersList = usersList
    UI.AdminTab.UserInput = userInput
    UI.AdminTab.AddUserButton = addUserButton
    
    -- Add hover effects
    addUserButton.MouseEnter:Connect(function()
        AnimateProperty(addUserButton, "BackgroundColor3", THEME[State.CurrentTheme].Secondary)
    end)
    
    addUserButton.MouseLeave:Connect(function()
        AnimateProperty(addUserButton, "BackgroundColor3", THEME[State.CurrentTheme].Primary)
    end)
    
    -- Add click handler
    addUserButton.MouseButton1Click:Connect(function()
        local username = userInput.Text
        if username and username:gsub("%s", "") ~= "" then
            AddUser(username, "User")
            userInput.Text = ""
        end
    end)
    
    -- Create Logs tab content
    local logsContent = adminTabContents["Logs"]
    
    -- Logs list
    local logsList = Instance.new("ScrollingFrame")
    logsList.Size = UDim2.new(1, 0, 1, 0)
    logsList.BackgroundTransparency = 1
    logsList.BorderSizePixel = 0
    logsList.ScrollBarThickness = 4
    logsList.ScrollBarImageColor3 = THEME[State.CurrentTheme].Secondary
    logsList.Parent = logsContent
    
    local logsLayout = Instance.new("UIListLayout")
    logsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    logsLayout.Padding = UDim.new(0, 5)
    logsLayout.Parent = logsList
    
    local logsPadding = Instance.new("UIPadding")
    logsPadding.PaddingTop = UDim.new(0, 10)
    logsPadding.PaddingBottom = UDim.new(0, 10)
    logsPadding.PaddingLeft = UDim.new(0, 10)
    logsPadding.PaddingRight = UDim.new(0, 10)
    logsPadding.Parent = logsList
    
    -- Store references
    UI.AdminTab.LogsList = logsList
    
    -- Create Stats tab content
    local statsContent = adminTabContents["Stats"]
    
    -- Stats container
    local statsContainer = Instance.new("Frame")
    statsContainer.Size = UDim2.new(1, 0, 1, 0)
    statsContainer.BackgroundTransparency = 1
    statsContainer.Parent = statsContent
    
    -- Total requests
    local totalRequestsFrame = Instance.new("Frame")
    totalRequestsFrame.Size = UDim2.new(0.5, -10, 0, 100)
    totalRequestsFrame.Position = UDim2.new(0, 10, 0, 10)
    totalRequestsFrame.BackgroundColor3 = THEME[State.CurrentTheme].BackgroundSecondary
    totalRequestsFrame.Parent = statsContainer
    
    -- Add corner radius
    local totalRequestsCorner = Instance.new("UICorner")
    totalRequestsCorner.CornerRadius = UDim.new(0, 8)
    totalRequestsCorner.Parent = totalRequestsFrame
    
    local totalRequestsLabel = Instance.new("TextLabel")
    totalRequestsLabel.Size = UDim2.new(1, 0, 0, 20)
    totalRequestsLabel.Position = UDim2.new(0, 0, 0, 10)
    totalRequestsLabel.BackgroundTransparency = 1
    totalRequestsLabel.Font = Enum.Font.GothamBold
    totalRequestsLabel.TextSize = 14
    totalRequestsLabel.TextColor3 = THEME[State.CurrentTheme].Text
    totalRequestsLabel.Text = "Total Requests"
    totalRequestsLabel.Parent = totalRequestsFrame
    
    local totalRequestsValue = Instance.new("TextLabel")
    totalRequestsValue.Size = UDim2.new(1, 0, 0, 40)
    totalRequestsValue.Position = UDim2.new(0, 0, 0, 40)
    totalRequestsValue.BackgroundTransparency = 1
    totalRequestsValue.Font = Enum.Font.GothamBold
    totalRequestsValue.TextSize = 32
    totalRequestsValue.TextColor3 = THEME[State.CurrentTheme].Primary
    totalRequestsValue.Text = "0"
    totalRequestsValue.Parent = totalRequestsFrame
    
    -- User count
    local userCountFrame = Instance.new("Frame")
    userCountFrame.Size = UDim2.new(0.5, -10, 0, 100)
    userCountFrame.Position = UDim2.new(0.5, 0, 0, 10)
    userCountFrame.BackgroundColor3 = THEME[State.CurrentTheme].BackgroundSecondary
    userCountFrame.Parent = statsContainer
    
    -- Add corner radius
    local userCountCorner = Instance.new("UICorner")
    userCountCorner.CornerRadius = UDim.new(0, 8)
    userCountCorner.Parent = userCountFrame
    
    local userCountLabel = Instance.new("TextLabel")
    userCountLabel.Size = UDim2.new(1, 0, 0, 20)
    userCountLabel.Position = UDim2.new(0, 0, 0, 10)
    userCountLabel.BackgroundTransparency = 1
    userCountLabel.Font = Enum.Font.GothamBold
    userCountLabel.TextSize = 14
    userCountLabel.TextColor3 = THEME[State.CurrentTheme].Text
    userCountLabel.Text = "Total Users"
    userCountLabel.Parent = userCountFrame
    
    local userCountValue = Instance.new("TextLabel")
    userCountValue.Size = UDim2.new(1, 0, 0, 40)
    userCountValue.Position = UDim2.new(0, 0, 0, 40)
    userCountValue.BackgroundTransparency = 1
    userCountValue.Font = Enum.Font.GothamBold
    userCountValue.TextSize = 32
    userCountValue.TextColor3 = THEME[State.CurrentTheme].Success
    userCountValue.Text = "0"
    userCountValue.Parent = userCountFrame
    
    -- Model usage
    local modelUsageFrame = Instance.new("Frame")
    modelUsageFrame.Size = UDim2.new(1, -20, 0, 200)
    modelUsageFrame.Position = UDim2.new(0, 10, 0, 120)
    modelUsageFrame.BackgroundColor3 = THEME[State.CurrentTheme].BackgroundSecondary
    modelUsageFrame.Parent = statsContainer
    
    -- Add corner radius
    local modelUsageCorner = Instance.new("UICorner")
    modelUsageCorner.CornerRadius = UDim.new(0, 8)
    modelUsageCorner.Parent = modelUsageFrame
    
    local modelUsageLabel = Instance.new("TextLabel")
    modelUsageLabel.Size = UDim2.new(1, 0, 0, 20)
    modelUsageLabel.Position = UDim2.new(0, 0, 0, 10)
    modelUsageLabel.BackgroundTransparency = 1
    modelUsageLabel.Font = Enum.Font.GothamBold
    modelUsageLabel.TextSize = 14
    modelUsageLabel.TextColor3 = THEME[State.CurrentTheme].Text
    modelUsageLabel.Text = "Model Usage"
    modelUsageLabel.Parent = modelUsageFrame
    
    -- Store references
    UI.AdminTab.TotalRequestsValue = totalRequestsValue
    UI.AdminTab.UserCountValue = userCountValue
    UI.AdminTab.ModelUsageFrame = modelUsageFrame
    
    -- Function to update users UI
    function UpdateUsersUI()
        -- Clear existing users
        for _, child in ipairs(usersList:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        -- Add users
        for i, user in ipairs(State.UsersList) do
            local userFrame = Instance.new("Frame")
            userFrame.Size = UDim2.new(1, 0, 0, 50)
            userFrame.BackgroundColor3 = THEME[State.CurrentTheme].BackgroundSecondary
            userFrame.LayoutOrder = i
            userFrame.Parent = usersList
            
            -- Add corner radius
            local userCorner = Instance.new("UICorner")
            userCorner.CornerRadius = UDim.new(0, 8)
            userCorner.Parent = userFrame
            
            -- Username
            local username = Instance.new("TextLabel")
            username.Size = UDim2.new(0.4, 0, 1, 0)
            username.Position = UDim2.new(0, 10, 0, 0)
            username.BackgroundTransparency = 1
            username.Font = Enum.Font.GothamBold
            username.TextSize = 14
            username.TextColor3 = THEME[State.CurrentTheme].Text
            username.TextXAlignment = Enum.TextXAlignment.Left
            username.Text = user.username
            username.Parent = userFrame
            
            -- Role
            local role = Instance.new("TextLabel")
            role.Size = UDim2.new(0.3, 0, 1, 0)
            role.Position = UDim2.new(0.4, 0, 0, 0)
            role.BackgroundTransparency = 1
            role.Font = Enum.Font.Gotham
            role.TextSize = 14
            role.TextColor3 = THEME[State.CurrentTheme].TextSecondary
            role.Text = user.role
            role.Parent = userFrame
            
            -- Remove button
            local removeButton = Instance.new("TextButton")
            removeButton.Size = UDim2.new(0, 80, 0, 30)
            removeButton.Position = UDim2.new(1, -90, 0.5, 0)
            removeButton.AnchorPoint = Vector2.new(0, 0.5)
            removeButton.BackgroundColor3 = THEME[State.CurrentTheme].Error
            removeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            removeButton.Font = Enum.Font.GothamBold
            removeButton.TextSize = 12
            removeButton.Text = "Remove"
            removeButton.Parent = userFrame
            
            -- Add corner radius
            local removeCorner = Instance.new("UICorner")
            removeCorner.CornerRadius = UDim.new(0, 6)
            removeCorner.Parent = removeButton
            
            -- Add hover effects
            removeButton.MouseEnter:Connect(function()
                AnimateProperty(removeButton, "BackgroundColor3", Color3.fromRGB(255, 100, 100))
            end)
            
            removeButton.MouseLeave:Connect(function()
                AnimateProperty(removeButton, "BackgroundColor3", THEME[State.CurrentTheme].Error)
            end)
            
            -- Add click handler
            removeButton.MouseButton1Click:Connect(function()
                RemoveUser(user.username)
            end)
        end
    end
    
    -- Function to update logs UI
    function UpdateLogsUI()
        -- Clear existing logs
        for _, child in ipairs(logsList:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        -- Add logs
        for i, log in ipairs(State.LogsList) do
            local logFrame = Instance.new("Frame")
            logFrame.Size = UDim2.new(1, 0, 0, 80)
            logFrame.BackgroundColor3 = THEME[State.CurrentTheme].BackgroundSecondary
            logFrame.LayoutOrder = i
            logFrame.Parent = logsList
            
            -- Add corner radius
            local logCorner = Instance.new("UICorner")
            logCorner.CornerRadius = UDim.new(0, 8)
            logCorner.Parent = logFrame
            
            -- Username and timestamp
            local header = Instance.new("TextLabel")
            header.Size = UDim2.new(1, -20, 0, 20)
            header.Position = UDim2.new(0, 10, 0, 5)
            header.BackgroundTransparency = 1
            header.Font = Enum.Font.GothamBold
            header.TextSize = 12
            header.TextColor3 = THEME[State.CurrentTheme].Primary
            header.TextXAlignment = Enum.TextXAlignment.Left
            
            -- Format timestamp
            local timestamp = log.timestamp
            if type(timestamp) == "string" then
                local success, dateTime = pcall(function()
                    return DateTime.fromIsoDate(timestamp)
                end)
                
                if success then
                    timestamp = dateTime:FormatLocalTime("LLL", "en-us")
                end
            end
            
            header.Text = log.username .. " • " .. timestamp .. " • " .. log.model
            header.Parent = logFrame
            
            -- Prompt
            local prompt = Instance.new("TextLabel")
            prompt.Size = UDim2.new(1, -20, 0, 40)
            prompt.Position = UDim2.new(0, 10, 0, 30)
            prompt.BackgroundTransparency = 1
            prompt.Font = Enum.Font.Gotham
            prompt.TextSize = 12
            prompt.TextColor3 = THEME[State.CurrentTheme].Text
            prompt.TextXAlignment = Enum.TextXAlignment.Left
            prompt.TextYAlignment = Enum.TextYAlignment.Top
            prompt.TextWrapped = true
            prompt.Text = log.prompt
            prompt.Parent = logFrame
        end
    end
    
    -- Function to update stats UI
    function UpdateStatsUI()
        if not State.UsageStats then return end
        
        -- Update total requests
        UI.AdminTab.TotalRequestsValue.Text = tostring(State.UsageStats.total_requests or 0)
        
        -- Update user count
        UI.AdminTab.UserCountValue.Text = tostring(#State.UsersList)
        
        -- Update model usage
        local modelUsageFrame = UI.AdminTab.ModelUsageFrame
        
        -- Clear existing model usage
        for _, child in ipairs(modelUsageFrame:GetChildren()) do
            if child:IsA("Frame") and child.Name == "ModelBar" then
                child:Destroy()
            end
        end
        
        -- Add model usage bars
        local modelCounts = State.UsageStats.model_counts or {}
        local totalCount = State.UsageStats.total_requests or 0
        
        local yOffset = 40
        local barHeight = 20
        local spacing = 5
        
        for model, count in pairs(modelCounts) do
            local percentage = totalCount > 0 and (count / totalCount) or 0
            
            local barFrame = Instance.new("Frame")
            barFrame.Name = "ModelBar"
            barFrame.Size = UDim2.new(1, -20, 0, barHeight)
            barFrame.Position = UDim2.new(0, 10, 0, yOffset)
            barFrame.BackgroundColor3 = THEME[State.CurrentTheme].Background
            barFrame.Parent = modelUsageFrame
            
            -- Add corner radius
            local barCorner = Instance.new("UICorner")
            barCorner.CornerRadius = UDim.new(0, 4)
            barCorner.Parent = barFrame
            
            -- Bar fill
            local barFill = Instance.new("Frame")
            barFill.Size = UDim2.new(percentage, 0, 1, 0)
            barFill.BackgroundColor3 = THEME[State.CurrentTheme].Primary
            barFill.Parent = barFrame
            
            -- Add corner radius
            local fillCorner = Instance.new("UICorner")
            fillCorner.CornerRadius = UDim.new(0, 4)
            fillCorner.Parent = barFill
            
            -- Model name
            local modelName = Instance.new("TextLabel")
            modelName.Size = UDim2.new(0.7, 0, 1, 0)
            modelName.Position = UDim2.new(0, 10, 0, 0)
            modelName.BackgroundTransparency = 1
            modelName.Font = Enum.Font.Gotham
            modelName.TextSize = 12
            modelName.TextColor3 = THEME[State.CurrentTheme].Text
            modelName.TextXAlignment = Enum.TextXAlignment.Left
            modelName.Text = model:match("([^/]+)$") or model
            modelName.Parent = barFrame
            
            -- Count
            local countLabel = Instance.new("TextLabel")
            countLabel.Size = UDim2.new(0.3, -10, 1, 0)
            countLabel.Position = UDim2.new(0.7, 0, 0, 0)
            countLabel.BackgroundTransparency = 1
            countLabel.Font = Enum.Font.Gotham
            countLabel.TextSize = 12
            countLabel.TextColor3 = THEME[State.CurrentTheme].Text
            countLabel.TextXAlignment = Enum.TextXAlignment.Right
            countLabel.Text = tostring(count) .. " (" .. math.floor(percentage * 100) .. "%)"
            countLabel.Parent = barFrame
            
            yOffset = yOffset + barHeight + spacing
        end
    end
end

local function CreateHistoryTab()
    local content = UI.TabContents["History"]
    
    -- History list
    local historyList = Instance.new("ScrollingFrame")
    historyList.Size = UDim2.new(1, 0, 1, 0)
    historyList.BackgroundTransparency = 1
    historyList.BorderSizePixel = 0
    historyList.ScrollBarThickness = 4
    historyList.ScrollBarImageColor3 = THEME[State.CurrentTheme].Secondary
    historyList.Parent = content
    
    local historyLayout = Instance.new("UIListLayout")
    historyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    historyLayout.Padding = UDim.new(0, 10)
    historyLayout.Parent = historyList
    
    local historyPadding = Instance.new("UIPadding")
    historyPadding.PaddingTop = UDim.new(0, 10)
    historyPadding.PaddingBottom = UDim.new(0, 10)
    historyPadding.PaddingLeft = UDim.new(0, 10)
    historyPadding.PaddingRight = UDim.new(0, 10)
    historyPadding.Parent = historyList
    
    -- Store references
    UI.HistoryTab.HistoryList = historyList
    
    -- Function to update history UI
    function UpdateHistoryUI(conversations)
        -- Clear existing history items
        for _, child in ipairs(historyList:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        -- Add history items
        for i, conversation in ipairs(conversations or {}) do
            local historyFrame = Instance.new("Frame")
            historyFrame.Size = UDim2.new(1, 0, 0, 80)
            historyFrame.BackgroundColor3 = THEME[State.CurrentTheme].BackgroundSecondary
            historyFrame.LayoutOrder = i
            historyFrame.Parent = historyList
            
            -- Add corner radius
            local historyCorner = Instance.new("UICorner")
            historyCorner.CornerRadius = UDim.new(0, 8)
            historyCorner.Parent = historyFrame
            
            -- Timestamp
            local timestamp = Instance.new("TextLabel")
            timestamp.Size = UDim2.new(1, -20, 0, 20)
            timestamp.Position = UDim2.new(0, 10, 0, 5)
            timestamp.BackgroundTransparency = 1
            timestamp.Font = Enum.Font.GothamBold
            timestamp.TextSize = 12
            timestamp.TextColor3 = THEME[State.CurrentTheme].Primary
            timestamp.TextXAlignment = Enum.TextXAlignment.Left
            
            -- Format timestamp
            local timestampText = conversation.last_timestamp
            if type(timestampText) == "string" then
                local success, dateTime = pcall(function()
                    return DateTime.fromIsoDate(timestampText)
                end)
                
                if success then
                    timestampText = dateTime:FormatLocalTime("LLL", "en-us")
                end
            end
            
            timestamp.Text = timestampText .. " • " .. conversation.message_count .. " messages"
            timestamp.Parent = historyFrame
            
            -- Preview
            local preview = Instance.new("TextLabel")
            preview.Size = UDim2.new(1, -20, 0, 40)
            preview.Position = UDim2.new(0, 10, 0, 30)
            preview.BackgroundTransparency = 1
            preview.Font = Enum.Font.Gotham
            preview.TextSize = 12
            preview.TextColor3 = THEME[State.CurrentTheme].Text
            preview.TextXAlignment = Enum.TextXAlignment.Left
            preview.TextYAlignment = Enum.TextYAlignment.Top
            preview.TextWrapped = true
            preview.Text = conversation.preview
            preview.Parent = historyFrame
            
            -- Add hover effect
            historyFrame.MouseEnter:Connect(function()
                AnimateProperty(historyFrame, "BackgroundColor3", THEME[State.CurrentTheme].Border)
            end)
            
            historyFrame.MouseLeave:Connect(function()
                AnimateProperty(historyFrame, "BackgroundColor3", THEME[State.CurrentTheme].BackgroundSecondary)
            end)
            
            -- Add click handler
            historyFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    GetConversation(conversation.conversation_id)
                    ShowTab("Chat")
                end
            end)
        end
    end
end

local function CreateProfileMenu()
    -- Profile menu container
    local profileMenu = Instance.new("Frame")
    profileMenu.Size = UDim2.new(0, 200, 0, 0) -- Will be animated
    profileMenu.Position = UDim2.new(1, -15, 0, 50)
    profileMenu.AnchorPoint = Vector2.new(1, 0)
    profileMenu.BackgroundColor3 = THEME[State.CurrentTheme].BackgroundSecondary
    profileMenu.Visible = false
    profileMenu.ZIndex = 100
    profileMenu.Parent = UI.MainFrame
    
    -- Add corner radius
    local menuCorner = Instance.new("UICorner")
    menuCorner.CornerRadius = UDim.new(0, 8)
    menuCorner.Parent = profileMenu
    
    -- Add shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = THEME[State.CurrentTheme].Shadow
    shadow.ImageTransparency = THEME[State.CurrentTheme].ShadowTransparency
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.ZIndex = profileMenu.ZIndex - 1
    shadow.Parent = profileMenu
    
    -- Avatar
    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.new(0, 60, 0, 60)
    avatar.Position = UDim2.new(0.5, 0, 0, 20)
    avatar.AnchorPoint = Vector2.new(0.5, 0)
    avatar.BackgroundColor3 = THEME[State.CurrentTheme].Background
    avatar.ZIndex = 101
    avatar.Parent = profileMenu
    
    -- Add corner radius (circle)
    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(1, 0)
    avatarCorner.Parent = avatar
    
    -- Username
    local username = Instance.new("TextLabel")
    username.Size = UDim2.new(1, 0, 0, 20)
    username.Position = UDim2.new(0, 0, 0, 90)
    username.BackgroundTransparency = 1
    username.Font = Enum.Font.GothamBold
    username.TextSize = 16
    username.TextColor3 = THEME[State.CurrentTheme].Text
    username.Text = "Username"
    username.ZIndex = 101
    username.Parent = profileMenu
    
    -- Role
    local role = Instance.new("TextLabel")
    role.Size = UDim2.new(1, 0, 0, 20)
    role.Position = UDim2.new(0, 0, 0, 110)
    role.BackgroundTransparency = 1
    role.Font = Enum.Font.Gotham
    role.TextSize = 14
    role.TextColor3 = THEME[State.CurrentTheme].Primary
    role.Text = "Role"
    role.ZIndex = 101
    role.Parent = profileMenu
    
    -- Divider
    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(0.8, 0, 0, 1)
    divider.Position = UDim2.new(0.1, 0, 0, 140)
    divider.BackgroundColor3 = THEME[State.CurrentTheme].Border
    divider.ZIndex = 101
    divider.Parent = profileMenu
    
    -- Theme toggle
    local themeToggleButton = Instance.new("TextButton")
    themeToggleButton.Size = UDim2.new(1, 0, 0, 40)
    themeToggleButton.Position = UDim2.new(0, 0, 0, 150)
    themeToggleButton.BackgroundTransparency = 1
    themeToggleButton.Font = Enum.Font.Gotham
    themeToggleButton.TextSize = 14
    themeToggleButton.TextColor3 = THEME[State.CurrentTheme].Text
    themeToggleButton.Text = "  Toggle Theme"
    themeToggleButton.TextXAlignment = Enum.TextXAlignment.Left
    themeToggleButton.ZIndex = 101
    themeToggleButton.Parent = profileMenu
    
    -- Theme icon
    local themeIcon = Instance.new("ImageLabel")
    themeIcon.Size = UDim2.new(0, 20, 0, 20)
    themeIcon.Position = UDim2.new(0, 20, 0.5, 0)
    themeIcon.AnchorPoint = Vector2.new(0, 0.5)
    themeIcon.BackgroundTransparency = 1
    themeIcon.Image = "rbxassetid://3926305904"
    themeIcon.ImageRectOffset = Vector2.new(116, 4)
    themeIcon.ImageRectSize = Vector2.new(24, 24)
    themeIcon.ImageColor3 = THEME[State.CurrentTheme].Primary
    themeIcon.ZIndex = 102
    themeIcon.Parent = themeToggleButton
    
    -- History button
    local historyButton = Instance.new("TextButton")
    historyButton.Size = UDim2.new(1, 0, 0, 40)
    historyButton.Position = UDim2.new(0, 0, 0, 190)
    historyButton.BackgroundTransparency = 1
    historyButton.Font = Enum.Font.Gotham
    historyButton.TextSize = 14
    historyButton.TextColor3 = THEME[State.CurrentTheme].Text
    historyButton.Text = "  Chat History"
    historyButton.TextXAlignment = Enum.TextXAlignment.Left
    historyButton.ZIndex = 101
    historyButton.Parent = profileMenu
    
    -- History icon
    local historyIcon = Instance.new("ImageLabel")
    historyIcon.Size = UDim2.new(0, 20, 0, 20)
    historyIcon.Position = UDim2.new(0, 20, 0.5, 0)
    historyIcon.AnchorPoint = Vector2.new(0, 0.5)
    historyIcon.BackgroundTransparency = 1
    historyIcon.Image = "rbxassetid://3926307971"
    historyIcon.ImageRectOffset = Vector2.new(764, 764)
    historyIcon.ImageRectSize = Vector2.new(36, 36)
    historyIcon.ImageColor3 = THEME[State.CurrentTheme].Primary
    historyIcon.ZIndex = 102
    historyIcon.Parent = historyButton
    
    -- Store references
    UI.ProfileMenu.Container = profileMenu
    UI.ProfileMenu.Avatar = avatar
    UI.ProfileMenu.Username = username
    UI.ProfileMenu.Role = role
    UI.ProfileMenu.ThemeToggleButton = themeToggleButton
    UI.ProfileMenu.HistoryButton = historyButton
    
    -- Add hover effects
    themeToggleButton.MouseEnter:Connect(function()
        AnimateProperty(themeToggleButton, "BackgroundTransparency", 0.9)
    end)
    
    themeToggleButton.MouseLeave:Connect(function()
        AnimateProperty(themeToggleButton, "BackgroundTransparency", 1)
    end)
    
    historyButton.MouseEnter:Connect(function()
        AnimateProperty(historyButton, "BackgroundTransparency", 0.9)
    end)
    
    historyButton.MouseLeave:Connect(function()
        AnimateProperty(historyButton, "BackgroundTransparency", 1)
    end)
    
    -- Add click handlers
    themeToggleButton.MouseButton1Click:Connect(function()
        ToggleTheme()
    end)
    
    historyButton.MouseButton1Click:Connect(function()
        ShowTab("History")
        ToggleProfileMenu()
    end)
end

local function ToggleProfileMenu()
    local profileMenu = UI.ProfileMenu.Container
    
    if not profileMenu.Visible then
        -- Update avatar
        local userId = Players.LocalPlayer.UserId
        UI.ProfileMenu.Avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. userId .. "&w=150&h=150"
        
        -- Update username and role
        UI.ProfileMenu.Username.Text = State.Username
        UI.ProfileMenu.Role.Text = State.Role
        
        -- Show menu
        profileMenu.Size = UDim2.new(0, 200, 0, 0)
        profileMenu.Visible = true
        
        -- Animate open
        AnimateProperty(profileMenu, "Size", UDim2.new(0, 200, 0, 240), 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    else
        -- Animate close
        local closeTween = AnimateProperty(profileMenu, "Size", UDim2.new(0, 200, 0, 0), 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        
        closeTween.Completed:Connect(function()
            profileMenu.Visible = false
        end)
    end
    
    State.IsMenuOpen = not State.IsMenuOpen
end

local function ToggleTheme()
    local newTheme = State.CurrentTheme == "Dark" and "Light" or "Dark"
    ApplyTheme(newTheme)
    
    -- Update theme toggle icon
    if UI.ThemeToggle then
        UI.ThemeToggle.ImageRectOffset = newTheme == "Dark" 
            and Vector2.new(116, 4)  -- Moon icon
            or Vector2.new(4, 4)      -- Sun icon
    end
}


-- Implement theme application function
function ApplyTheme(themeName)
    State.CurrentTheme = themeName
    local theme = THEME[themeName]
    
    -- Main frame
    if UI.MainFrame then
        AnimateProperty(UI.MainFrame, "BackgroundColor3", theme.Background)
    end
    
    -- Header
    local header = UI.MainFrame:FindFirstChild("Frame")
    if header then
        AnimateProperty(header, "BackgroundColor3", theme.BackgroundSecondary)
        
        -- Shadow
        local shadow = header:FindFirstChild("Frame")
        if shadow then
            AnimateProperty(shadow, "BackgroundColor3", theme.Shadow)
            AnimateProperty(shadow, "BackgroundTransparency", theme.ShadowTransparency)
        end
        
        -- Title
        local title = header:FindFirstChild("TextLabel")
        if title then
            AnimateProperty(title, "TextColor3", theme.Text)
        end
        
        -- Profile button
        if UI.ProfileButton then
            AnimateProperty(UI.ProfileButton, "ImageColor3", theme.Primary)
        end
        
        -- Theme toggle
        if UI.ThemeToggle then
            AnimateProperty(UI.ThemeToggle, "ImageColor3", theme.Primary)
        end
    end
    
    -- Tab buttons
    for _, tabData in pairs(UI.TabButtons) do
        if tabData.Button then
            if tabData.Button.Text == State.CurrentTab then
                AnimateProperty(tabData.Icon, "ImageColor3", theme.Primary)
                AnimateProperty(tabData.Label, "TextColor3", theme.Primary)
            else
                AnimateProperty(tabData.Icon, "ImageColor3", theme.TextSecondary)
                AnimateProperty(tabData.Label, "TextColor3", theme.TextSecondary)
            end
            
            if tabData.Indicator then
                AnimateProperty(tabData.Indicator, "BackgroundColor3", theme.Primary)
            end
        end
    end
    
    -- Chat tab
    if UI.ChatTab.InputBox then
        AnimateProperty(UI.ChatTab.InputBox, "BackgroundColor3", theme.Background)
        AnimateProperty(UI.ChatTab.InputBox, "TextColor3", theme.Text)
        AnimateProperty(UI.ChatTab.InputBox, "PlaceholderColor3", theme.TextSecondary)
    end
    
    if UI.ChatTab.SendButton then
        AnimateProperty(UI.ChatTab.SendButton, "BackgroundColor3", theme.Primary)
    end
    
    if UI.ChatTab.ModelSelector then
        AnimateProperty(UI.ChatTab.ModelSelector, "BackgroundColor3", theme.BackgroundSecondary)
        AnimateProperty(UI.ChatTab.ModelSelector, "TextColor3", theme.Text)
    end
    
    if UI.ChatTab.ClearButton then
        AnimateProperty(UI.ChatTab.ClearButton, "BackgroundColor3", theme.Error)
    end
    
    -- Update chat messages
    if UI.ChatTab.MessagesScroll then
        for _, child in ipairs(UI.ChatTab.MessagesScroll:GetChildren()) do
            if child:IsA("Frame") then
                local bubble = child:FindFirstChildOfClass("Frame")
                if bubble then
                    local isUser = bubble.Position.X.Scale > 0.5
                    AnimateProperty(bubble, "BackgroundColor3", isUser and theme.Primary or theme.BackgroundSecondary)
                    
                    local text = bubble:FindFirstChildOfClass("TextLabel")
                    if text then
                        AnimateProperty(text, "TextColor3", isUser and Color3.fromRGB(255, 255, 255) or theme.Text)
                    end
                end
            end
        end
    end
    
    -- Files tab
    if UI.FilesTab.UploadButton then
        AnimateProperty(UI.FilesTab.UploadButton, "BackgroundColor3", theme.Primary)
    end
    
    if UI.FilesTab.FilterButton then
        AnimateProperty(UI.FilesTab.FilterButton, "BackgroundColor3", theme.BackgroundSecondary)
        AnimateProperty(UI.FilesTab.FilterButton, "TextColor3", theme.Text)
    end
    
    -- Update file items
    if UI.FilesTab.FilesContainer then
        for _, child in ipairs(UI.FilesTab.FilesContainer:GetChildren()) do
            if child:IsA("Frame") then
                AnimateProperty(child, "BackgroundColor3", theme.BackgroundSecondary)
                
                local fileName = child:FindFirstChildOfClass("TextLabel")
                if fileName then
                    AnimateProperty(fileName, "TextColor3", theme.Text)
                end
            end
        end
    end
    
    -- Admin tab
    if UI.AdminTab then
        -- Update user list
        if UI.AdminTab.UsersList then
            for _, child in ipairs(UI.AdminTab.UsersList:GetChildren()) do
                if child:IsA("Frame") then
                    AnimateProperty(child, "BackgroundColor3", theme.BackgroundSecondary)
                    
                    local username = child:FindFirstChild("TextLabel")
                    if username then
                        AnimateProperty(username, "TextColor3", theme.Text)
                    end
                    
                    local role = child:FindFirstChild("TextLabel", 1)
                    if role then
                        AnimateProperty(role, "TextColor3", theme.TextSecondary)
                    end
                    
                    local removeButton = child:FindFirstChild("TextButton")
                    if removeButton then
                        AnimateProperty(removeButton, "BackgroundColor3", theme.Error)
                    end
                end
            end
        end
        
        -- Update logs list
        if UI.AdminTab.LogsList then
            for _, child in ipairs(UI.AdminTab.LogsList:GetChildren()) do
                if child:IsA("Frame") then
                    AnimateProperty(child, "BackgroundColor3", theme.BackgroundSecondary)
                    
                    local header = child:FindFirstChild("TextLabel")
                    if header then
                        AnimateProperty(header, "TextColor3", theme.Primary)
                    end
                    
                    local prompt = child:FindFirstChild("TextLabel", 1)
                    if prompt then
                        AnimateProperty(prompt, "TextColor3", theme.Text)
                    end
                end
            end
        end
        
        -- Update stats
        if UI.AdminTab.TotalRequestsValue then
            AnimateProperty(UI.AdminTab.TotalRequestsValue, "TextColor3", theme.Primary)
        end
        
        if UI.AdminTab.UserCountValue then
            AnimateProperty(UI.AdminTab.UserCountValue, "TextColor3", theme.Success)
        end
        
        if UI.AdminTab.ModelUsageFrame then
            AnimateProperty(UI.AdminTab.ModelUsageFrame, "BackgroundColor3", theme.BackgroundSecondary)
            
            for _, child in ipairs(UI.AdminTab.ModelUsageFrame:GetChildren()) do
                if child:IsA("Frame") and child.Name == "ModelBar" then
                    AnimateProperty(child, "BackgroundColor3", theme.Background)
                    
                    local barFill = child:FindFirstChildOfClass("Frame")
                    if barFill then
                        AnimateProperty(barFill, "BackgroundColor3", theme.Primary)
                    end
                    
                    local modelName = child:FindFirstChild("TextLabel")
                    if modelName then
                        AnimateProperty(modelName, "TextColor3", theme.Text)
                    end
                    
                    local countLabel = child:FindFirstChild("TextLabel", 1)
                    if countLabel then
                        AnimateProperty(countLabel, "TextColor3", theme.Text)
                    end
                end
            end
        end
    end
    
    -- History tab
    if UI.HistoryTab and UI.HistoryTab.HistoryList then
        for _, child in ipairs(UI.HistoryTab.HistoryList:GetChildren()) do
            if child:IsA("Frame") then
                AnimateProperty(child, "BackgroundColor3", theme.BackgroundSecondary)
                
                local timestamp = child:FindFirstChild("TextLabel")
                if timestamp then
                    AnimateProperty(timestamp, "TextColor3", theme.Primary)
                end
                
                local preview = child:FindFirstChild("TextLabel", 1)
                if preview then
                    AnimateProperty(preview, "TextColor3", theme.Text)
                end
            end
        end
    end
    
    -- Profile menu
    if UI.ProfileMenu.Container then
        AnimateProperty(UI.ProfileMenu.Container, "BackgroundColor3", theme.BackgroundSecondary)
        
        local shadow = UI.ProfileMenu.Container:FindFirstChild("ImageLabel")
        if shadow then
            AnimateProperty(shadow, "ImageColor3", theme.Shadow)
            AnimateProperty(shadow, "ImageTransparency", theme.ShadowTransparency)
        end
        
        if UI.ProfileMenu.Avatar then
            AnimateProperty(UI.ProfileMenu.Avatar, "BackgroundColor3", theme.Background)
        end
        
        if UI.ProfileMenu.Username then
            AnimateProperty(UI.ProfileMenu.Username, "TextColor3", theme.Text)
        end
        
        if UI.ProfileMenu.Role then
            AnimateProperty(UI.ProfileMenu.Role, "TextColor3", theme.Primary)
        end
        
        local divider = UI.ProfileMenu.Container:FindFirstChild("Frame")
        if divider then
            AnimateProperty(divider, "BackgroundColor3", theme.Border)
        end
        
        if UI.ProfileMenu.ThemeToggleButton then
            AnimateProperty(UI.ProfileMenu.ThemeToggleButton, "TextColor3", theme.Text)
            
            local themeIcon = UI.ProfileMenu.ThemeToggleButton:FindFirstChild("ImageLabel")
            if themeIcon then
                AnimateProperty(themeIcon, "ImageColor3", theme.Primary)
            end
        end
        
        if UI.ProfileMenu.HistoryButton then
            AnimateProperty(UI.ProfileMenu.HistoryButton, "TextColor3", theme.Text)
            
            local historyIcon = UI.ProfileMenu.HistoryButton:FindFirstChild("ImageLabel")
            if historyIcon then
                AnimateProperty(historyIcon, "ImageColor3", theme.Primary)
            end
        end
    end
    
    -- Loading overlay
    if UI.LoadingOverlay then
        AnimateProperty(UI.LoadingOverlay, "BackgroundColor3", theme.Background)
        
        local spinner = UI.LoadingOverlay:FindFirstChild("ImageLabel")
        if spinner then
            AnimateProperty(spinner, "ImageColor3", theme.Primary)
        end
        
        local text = UI.LoadingOverlay:FindFirstChild("TextLabel")
        if text then
            AnimateProperty(text, "TextColor3", theme.Text)
        end
    end
    
    -- Notifications
    for _, notification in ipairs(UI.Notifications) do
        AnimateProperty(notification, "BackgroundColor3", theme.BackgroundSecondary)
        
        local shadow = notification:FindFirstChild("ImageLabel")
        if shadow then
            AnimateProperty(shadow, "ImageColor3", theme.Shadow)
            AnimateProperty(shadow, "ImageTransparency", theme.ShadowTransparency)
        end
        
        local text = notification:FindFirstChild("TextLabel")
        if text then
            AnimateProperty(text, "TextColor3", theme.Text)
        end
    end
    
    -- Save theme preference
    plugin:SetSetting("AIAssistantTheme", themeName)
end

-- Initialize plugin
Initialize()

