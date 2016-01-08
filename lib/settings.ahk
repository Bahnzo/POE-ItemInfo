; ######### SETTINGS ############

; (Internal: RegExr x-forms)
; GroupBox
;   Gui, Add, GroupBox, (.+?) , (.+) -> ; $2 \n\n    GuiAddGroupBox("$2", "$1")
; Checkbox (with label)
;   Gui, Add, (.+?), (.+?) hwnd(.+?) v(.+?) g(.+?) Checked%(.+)%, (.+) -> GuiAdd$1("$7", "$2", Opts.$6, "$4", "$3", "$5")
; Checkbox /w/o label)
;   Gui, Add, (.+?), (.+?) hwnd(.+?) v(.+?) Checked%(.+)%, (.+) -> GuiAdd$1("$6", "$2", Opts.$5, "$4", "$3")
; Edit
;   Gui, Add, Edit, (.+?) hwnd(.+?) v(.+?), %(.+)% -> GuiAddEdit(Opts.$4, "$1", "$3", "", "$2")
; Text
;   Gui, Add, Text, (.+?) hwnd(.+?) v(.+?), (.+) -> GuiAddText("$4", "$1", "$3", "", "$2")
; Button
;   Gui, Add, Button, (.+?) g(.+?), (.+) -> GuiAddButton("$3", "$1", "", "$2", "")

CreateSettingsUI() 
{
    Global
    ; General 

    GuiAddGroupBox("General", "x7 y15 w260 h90")
    
    ; Note: window handles (hwnd) are only needed if a UI tooltip should be attached.
    
    GuiAddCheckbox("Only show tooltip if PoE is frontmost", "x17 y35 w210 h30", Opts.OnlyActiveIfPOEIsFront, "OnlyActiveIfPOEIsFront", "OnlyActiveIfPOEIsFrontH")
    AddToolTip(OnlyActiveIfPOEIsFrontH, "If checked the script does nothing if the`nPath of Exile window isn't the frontmost")
    GuiAddCheckbox("Put tooltip results on clipboard", "x17 y65 w210 h30", Opts.PutResultsOnClipboard, "PutResultsOnClipboard", "PutResultsOnClipboardH")
    AddToolTip(PutResultsOnClipboardH, "Put tooltip result text onto the system clipboard`n(overwriting the item info text PoE put there to begin with)")
    
    ; Display - All Gear 

    GuiAddGroupBox("Display - All Gear", "x7 y115 w260 h90")
    
    GuiAddCheckbox("Show item level", "x17 y135 w210 h30", Opts.ShowItemLevel, "ShowItemLevel")
    GuiAddCheckbox("Show max sockets based on item lvl", "x17 y165 w210 h30", Opts.ShowMaxSockets, "ShowMaxSockets", "ShowMaxSocketsH")
    AddToolTip(ShowMaxSocketsH, "Show maximum amount of sockets the item can have`nbased on its item level")

    ; Display - Weapons 

    GuiAddGroupBox("Display - Weapons", "x7 y215 w260 h60")

    GuiAddCheckbox("Show damage calculations", "x17 y235 w210 h30", Opts.ShowDamageCalculations, "ShowDamageCalculations")

    ; Display - Other 

    GuiAddGroupBox("Display - Other", "x7 y285 w260 h60")

    GuiAddCheckbox("Show currency value in chaos", "x17 y305 w210 h30", Opts.ShowCurrencyValueInChaos, "ShowCurrencyValueInChaos")

    ; Valuable Evaluations 

    GuiAddGroupBox("Valuable Evaluations", "x7 y355 w260 h150")

    GuiAddCheckbox("Show unique evaluation", "x17 y375 w210 h30", Opts.ShowUniqueEvaluation, "ShowUniqueEvaluation", "ShowUniqueEvaluationH")
    AddToolTip(ShowUniqueEvaluationH, "Mark unique as valuable based on its item name`n(can be edited in data\ValuableUniques.txt)")
    GuiAddCheckbox("Show gem evaluation", "x17 y405 w210 h30", Opts.ShowGemEvaluation, "ShowGemEvaluation", "ShowGemEvaluationH", "SettingsUI_ChkShowGemEvaluation")
    AddToolTip(ShowGemEvaluationH, "Mark gem as valuable if quality is higher`nthan the following threshold`n(can be edited in data\ValuableGems.txt)")
        GuiAddText("Gem quality valuable threshold:", "x37 y439 w150 h20", "LblGemQualityThreshold")
        GuiAddEdit(Opts.GemQualityValueThreshold, "x197 y437 w40 h20", "GemQualityValueThreshold")
    GuiAddCheckbox("Mark high number of links as valuable", "x17 y465 w210 h30", Opts.MarkHighLinksAsValuable, "MarkHighLinksAsValuable")
    
    ; Display - Affixes 

    GuiAddGroupBox("Display - Affixes", "x277 y15 w260 h360")

    GuiAddCheckbox("Show affix totals", "x287 y35 w210 h30", Opts.ShowAffixTotals, "ShowAffixTotals", "ShowAffixTotalsH")
    AddToolTip(ShowAffixTotalsH, "Show a statistic how many prefixes and suffixes`nthe item has")
    GuiAddCheckbox("Show affix details", "x287 y65 w210 h30", Opts.ShowAffixDetails, "ShowAffixDetails", "ShowAffixDetailsH", "SettingsUI_ChkShowAffixDetails")
    AddToolTip(ShowAffixDetailsH, "Show detailed affix breakdown. Note that crafted mods are not`nsupported and some ranges are guesstimated (marked with a *)")
        GuiAddCheckbox("Mirror affix lines", "x307 y95 w190 h30", Opts.MirrorAffixLines, "MirrorAffixLines", "MirrorAffixLinesH")
        AddToolTip(MirrorAffixLinesH, "Display truncated affix names within the breakdown")
    GuiAddCheckbox("Show affix level", "x287 y125 w210 h30", Opts.ShowAffixLevel, "ShowAffixLevel", "ShowAffixLevelH")
        AddToolTip(ShowAffixLevelH, "Show item level of the displayed affix value bracket")
    GuiAddCheckbox("Show affix bracket", "x287 y155 w210 h30", Opts.ShowAffixBracket, "ShowAffixBracket", "ShowAffixBracketH")
        AddToolTip(ShowAffixBracketH, "Show affix value bracket as is on the item")
    GuiAddCheckbox("Show affix max possible", "x287 y185 w210 h30", Opts.ShowAffixMaxPossible, "ShowAffixMaxPossible", "ShowAffixMaxPossibleH", "SettingsUI_ChkShowAffixMaxPossible")
        AddToolTip(ShowAffixMaxPossibleH, "Show max possible affix value bracket")
        GuiAddCheckbox("Max span starting from first", "x307 y215 w190 h30", Opts.MaxSpanStartingFromFirst, "MaxSpanStartingFromFirst", "MaxSpanStartingFromFirstH")
        AddToolTip(MaxSpanStartingFromFirstH, "Construct a pseudo range by combining the lowest possible`naffix value bracket with the max possible based on item level")
    GuiAddCheckbox("Show affix bracket tier", "x287 y245 w210 h30", Opts.ShowAffixBracketTier, "ShowAffixBracketTier", "ShowAffixBracketTierH", "SettingsUI_ChkShowAffixBracketTier")
        AddToolTip(ShowAffixBracketTierH, "Display affix bracket tier in reverse ordering,`nT1 being the best possible roll.")
        GuiAddCheckbox("Tier relative to item lvl", "x307 y275 w190 h20", Opts.TierRelativeToItemLevel, "TierRelativeToItemLevel", "TierRelativeToItemLevelH")
        GuiAddText("(hold Shift to toggle temporarily)", "x330 y295 w190 h20", "LblTierRelativeToItemLevelOverrideNote")
        AddToolTip(TierRelativeToItemLevelH, "When showing affix bracket tier, make T1 being best possible`ntaking item level into account.")
        GuiAddCheckbox("Show affix bracket tier total", "x307 y315 w190 h20", Opts.ShowAffixBracketTierTotal, "ShowAffixBracketTierTotal", "ShowAffixBracketTierTotalH")
        AddToolTip(ShowAffixBracketTierTotalH, "Show number of total affix bracket tiers in format T/N,`n where T = tier on item, N = number of total tiers available")
    GuiAddCheckbox("Show Darkshrine information", "x287 y345 w210 h20", Opts.ShowDarkShrineInfo, "ShowDarkShrineInfo", "ShowDarkShrineInfoH")
    AddToolTip(ShowDarkShrineInfoH, "Show information about possible Darkshrine effects")
        
    ; Display - Results 

    GuiAddGroupBox("Display - Results", "x277 y385 w260 h210")
    
    GuiAddCheckbox("Compact double ranges", "x287 y400  w210 h30", Opts.CompactDoubleRanges, "CompactDoubleRanges", "CompactDoubleRangesH")
    AddToolTip(CompactDoubleRangesH, "Show double ranges as one range,`ne.g. x-y (to) z-w becomes x-w")
    GuiAddCheckbox("Compact affix types", "x287 y435 w210 h30", Opts.CompactAffixTypes, "CompactAffixTypes", "CompactAffixTypesH")
    AddToolTip(CompactAffixTypesH, "Replace affix type with a short-hand version,`ne.g. P=Prefix, S=Suffix, CP=Composite")

    GuiAddText("Mirror line field width:", "x287 y477 w110 h20", "LblMirrorLineFieldWidth")
    GuiAddEdit(Opts.MirrorLineFieldWidth, "x407 y475 w40 h20", "MirrorLineFieldWidth")
    GuiAddText("Value range field width:", "x287 y517 w120 h20", "LblValueRangeFieldWidth")
    GuiAddEdit(Opts.ValueRangeFieldWidth, "x407 y515 w40 h20", "ValueRangeFieldWidth")
    GuiAddText("Affix detail delimiter:", "x287 y537 w120 h20", "LblAffixDetailDelimiter")
    GuiAddEdit(Opts.AffixDetailDelimiter, "x407 y535 w40 h20", "AffixDetailDelimiter")
    GuiAddText("Affix detail ellipsis:", "x287 y567 w120 h20", "LblAffixDetailEllipsis")
    GuiAddEdit(Opts.AffixDetailEllipsis, "x407 y565 w40 h20", "AffixDetailEllipsis")

    ; Tooltip 

    GuiAddGroupBox("Tooltip", "x7 y515 w260 h185")
    
    GuiAddCheckBox("Use tooltip timeout", "x17 y530 w210 h30", Opts.UseTooltipTimeout, "UseTooltipTimeout", "UseTooltipTimeoutH", "SettingsUI_ChkUseTooltipTimeout")
    AddToolTip(UseTooltipTimeoutH, "Hide tooltip automatically after x amount of ticks have passed")
        GuiAddText("Timeout ticks (1 tick = 100ms):", "x27 y562 w150 h20", "LblToolTipTimeoutTicks")
        GuiAddEdit(Opts.ToolTipTimeoutTicks, "x187 y560 w50 h20", "ToolTipTimeoutTicks")

    GuiAddCheckbox("Display at fixed coordinates", "x17 y580 w230 h30", Opts.DisplayToolTipAtFixedCoords, "DisplayToolTipAtFixedCoords", "DisplayToolTipAtFixedCoordsH", "SettingsUI_ChkDisplayToolTipAtFixedCoords")
    AddToolTip(DisplayToolTipAtFixedCoordsH, "Show tooltip in virtual screen space at the fixed`ncoordinates given below. Virtual screen space means`nthe full desktop frame, including any secondary`nmonitors. Coords are relative to the top left edge`nand increase going down and to the right.")
        GuiAddText("X:", "x37 y612 w20 h20", "LblScreenOffsetX")
        GuiAddEdit(Opts.ScreenOffsetX, "x55 y610 w40 h20", "ScreenOffsetX")
        GuiAddText("Y:", "x105 y612 w20 h20", "LblScreenOffsetY")
        GuiAddEdit(Opts.ScreenOffsetY, "x125 y610 w40 h20", "ScreenOffsetY")

    GuiAddText("Mousemove threshold (px):", "x17 y642 w160 h20", "LblMouseMoveThreshold", "LblMouseMoveThresholdH")
    AddToolTip(LblMouseMoveThresholdH, "Hide tooltip automatically after the mouse has moved x amount of pixels")
    GuiAddEdit(Opts.MouseMoveThreshold, "x187 y640 w50 h20", "MouseMoveThreshold", "MouseMoveThresholdH")

    GuiAddText("Font Size:", "x17 y672 w160 h20", "LblFontSize")
    GuiAddEdit(Opts.FontSize, "x187 y670 w50 h20", "FontSize")

    GuiAddText("Mouse over settings or see the beginning of the PoE-Item-Info.ahk script for comments on what these settings do exactly.", "x277 y605 w250 h60")

    GuiAddButton("&Defaults", "x287 y670 w80 h23", "SettingsUI_BtnDefaults")
    GuiAddButton("&OK", "Default x372 y670 w75 h23", "SettingsUI_BtnOK")
    GuiAddButton("&Cancel", "x452 y670 w80 h23", "SettingsUI_BtnCancel")
}

UpdateSettingsUI()
{    
    Global

    GuiControl,, OnlyActiveIfPOEIsFront, % Opts.OnlyActiveIfPOEIsFront
    GuiControl,, PutResultsOnClipboard, % Opts.PutResultsOnClipboard
    GuiControl,, ShowItemLevel, % Opts.ShowItemLevel
    GuiControl,, ShowMaxSockets, % Opts.ShowMaxSockets
    GuiControl,, ShowDamageCalculations, % Opts.ShowDamageCalculations
    GuiControl,, ShowCurrencyValueInChaos, % Opts.ShowCurrencyValueInChaos
    GuiControl,, DisplayToolTipAtFixedCoords, % Opts.DisplayToolTipAtFixedCoords
    If (Opts.DisplayToolTipAtFixedCoords == False) 
    {
        GuiControl, Disable, LblScreenOffsetX
        GuiControl, Disable, ScreenOffsetX
        GuiControl, Disable, LblScreenOffsetY
        GuiControl, Disable, ScreenOffsetY        
    }
    Else
    {
        GuiControl, Enable, LblScreenOffsetX
        GuiControl, Enable, ScreenOffsetX
        GuiControl, Enable, LblScreenOffsetY
        GuiControl, Enable, ScreenOffsetY
    }
    ;~ GetScreenInfo()
    ;~ If (Globals.Get("MonitorCount", 1) > 1) 
    ;~ {
        ;~ GuiControl,, DisplayToolTipAtFixedCoords, % Opts.DisplayToolTipAtFixedCoords
        ;~ GuiControl,, ScreenOffsetX, % Opts.ScreenOffsetX
        ;~ GuiControl,, ScreenOffsetY, % Opts.ScreenOffsetY
        ;~ GuiControl, Enable, DisplayToolTipAtFixedCoords
        ;~ GuiControl, Enable, LblScreenOffsetX
        ;~ GuiControl, Enable, ScreenOffsetX
        ;~ GuiControl, Enable, LblScreenOffsetY
        ;~ GuiControl, Enable, ScreenOffsetY
    ;~ }
    ;~ Else
    ;~ {
        ;~ GuiControl,, DisplayToolTipAtFixedCoords, 0
        ;~ GuiControl,, ScreenOffsetX, 0
        ;~ GuiControl,, ScreenOffsetY, 0
        ;~ GuiControl, Disable, DisplayToolTipAtFixedCoords
        ;~ GuiControl, Disable, LblScreenOffsetX
        ;~ GuiControl, Disable, ScreenOffsetX
        ;~ GuiControl, Disable, LblScreenOffsetY
        ;~ GuiControl, Disable, ScreenOffsetY
    ;~ }
    
    GuiControl,, ShowUniqueEvaluation, % Opts.ShowUniqueEvaluation
    GuiControl,, ShowGemEvaluation, % Opts.ShowGemEvaluation
    If (Opts.ShowGemEvaluation == False) 
    {
        GuiControl, Disable, LblGemQualityThreshold
        GuiControl, Disable, GemQualityValueThreshold
    }
    Else
    {
        GuiControl, Enable, LblGemQualityThreshold
        GuiControl, Enable, GemQualityValueThreshold
    }
    GuiControl,, GemQualityValueThreshold, % Opts.GemQualityValueThreshold
    GuiControl,, MarkHighLinksAsValuable, % Opts.MarkHighLinksAsValuable
    
    GuiControl,, ShowAffixTotals, % Opts.ShowAffixTotals
    GuiControl,, ShowAffixDetails, % Opts.ShowAffixDetails
    If (Opts.ShowAffixDetails == False) 
    {
        GuiControl, Disable, MirrorAffixLines
    }
    Else
    {
        GuiControl, Enable, MirrorAffixLines
    }
    GuiControl,, MirrorAffixLines, % Opts.MirrorAffixLines
    GuiControl,, ShowAffixLevel, % Opts.ShowAffixLevel
    GuiControl,, ShowAffixBracket, % Opts.ShowAffixBracket
    GuiControl,, ShowAffixMaxPossible, % Opts.ShowAffixMaxPossible
    If (Opts.ShowAffixMaxPossible == False) 
    {
        GuiControl, Disable, MaxSpanStartingFromFirst
    }
    Else
    {
        GuiControl, Enable, MaxSpanStartingFromFirst
    }
    GuiControl,, MaxSpanStartingFromFirst, % Opts.MaxSpanStartingFromFirst
    GuiControl,, ShowAffixBracketTier, % Opts.ShowAffixBracketTier
    GuiControl,, ShowAffixBracketTierTotal, % Opts.ShowAffixBracketTierTotal
    If (Opts.ShowAffixBracketTier == False) 
    {
        GuiControl, Disable, TierRelativeToItemLevel
        GuiControl, Disable, ShowAffixBracketTierTotal
    }
    Else
    {
        GuiControl, Enable, TierRelativeToItemLevel
        GuiControl, Enable, ShowAffixBracketTierTotal
    }
    GuiControl,, TierRelativeToItemLevel, % Opts.TierRelativeToItemLevel
    GuiControl,, ShowDarkShrineInfo, % Opts.ShowDarkShrineInfo
    
    GuiControl,, CompactDoubleRanges, % Opts.CompactDoubleRanges
    GuiControl,, CompactAffixTypes, % Opts.CompactAffixTypes
    GuiControl,, MirrorLineFieldWidth, % Opts.MirrorLineFieldWidth
    GuiControl,, ValueRangeFieldWidth, % Opts.ValueRangeFieldWidth
    GuiControl,, AffixDetailDelimiter, % Opts.AffixDetailDelimiter
    GuiControl,, AffixDetailEllipsis, % Opts.AffixDetailEllipsis
    
    GuiControl,, UseTooltipTimeout, % Opts.UseTooltipTimeout
    If (Opts.UseTooltipTimeout == False) 
    {
        GuiControl, Disable, LblToolTipTimeoutTicks
        GuiControl, Disable, ToolTipTimeoutTicks
    }
    Else
    {
        GuiControl, Enable, LblToolTipTimeoutTicks
        GuiControl, Enable, ToolTipTimeoutTicks
    }
    GuiControl,, ToolTipTimeoutTicks, % Opts.ToolTipTimeoutTicks
    GuiControl,, MouseMoveThreshold, % Opts.MouseMoveThreshold
    GuiControl,, FontSize, % Opts.FontSize
}

ShowSettingsUI()
{
    ; remove POE-Item-Info tooltip if still visible
    SetTimer, ToolTipTimer, Off
    ToolTip
    Fonts.SetUIFont(9)
    Gui, Show, w545 h710, PoE Item Info Settings
}

IniRead(ConfigPath, Section_, Key, Default_) 
{
    Result := ""
    IniRead, Result, %ConfigPath%, %Section_%, %Key%, %Default_%
    return Result
}

IniWrite(Val, ConfigPath, Section_, Key)
{
    IniWrite, %Val%, %ConfigPath%, %Section_%, %Key%
}

ReadConfig(ConfigPath="config.ini")
{
    Global
    IfExist, %ConfigPath%
    {
        ; General
        
        Opts.OnlyActiveIfPOEIsFront := IniRead(ConfigPath, "General", "OnlyActiveIfPOEIsFront", Opts.OnlyActiveIfPOEIsFront)
        Opts.PutResultsOnClipboard := IniRead(ConfigPath, "General", "PutResultsOnClipboard", Opts.PutResultsOnClipboard)
        
        ; Display - All Gear
        
        Opts.ShowItemLevel := IniRead(ConfigPath, "DisplayAllGear", "ShowItemLevel", Opts.ShowItemLevel)
        Opts.ShowMaxSockets := IniRead(ConfigPath, "DisplayAllGear", "ShowMaxSockets", Opts.ShowMaxSockets)
        
        ; Display - Weapons
        
        Opts.ShowDamageCalculations := IniRead(ConfigPath, "DisplayWeapons", "ShowDamageCalculations", Opts.ShowDamageCalculations)
        
        ; Display - Other
        
        Opts.ShowCurrencyValueInChaos := IniRead(ConfigPath, "DisplayOther", "ShowCurrencyValueInChaos", Opts.ShowCurrencyValueInChaos)
        
        ; Valuable Evaluations
        
        Opts.ShowUniqueEvaluation := IniRead(ConfigPath, "ValuableEvaluations", "ShowUniqueEvaluation", Opts.ShowUniqueEvaluation)
        Opts.ShowGemEvaluation := IniRead(ConfigPath, "ValuableEvaluations", "ShowGemEvaluation", Opts.ShowGemEvaluation)
        Opts.GemQualityValueThreshold := IniRead(ConfigPath, "ValuableEvaluations", "GemQualityValueThreshold", Opts.GemQualityValueThreshold)
        Opts.MarkHighLinksAsValuable := IniRead(ConfigPath, "ValuableEvaluations", "MarkHighLinksAsValuable", Opts.MarkHighLinksAsValuable)
        
        ; Display - Affixes
        
        Opts.ShowAffixTotals := IniRead(ConfigPath, "DisplayAffixes", "ShowAffixTotals", Opts.ShowAffixTotals)
        Opts.ShowAffixDetails := IniRead(ConfigPath, "DisplayAffixes", "ShowAffixDetails", Opts.ShowAffixDetails)
        Opts.MirrorAffixLines := IniRead(ConfigPath, "DisplayAffixes", "MirrorAffixLines", Opts.MirrorAffixLines)
        Opts.ShowAffixLevel := IniRead(ConfigPath, "DisplayAffixes", "ShowAffixLevel", Opts.ShowAffixLevel)
        Opts.ShowAffixBracket := IniRead(ConfigPath, "DisplayAffixes", "ShowAffixBracket", Opts.ShowAffixBracket)
        Opts.ShowAffixMaxPossible := IniRead(ConfigPath, "DisplayAffixes", "ShowAffixMaxPossible", Opts.ShowAffixMaxPossible)
        Opts.MaxSpanStartingFromFirst := IniRead(ConfigPath, "DisplayAffixes", "MaxSpanStartingFromFirst", Opts.MaxSpanStartingFromFirst)
        Opts.ShowAffixBracketTier := IniRead(ConfigPath, "DisplayAffixes", "ShowAffixBracketTier", Opts.ShowAffixBracketTier)
        Opts.TierRelativeToItemLevel := IniRead(ConfigPath, "DisplayAffixes", "TierRelativeToItemLevel", Opts.TierRelativeToItemLevel)
        Opts.ShowAffixBracketTierTotal := IniRead(ConfigPath, "DisplayAffixes", "ShowAffixBracketTierTotal", Opts.ShowAffixBracketTierTotal)
        Opts.ShowDarkShrineInfo := IniRead(ConfigPath, "DisplayAffixes", "ShowDarkShrineInfo", Opts.ShowDarkShrineInfo)
        
        ; Display - Results
        
        Opts.CompactDoubleRanges := IniRead(ConfigPath, "DisplayResults", "CompactDoubleRanges", Opts.CompactDoubleRanges)
        Opts.CompactAffixTypes := IniRead(ConfigPath, "DisplayResults", "CompactAffixTypes", Opts.CompactAffixTypes)
        Opts.MirrorLineFieldWidth := IniRead(ConfigPath, "DisplayResults", "MirrorLineFieldWidth", Opts.MirrorLineFieldWidth)
        Opts.ValueRangeFieldWidth := IniRead(ConfigPath, "DisplayResults", "ValueRangeFieldWidth", Opts.ValueRangeFieldWidth)
        Opts.AffixDetailDelimiter := IniRead(ConfigPath, "DisplayResults", "AffixDetailDelimiter", Opts.AffixDetailDelimiter)
        Opts.AffixDetailEllipsis := IniRead(ConfigPath, "DisplayResults", "AffixDetailEllipsis", Opts.AffixDetailEllipsis)
        
        ; Tooltip
        
        Opts.MouseMoveThreshold := IniRead(ConfigPath, "Tooltip", "MouseMoveThreshold", Opts.MouseMoveThreshold)
        Opts.UseTooltipTimeout := IniRead(ConfigPath, "Tooltip", "UseTooltipTimeout", Opts.UseTooltipTimeout)
        Opts.DisplayToolTipAtFixedCoords := IniRead(ConfigPath, "Tooltip", "DisplayToolTipAtFixedCoords", Opts.DisplayToolTipAtFixedCoords)
        Opts.ScreenOffsetX := IniRead(ConfigPath, "Tooltip", "ScreenOffsetX", Opts.ScreenOffsetX)
        Opts.ScreenOffsetY := IniRead(ConfigPath, "Tooltip", "ScreenOffsetY", Opts.ScreenOffsetY)
        Opts.ToolTipTimeoutTicks := IniRead(ConfigPath, "Tooltip", "ToolTipTimeoutTicks", Opts.ToolTipTimeoutTicks)
        Opts.FontSize := IniRead(ConfigPath, "Tooltip", "FontSize", Opts.FontSize)
    }
}

WriteConfig(ConfigPath="config.ini")
{
    Global
    Opts.ScanUI()
    
    ; General
    
    IniWrite(Opts.OnlyActiveIfPOEIsFront, ConfigPath, "General", "OnlyActiveIfPOEIsFront")
    IniWrite(Opts.PutResultsOnClipboard, ConfigPath, "General", "PutResultsOnClipboard")
    
    ; Display - All Gear
    
    IniWrite(Opts.ShowItemLevel, ConfigPath, "DisplayAllGear", "ShowItemLevel")
    IniWrite(Opts.ShowMaxSockets, ConfigPath, "DisplayAllGear", "ShowMaxSockets")
    
    ; Display - Weapons
    
    IniWrite(Opts.ShowDamageCalculations, ConfigPath, "DisplayWeapons", "ShowDamageCalculations")
    
    ; Display - Other
    
    IniWrite(Opts.ShowCurrencyValueInChaos, ConfigPath, "DisplayOther", "ShowCurrencyValueInChaos")
    
    ; Valuable Evaluations
    
    IniWrite(Opts.ShowUniqueEvaluation, ConfigPath, "ValuableEvaluations", "ShowUniqueEvaluation")
    IniWrite(Opts.ShowGemEvaluation, ConfigPath, "ValuableEvaluations", "ShowGemEvaluation")
    IniWrite(Opts.GemQualityValueThreshold, ConfigPath, "ValuableEvaluations", "GemQualityValueThreshold")
    IniWrite(Opts.MarkHighLinksAsValuable, ConfigPath, "ValuableEvaluations", "MarkHighLinksAsValuable")
    
    ; Display - Affixes
    
    IniWrite(Opts.ShowAffixTotals, ConfigPath, "DisplayAffixes", "ShowAffixTotals")
    IniWrite(Opts.ShowAffixDetails, ConfigPath, "DisplayAffixes", "ShowAffixDetails")
    IniWrite(Opts.MirrorAffixLines, ConfigPath, "DisplayAffixes", "MirrorAffixLines")
    IniWrite(Opts.ShowAffixLevel, ConfigPath, "DisplayAffixes", "ShowAffixLevel")
    IniWrite(Opts.ShowAffixBracket, ConfigPath, "DisplayAffixes", "ShowAffixBracket")
    IniWrite(Opts.ShowAffixMaxPossible, ConfigPath, "DisplayAffixes", "ShowAffixMaxPossible")
    IniWrite(Opts.MaxSpanStartingFromFirst, ConfigPath, "DisplayAffixes", "MaxSpanStartingFromFirst")
    IniWrite(Opts.ShowAffixBracketTier, ConfigPath, "DisplayAffixes", "ShowAffixBracketTier")
    IniWrite(Opts.TierRelativeToItemLevel, ConfigPath, "DisplayAffixes", "TierRelativeToItemLevel")
    IniWrite(Opts.ShowAffixBracketTierTotal, ConfigPath, "DisplayAffixes", "ShowAffixBracketTierTotal")
    IniWrite(Opts.ShowDarkShrineInfo, ConfigPath, "DisplayAffixes", "ShowDarkShrineInfo")
    
    ; Display - Results
    
    IniWrite(Opts.CompactDoubleRanges, ConfigPath, "DisplayResults", "CompactDoubleRanges")
    IniWrite(Opts.CompactAffixTypes, ConfigPath, "DisplayResults", "CompactAffixTypes")
    IniWrite(Opts.MirrorLineFieldWidth, ConfigPath, "DisplayResults", "MirrorLineFieldWidth")
    IniWrite(Opts.ValueRangeFieldWidth, ConfigPath, "DisplayResults", "ValueRangeFieldWidth")
    If IsEmptyString(Opts.AffixDetailDelimiter)
    {
        IniWrite("""" . Opts.AffixDetailDelimiter . """", ConfigPath, "DisplayResults", "AffixDetailDelimiter")
    }
    Else
    {
        IniWrite(Opts.AffixDetailDelimiter, ConfigPath, "DisplayResults", "AffixDetailDelimiter")
    }
    IniWrite(Opts.AffixDetailEllipsis, ConfigPath, "DisplayResults", "AffixDetailEllipsis")
    
    ; Tooltip
    
    IniWrite(Opts.MouseMoveThreshold, ConfigPath, "Tooltip", "MouseMoveThreshold")
    IniWrite(Opts.UseTooltipTimeout, ConfigPath, "Tooltip", "UseTooltipTimeout")
    IniWrite(Opts.DisplayToolTipAtFixedCoords, ConfigPath, "Tooltip", "DisplayToolTipAtFixedCoords")
    IniWrite(Opts.ScreenOffsetX, ConfigPath, "Tooltip", "ScreenOffsetX")
    IniWrite(Opts.ScreenOffsetY, ConfigPath, "Tooltip", "ScreenOffsetY")
    IniWrite(Opts.ToolTipTimeoutTicks, ConfigPath, "Tooltip", "ToolTipTimeoutTicks")
    IniWrite(Opts.FontSize, ConfigPath, "Tooltip", "FontSize") 
}

CopyDefaultConfig()
{
    FileCopy, %A_ScriptDir%\data\defaults.ini, %A_ScriptDir%
    FileMove, %A_ScriptDir%\defaults.ini, %A_ScriptDir%\config.ini
}

RemoveConfig()
{
    FileDelete, %A_ScriptDir%\config.ini
}

CreateDefaultConfig()
{
    WriteConfig(A_ScriptDir . "\data\defaults.ini")
}

GetContributors(AuthorsPerLine=0) 
{
    IfNotExist, %A_ScriptDir%\AUTHORS.txt
    {
        return "`r`n AUTHORS.txt missing `r`n"
    }
    Authors := "`r`n"
    i := 0
    Loop, Read, %A_ScriptDir%\AUTHORS.txt, `r, `n
    {
        Authors := Authors . A_LoopReadLine . " "
        i += 1
        if (AuthorsPerLine != 0 and mod(i, AuthorsPerLine) == 0) ; every four authors
        {
            Authors := Authors . "`r`n"
        }
    }
    return Authors
}