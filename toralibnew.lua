local library = {flags = {}, windows = {}, open = true, scale = 1}

local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")
local textService = game:GetService("TextService")
local inputService = game:GetService("UserInputService")
local players = game:GetService("Players")
local coreGui = game:GetService("CoreGui")

local ui = Enum.UserInputType.MouseButton1
local isMobile = inputService.TouchEnabled and not inputService.KeyboardEnabled
local dragging, dragInput, dragStart, startPos, dragObject

local blacklistedKeys = {
	Enum.KeyCode.Unknown,
	Enum.KeyCode.W,
	Enum.KeyCode.A,
	Enum.KeyCode.S,
	Enum.KeyCode.D,
	Enum.KeyCode.Slash,
	Enum.KeyCode.Tab,
	Enum.KeyCode.Backspace,
	Enum.KeyCode.Escape,
	Enum.KeyCode.Space
}

local whitelistedMouseinputs = {
	Enum.UserInputType.MouseButton1,
	Enum.UserInputType.MouseButton2,
	Enum.UserInputType.MouseButton3
}

local function updateScale()
	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
	if viewport.X < 700 then
		library.scale = 0.75
	elseif viewport.X < 1000 then
		library.scale = 0.85
	elseif viewport.X > 1800 then
		library.scale = 1.1
	else
		library.scale = 1
	end
end

updateScale()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
end

local function roundNumber(num, bracket)
	bracket = bracket or 1
	local a = math.floor(num / bracket + (math.sign(num) * 0.5)) * bracket
	if a < 0 then
		a = a + bracket
	end
	return a
end

local function keyCheck(x, x1)
	for _, v in next, x1 do
		if v == x then
			return true
		end
	end
	return false
end

local function update(input)
	local delta = input.Position - dragStart
	local yPos = (startPos.Y.Offset + delta.Y) < -36 and -36 or startPos.Y.Offset + delta.Y
	dragObject:TweenPosition(UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, yPos), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.12, true)
end

local chromaColor = Color3.fromHSV(0, 1, 1)
local rainbowTime = 5
task.spawn(function()
	while true do
		chromaColor = Color3.fromHSV(tick() % rainbowTime / rainbowTime, 1, 1)
		task.wait()
	end
end)

local function createRipple(parent, position)
	local ripple = Instance.new("ImageLabel")
	ripple.Name = "Ripple"
	ripple.AnchorPoint = Vector2.new(0.5, 0.5)
	ripple.Position = UDim2.new(0, position.X - parent.AbsolutePosition.X, 0, position.Y - parent.AbsolutePosition.Y)
	ripple.Size = UDim2.new(0, 0, 0, 0)
	ripple.BackgroundTransparency = 1
	ripple.Image = "rbxassetid://3570695787"
	ripple.ImageColor3 = Color3.fromRGB(255, 255, 255)
	ripple.ImageTransparency = 0.6
	ripple.ScaleType = Enum.ScaleType.Slice
	ripple.SliceCenter = Rect.new(100, 100, 100, 100)
	ripple.SliceScale = 1
	ripple.ZIndex = 10
	ripple.Parent = parent

	local targetSize = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2.2
	local tween = tweenService:Create(ripple, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, targetSize, 0, targetSize),
		ImageTransparency = 1
	})
	tween:Play()
	tween.Completed:Connect(function()
		ripple:Destroy()
	end)
end

function library:Create(class, properties)
	properties = typeof(properties) == "table" and properties or {}
	local inst = Instance.new(class)
	for property, value in next, properties do
		inst[property] = value
	end
	return inst
end

local function createOptionHolder(holderTitle, parent, parentTable, subHolder)
	local baseSize = subHolder and 36 or 42
	local scaledSize = math.floor(baseSize * library.scale)
	local windowWidth = math.floor(240 * library.scale)

	parentTable.main = library:Create("ImageButton", {
		LayoutOrder = subHolder and parentTable.position or 0,
		Position = UDim2.new(0, math.floor(16 * library.scale) + (math.floor(255 * library.scale) * (parentTable.position or 0)), 0, math.floor(16 * library.scale)),
		Size = UDim2.new(0, windowWidth, 0, scaledSize),
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageColor3 = Color3.fromRGB(18, 18, 22),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.045,
		ClipsDescendants = true,
		Parent = parent
	})

	local roundFrame
	if not subHolder then
		roundFrame = library:Create("ImageLabel", {
			Size = UDim2.new(1, 0, 0, scaledSize),
			BackgroundTransparency = 1,
			Image = "rbxassetid://3570695787",
			ImageColor3 = parentTable.open and Color3.fromRGB(12, 12, 16) or Color3.fromRGB(8, 8, 12),
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(100, 100, 100, 100),
			SliceScale = 0.045,
			Parent = parentTable.main
		})
	end

	local title = library:Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, scaledSize),
		BackgroundTransparency = subHolder and 0 or 1,
		BackgroundColor3 = Color3.fromRGB(14, 14, 18),
		BorderSizePixel = 0,
		Text = holderTitle,
		TextSize = math.floor((subHolder and 15 or 16) * library.scale),
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.fromRGB(240, 240, 245),
		Parent = parentTable.main
	})

	local closeHolder = library:Create("Frame", {
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(-1, 0, 1, 0),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundTransparency = 1,
		Parent = title
	})

	local close = library:Create("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, -scaledSize - 8, 1, -scaledSize - 8),
		Rotation = parentTable.open and 90 or 180,
		BackgroundTransparency = 1,
		Image = "rbxassetid://4918373417",
		ImageColor3 = parentTable.open and Color3.fromRGB(80, 80, 90) or Color3.fromRGB(50, 50, 60),
		ScaleType = Enum.ScaleType.Fit,
		Parent = closeHolder
	})

	parentTable.content = library:Create("Frame", {
		Position = UDim2.new(0, 0, 0, scaledSize),
		Size = UDim2.new(1, 0, 1, -scaledSize),
		BackgroundTransparency = 1,
		Parent = parentTable.main
	})

	local layout = library:Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, math.floor(2 * library.scale)),
		Parent = parentTable.content
	})

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		parentTable.content.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y)
		parentTable.main.Size = #parentTable.options > 0 and parentTable.open and UDim2.new(0, windowWidth, 0, layout.AbsoluteContentSize.Y + scaledSize) or UDim2.new(0, windowWidth, 0, scaledSize)
	end)

	if not subHolder then
		library:Create("UIPadding", {
			PaddingTop = UDim.new(0, math.floor(4 * library.scale)),
			PaddingBottom = UDim.new(0, math.floor(4 * library.scale)),
			Parent = parentTable.content
		})

		title.InputBegan:Connect(function(input)
			if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
				dragObject = parentTable.main
				dragging = true
				dragStart = input.Position
				startPos = dragObject.Position
			end
		end)

		title.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				dragInput = input
			end
		end)

		title.InputEnded:Connect(function(input)
			if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
	end

	closeHolder.InputBegan:Connect(function(input)
		if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
			createRipple(closeHolder, input.Position)
			parentTable.open = not parentTable.open
			tweenService:Create(close, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Rotation = parentTable.open and 90 or 180,
				ImageColor3 = parentTable.open and Color3.fromRGB(80, 80, 90) or Color3.fromRGB(50, 50, 60)
			}):Play()
			if subHolder then
				tweenService:Create(title, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					BackgroundColor3 = parentTable.open and Color3.fromRGB(18, 18, 24) or Color3.fromRGB(14, 14, 18)
				}):Play()
			else
				tweenService:Create(roundFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					ImageColor3 = parentTable.open and Color3.fromRGB(12, 12, 16) or Color3.fromRGB(8, 8, 12)
				}):Play()
			end
			parentTable.main:TweenSize(
				#parentTable.options > 0 and parentTable.open and UDim2.new(0, windowWidth, 0, layout.AbsoluteContentSize.Y + scaledSize) or UDim2.new(0, windowWidth, 0, scaledSize),
				Enum.EasingDirection.Out,
				Enum.EasingStyle.Quint,
				0.28,
				true
			)
		end
	end)

	function parentTable:SetTitle(newTitle)
		title.Text = tostring(newTitle)
	end

	return parentTable
end

local function createLabel(option, parent)
	local main = library:Create("TextLabel", {
		LayoutOrder = option.position,
		Size = UDim2.new(1, 0, 0, math.floor(28 * library.scale)),
		BackgroundTransparency = 1,
		Text = "  " .. option.text,
		TextSize = math.floor(15 * library.scale),
		Font = Enum.Font.GothamMedium,
		TextColor3 = Color3.fromRGB(220, 220, 230),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent.content
	})

	setmetatable(option, {
		__newindex = function(t, i, v)
			if i == "Text" then
				main.Text = "  " .. tostring(v)
			end
		end
	})
end

local function createToggle(option, parent)
	local main = library:Create("TextLabel", {
		LayoutOrder = option.position,
		Size = UDim2.new(1, 0, 0, math.floor(34 * library.scale)),
		BackgroundTransparency = 1,
		Text = "  " .. option.text,
		TextSize = math.floor(15 * library.scale),
		Font = Enum.Font.GothamMedium,
		TextColor3 = Color3.fromRGB(235, 235, 245),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent.content
	})

	local tickboxOutline = library:Create("ImageLabel", {
		Position = UDim2.new(1, -math.floor(8 * library.scale), 0, math.floor(5 * library.scale)),
		Size = UDim2.new(-1, math.floor(12 * library.scale), 1, -math.floor(12 * library.scale)),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageColor3 = option.state and Color3.fromRGB(255, 70, 85) or Color3.fromRGB(90, 90, 105),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.025,
		Parent = main
	})

	local tickboxInner = library:Create("ImageLabel", {
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageColor3 = option.state and Color3.fromRGB(255, 70, 85) or Color3.fromRGB(22, 22, 28),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.025,
		Parent = tickboxOutline
	})

	local checkmarkHolder = library:Create("Frame", {
		Position = UDim2.new(0, 3, 0, 3),
		Size = option.state and UDim2.new(1, -6, 1, -6) or UDim2.new(0, 0, 1, -6),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = tickboxOutline
	})

	local checkmark = library:Create("ImageLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundTransparency = 1,
		Image = "rbxassetid://4919148038",
		ImageColor3 = Color3.fromRGB(18, 18, 22),
		Parent = checkmarkHolder
	})

	local inContact = false

	main.InputBegan:Connect(function(input)
		if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
			createRipple(main, input.Position)
			option:SetState(not option.state)
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			inContact = true
			if not option.state then
				tweenService:Create(tickboxOutline, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					ImageColor3 = Color3.fromRGB(130, 130, 145)
				}):Play()
			end
		end
	end)

	main.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			inContact = false
			if not option.state then
				tweenService:Create(tickboxOutline, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					ImageColor3 = Color3.fromRGB(90, 90, 105)
				}):Play()
			end
		end
	end)

	function option:SetState(state)
		library.flags[self.flag] = state
		self.state = state
		checkmarkHolder:TweenSize(
			option.state and UDim2.new(1, -6, 1, -6) or UDim2.new(0, 0, 1, -6),
			Enum.EasingDirection.Out,
			Enum.EasingStyle.Quint,
			0.22,
			true
		)
		tweenService:Create(tickboxInner, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			ImageColor3 = state and Color3.fromRGB(255, 70, 85) or Color3.fromRGB(22, 22, 28)
		}):Play()
		if state then
			tweenService:Create(tickboxOutline, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				ImageColor3 = Color3.fromRGB(255, 70, 85)
			}):Play()
		else
			tweenService:Create(tickboxOutline, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				ImageColor3 = inContact and Color3.fromRGB(130, 130, 145) or Color3.fromRGB(90, 90, 105)
			}):Play()
		end
		self.callback(state)
	end

	if option.state then
		task.delay(0.8, function()
			option.callback(true)
		end)
	end

	setmetatable(option, {
		__newindex = function(t, i, v)
			if i == "Text" then
				main.Text = "  " .. tostring(v)
			end
		end
	})
end

local function createButton(option, parent)
	local main = library:Create("TextLabel", {
		ZIndex = 2,
		LayoutOrder = option.position,
		Size = UDim2.new(1, 0, 0, math.floor(36 * library.scale)),
		BackgroundTransparency = 1,
		Text = "  " .. option.text,
		TextSize = math.floor(15 * library.scale),
		Font = Enum.Font.GothamMedium,
		TextColor3 = Color3.fromRGB(240, 240, 250),
		Parent = parent.content
	})

	local roundFrame = library:Create("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, -math.floor(14 * library.scale), 1, -math.floor(10 * library.scale)),
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageColor3 = Color3.fromRGB(35, 35, 45),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.025,
		Parent = main
	})

	local inContact = false
	local clicking = false

	main.InputBegan:Connect(function(input)
		if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
			createRipple(roundFrame, input.Position)
			library.flags[option.flag] = true
			clicking = true
			tweenService:Create(roundFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				ImageColor3 = Color3.fromRGB(255, 70, 85)
			}):Play()
			option.callback()
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			inContact = true
			tweenService:Create(roundFrame, TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				ImageColor3 = Color3.fromRGB(55, 55, 70)
			}):Play()
		end
	end)

	main.InputEnded:Connect(function(input)
		if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
			clicking = false
			tweenService:Create(roundFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				ImageColor3 = inContact and Color3.fromRGB(55, 55, 70) or Color3.fromRGB(35, 35, 45)
			}):Play()
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			inContact = false
			if not clicking then
				tweenService:Create(roundFrame, TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					ImageColor3 = Color3.fromRGB(35, 35, 45)
				}):Play()
			end
		end
	end)
end

local function createBind(option, parent)
	local binding = false
	local loop = nil
	local text = string.match(option.key, "Mouse") and string.sub(option.key, 1, 5) .. string.sub(option.key, 12, 13) or option.key

	local main = library:Create("TextLabel", {
		LayoutOrder = option.position,
		Size = UDim2.new(1, 0, 0, math.floor(34 * library.scale)),
		BackgroundTransparency = 1,
		Text = "  " .. option.text,
		TextSize = math.floor(15 * library.scale),
		Font = Enum.Font.GothamMedium,
		TextColor3 = Color3.fromRGB(235, 235, 245),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent.content
	})

	local roundFrame = library:Create("ImageLabel", {
		Position = UDim2.new(1, -math.floor(8 * library.scale), 0, math.floor(5 * library.scale)),
		Size = UDim2.new(0, -textService:GetTextSize(text, math.floor(14 * library.scale), Enum.Font.GothamMedium, Vector2.new(9e9, 9e9)).X - math.floor(18 * library.scale), 1, -math.floor(10 * library.scale)),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageColor3 = Color3.fromRGB(35, 35, 45),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.025,
		Parent = main
	})

	local bindinput = library:Create("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextSize = math.floor(14 * library.scale),
		Font = Enum.Font.GothamMedium,
		TextColor3 = Color3.fromRGB(240, 240, 250),
		Parent = roundFrame
	})

	local inContact = false

	main.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			inContact = true
			if not binding then
				tweenService:Create(roundFrame, TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					ImageColor3 = Color3.fromRGB(55, 55, 70)
				}):Play()
			end
		end
	end)

	main.InputEnded:Connect(function(input)
		if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
			createRipple(roundFrame, input.Position)
			binding = true
			bindinput.Text = "..."
			tweenService:Create(roundFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				ImageColor3 = Color3.fromRGB(255, 70, 85)
			}):Play()
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			inContact = false
			if not binding then
				tweenService:Create(roundFrame, TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					ImageColor3 = Color3.fromRGB(35, 35, 45)
				}):Play()
			end
		end
	end)

	inputService.InputBegan:Connect(function(input)
		if inputService:GetFocusedTextBox() then
			return
		end
		if (input.KeyCode.Name == option.key or input.UserInputType.Name == option.key) and not binding then
			if option.hold then
				loop = runService.Heartbeat:Connect(function()
					if binding then
						option.callback(true)
						loop:Disconnect()
						loop = nil
					else
						option.callback()
					end
				end)
			else
				option.callback()
			end
		elseif binding then
			local key
			pcall(function()
				if not keyCheck(input.KeyCode, blacklistedKeys) then
					key = input.KeyCode
				end
			end)
			pcall(function()
				if keyCheck(input.UserInputType, whitelistedMouseinputs) and not key then
					key = input.UserInputType
				end
			end)
			key = key or option.key
			option:SetKey(key)
		end
	end)

	inputService.InputEnded:Connect(function(input)
		if input.KeyCode.Name == option.key or input.UserInputType.Name == option.key or input.UserInputType.Name == "MouseMovement" then
			if loop then
				loop:Disconnect()
				loop = nil
				option.callback(true)
			end
		end
	end)

	function option:SetKey(key)
		binding = false
		if loop then
			loop:Disconnect()
			loop = nil
		end
		self.key = key or self.key
		self.key = self.key.Name or self.key
		library.flags[self.flag] = self.key
		if string.match(self.key, "Mouse") then
			bindinput.Text = string.sub(self.key, 1, 5) .. string.sub(self.key, 12, 13)
		else
			bindinput.Text = self.key
		end
		tweenService:Create(roundFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			ImageColor3 = inContact and Color3.fromRGB(55, 55, 70) or Color3.fromRGB(35, 35, 45)
		}):Play()
		roundFrame.Size = UDim2.new(0, -textService:GetTextSize(bindinput.Text, math.floor(13 * library.scale), Enum.Font.GothamMedium, Vector2.new(9e9, 9e9)).X - math.floor(18 * library.scale), 1, -math.floor(10 * library.scale))
	end
end

local function createSlider(option, parent)
	local main = library:Create("Frame", {
		LayoutOrder = option.position,
		Size = UDim2.new(1, 0, 0, math.floor(52 * library.scale)),
		BackgroundTransparency = 1,
		Parent = parent.content
	})

	local title = library:Create("TextLabel", {
		Position = UDim2.new(0, 0, 0, math.floor(4 * library.scale)),
		Size = UDim2.new(1, 0, 0, math.floor(20 * library.scale)),
		BackgroundTransparency = 1,
		Text = "  " .. option.text,
		TextSize = math.floor(15 * library.scale),
		Font = Enum.Font.GothamMedium,
		TextColor3 = Color3.fromRGB(235, 235, 245),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = main
	})

	local slider = library:Create("ImageLabel", {
		Position = UDim2.new(0, math.floor(12 * library.scale), 0, math.floor(32 * library.scale)),
		Size = UDim2.new(1, -math.floor(24 * library.scale), 0, math.floor(6 * library.scale)),
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageColor3 = Color3.fromRGB(28, 28, 36),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.025,
		Parent = main
	})

	local fill = library:Create("ImageLabel", {
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageColor3 = Color3.fromRGB(70, 70, 90),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.025,
		Parent = slider
	})

	local circle = library:Create("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new((option.value - option.min) / (option.max - option.min), 0, 0.5, 0),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageColor3 = Color3.fromRGB(70, 70, 90),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 1,
		Parent = slider
	})

	local valueRound = library:Create("ImageLabel", {
		Position = UDim2.new(1, -math.floor(8 * library.scale), 0, math.floor(4 * library.scale)),
		Size = UDim2.new(0, -math.floor(58 * library.scale), 0, math.floor(20 * library.scale)),
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageColor3 = Color3.fromRGB(35, 35, 45),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.025,
		Parent = main
	})

	local inputvalue = library:Create("TextBox", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = tostring(option.value),
		TextColor3 = Color3.fromRGB(230, 230, 240),
		TextSize = math.floor(13 * library.scale),
		TextWrapped = true,
		Font = Enum.Font.GothamMedium,
		Parent = valueRound
	})

	if option.min >= 0 then
		fill.Size = UDim2.new((option.value - option.min) / (option.max - option.min), 0, 1, 0)
	else
		fill.Position = UDim2.new((0 - option.min) / (option.max - option.min), 0, 0, 0)
		fill.Size = UDim2.new(option.value / (option.max - option.min), 0, 1, 0)
	end

	local sliding = false
	local inContact = false

	main.InputBegan:Connect(function(input)
		if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
			createRipple(slider, input.Position)
			tweenService:Create(fill, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				ImageColor3 = Color3.fromRGB(255, 70, 85)
			}):Play()
			tweenService:Create(circle, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Size = UDim2.new(3.2, 0, 3.2, 0),
				ImageColor3 = Color3.fromRGB(255, 70, 85)
			}):Play()
			sliding = true
			option:SetValue(option.min + ((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X) * (option.max - option.min))
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			inContact = true
			if not sliding then
				tweenService:Create(fill, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					ImageColor3 = Color3.fromRGB(110, 110, 130)
				}):Play()
				tweenService:Create(circle, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					Size = UDim2.new(2.6, 0, 2.6, 0),
					ImageColor3 = Color3.fromRGB(110, 110, 130)
				}):Play()
			end
		end
	end)

	inputService.InputChanged:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and sliding then
			option:SetValue(option.min + ((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X) * (option.max - option.min))
		end
	end)

	main.InputEnded:Connect(function(input)
		if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
			sliding = false
			tweenService:Create(fill, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				ImageColor3 = inContact and Color3.fromRGB(110, 110, 130) or Color3.fromRGB(70, 70, 90)
			}):Play()
			tweenService:Create(circle, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Size = inContact and UDim2.new(2.6, 0, 2.6, 0) or UDim2.new(0, 0, 0, 0),
				ImageColor3 = inContact and Color3.fromRGB(110, 110, 130) or Color3.fromRGB(70, 70, 90)
			}):Play()
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			inContact = false
			inputvalue:ReleaseFocus()
			if not sliding then
				tweenService:Create(fill, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					ImageColor3 = Color3.fromRGB(70, 70, 90)
				}):Play()
				tweenService:Create(circle, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					Size = UDim2.new(0, 0, 0, 0),
					ImageColor3 = Color3.fromRGB(70, 70, 90)
				}):Play()
			end
		end
	end)

	inputvalue.FocusLost:Connect(function()
		tweenService:Create(circle, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 0, 0, 0),
			ImageColor3 = Color3.fromRGB(70, 70, 90)
		}):Play()
		option:SetValue(tonumber(inputvalue.Text) or option.value)
	end)

	function option:SetValue(value)
		value = roundNumber(value, option.float)
		value = math.clamp(value, self.min, self.max)
		circle:TweenPosition(UDim2.new((value - self.min) / (self.max - self.min), 0, 0.5, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.12, true)
		if self.min >= 0 then
			fill:TweenSize(UDim2.new((value - self.min) / (self.max - self.min), 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.12, true)
		else
			fill:TweenPosition(UDim2.new((0 - self.min) / (self.max - self.min), 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.12, true)
			fill:TweenSize(UDim2.new(value / (self.max - self.min), 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.12, true)
		end
		library.flags[self.flag] = value
		self.value = value
		inputvalue.Text = tostring(value)
		self.callback(value)
	end
end

local function createList(option, parent, holder)
	local valueCount = 0
	local windowWidth = math.floor(250 * library.scale)

	local main = library:Create("Frame", {
		LayoutOrder = option.position,
		Size = UDim2.new(1, 0, 0, math.floor(54 * library.scale)),
		BackgroundTransparency = 1,
		Parent = parent.content
	})

	local roundFrame = library:Create("ImageLabel", {
		Position = UDim2.new(0, math.floor(8 * library.scale), 0, math.floor(4 * library.scale)),
		Size = UDim2.new(1, -math.floor(16 * library.scale), 1, -math.floor(10 * library.scale)),
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageColor3 = Color3.fromRGB(35, 35, 45),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.025,
		Parent = main
	})

	local title = library:Create("TextLabel", {
		Position = UDim2.new(0, math.floor(14 * library.scale), 0, math.floor(8 * library.scale)),
		Size = UDim2.new(1, -math.floor(28 * library.scale), 0, math.floor(14 * library.scale)),
		BackgroundTransparency = 1,
		Text = option.text,
		TextSize = math.floor(13 * library.scale),
		Font = Enum.Font.GothamMedium,
		TextColor3 = Color3.fromRGB(140, 140, 155),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = main
	})

	local listvalue = library:Create("TextLabel", {
		Position = UDim2.new(0, math.floor(14 * library.scale), 0, math.floor(22 * library.scale)),
		Size = UDim2.new(1, -math.floor(28 * library.scale), 0, math.floor(24 * library.scale)),
		BackgroundTransparency = 1,
		Text = option.value,
		TextSize = math.floor(16 * library.scale),
		Font = Enum.Font.GothamMedium,
		TextColor3 = Color3.fromRGB(245, 245, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = main
	})

	library:Create("ImageLabel", {
		Position = UDim2.new(1, -math.floor(18 * library.scale), 0, math.floor(16 * library.scale)),
		Size = UDim2.new(-1, math.floor(34 * library.scale), 1, -math.floor(34 * library.scale)),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		Rotation = 90,
		BackgroundTransparency = 1,
		Image = "rbxassetid://4918373417",
		ImageColor3 = Color3.fromRGB(140, 140, 155),
		ScaleType = Enum.ScaleType.Fit,
		Parent = roundFrame
	})

	option.mainHolder = library:Create("ImageButton", {
		ZIndex = 5,
		Size = UDim2.new(0, windowWidth, 0, math.floor(54 * library.scale)),
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageTransparency = 1,
		ImageColor3 = Color3.fromRGB(24, 24, 32),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.03,
		Visible = false,
		Parent = library.base
	})

	local content = library:Create("ScrollingFrame", {
		ZIndex = 5,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100),
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = option.mainHolder
	})

	library:Create("UIPadding", {
		PaddingTop = UDim.new(0, math.floor(6 * library.scale)),
		Parent = content
	})

	local layout = library:Create("UIListLayout", {
		Parent = content
	})

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		option.mainHolder.Size = UDim2.new(0, windowWidth, 0, (valueCount > 4 and (4 * math.floor(40 * library.scale)) or layout.AbsoluteContentSize.Y) + math.floor(14 * library.scale))
		content.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + math.floor(14 * library.scale))
	end)

	local inContact = false

	roundFrame.InputBegan:Connect(function(input)
		if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
			createRipple(roundFrame, input.Position)
			if library.activePopup then
				library.activePopup:Close()
			end
			local position = main.AbsolutePosition
			option.mainHolder.Position = UDim2.new(0, position.X - 4, 0, position.Y - 8)
			option.open = true
			option.mainHolder.Visible = true
			library.activePopup = option
			content.ScrollBarThickness = math.floor(5 * library.scale)
			tweenService:Create(option.mainHolder, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				ImageTransparency = 0,
				Position = UDim2.new(0, position.X - 4, 0, position.Y - 2)
			}):Play()
			tweenService:Create(option.mainHolder, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, 0.08), {
				Position = UDim2.new(0, position.X - 4, 0, position.Y + 2)
			}):Play()
			for _, label in next, content:GetChildren() do
				if label:IsA("TextLabel") then
					tweenService:Create(label, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						BackgroundTransparency = 0,
						TextTransparency = 0
					}):Play()
				end
			end
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			inContact = true
			if not option.open then
				tweenService:Create(roundFrame, TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					ImageColor3 = Color3.fromRGB(55, 55, 70)
				}):Play()
			end
		end
	end)

	roundFrame.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			inContact = false
			if not option.open then
				tweenService:Create(roundFrame, TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					ImageColor3 = Color3.fromRGB(35, 35, 45)
				}):Play()
			end
		end
	end)

	function option:AddValue(value)
		valueCount = valueCount + 1
		local label = library:Create("TextLabel", {
			ZIndex = 5,
			Size = UDim2.new(1, 0, 0, math.floor(40 * library.scale)),
			BackgroundColor3 = Color3.fromRGB(24, 24, 32),
			BorderSizePixel = 0,
			Text = "    " .. value,
			TextSize = math.floor(14 * library.scale),
			TextTransparency = self.open and 0 or 1,
			Font = Enum.Font.GothamMedium,
			TextColor3 = Color3.fromRGB(245, 245, 255),
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = content
		})

		local labelInContact = false
		local clicking = false

		label.InputBegan:Connect(function(input)
			if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
				createRipple(label, input.Position)
				clicking = true
				tweenService:Create(label, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					BackgroundColor3 = Color3.fromRGB(14, 14, 20)
				}):Play()
				self:SetValue(value)
			end
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				labelInContact = true
				if not clicking then
					tweenService:Create(label, TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						BackgroundColor3 = Color3.fromRGB(32, 32, 42)
					}):Play()
				end
			end
		end)

		label.InputEnded:Connect(function(input)
			if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
				clicking = false
				tweenService:Create(label, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					BackgroundColor3 = labelInContact and Color3.fromRGB(32, 32, 42) or Color3.fromRGB(24, 24, 32)
				}):Play()
			end
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				labelInContact = false
				if not clicking then
					tweenService:Create(label, TweenInfo.new(0.1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						BackgroundColor3 = Color3.fromRGB(24, 24, 32)
					}):Play()
				end
			end
		end)
	end

	if not table.find(option.values, option.value) then
		option:AddValue(option.value)
	end

	for _, value in next, option.values do
		option:AddValue(tostring(value))
	end

	function option:RemoveValue(value)
		for _, label in next, content:GetChildren() do
			if label:IsA("TextLabel") and label.Text == "    " .. value then
				label:Destroy()
				valueCount = valueCount - 1
				break
			end
		end
		if self.value == value then
			self:SetValue("")
		end
	end

	function option:SetValue(value)
		library.flags[self.flag] = tostring(value)
		self.value = tostring(value)
		listvalue.Text = self.value
		self.callback(value)
	end

	function option:Close()
		library.activePopup = nil
		self.open = false
		content.ScrollBarThickness = 0
		local position = main.AbsolutePosition
		tweenService:Create(roundFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			ImageColor3 = inContact and Color3.fromRGB(55, 55, 70) or Color3.fromRGB(35, 35, 45)
		}):Play()
		tweenService:Create(self.mainHolder, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			ImageTransparency = 1,
			Position = UDim2.new(0, position.X - 4, 0, position.Y - 8)
		}):Play()
		for _, label in next, content:GetChildren() do
			if label:IsA("TextLabel") then
				tweenService:Create(label, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					BackgroundTransparency = 1,
					TextTransparency = 1
				}):Play()
			end
		end
		task.delay(0.28, function()
			if not self.open then
				self.mainHolder.Visible = false
			end
		end)
	end

	return option
end

local function createBox(option, parent)
	local main = library:Create("Frame", {
		LayoutOrder = option.position,
		Size = UDim2.new(1, 0, 0, math.floor(54 * library.scale)),
		BackgroundTransparency = 1,
		Parent = parent.content
	})

	local outline = library:Create("ImageLabel", {
		Position = UDim2.new(0, math.floor(8 * library.scale), 0, math.floor(4 * library.scale)),
		Size = UDim2.new(1, -math.floor(16 * library.scale), 1, -math.floor(10 * library.scale)),
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageColor3 = Color3.fromRGB(55, 55, 70),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.025,
		Parent = main
	})

	local roundFrame = library:Create("ImageLabel", {
		Position = UDim2.new(0, math.floor(10 * library.scale), 0, math.floor(6 * library.scale)),
		Size = UDim2.new(1, -math.floor(20 * library.scale), 1, -math.floor(14 * library.scale)),
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageColor3 = Color3.fromRGB(18, 18, 24),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.015,
		Parent = main
	})

	local title = library:Create("TextLabel", {
		Position = UDim2.new(0, math.floor(14 * library.scale), 0, math.floor(8 * library.scale)),
		Size = UDim2.new(1, -math.floor(28 * library.scale), 0, math.floor(14 * library.scale)),
		BackgroundTransparency = 1,
		Text = option.text,
		TextSize = math.floor(13 * library.scale),
		Font = Enum.Font.GothamMedium,
		TextColor3 = Color3.fromRGB(120, 120, 140),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = main
	})

	local inputvalue = library:Create("TextBox", {
		Position = UDim2.new(0, math.floor(14 * library.scale), 0, math.floor(22 * library.scale)),
		Size = UDim2.new(1, -math.floor(28 * library.scale), 0, math.floor(24 * library.scale)),
		BackgroundTransparency = 1,
		Text = option.value,
		TextSize = math.floor(16 * library.scale),
		Font = Enum.Font.GothamMedium,
		TextColor3 = Color3.fromRGB(245, 245, 255),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Parent = main
	})

	local inContact = false
	local focused = false

	main.InputBegan:Connect(function(input)
		if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
			if not focused then
				inputvalue:CaptureFocus()
			end
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			inContact = true
			if not focused then
				tweenService:Create(outline, TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					ImageColor3 = Color3.fromRGB(90, 90, 110)
				}):Play()
			end
		end
	end)

	main.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			inContact = false
			if not focused then
				tweenService:Create(outline, TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					ImageColor3 = Color3.fromRGB(55, 55, 70)
				}):Play()
			end
		end
	end)

	inputvalue.Focused:Connect(function()
		focused = true
		tweenService:Create(outline, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			ImageColor3 = Color3.fromRGB(255, 70, 85)
		}):Play()
	end)

	inputvalue.FocusLost:Connect(function(enter)
		focused = false
		tweenService:Create(outline, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			ImageColor3 = Color3.fromRGB(55, 55, 70)
		}):Play()
		option:SetValue(inputvalue.Text, enter)
	end)

	function option:SetValue(value, enter)
		library.flags[self.flag] = tostring(value)
		self.value = tostring(value)
		inputvalue.Text = self.value
		self.callback(value, enter)
	end
end

local function createColorPickerWindow(option)
	local windowWidth = math.floor(250 * library.scale)
	option.mainHolder = library:Create("ImageButton", {
		ZIndex = 5,
		Size = UDim2.new(0, windowWidth, 0, math.floor(190 * library.scale)),
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageTransparency = 1,
		ImageColor3 = Color3.fromRGB(24, 24, 32),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.03,
		Visible = false,
		Parent = library.base
	})

	local hue, sat, val = Color3.toHSV(option.color)
	hue, sat, val = hue == 0 and 1 or hue, sat + 0.005, val - 0.005
	local editinghue = false
	local editingsatval = false
	local currentColor = option.color
	local previousColors = {[1] = option.color}
	local originalColor = option.color
	local rainbowEnabled = false
	local rainbowLoop = nil

	function option:updateVisuals(Color)
		currentColor = Color
		self.visualize2.ImageColor3 = Color
		hue, sat, val = Color3.toHSV(Color)
		hue = hue == 0 and 1 or hue
		self.satval.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
		self.hueSlider.Position = UDim2.new(1 - hue, 0, 0, 0)
		self.satvalSlider.Position = UDim2.new(sat, 0, 1 - val, 0)
	end

	option.hue = library:Create("ImageLabel", {
		ZIndex = 5,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, math.floor(10 * library.scale), 1, -math.floor(10 * library.scale)),
		Size = UDim2.new(1, -math.floor(105 * library.scale), 0, math.floor(22 * library.scale)),
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageTransparency = 1,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.025,
		Parent = option.mainHolder
	})

	library:Create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
			ColorSequenceKeypoint.new(0.157, Color3.fromRGB(255, 0, 255)),
			ColorSequenceKeypoint.new(0.323, Color3.fromRGB(0, 0, 255)),
			ColorSequenceKeypoint.new(0.488, Color3.fromRGB(0, 255, 255)),
			ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 255, 0)),
			ColorSequenceKeypoint.new(0.817, Color3.fromRGB(255, 255, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
		}),
		Parent = option.hue
	})

	option.hueSlider = library:Create("Frame", {
		ZIndex = 5,
		Position = UDim2.new(1 - hue, 0, 0, 0),
		Size = UDim2.new(0, 3, 1, 0),
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = option.hue
	})

	option.hue.InputBegan:Connect(function(input)
		if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
			editinghue = true
			local x = (input.Position.X - option.hue.AbsolutePosition.X) / option.hue.AbsoluteSize.X
			x = math.clamp(x, 0, 0.995)
			option:updateVisuals(Color3.fromHSV(1 - x, sat, val))
		end
	end)

	inputService.InputChanged:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and editinghue then
			local x = (input.Position.X - option.hue.AbsolutePosition.X) / option.hue.AbsoluteSize.X
			x = math.clamp(x, 0, 0.995)
			option:updateVisuals(Color3.fromHSV(1 - x, sat, val))
		end
	end)

	option.hue.InputEnded:Connect(function(input)
		if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
			editinghue = false
		end
	end)

	option.satval = library:Create("ImageLabel", {
		ZIndex = 5,
		Position = UDim2.new(0, math.floor(10 * library.scale), 0, math.floor(10 * library.scale)),
		Size = UDim2.new(1, -math.floor(105 * library.scale), 1, -math.floor(46 * library.scale)),
		BackgroundTransparency = 1,
		BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
		BorderSizePixel = 0,
		Image = "rbxassetid://4155801252",
		ImageTransparency = 1,
		ClipsDescendants = true,
		Parent = option.mainHolder
	})

	option.satvalSlider = library:Create("Frame", {
		ZIndex = 5,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(sat, 0, 1 - val, 0),
		Size = UDim2.new(0, 6, 0, 6),
		Rotation = 45,
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Parent = option.satval
	})

	option.satval.InputBegan:Connect(function(input)
		if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
			editingsatval = true
			local x = (input.Position.X - option.satval.AbsolutePosition.X) / option.satval.AbsoluteSize.X
			local y = (input.Position.Y - option.satval.AbsolutePosition.Y) / option.satval.AbsoluteSize.Y
			x = math.clamp(x, 0.005, 1)
			y = math.clamp(y, 0, 0.995)
			option:updateVisuals(Color3.fromHSV(hue, x, 1 - y))
		end
	end)

	inputService.InputChanged:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and editingsatval then
			local x = (input.Position.X - option.satval.AbsolutePosition.X) / option.satval.AbsoluteSize.X
			local y = (input.Position.Y - option.satval.AbsolutePosition.Y) / option.satval.AbsoluteSize.Y
			x = math.clamp(x, 0.005, 1)
			y = math.clamp(y, 0, 0.995)
			option:updateVisuals(Color3.fromHSV(hue, x, 1 - y))
		end
	end)

	option.satval.InputEnded:Connect(function(input)
		if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
			editingsatval = false
		end
	end)

	option.visualize2 = library:Create("ImageLabel", {
		ZIndex = 5,
		Position = UDim2.new(1, -math.floor(10 * library.scale), 0, math.floor(10 * library.scale)),
		Size = UDim2.new(0, -math.floor(82 * library.scale), 0, math.floor(82 * library.scale)),
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageColor3 = currentColor,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.025,
		Parent = option.mainHolder
	})

	local function createColorButton(text, yPos, callback)
		local btn = library:Create("ImageLabel", {
			ZIndex = 5,
			Position = UDim2.new(1, -math.floor(10 * library.scale), 0, math.floor(yPos * library.scale)),
			Size = UDim2.new(0, -math.floor(82 * library.scale), 0, math.floor(20 * library.scale)),
			BackgroundTransparency = 1,
			Image = "rbxassetid://3570695787",
			ImageTransparency = 1,
			ImageColor3 = Color3.fromRGB(28, 28, 36),
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = Rect.new(100, 100, 100, 100),
			SliceScale = 0.025,
			Parent = option.mainHolder
		})

		local btnText = library:Create("TextLabel", {
			ZIndex = 5,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = text,
			TextTransparency = 1,
			Font = Enum.Font.GothamMedium,
			TextSize = math.floor(13 * library.scale),
			TextColor3 = Color3.fromRGB(245, 245, 255),
			Parent = btn
		})

		btn.InputBegan:Connect(function(input)
			if (input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch) and not rainbowEnabled then
				createRipple(btn, input.Position)
				callback()
			end
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				tweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					ImageColor3 = Color3.fromRGB(18, 18, 24)
				}):Play()
			end
		end)

		btn.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				tweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					ImageColor3 = Color3.fromRGB(28, 28, 36)
				}):Play()
			end
		end)

		return btn, btnText
	end

	option.resetColor, option.resetText = createColorButton("Reset", 96, function()
		previousColors = {originalColor}
		option:SetColor(originalColor)
	end)

	option.undoColor, option.undoText = createColorButton("Undo", 118, function()
		local num = #previousColors == 1 and 0 or 1
		option:SetColor(previousColors[#previousColors - num])
		if #previousColors ~= 1 then
			table.remove(previousColors, #previousColors)
		end
	end)

	option.setColor, option.setText = createColorButton("Set", 140, function()
		table.insert(previousColors, currentColor)
		option:SetColor(currentColor)
	end)

	option.rainbow, option.rainbowText = createColorButton("Rainbow", 162, function()
		rainbowEnabled = not rainbowEnabled
		if rainbowEnabled then
			rainbowLoop = runService.Heartbeat:Connect(function()
				option:SetColor(chromaColor)
				option.rainbowText.TextColor3 = chromaColor
			end)
		else
			if rainbowLoop then
				rainbowLoop:Disconnect()
			end
			option:SetColor(previousColors[#previousColors])
			option.rainbowText.TextColor3 = Color3.fromRGB(245, 245, 255)
		end
	end)

	return option
end

local function createColor(option, parent, holder)
	option.main = library:Create("TextLabel", {
		LayoutOrder = option.position,
		Size = UDim2.new(1, 0, 0, math.floor(34 * library.scale)),
		BackgroundTransparency = 1,
		Text = "  " .. option.text,
		TextSize = math.floor(15 * library.scale),
		Font = Enum.Font.GothamMedium,
		TextColor3 = Color3.fromRGB(235, 235, 245),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = parent.content
	})

	local colorBoxOutline = library:Create("ImageLabel", {
		Position = UDim2.new(1, -math.floor(8 * library.scale), 0, math.floor(5 * library.scale)),
		Size = UDim2.new(-1, math.floor(12 * library.scale), 1, -math.floor(12 * library.scale)),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageColor3 = Color3.fromRGB(90, 90, 105),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.025,
		Parent = option.main
	})

	option.visualize = library:Create("ImageLabel", {
		Position = UDim2.new(0, 2, 0, 2),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundTransparency = 1,
		Image = "rbxassetid://3570695787",
		ImageColor3 = option.color,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(100, 100, 100, 100),
		SliceScale = 0.025,
		Parent = colorBoxOutline
	})

	local inContact = false

	option.main.InputBegan:Connect(function(input)
		if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
			createRipple(option.main, input.Position)
			if not option.mainHolder then
				createColorPickerWindow(option)
			end
			if library.activePopup then
				library.activePopup:Close()
			end
			local position = option.main.AbsolutePosition
			option.mainHolder.Position = UDim2.new(0, position.X - 4, 0, position.Y - 8)
			option.open = true
			option.mainHolder.Visible = true
			library.activePopup = option
			tweenService:Create(option.mainHolder, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				ImageTransparency = 0,
				Position = UDim2.new(0, position.X - 4, 0, position.Y - 2)
			}):Play()
			tweenService:Create(option.mainHolder, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, 0.08), {
				Position = UDim2.new(0, position.X - 4, 0, position.Y + 2)
			}):Play()
			tweenService:Create(option.satval, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0
			}):Play()
			for _, object in next, option.mainHolder:GetDescendants() do
				if object:IsA("TextLabel") then
					tweenService:Create(object, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						TextTransparency = 0
					}):Play()
				elseif object:IsA("ImageLabel") then
					tweenService:Create(object, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						ImageTransparency = 0
					}):Play()
				elseif object:IsA("Frame") then
					tweenService:Create(object, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						BackgroundTransparency = 0
					}):Play()
				end
			end
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			inContact = true
			if not option.open then
				tweenService:Create(colorBoxOutline, TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					ImageColor3 = Color3.fromRGB(130, 130, 145)
				}):Play()
			end
		end
	end)

	option.main.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			inContact = false
			if not option.open then
				tweenService:Create(colorBoxOutline, TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					ImageColor3 = Color3.fromRGB(90, 90, 105)
				}):Play()
			end
		end
	end)

	function option:SetColor(newColor)
		if self.mainHolder then
			self:updateVisuals(newColor)
		end
		self.visualize.ImageColor3 = newColor
		library.flags[self.flag] = newColor
		self.color = newColor
		self.callback(newColor)
	end

	function option:Close()
		library.activePopup = nil
		self.open = false
		local position = self.main.AbsolutePosition
		tweenService:Create(self.mainHolder, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			ImageTransparency = 1,
			Position = UDim2.new(0, position.X - 4, 0, position.Y - 8)
		}):Play()
		tweenService:Create(self.satval, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1
		}):Play()
		for _, object in next, self.mainHolder:GetDescendants() do
			if object:IsA("TextLabel") then
				tweenService:Create(object, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					TextTransparency = 1
				}):Play()
			elseif object:IsA("ImageLabel") then
				tweenService:Create(object, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					ImageTransparency = 1
				}):Play()
			elseif object:IsA("Frame") then
				tweenService:Create(object, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					BackgroundTransparency = 1
				}):Play()
			end
		end
		task.delay(0.28, function()
			if not self.open then
				self.mainHolder.Visible = false
			end
		end)
	end
end

local function loadOptions(option, holder)
	for _, newOption in next, option.options do
		if newOption.type == "label" then
			createLabel(newOption, option)
		elseif newOption.type == "toggle" then
			createToggle(newOption, option)
		elseif newOption.type == "button" then
			createButton(newOption, option)
		elseif newOption.type == "list" then
			createList(newOption, option, holder)
		elseif newOption.type == "box" then
			createBox(newOption, option)
		elseif newOption.type == "bind" then
			createBind(newOption, option)
		elseif newOption.type == "slider" then
			createSlider(newOption, option)
		elseif newOption.type == "color" then
			createColor(newOption, option, holder)
		elseif newOption.type == "folder" then
			newOption:init()
		end
	end
end

local function getFunctions(parent)
	function parent:AddLabel(option)
		option = typeof(option) == "table" and option or {}
		option.text = tostring(option.text)
		option.type = "label"
		option.position = #self.options
		table.insert(self.options, option)
		return option
	end

	function parent:AddToggle(option)
		option = typeof(option) == "table" and option or {}
		option.text = tostring(option.text)
		option.state = typeof(option.state) == "boolean" and option.state or false
		option.callback = typeof(option.callback) == "function" and option.callback or function() end
		option.type = "toggle"
		option.position = #self.options
		option.flag = option.flag or option.text
		library.flags[option.flag] = option.state
		table.insert(self.options, option)
		return option
	end

	function parent:AddButton(option)
		option = typeof(option) == "table" and option or {}
		option.text = tostring(option.text)
		option.callback = typeof(option.callback) == "function" and option.callback or function() end
		option.type = "button"
		option.position = #self.options
		option.flag = option.flag or option.text
		table.insert(self.options, option)
		return option
	end

	function parent:AddBind(option)
		option = typeof(option) == "table" and option or {}
		option.text = tostring(option.text)
		option.key = (option.key and option.key.Name) or option.key or "F"
		option.hold = typeof(option.hold) == "boolean" and option.hold or false
		option.callback = typeof(option.callback) == "function" and option.callback or function() end
		option.type = "bind"
		option.position = #self.options
		option.flag = option.flag or option.text
		library.flags[option.flag] = option.key
		table.insert(self.options, option)
		return option
	end

	function parent:AddSlider(option)
		option = typeof(option) == "table" and option or {}
		option.text = tostring(option.text)
		option.min = typeof(option.min) == "number" and option.min or 0
		option.max = typeof(option.max) == "number" and option.max or 0
		option.dual = typeof(option.dual) == "boolean" and option.dual or false
		option.value = math.clamp(typeof(option.value) == "number" and option.value or option.min, option.min, option.max)
		option.value2 = typeof(option.value2) == "number" and option.value2 or option.max
		option.callback = typeof(option.callback) == "function" and option.callback or function() end
		option.float = typeof(option.float) == "number" and option.float or 1
		option.type = "slider"
		option.position = #self.options
		option.flag = option.flag or option.text
		library.flags[option.flag] = option.value
		table.insert(self.options, option)
		return option
	end

	function parent:AddList(option)
		option = typeof(option) == "table" and option or {}
		option.text = tostring(option.text)
		option.values = typeof(option.values) == "table" and option.values or {}
		option.value = tostring(option.value or option.values[1] or "")
		option.callback = typeof(option.callback) == "function" and option.callback or function() end
		option.open = false
		option.type = "list"
		option.position = #self.options
		option.flag = option.flag or option.text
		library.flags[option.flag] = option.value
		table.insert(self.options, option)
		return option
	end

	function parent:AddBox(option)
		option = typeof(option) == "table" and option or {}
		option.text = tostring(option.text)
		option.value = tostring(option.value or "")
		option.callback = typeof(option.callback) == "function" and option.callback or function() end
		option.type = "box"
		option.position = #self.options
		option.flag = option.flag or option.text
		library.flags[option.flag] = option.value
		table.insert(self.options, option)
		return option
	end

	function parent:AddColor(option)
		option = typeof(option) == "table" and option or {}
		option.text = tostring(option.text)
		option.color = typeof(option.color) == "table" and Color3.new(tonumber(option.color[1]), tonumber(option.color[2]), tonumber(option.color[3])) or option.color or Color3.new(1, 1, 1)
		option.callback = typeof(option.callback) == "function" and option.callback or function() end
		option.open = false
		option.type = "color"
		option.position = #self.options
		option.flag = option.flag or option.text
		library.flags[option.flag] = option.color
		table.insert(self.options, option)
		return option
	end

	function parent:AddFolder(title)
		local option = {}
		option.title = tostring(title)
		option.options = {}
		option.open = false
		option.type = "folder"
		option.position = #self.options
		table.insert(self.options, option)
		getFunctions(option)
		function option:init()
			createOptionHolder(self.title, parent.content, self, true)
			loadOptions(self, parent)
		end
		return option
	end
end

function library:CreateWindow(title)
	local window = {
		title = tostring(title),
		options = {},
		open = true,
		canInit = true,
		init = false,
		position = #self.windows
	}
	getFunctions(window)
	table.insert(library.windows, window)
	return window
end

function library:Init()
	self.base = self.base or self:Create("ScreenGui")
	if syn and syn.protect_gui then
		syn.protect_gui(self.base)
	elseif get_hidden_gui then
		get_hidden_gui(self.base)
	elseif gethui then
		self.base.Parent = gethui()
	else
		self.base.Parent = coreGui
	end
	self.base.ResetOnSpawn = false
	self.base.Name = "ToraScriptV2"
	self.base.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	for _, window in next, self.windows do
		if window.canInit and not window.init then
			window.init = true
			createOptionHolder(window.title, self.base, window)
			loadOptions(window)
		end
	end
	return self.base
end

function library:Close()
	self.open = not self.open
	if self.activePopup then
		self.activePopup:Close()
	end
	for _, window in next, self.windows do
		if window.main then
			window.main.Visible = self.open
		end
	end
end

inputService.InputBegan:Connect(function(input)
	if input.UserInputType == ui or input.UserInputType == Enum.UserInputType.Touch then
		if library.activePopup then
			local holder = library.activePopup.mainHolder
			if input.Position.X < holder.AbsolutePosition.X or input.Position.Y < holder.AbsolutePosition.Y or
			   input.Position.X > holder.AbsolutePosition.X + holder.AbsoluteSize.X or
			   input.Position.Y > holder.AbsolutePosition.Y + holder.AbsoluteSize.Y then
				library.activePopup:Close()
			end
		end
	end
end)

inputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		update(input)
	end
end)

task.spawn(function()
	local localPlayer = players.LocalPlayer or players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	if localPlayer then
		local virtualUser = game:GetService("VirtualUser")
		localPlayer.Idled:Connect(function()
			virtualUser:CaptureController()
			virtualUser:ClickButton2(Vector2.new())
		end)
	end
end)

return library
