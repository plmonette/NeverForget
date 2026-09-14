local addonName, addon = ...

local ipairs = ipairs
local CreateFrame = CreateFrame
local GetCursorInfo = GetCursorInfo
local ClearCursor = ClearCursor
local Item = Item
local BackdropTemplateMixin = BackdropTemplateMixin
local GetItemInfo = GetItemInfo

local function GetFrameWidth()
  return addon.API.GetChecklistWidth()
end

-- The vertical space that each items in the list takes.
local CHECKLIST_FRAME_ITEM_HEIGHT = 20


local function CreateCopyOfItemList(checklistIndex)
  local item_list = addon.API.GetItemList(checklistIndex)

  local copy = {}
  for i, item in ipairs(item_list) do
    copy[i] = {}
    copy[i].item_id = item.item_id
    copy[i].item_count = item.item_count
  end

  return copy
end

local function CreateHeaderTitle(parent_frame)
  local header_title = parent_frame:CreateFontString(nil, "Artwork", "GameFontNormal")

  header_title:SetPoint("Left", 5, 0)
  header_title:SetTextColor(1, 0.82, 0, 1)
  header_title:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
  header_title:SetText("NeverForget - Editing")

  return header_title
end

local function CreateEditModeFrame()
  -- This frame is named so that its position is restored on addon load.
  local header_frame = CreateFrame("Frame", "NeverForget_EditMode_HeaderFrame", nil, BackdropTemplateMixin and "BackdropTemplate")

  header_frame:SetSize(GetFrameWidth(), CHECKLIST_FRAME_ITEM_HEIGHT)
  header_frame:SetPoint("Top", 0, -300)
  addon.FrameUtil.SetDarkFrameBackdrop(header_frame)

  addon.FrameUtil.SetFrameMovable(header_frame)

  header_frame.title = CreateHeaderTitle(header_frame)

  local separator = header_frame:CreateTexture(nil, "OVERLAY")
  separator:SetHeight(1)
  separator:SetPoint("BOTTOMLEFT", header_frame, "BOTTOMLEFT")
  separator:SetPoint("BOTTOMRIGHT", header_frame, "BOTTOMRIGHT")
  separator:SetColorTexture(0.9, 0.7, 0, 0.6)

  local edit_frame = CreateFrame("Frame", nil, header_frame, BackdropTemplateMixin and "BackdropTemplate")
  header_frame.edit_frame = edit_frame

  function edit_frame:Initialize()
    self:SetWidth(GetFrameWidth())
    self:SetPoint("Top", 0, -header_frame:GetHeight()) --, 0, -parent_frame:GetHeight())
    addon.FrameUtil.SetFrameBackdrop(self)

    self:CreateSaveButton()
    self:CreateCancelButton()
    self:CreateAddItemRowFrame(function(item_id_or_link)
      local identifier = addon.Util.GetItemIdentifier(item_id_or_link) or item_id_or_link
      addon.API.AddItemToItemList(edit_frame.item_list, identifier, 1)
      edit_frame:Refresh()
    end)

    self.item_name_font_strings = {}
    self.item_count_edit_boxes = {}
    self.item_remove_buttons = {}
    self.row_background_frames = {}
  end

  function edit_frame:GetRowBackgroundFrame(index)
    local row_bg = self.row_background_frames[index]
    if row_bg == nil then
      row_bg = CreateFrame("Frame", nil, self, BackdropTemplateMixin and "BackdropTemplate")
      row_bg:EnableMouse(true)
      addon.FrameUtil.SetRowBackdrop(row_bg)

      row_bg:SetScript("OnEnter", function(self)
        addon.FrameUtil.SetRowHoverBackdrop(self)
      end)
      row_bg:SetScript("OnLeave", function(self)
        addon.FrameUtil.SetRowBackdrop(self)
      end)

      self.row_background_frames[index] = row_bg
    end
    return row_bg
  end

  function edit_frame:CreateSaveButton()
    local save_button = addon.FrameUtil.CreateButton(self, "Save", function()
      self:SaveItemList()
    end)

    save_button:SetSize(70, 20)
    save_button:SetPoint("Bottom", 45, 10)
    addon.FrameUtil.SetDarkFrameBackdrop(save_button)

    self.save_button = save_button
  end

  function edit_frame:CreateCancelButton()
    local cancel_button = addon.FrameUtil.CreateButton(self, "Cancel", function()
      self:CancelEdit()
    end)

    cancel_button:SetSize(70, 20)
    cancel_button:SetPoint("Bottom", -45, 10)
    addon.FrameUtil.SetDarkFrameBackdrop(cancel_button)

    self.cancel_button = cancel_button
  end

  function edit_frame:SaveItemList()
    if edit_frame.last_focused_edit_box then
      edit_frame.last_focused_edit_box:SetItemCount()
    end

    addon.API.SetItemList(self.checklistIndex, self.item_list)

    self.item_list = nil
    header_frame:Hide()
  end

  function edit_frame:CancelEdit()
    self.item_list = nil
    header_frame:Hide()
  end

  function edit_frame:CreateAddItemRowFrame(add_item_callback)
    local add_item_row_frame = CreateFrame("Frame", nil, self, BackdropTemplateMixin and "BackdropTemplate")

    addon.FrameUtil.SetDropZoneBackdrop(add_item_row_frame)

    add_item_row_frame:SetSize(200, 20)
    add_item_row_frame:SetPoint("Bottom")

    function add_item_row_frame:OnClick(button)
      if button ~= "LeftButton" then
        return
      end

      -- Check if there is an item on the cursor
      local info_type, item_id, item_link = GetCursorInfo()
      if info_type ~= "item" then
        return
      end

      add_item_callback(item_link or item_id)
      ClearCursor()
    end

    add_item_row_frame:EnableMouse(true)
    add_item_row_frame:SetScript("OnReceiveDrag", function(self)
      self:OnClick("LeftButton")
    end)
    add_item_row_frame:SetScript("OnMouseDown", function(self, button)
      self:OnClick(button)
    end)

    add_item_row_frame:SetScript("OnEnter", function(self)
      local info_type = GetCursorInfo()
      if info_type == "item" then
        self:SetBackdropBorderColor(1, 0.9, 0, 1)
        self:SetBackdropColor(0.2, 0.2, 0.2, 0.95)
      end
    end)
    add_item_row_frame:SetScript("OnLeave", function(self)
      self:SetBackdropBorderColor(0.9, 0.7, 0, 0.5)
      self:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
    end)

    add_item_row_frame:Show()

    local font_string = addon.FrameUtil.CreateFontString(add_item_row_frame)

    font_string:SetPoint("Center")
    font_string:SetText("Add an item by dragging it here")
    font_string:SetTextColor(0.9, 0.7, 0, 0.8)
    font_string:Show()

    self.add_item_row_frame = add_item_row_frame
  end

  function edit_frame:GetRemoveButton(index)
    local remove_button = self.item_remove_buttons[index]
    if remove_button == nil then
      remove_button = addon.FrameUtil.CreateButton(self, "X", nil)

      addon.FrameUtil.SetDarkFrameBackdrop(remove_button)

      remove_button:SetSize(20, 20)
      remove_button:Hide()

      --font_string:SetSize(20, self:GetWidth() - 50)
      self.item_remove_buttons[index] = remove_button
    end

    return remove_button
  end

  function edit_frame:GetItemNameFontString(index)
    local font_string = self.item_name_font_strings[index]
    if font_string == nil then
      font_string = addon.FrameUtil.CreateFontString(self)
      --font_string:SetSize(20, self:GetWidth() - 50)
      self.item_name_font_strings[index] = font_string
    end

    return font_string
  end

  function edit_frame:GetItemCountEditBox(index)
    local edit_box = self.item_count_edit_boxes[index]
    if edit_box == nil then
      edit_box = addon.FrameUtil.CreateEditBox(self)
      edit_box:SetSize(50, 20)
      edit_box:SetNumeric(true)
      edit_box:SetMaxLetters(5)
      self.item_count_edit_boxes[index] = edit_box
    end

    return edit_box
  end

  function edit_frame:SetChecklistIndex(index)
    self.checklistIndex = index
    local colored_checklist_name = addon.Util.GetColoredText(addon.API.GetChecklistName(index), "Blue")
    header_frame.title:SetText("NeverForget - Editing " .. colored_checklist_name)
    self.item_list = CreateCopyOfItemList(self.checklistIndex)
  end

  function edit_frame:Refresh()
    local width = GetFrameWidth()
    header_frame:SetWidth(width)
    self:SetWidth(width)

    -- First hide all existing frames. This is needed because there could now
    -- be one less element in the item list since last refresh, meaning there
    -- might be one frame of each type that is still showing that will not get
    -- overwritten.
    for i, edit_box in ipairs(self.item_count_edit_boxes) do
      edit_box:Hide()
    end
    for i, font_string in ipairs(self.item_name_font_strings) do
      if font_string.cancel_callback ~= nil then
        font_string.cancel_callback()
      end
      font_string:Hide()
    end
    for i, remove_button in ipairs(self.item_remove_buttons) do
      remove_button:Hide()
    end
    if self.row_background_frames then
      for i, row_bg in ipairs(self.row_background_frames) do
        row_bg:Hide()
      end
    end

    -- Show each item rows. Could be none if the list is currently empty.
    for i, item in ipairs(self.item_list) do
      local item_id = item.item_id
      local item_count = item.item_count

      local y_position = -(i-1)*CHECKLIST_FRAME_ITEM_HEIGHT

      local row_bg = self:GetRowBackgroundFrame(i)
      row_bg:SetSize(GetFrameWidth(), CHECKLIST_FRAME_ITEM_HEIGHT)
      row_bg:SetPoint("TopLeft", 0, y_position)
      row_bg:Show()

      -- Display the close buttons.
      local remove_button = self:GetRemoveButton(i)
      remove_button:SetParent(row_bg)
      remove_button:SetSize(16, 16)
      remove_button:ClearAllPoints()
      remove_button:SetPoint("Left", 4, 0)
      remove_button:Show()
      remove_button:SetScript("OnClick", function()
        addon.API.RemoveItemFromItemList(edit_frame.item_list, i)
        edit_frame:Refresh()
      end)

      -- Display the item's name.
      local item_name_font_string = self:GetItemNameFontString(i)
      item_name_font_string:SetParent(row_bg)
      item_name_font_string:ClearAllPoints()
      item_name_font_string:SetPoint("Left", remove_button, "Right", 6, 0)
      item_name_font_string:SetSize(GetFrameWidth() - 75, CHECKLIST_FRAME_ITEM_HEIGHT)
      item_name_font_string:SetJustifyH("Left")
      item_name_font_string:SetText(item_id)
      item_name_font_string:Show()

      local item = addon.Util.CreateItem(item_id)
      item_name_font_string.cancel_callback = item:ContinueWithCancelOnItemLoad(function()
        local _, itemLink = GetItemInfo(item_id)
        item_name_font_string:SetText(itemLink or item:GetItemLink() or item_id)
      end)

      -- Display the item's count in an edit box
      local item_count_edit_box = self:GetItemCountEditBox(i)
      item_count_edit_box:SetParent(row_bg)
      item_count_edit_box:SetSize(40, 18)
      item_count_edit_box:ClearAllPoints()
      item_count_edit_box:SetPoint("Right", -4, 0)
      item_count_edit_box.original_count = item_count
      item_count_edit_box:SetText(item_count)
      item_count_edit_box:Show()

      function item_count_edit_box:SetItemCount()
        local new_count = self:GetNumber()
        if new_count == 0 then
          self:SetText(self.original_count)
          edit_frame:Refresh()
          self:ClearFocus()
          return
        end

        addon.API.ModifyItemCount(edit_frame.item_list, item_id, new_count)
        self:ClearFocus()
        edit_frame:Refresh()
      end

      item_count_edit_box:SetScript("OnEnterPressed", function(self)
        self:SetItemCount()
      end)

      item_count_edit_box:SetScript("OnEditFocusGained", function(self)
        edit_frame.last_focused_edit_box = self
        --self:HighlightText(0, 0)
      end)

      item_count_edit_box:SetScript("OnEditFocusLost", function(self)
        edit_frame.last_focused_edit_box = nil
        if edit_frame.item_list then
          self:SetItemCount()
        end
        --self:HighlightText(0, 0)
      end)

    end

    -- Show add item row.
    self.add_item_row_frame:SetSize(GetFrameWidth() - 20, 24)
    self.add_item_row_frame:ClearAllPoints()
    self.add_item_row_frame:SetPoint("Bottom", 0, 36)

    self:SetHeight(20 * #self.item_list + 65)
  end

  edit_frame:Initialize()

  return header_frame
end

local headerFrame = nil

function addon.OpenEditMode(checklistIndex)
  if not headerFrame then
    headerFrame = CreateEditModeFrame()
    addon.editModeFrame = headerFrame
  end

  headerFrame.edit_frame:SetChecklistIndex(checklistIndex)
  headerFrame.edit_frame:Refresh()

  headerFrame:Show()
end

function addon.CloseEditMode()
  if headerFrame then
    headerFrame:Hide()
  end
end