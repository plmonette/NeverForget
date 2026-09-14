local addonName, addon = ...

local CreateFrame = CreateFrame
local LibStub = LibStub
local Settings = Settings
local GameTooltip = GameTooltip

local addon_frame = CreateFrame("Frame")

-- Do not access until initialization.
local header_frame = nil

addon_frame:RegisterEvent("ADDON_LOADED")
addon_frame:SetScript("OnEvent", function(self, event, arg1)
  -- Make sure the event received is the one for our addon specifically.
  if event ~= "ADDON_LOADED" then return end
  if arg1 ~= addonName then return end

  -- No longer need to receive this event.
  addon_frame:UnregisterEvent("ADDON_LOADED")

  addon.API.Initialize()

  header_frame = addon.CreateHeaderFrame()

  addon.API.SetOnChangeCallback(function()
    header_frame:Refresh()
    if addon.editModeFrame and addon.editModeFrame:IsShown() then
      addon.editModeFrame.edit_frame:Refresh()
    end
  end)

  header_frame:RegisterEvent("BAG_UPDATE")
  header_frame:SetScript("OnEvent", function(self, event)
    self:Refresh()
  end)

  function header_frame:Toggle()
    addon.FrameUtil.ToggleFrame(self)
    addon.API.ToggleHidden()
  end

  header_frame:Refresh()

  if addon.API.IsHidden() then
    header_frame:Hide()
  else
    header_frame:Show()
  end

  -- LibDataBroker stuff
  local data_object = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("NeverForget", {
    type = "launcher",
    icon = "Interface\\Icons\\inv_misc_note_06",
    OnClick = function(clickedframe, button)
      if button == "LeftButton" then
        header_frame:Toggle()
      end
      if button == "RightButton" then
        if addon.optionsCategoryID then
          Settings.OpenToCategory(addon.optionsCategoryID)
        end
      end
    end,
  })
  function data_object:OnTooltipShow()
    self:AddLine("|cffffffffNeverForget|r")
    self:AddLine("Click to show/hide")
    self:AddLine("Right-click to open options")
  end
  function data_object:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
    GameTooltip:ClearLines()
    data_object.OnTooltipShow(GameTooltip)
    GameTooltip:Show()
  end
  function data_object:OnLeave()
    GameTooltip:Hide()
  end

  -- LibDBIcon stuff
  local icon = LibStub:GetLibrary("LibDBIcon-1.0")
  local minimap_db = addon.API.GetMinimapDB()
  icon:Register("NeverForgetLDB", data_object, minimap_db)

  local show_icon_callback = function()
    addon.API.SetMinimapButtonVisible()
    icon:Show("NeverForgetLDB")
  end
  local hide_icon_callback = function()
    addon.API.SetMinimapButtonHidden()
    icon:Hide("NeverForgetLDB")
  end

  addon.show_icon_callback = show_icon_callback
  addon.hide_icon_callback = hide_icon_callback
  addon.refresh_icon_callback = function()
    if icon:IsRegistered("NeverForgetLDB") then
      icon:Refresh("NeverForgetLDB", addon.API.GetMinimapDB())
    end
  end

  local options_panel = addon.CreateOptionsPanel(show_icon_callback, hide_icon_callback)
  addon.options_panel = options_panel
end)

-- Function for Toggle Window keybind. Must remain global for Bindings.xml.
function NeverForget_ToggleWindow()
  if header_frame then
    header_frame:Toggle()
  end
end

BINDING_NAME_TOGGLE_WINDOW = "Toggle Window"
BINDING_HEADER_NEVERFORGET = "NeverForget"



--[[

Todo list:

Add option panel to delete profile data. This could be used by someone in a bad
state to get out of said bad state. Should be initialized before anything else
so that if the bad state cause an error early in the addon's initialization, the
button still works.

Make edit mode more pretty
Reorder list.
Resizable checklist.
Put item link in checklist instead of only name.
Automatically retrieve items from bank
]]
