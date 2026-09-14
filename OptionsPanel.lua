local addonName, addon = ...

local CreateFrame = CreateFrame
local UIParent = UIParent
local Settings = Settings
local StaticPopup_Show = StaticPopup_Show
local math = math
local _G = _G

function addon.CreateOptionsPanel(show_icon_callback, hide_icon_callback)
  -- Options panel
  local options_panel = CreateFrame("Frame", nil, UIParent)
  options_panel.name = "NeverForget"

  options_panel.minimap_button_visibility_label = addon.FrameUtil.CreateFontString(options_panel)
  options_panel.minimap_button_visibility_label:SetSize(210, 20)
  options_panel.minimap_button_visibility_label:SetPoint("TopLeft", 5, -5)
  options_panel.minimap_button_visibility_label:SetJustifyH("Left")
  options_panel.minimap_button_visibility_label:SetText("Show minimap button")
  options_panel.minimap_button_visibility_label:Show()
 
  options_panel.minimap_button_visibility_checkbox = CreateFrame("CheckButton", nil, options_panel, "ChatConfigCheckButtonTemplate") 
  options_panel.minimap_button_visibility_checkbox:SetPoint("TopLeft", 125, -5)
  options_panel.minimap_button_visibility_checkbox:SetScript("OnClick", function(self)
    local checked = self:GetChecked()
    if checked then
      show_icon_callback()
      addon.API.SetMinimapButtonVisible()
    else
      hide_icon_callback()
      addon.API.SetMinimapButtonHidden()
    end
  end)

  options_panel.tooltips_enabled_label = addon.FrameUtil.CreateFontString(options_panel)
  options_panel.tooltips_enabled_label:SetSize(210, 20)
  options_panel.tooltips_enabled_label:SetPoint("TopLeft", 5, -25)
  options_panel.tooltips_enabled_label:SetJustifyH("Left")
  options_panel.tooltips_enabled_label:SetText("Show item tooltips")
  options_panel.tooltips_enabled_label:Show()

  options_panel.tooltips_enabled_checkbox = CreateFrame("CheckButton", nil, options_panel, "ChatConfigCheckButtonTemplate")
  options_panel.tooltips_enabled_checkbox:SetPoint("TopLeft", 125, -25)
  options_panel.tooltips_enabled_checkbox:SetScript("OnClick", function(self)
    local checked = self:GetChecked()
    addon.API.SetTooltipsEnabled(checked)
  end)

  -- Width control slider
  options_panel.width_slider = CreateFrame("Slider", "NeverForgetWidthSlider", options_panel, "OptionsSliderTemplate")
  options_panel.width_slider:SetPoint("TopLeft", 10, -65)
  options_panel.width_slider:SetWidth(150)
  options_panel.width_slider:SetMinMaxValues(200, 500)
  options_panel.width_slider:SetValueStep(10)
  if options_panel.width_slider.SetObeyStepOnDrag then
    options_panel.width_slider:SetObeyStepOnDrag(true)
  end

  local slider_text = _G["NeverForgetWidthSliderText"]
  local slider_low = _G["NeverForgetWidthSliderLow"]
  local slider_high = _G["NeverForgetWidthSliderHigh"]

  if slider_low then slider_low:SetText("200") end
  if slider_high then slider_high:SetText("500") end

  options_panel.width_slider:SetScript("OnValueChanged", function(self, value)
    local rounded = math.floor(value + 0.5)
    if slider_text then
      slider_text:SetText("Checklist Width: " .. rounded)
    end
    if rounded ~= addon.API.GetChecklistWidth() then
      addon.API.SetChecklistWidth(rounded)
    end
  end)

  options_panel.reset_button = addon.FrameUtil.CreateButton(options_panel, "Reset Database", function()
    StaticPopup_Show("NEVERFORGET_API_CONFIRM_RESET")
  end)
  options_panel.reset_button:SetSize(120, 20)
  options_panel.reset_button:SetPoint("TopLeft", 5, -110)
  addon.FrameUtil.SetDarkFrameBackdrop(options_panel.reset_button)

  function options_panel:refresh()
    local is_icon_visible = addon.API.IsMinimapButtonVisible()
    self.minimap_button_visibility_checkbox:SetChecked(is_icon_visible)
    
    local tooltips_enabled = addon.API.AreTooltipsEnabled()
    self.tooltips_enabled_checkbox:SetChecked(tooltips_enabled)
    
    local width = addon.API.GetChecklistWidth()
    self.width_slider:SetValue(width)
    if slider_text then
      slider_text:SetText("Checklist Width: " .. width)
    end
  end

  options_panel:SetScript("OnShow", function(self)
    self:refresh()
  end)

  local category = Settings.RegisterCanvasLayoutCategory(options_panel, options_panel.name)
  Settings.RegisterAddOnCategory(category)
  addon.optionsCategoryID = category:GetID()

  return options_panel
end