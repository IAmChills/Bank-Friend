local welcome = [=[|cffeeee22Bank Friend loaded!
Shift + Double-RightClick to use items in bags while Bank Frame is open. Use /consumetimer N (/ct N) to calibrate 
the doubleclick window for 0.1< N <0.5, in seconds.
]=]
local welcome_msg = string.gsub(welcome,"\92n", "\n") --Subbing out my text editor's new line escape for the \n recognized by WoW.. i think
print(welcome_msg)

local isBankOpen = false 
local btn

local doubleClickWindow = 0.3 -- Default time, in seconds, for the double click to be executed
local maxWindow = 0.5         -- max and min set to prevent wonky behavior from user error 
local minWindow = 0.1         

--Slash Commands
SLASH_CONSUMETIMER1 = "/consumetimer"
SLASH_CONSUMETIMER2 = "/ct"         --Please check to make sure this doesn't overlap with any of your addons. Comment out or edit as needed
local function setTimer(msg)        --Catch and save user input from slash command
    local timer = tonumber(msg)
    if timer then
        if timer >= 0.1 and timer <= 0.5 then
            doubleClickWindow = timer
            print("|cffffff00Consume timer set to "..timer.." seconds.") -- "|caarrggbb" is an escape sequence to set alpha and rgb color of text in hex.
        else
            print("|cffee0022Consume timer (in seconds) must be number between 0.1 and 0.5")
        end    
    else
       print("|cffee0022Consume timer (in seconds) must be number between 0.1 and 0.5")
    end
end
SlashCmdList["CONSUMETIMER"] = function(msg) setTimer(msg) end


-- Reset button after time, clicking or on BankClose (can't find a way to hook into bag closing)
local function dismissButton()
    btn:SetPoint("BOTTOMLEFT")
    btn:SetAttribute("macrotext","")
    btn:Hide() 
end

--Find cursor position and move the Button to the cursor
local function callButton()
    local x,y = GetCursorPosition()
    local x_off, y_off = btn:GetWidth()/2, btn:GetHeight()/2
    local scale = UIParent:GetEffectiveScale()                 --convert mouse coords into scale used for ui elements
    local set_x, set_y = (x/scale) - x_off , (y/scale) - y_off --Update x,y by scale, then offset
    btn:SetPoint("BOTTOMLEFT",set_x,set_y)                     --Call button to cursor
    btn:Show()                                                 --Make it clickable
    C_Timer.After(doubleClickWindow, dismissButton)            --Set timer for button to dismiss if click is not registered quickly (Should simulate a double click)
end

-- Set up script to handle item usage 
local function ItemHook(self, button)
    if isBankOpen  and IsLeftShiftKeyDown() and button == "RightButton" then 
        
        StackSplitFrame:Hide() -- Hide the stack split window that pops up by default 
        local itemName = ""
        local itemName = GetItemInfo(C_Container.GetContainerItemInfo(self:GetParent():GetID(), self:GetID()).itemID)
        btn:SetAttribute("macrotext","/use "..itemName) 
        
        --btn:Click() --Can't click a secure button with Click()
        callButton()  -- So instead we move to button under the cursor for a cheeky double-click simulation
       
    end 
end

--Event Handler
local function onOpenClose(self, event)
     if event == "BANKFRAME_OPENED" or event == "MERCHANT_SHOW" or event == "TRADE_SHOW" then 
        isBankOpen = true 
    else 
        isBankOpen = false
        dismissButton()
    end
end
   
-- Set up the button 
btn = CreateFrame("Button", "Consumer_BankFriend", UIParent, "SecureActionButtonTemplate") -- Creates the SecureActionButton required to run macrotext. This btn is invisible.
--btn = CreateFrame("Button", "Consumer_BankFriend", UIParent, "UIPanelButtonTemplate")    -- Comment out above line and use this one instead to visualize the button maipulation (will turn off /use item)
btn:SetPoint("BOTTOMLEFT")
btn:SetWidth(10);btn:SetHeight(20)
btn:SetFrameStrata("HIGH")

btn:SetAttribute("type", "macro")
btn:RegisterForClicks("RightButtonDown") --Feels a little strange for WoW to be catching on the down click, but is a bit more responsive

btn:RegisterEvent("BANKFRAME_OPENED") btn:RegisterEvent("BANKFRAME_CLOSED")
btn:RegisterEvent("MERCHANT_SHOW") btn:RegisterEvent("MERCHANT_CLOSED")
btn:RegisterEvent("TRADE_SHOW") btn:RegisterEvent("TRADE_CLOSED")

btn:SetScript("OnEvent", onOpenClose) 
btn:HookScript("OnClick", dismissButton)    --SetScript doesn't work here for some reason. Using HookScript instead
hooksecurefunc("ContainerFrameItemButton_OnModifiedClick", ItemHook)