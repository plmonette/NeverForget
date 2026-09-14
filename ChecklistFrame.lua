local addonName, addon = ...

local ipairs = ipairs
local table = table
local CreateFrame = CreateFrame
local GetItemCount = GetItemCount
local GetItemInfo = GetItemInfo
local Item = Item
local UIParent = UIParent
local ToggleDropDownMenu = ToggleDropDownMenu
local UIDropDownMenu_CreateInfo = UIDropDownMenu_CreateInfo
local UIDropDownMenu_AddButton = UIDropDownMenu_AddButton
local UIDropDownMenu_Initialize = UIDropDownMenu_Initialize
local CloseDropDownMenus = CloseDropDownMenus
local BackdropTemplateMixin = BackdropTemplateMixin
local GameTooltip = GameTooltip

local function GetFrameWidth()
  return addon.API.GetChecklistWidth()
end

-- The vertical space that each items in the list takes.
local CHECKLIST_FRAME_ITEM_HEIGHT = 20

-- Creates the header title text. This is the name of the addon in the header_frame
-- frame.
local function CreateHeaderTitle(parent_frame)
  local header_title = parent_frame:CreateFontString(nil, "Artwork", "GameFontNormal")

  header_title:SetPoint("Left", 5, 0)
  header_title:SetTextColor(1, 0.82, 0, 1)
  header_title:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
  if addon.API.IsMinimized() then
    header_title:SetText("NeverForget - Minimized")
  else
    header_title:SetText("NeverForget")
  end

  return header_title
end

local function CreateXButton(parent_frame)
  local x_button = addon.FrameUtil.CreateButton(parent_frame, "X", nil)

  addon.FrameUtil.SetDarkFrameBackdrop(x_button)

  x_button:SetSize(20, 20)
  x_button:Hide()

  return x_button
end

-- Creates the container frame. The container frame is the one that displays the
-- checklist items and that can be minimized.
local function CreateContainerFrame(parent_frame)
  local container_frame = CreateFrame("Frame", nil, parent_frame, BackdropTemplateMixin and "BackdropTemplate")

  function container_frame:Initialize()
    self:SetWidth(GetFrameWidth())
    -- container_frame:SetPoint("Bottom")
    self.assigned_font_strings = {}
    self.available_font_strings = {}
    self.assigned_tooltip_frames = {}
    self.available_tooltip_frames = {}
    self.assigned_row_background_frames = {}
    self.available_row_background_frames = {}

    -- TODO FIX
    -- Initial state of minimized, which depends on saved variables.
    if addon.API.IsMinimized() then
      self:Hide()
    else
      self:Show()
    end

    self:SetPoint("Top", 0, -parent_frame:GetHeight())  -- Minus header height.
    addon.FrameUtil.SetFrameBackdrop(self)
  end

  function container_frame:GetFontString()
    if #self.available_font_strings == 0 then
      local new_font_string = addon.FrameUtil.CreateFontString(self)
      table.insert(self.available_font_strings, new_font_string)
    end

    local font_string = table.remove(self.available_font_strings)
    table.insert(self.assigned_font_strings, font_string)

    font_string:SetParent(self)
    font_string:ClearAllPoints()

    return font_string
  end

  function container_frame:GetTooltipFrame()
    if #self.available_tooltip_frames == 0 then
      local new_frame = CreateFrame("Frame", nil, self)
      new_frame:EnableMouse(true)
      table.insert(self.available_tooltip_frames, new_frame)
    end

    local tooltip_frame = table.remove(self.available_tooltip_frames)
    table.insert(self.assigned_tooltip_frames, tooltip_frame)

    tooltip_frame:ClearAllPoints()
    tooltip_frame:SetScript("OnEnter", nil)
    tooltip_frame:SetScript("OnLeave", nil)

    return tooltip_frame
  end

  function container_frame:GetRowBackgroundFrame()
    if #self.available_row_background_frames == 0 then
      local row_bg = CreateFrame("Frame", nil, self, BackdropTemplateMixin and "BackdropTemplate")
      row_bg:EnableMouse(true)
      addon.FrameUtil.SetRowBackdrop(row_bg)

      table.insert(self.available_row_background_frames, row_bg)
    end

    local row_bg = table.remove(self.available_row_background_frames)
    table.insert(self.assigned_row_background_frames, row_bg)

    row_bg:ClearAllPoints()
    addon.FrameUtil.SetRowBackdrop(row_bg)

    return row_bg
  end

  function container_frame:AddItemListNameRow(item_list_name)
    -- If there's already a list above, add 8px vertical padding.
    if self.row_count > 0 then
      self.current_y_offset = self.current_y_offset - 8
    end

    local y_position = self.current_y_offset
    self.current_y_offset = self.current_y_offset - CHECKLIST_FRAME_ITEM_HEIGHT
    self.row_count = self.row_count + 1

    local font_string = self:GetFontString()
    font_string.is_name_label = true
    font_string:SetParent(self)
    font_string:ClearAllPoints()

    font_string:SetSize(GetFrameWidth() - 50, 20)
    font_string:SetPoint("TopLeft", 3, y_position - 1)
    font_string:SetJustifyH("Left")

    font_string:SetTextColor(0.6, 0.8, 1.0, 1) -- Cool Ice Blue
    font_string:SetText(item_list_name)

    font_string:Show()
  end

  function container_frame:AddItemRow(item_id, item_count, bankIncluded)
    local y_position = self.current_y_offset
    self.current_y_offset = self.current_y_offset - CHECKLIST_FRAME_ITEM_HEIGHT
    self.row_count = self.row_count + 1

    -- Create row background frame
    local row_bg = self:GetRowBackgroundFrame()
    row_bg:SetSize(GetFrameWidth(), CHECKLIST_FRAME_ITEM_HEIGHT)
    row_bg:SetPoint("TopLeft", 0, y_position)
    row_bg:Show()

    -- Display item name
    local font_string = self:GetFontString()
    font_string.is_name_label = true
    font_string:SetParent(row_bg)
    font_string:ClearAllPoints()
    font_string:SetSize(GetFrameWidth() - 70, CHECKLIST_FRAME_ITEM_HEIGHT)
    font_string:SetPoint("Left", 4, 0)
    font_string:SetJustifyH("Left")
    font_string:SetText(item_id)
    
    local item = addon.Util.CreateItem(item_id)
    font_string.cancel_callback = item:ContinueWithCancelOnItemLoad(function()
      local _, itemLink = GetItemInfo(item_id)
      font_string:SetText(itemLink or item:GetItemLink() or item_id)
    end)

    font_string:Show()

    local tooltip_frame = self:GetTooltipFrame()
    tooltip_frame:SetParent(row_bg)
    tooltip_frame:SetSize(GetFrameWidth() - 70, CHECKLIST_FRAME_ITEM_HEIGHT)
    tooltip_frame:ClearAllPoints()
    tooltip_frame:SetPoint("Left", 4, 0)
    tooltip_frame:Show()

    tooltip_frame:SetScript("OnEnter", function(self)
      addon.FrameUtil.SetRowHoverBackdrop(row_bg)
      if not addon.API.AreTooltipsEnabled() then
        return
      end
      local item_link = item:GetItemLink()
      if item_link then
        GameTooltip:SetOwner(self, "ANCHOR_NONE")
        GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
        GameTooltip:SetHyperlink(item_link)
        GameTooltip:Show()
      end
    end)
    tooltip_frame:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
      if not row_bg:IsMouseOver() then
        addon.FrameUtil.SetRowBackdrop(row_bg)
      end
    end)

    row_bg:SetScript("OnEnter", function(self)
      addon.FrameUtil.SetRowHoverBackdrop(self)
    end)
    row_bg:SetScript("OnLeave", function(self)
      if not tooltip_frame:IsMouseOver() then
        addon.FrameUtil.SetRowBackdrop(self)
      end
    end)

    -- Display item count
    local real_item_count = GetItemCount(item_id, bankIncluded)

    local text_color = "Red"
    if real_item_count >= item_count then
      text_color = "Green"
    end

    local item_count_font_string = self:GetFontString()
    item_count_font_string.is_name_label = false
    item_count_font_string:SetParent(row_bg)
    item_count_font_string:ClearAllPoints()
    item_count_font_string:SetSize(60, CHECKLIST_FRAME_ITEM_HEIGHT)
    item_count_font_string:SetPoint("Right", -4, 0)
    item_count_font_string:SetJustifyH("Right")

    local colored_count = addon.Util.GetColoredText(real_item_count .. "/" .. item_count, text_color)
    item_count_font_string:SetText(colored_count)
    item_count_font_string:Show()
  end

  function container_frame:Refresh()
    self.row_count = 0
    self.current_y_offset = 0
    -- Hide all existing font_strings, and cancel the item name fetch.
    for i, font_string in ipairs(self.assigned_font_strings) do
      if font_string.cancel_callback ~= nil then
        font_string.cancel_callback()
      end

      font_string:Hide()
      table.insert(self.available_font_strings, font_string)
    end
    self.assigned_font_strings = {}

    for i, tooltip_frame in ipairs(self.assigned_tooltip_frames) do
      tooltip_frame:Hide()
      table.insert(self.available_tooltip_frames, tooltip_frame)
    end
    self.assigned_tooltip_frames = {}

    for i, row_bg in ipairs(self.assigned_row_background_frames) do
      row_bg:Hide()
      row_bg:SetScript("OnEnter", nil)
      row_bg:SetScript("OnLeave", nil)
      table.insert(self.available_row_background_frames, row_bg)
    end
    self.assigned_row_background_frames = {}

    for checklistIndex = 1, addon.API.GetChecklistCount() do
      if addon.API.IsChecklistVisible(checklistIndex) then
        local item_list = addon.API.GetItemList(checklistIndex)

        local bankIncluded = addon.API.IsBankIncluded(checklistIndex)

        -- Include one for the checklist name header.
        local checklist_name = addon.API.GetChecklistName(checklistIndex)
        if #item_list == 0 then
          checklist_name = checklist_name .. " (Empty)"
        end
        if bankIncluded then
          checklist_name = checklist_name .. " (Bank included)"
        end
        self:AddItemListNameRow(checklist_name)

        -- Set up each element of the checklist.
        for i, element in ipairs(item_list) do
          local item_id = element.item_id
          local item_count = element.item_count

          self:AddItemRow(item_id, item_count, bankIncluded)

          --[[frame:SetHyperlinksEnabled(true)
          frame:SetScript("OnHyperlinkEnter", function()
            -- Not ideal because it depends on the Item:CreateFromItemID() above.
            GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
            GameTooltip:SetHyperlink(item:GetItemLink())
            GameTooltip:Show()
          end)
          frame:SetScript("OnHyperlinkLeave", function()
            GameTooltip:Hide()
          end)]]
        
        end
      end
    end

    if self.row_count == 0 then
      local colored_text = addon.Util.GetColoredText("No selected item lists", "Red")
      self:AddItemListNameRow(colored_text)
    end

    -- Set the container height based on the total accumulated Y offset.
    self:SetHeight(-self.current_y_offset)
  end
  return container_frame
end

-- Creates the header frame. The header frame is movable frame that contains
-- the name of the addon and the + and - buttons.
function addon.CreateHeaderFrame()
  -- This frame is named so that its position is restored on addon load.
  local header_frame = CreateFrame("Frame", "NeverForget_HeaderFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")

  header_frame:SetSize(GetFrameWidth(), CHECKLIST_FRAME_ITEM_HEIGHT)
  header_frame:SetPoint("Center")
  addon.FrameUtil.SetDarkFrameBackdrop(header_frame)

  addon.FrameUtil.SetFrameMovable(header_frame)

  local separator = header_frame:CreateTexture(nil, "OVERLAY")
  separator:SetHeight(1)
  separator:SetPoint("BOTTOMLEFT", header_frame, "BOTTOMLEFT")
  separator:SetPoint("BOTTOMRIGHT", header_frame, "BOTTOMRIGHT")
  separator:SetColorTexture(0.9, 0.7, 0, 0.6)

  -- Children
  header_frame.buttons = {}
  function header_frame:CreateButton(icon_character, callback)
    local index = #self.buttons + 1

    local header_button = addon.FrameUtil.CreateButton(self,
        icon_character,
        callback)

    header_button:SetSize(CHECKLIST_FRAME_ITEM_HEIGHT, CHECKLIST_FRAME_ITEM_HEIGHT)
    header_button:SetPoint("Right", -(index - 1) * CHECKLIST_FRAME_ITEM_HEIGHT, 0)

    self.buttons[index] = header_button
  end

  function header_frame:CreateTextureButton(normalTex, pushedTex, yOffset, callback)
    local index = #self.buttons + 1

    local header_button = CreateFrame("Button", nil, self)
    header_button:SetSize(16, 16)
    
    header_button:SetNormalTexture(normalTex)
    if pushedTex then
      header_button:SetPushedTexture(pushedTex)
    end

    header_button:SetScript("OnEnter", function(self)
      local normal = self:GetNormalTexture()
      local pushed = self:GetPushedTexture()
      if normal then normal:SetVertexColor(1, 0, 0) end
      if pushed then pushed:SetVertexColor(1, 0, 0) end
    end)
    header_button:SetScript("OnLeave", function(self)
      local normal = self:GetNormalTexture()
      local pushed = self:GetPushedTexture()
      if normal then normal:SetVertexColor(1, 1, 1) end
      if pushed then pushed:SetVertexColor(1, 1, 1) end
    end)
    header_button:SetScript("OnMouseDown", function(self, button)
      if button == "LeftButton" then
        local normal = self:GetNormalTexture()
        local pushed = self:GetPushedTexture()
        if normal then normal:SetVertexColor(0.5, 0.5, 0.5) end
        if pushed then pushed:SetVertexColor(0.5, 0.5, 0.5) end
      end
    end)
    header_button:SetScript("OnMouseUp", function(self, button)
      if button == "LeftButton" then
        local normal = self:GetNormalTexture()
        local pushed = self:GetPushedTexture()
        if self:IsMouseOver() then
          if normal then normal:SetVertexColor(1, 0, 0) end
          if pushed then pushed:SetVertexColor(1, 0, 0) end
        else
          if normal then normal:SetVertexColor(1, 1, 1) end
          if pushed then pushed:SetVertexColor(1, 1, 1) end
        end
      end
    end)

    local y = yOffset or 0
    header_button:SetPoint("Right", -(index - 1) * 20, y)
    header_button:SetScript("OnClick", callback)

    self.buttons[index] = header_button
    return header_button
  end

  header_frame.title = CreateHeaderTitle(header_frame)

  -- Container frame.
  local container_frame = CreateContainerFrame(header_frame)

  container_frame:Initialize()

  header_frame.container_frame = container_frame

  -- Golden Minimize Button (Arrow-Up/Down)
  local gold_min_btn = header_frame:CreateTextureButton(
    addon.API.IsMinimized() and "Interface\\Buttons\\Arrow-Down-Up" or "Interface\\Buttons\\Arrow-Up-Up",
    addon.API.IsMinimized() and "Interface\\Buttons\\Arrow-Down-Down" or "Interface\\Buttons\\Arrow-Up-Down",
    2,
    function()
      addon.API.ToggleMinimized()
      if addon.API.IsMinimized() then
        header_frame.container_frame:Hide()
      else
        header_frame.container_frame:Show()
      end
      header_frame:Refresh()
    end
  )
  header_frame.gold_min_btn = gold_min_btn

  -- Golden Options/Menu Button (Gear Icon)
  local options_btn = header_frame:CreateTextureButton(
    "Interface\\Buttons\\UI-OptionsButton",
    nil,
    0,
    function()
      ToggleDropDownMenu(1, nil, MyDropDown, "cursor", 0, 0)
    end
  )
  options_btn:SetSize(12, 12)

  local function Initialize(frame, level, menuList)
    if level == 1 then
      local info = UIDropDownMenu_CreateInfo()
      info.text = "Your checklists"
      info.isTitle = true
      info.notCheckable = true
      UIDropDownMenu_AddButton(info)

      -- One item per checklist.
      for checklistIndex=1, addon.API.GetChecklistCount() do
        info = UIDropDownMenu_CreateInfo()
        info.text = addon.Util.GetColoredText(addon.API.GetChecklistName(checklistIndex), "Blue")
        info.hasArrow = true
        info.keepShownOnClick = true
        info.isNotRadio = true
        info.menuList = checklistIndex
        info.arg1 = checklistIndex
        info.checked =  addon.API.IsChecklistVisible(checklistIndex)
        info.func = function(self, arg1)
          addon.API.ToggleChecklistVisibility(arg1)
        end
        UIDropDownMenu_AddButton(info)
      end

      -- Separator
      info = UIDropDownMenu_CreateInfo()
      info.disabled = true 
      info.notCheckable = true
      UIDropDownMenu_AddButton(info)

      -- Title button
      info = UIDropDownMenu_CreateInfo()
      info.text = "Actions"
      info.isTitle = true
      info.notCheckable = true
      UIDropDownMenu_AddButton(info)

      info = UIDropDownMenu_CreateInfo()
      info.text = "New list"
      info.notCheckable = true
      info.func = addon.API.CreateChecklist
      UIDropDownMenu_AddButton(info)
    end

    if level == 2 then
      local checklistIndex = menuList

      -- Title button
      local info = UIDropDownMenu_CreateInfo()
      info.text = addon.Util.GetColoredText(addon.API.GetChecklistName(checklistIndex), "Blue")
      info.isTitle = true
      info.notCheckable = true
      UIDropDownMenu_AddButton(info, 2)

      info = UIDropDownMenu_CreateInfo()
      info.text = "Edit"
      info.notCheckable = true
      info.arg1 = checklistIndex
      info.func = function(self, arg1)
        addon.OpenEditMode(arg1)
        CloseDropDownMenus()
      end
      UIDropDownMenu_AddButton(info, 2)

      info = UIDropDownMenu_CreateInfo()
      info.text = "Rename"
      info.notCheckable = true
      info.arg1 = checklistIndex
      info.func = function(self, arg1)
        addon.API.RenameChecklist(arg1)
        CloseDropDownMenus()
      end
      UIDropDownMenu_AddButton(info, 2)

      info = UIDropDownMenu_CreateInfo()
      info.text = "Delete"
      info.notCheckable = true
      info.arg1 = checklistIndex
      info.func = function(self, arg1)
        addon.API.DeleteChecklist(arg1)
        CloseDropDownMenus()
      end
      UIDropDownMenu_AddButton(info, 2)

      info = UIDropDownMenu_CreateInfo()
      info.text = "Move up"
      info.notCheckable = true
      info.arg1 = checklistIndex
      info.disabled = checklistIndex == 1
      info.func = function(self, arg1)
        addon.API.MoveChecklistUp(arg1)
        CloseDropDownMenus()
      end
      UIDropDownMenu_AddButton(info, 2)

      info = UIDropDownMenu_CreateInfo()
      info.text = "Move down"
      info.notCheckable = true
      info.arg1 = checklistIndex
      info.disabled = checklistIndex == addon.API.GetChecklistCount()
      info.func = function(self, arg1)
        addon.API.MoveChecklistDown(arg1)
        CloseDropDownMenus()
      end
      UIDropDownMenu_AddButton(info, 2)

      -- Separator
      info = UIDropDownMenu_CreateInfo()
      info.disabled = true 
      info.notCheckable = true
      UIDropDownMenu_AddButton(info, 2)

      -- Title button
      info = UIDropDownMenu_CreateInfo()
      info.text = "List options"
      info.isTitle = true
      info.notCheckable = true
      UIDropDownMenu_AddButton(info, 2)

      info = UIDropDownMenu_CreateInfo()
      info.text = "Include bank"
      info.checked = addon.API.IsBankIncluded(checklistIndex)
      info.keepShownOnClick = true
      info.isNotRadio = true
      info.arg1 = checklistIndex
      info.func = function(self, arg1)
        addon.API.ToggleIncludeBank(arg1)
      end
      UIDropDownMenu_AddButton(info, 2)

      -- Separator
      info = UIDropDownMenu_CreateInfo()
      info.disabled = true 
      info.notCheckable = true
      UIDropDownMenu_AddButton(info, 2)

      -- Title button
      info = UIDropDownMenu_CreateInfo()
      info.text = "Import options"
      info.isTitle = true
      info.notCheckable = true
      UIDropDownMenu_AddButton(info, 2)

      info = UIDropDownMenu_CreateInfo()
      info.text = "Import"
      info.notCheckable = true
      info.arg1 = checklistIndex
      info.func = function(self, arg1)
        addon.OpenImportFrame(arg1)
        CloseDropDownMenus()
      end
      UIDropDownMenu_AddButton(info, 2)

      info = UIDropDownMenu_CreateInfo()
      info.text = "Show import string"
      info.notCheckable = true
      info.arg1 = checklistIndex
      info.func = function(self, arg1)
        addon.OpenShowImportStringWindow(arg1)
        CloseDropDownMenus()
      end
      UIDropDownMenu_AddButton(info, 2)
    end
  end

  local drop_down_frame = CreateFrame("Frame", "MyDropDown", UIParent, "UIDropDownMenuTemplate")

  UIDropDownMenu_Initialize(drop_down_frame, Initialize, "MENU")

  function header_frame:Refresh()
    header_frame.container_frame:Refresh()

    local width = GetFrameWidth()
    header_frame:SetWidth(width)
    header_frame.container_frame:SetWidth(width)

    if header_frame.gold_min_btn then
      header_frame.gold_min_btn:ClearAllPoints()
      if addon.API.IsMinimized() then
        header_frame.gold_min_btn:SetNormalTexture("Interface\\Buttons\\Arrow-Down-Up")
        header_frame.gold_min_btn:SetPushedTexture("Interface\\Buttons\\Arrow-Down-Down")
        header_frame.gold_min_btn:SetPoint("Right", 0, -5)
      else
        header_frame.gold_min_btn:SetNormalTexture("Interface\\Buttons\\Arrow-Up-Up")
        header_frame.gold_min_btn:SetPushedTexture("Interface\\Buttons\\Arrow-Up-Down")
        header_frame.gold_min_btn:SetPoint("Right", 0, 2)
      end
    end

    if addon.API.IsMinimized() then
      header_frame.title:SetText("NeverForget - Minimized")
    else
      header_frame.title:SetText("NeverForget")
    end
  end

  return header_frame
end