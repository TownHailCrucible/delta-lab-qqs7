local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local player = Players.LocalPlayer

-- Clean up old GUI
if player.PlayerGui:FindFirstChild("MovieLibrary") then
	player.PlayerGui.MovieLibrary:Destroy()
end

-- GUI Setup
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "MovieLibrary"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 500, 0, 500)
frame.Position = UDim2.new(0.5, -250, 0.5, -250)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, -40, 0, 40)
title.Position = UDim2.new(0, 10, 0, 10)
title.Text = "🎬 Movie Menu"
title.Font = Enum.Font.GothamBold
title.TextSize = 24
title.TextColor3 = Color3.new(1, 1, 1)
title.BackgroundTransparency = 1

local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 10)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
closeBtn.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

local searchBox = Instance.new("TextBox", frame)
searchBox.PlaceholderText = "Search for a movie..."
searchBox.Size = UDim2.new(1, -20, 0, 30)
searchBox.Position = UDim2.new(0, 10, 0, 55)
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 18
searchBox.TextColor3 = Color3.new(0, 0, 0)
searchBox.BackgroundColor3 = Color3.fromRGB(240, 240, 240)

local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(1, -20, 1, -100)
scroll.Position = UDim2.new(0, 10, 0, 95)
scroll.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
scroll.BorderSizePixel = 0
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollBarThickness = 6

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 5)
layout.SortOrder = Enum.SortOrder.LayoutOrder

-- Movies
local movies = {
	{title = "Emesis Blue (2023)", url = "https://youtu.be/V0ODG8bFme0"},
	{title = "Zombieland (2009)", url = "https://myflixerz.to/watch-movie/zombieland-19269.5298178"},
	{title = "Borat (2006)", url = "https://www.lookmovie2.to/movies/play/1689756713-borat-cultural-learnings-of-america"},
	{title = "Borat 2 (2020)", url = "https://www.tokyvideo.com/video/watch-free-film-borat-2"},
	{title = "Brüno (2009)", url = "https://ww1.goojara.to/moe97o"},
	{title = "El Camino (2019)", url = "https://www.dailymotion.com/video/x9ayulw"},
	{title = "Jungle Book (1942)", url = "https://watch.plex.tv/movie/jungle-book-1942?utm_medium=share"},
	{title = "Night of the Living Dead", url = "https://watch.plex.tv/movie/night-of-the-living-dead?utm_medium=share"},
	{title = "Charade (1963)", url = "https://watch.plex.tv/movie/charade-1963?utm_medium=share"},
	{title = "Nosferatu (1922)", url = "https://archive.org/details/nosferatu"},
	{title = "Reefer Madness (1936)", url = "https://archive.org/details/reefer_madness_2013"},
	-- Add more movies here if you want
}

-- Show Movies
local function refreshList(filter)
	for _, child in pairs(scroll:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end

	for _, movie in ipairs(movies) do
		if not filter or movie.title:lower():find(filter:lower()) then
			local btn = Instance.new("TextButton", scroll)
			btn.Size = UDim2.new(1, 0, 0, 40)
			btn.Text = movie.title
			btn.Font = Enum.Font.Gotham
			btn.TextSize = 18
			btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
			btn.TextColor3 = Color3.new(1, 1, 1)
			btn.MouseButton1Click:Connect(function()
				if setclipboard then
					setclipboard(movie.url)
				elseif syn and syn.setclipboard then
					syn.setclipboard(movie.url)
				end
				StarterGui:SetCore("SendNotification", {
					Title = "Copied to Clipboard",
					Text = movie.title,
					Duration = 3
				})
			end)
		end
	end
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	refreshList(searchBox.Text)
end)

refreshList()
