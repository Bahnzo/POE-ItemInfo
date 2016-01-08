; ########### TIMERS ############

; Tick every 100 ms
; Remove tooltip if mouse is moved or 5 seconds pass
ToolTipTimer:
    Global Opts, ToolTipTimeout
    ToolTipTimeout += 1
    MouseGetPos, CurrX, CurrY
    MouseMoved := (CurrX - X) ** 2 + (CurrY - Y) ** 2 > Opts.MouseMoveThreshold ** 2
    If (MouseMoved or ((UseTooltipTimeout == 1) and (ToolTipTimeout >= Opts.ToolTipTimeoutTicks)))
    {
        SetTimer, ToolTipTimer, Off
        ToolTip
    }
    return

OnClipBoardChange:
    Global Opts
    If (Opts.OnlyActiveIfPOEIsFront)
    {
        ; do nothing if Path of Exile isn't the foremost window
        IfWinActive, Path of Exile ahk_class Direct3DWindowClass
        {
            ParseClipBoardChanges()
        }
    }
    Else
    {
        ; if running tests parse clipboard regardless if PoE is foremost
        ; so we can check individual cases from test case text files
        ParseClipBoardChanges()
    }
    return

ShowSettingsUI:
    ReadConfig()
    Sleep, 50
    UpdateSettingsUI()
    Sleep, 50
    ShowSettingsUI()
    return
    
SettingsUI_BtnOK:
    Global Opts
    Gui, Submit
    Sleep, 50
    WriteConfig()
    UpdateSettingsUI()
    Fonts.SetFixedFont(GuiGet("FontSize", Opts.FontSize))
    return

SettingsUI_BtnCancel:
    Gui, Cancel
    return

SettingsUI_BtnDefaults:
    Gui, Cancel
    RemoveConfig()
    Sleep, 75
    CopyDefaultConfig()
    Sleep, 75
    ReadConfig()
    Sleep, 75
    UpdateSettingsUI()
    ShowSettingsUI()
    return
    
SettingsUI_ChkShowGemEvaluation:
    GuiControlGet, IsChecked,, ShowGemEvaluation
    If (Not IsChecked) 
    {
        GuiControl, Disable, LblGemQualityThreshold
        GuiControl, Disable, GemQualityValueThreshold
    }
    Else
    {
        GuiControl, Enable, LblGemQualityThreshold
        GuiControl, Enable, GemQualityValueThreshold
    }
    return
    
SettingsUI_ChkShowAffixDetails:
    GuiControlGet, IsChecked,, ShowAffixDetails
    If (Not IsChecked) 
    {
        GuiControl, Disable, MirrorAffixLines
    }
    Else
    {
        GuiControl, Enable, MirrorAffixLines
    }
    return

SettingsUI_ChkShowAffixMaxPossible:
    GuiControlGet, IsChecked,, ShowAffixMaxPossible
    If (Not IsChecked) 
    {
        GuiControl, Disable, MaxSpanStartingFromFirst
    }
    Else
    {
        GuiControl, Enable, MaxSpanStartingFromFirst
    }
    return
    
SettingsUI_ChkShowAffixBracketTier:
    GuiControlGet, IsChecked,, ShowAffixBracketTier
    If (Not IsChecked) 
    {
        GuiControl, Disable, TierRelativeToItemLevel
        GuiControl, Disable, ShowAffixBracketTierTotal
    }
    Else
    {
        GuiControl, Enable, TierRelativeToItemLevel
        GuiControl, Enable, ShowAffixBracketTierTotal
    }
    return
    
SettingsUI_ChkUseTooltipTimeout:
    GuiControlGet, IsChecked,, UseTooltipTimeout
    If (Not IsChecked) 
    {
        GuiControl, Disable, LblToolTipTimeoutTicks
        GuiControl, Disable, ToolTipTimeoutTicks
    }
    Else
    {
        GuiControl, Enable, LblToolTipTimeoutTicks
        GuiControl, Enable, ToolTipTimeoutTicks
    }
    return
    
SettingsUI_ChkDisplayToolTipAtFixedCoords:
    GuiControlGet, IsChecked,, DisplayToolTipAtFixedCoords
    If (Not IsChecked) 
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
    return

MenuTray_About:
    IfNotEqual, FirstTimeA, No
  {
        Authors := GetContributors(0)
        RelVer := Globals.get("ReleaseVersion")
    Gui, 2:+owner1 -Caption +Border
    Gui, 2:Font, S10 CA03410,verdana
    Gui, 2:Add, Text, x260 y27 w170 h20 Center, Release %RelVer%
    Gui, 2:Add, Button, 0x8000 x316 y300 w70 h21, Close
    Gui, 2:Add, Picture, 0x1000 x17 y16 w230 h180 gAboutDlg_Fishing, %A_ScriptDir%\data\splash.png
    Gui, 2:Font, Underline C3571AC,verdana
    Gui, 2:Add, Text, x260 y57 w170 h20 gVisitForumsThread Center, PoE forums thread
    Gui, 2:Add, Text, x260 y87 w170 h20 gAboutDlg_AhkHome Center, AutoHotkey homepage
    Gui, 2:Add, Text, x260 y117 w170 h20 gAboutDlg_GitHub Center, PoE-Item-Info GitHub
    Gui, 2:Font, S7 CDefault normal, Verdana
    Gui, 2:Add, Text, x16 y207 w410 h80,
    (LTrim
        Shows affix breakdowns and other useful infos for any item or item link.
        
        Usage: Set PoE to Windowed Fullscreen mode and hover over any item or item link. Press Ctrl+C to show a tooltip.
        
        (c) %A_YYYY% Hazydoc, Nipper4369 and contributors:
        )
    Gui, 2:Add, Text, x16 y277 w270 h80, %Authors%
        
    FirstTimeA = No
  }
  
  Gui, 2:Show, h340 w435, About..
  
  ; Release counter animation
  tmpH = 0
  Loop, 20
  {
    tmpH += 1
    ControlMove, Static1,,,, %tmpH%, About..
    Sleep, 100
  }
    return

AboutDlg_Fishing:
    ; See, GGG Chris, I have your best interests at heart. Hire me! :)
    MsgBox, 32, Did You Know?, Fishing is reel!
    return
    
AboutDlg_AhkHome:
  Run, http://ahkscript.org
    return

AboutDlg_GitHub:
    Run, http://github.com/Bahnzo/POE-ItemInfo
    return 
    
VisitForumsThread:
    Run, http://www.pathofexile.com/forum/view-thread/1463814
    return

2ButtonClose:
2GuiClose:
  WinGet, AbtWndID, ID, About..
  DllCall("AnimateWindow", "Int", AbtWndID, "Int", 500, "Int", 0x00090010)
  WinActivate, ahk_id %MainWndID%
    return

EditValuableUniques:
    OpenCreateDataTextFile("ValuableUniques.txt")
    return

EditValuableGems:
    OpenCreateDataTextFile("ValuableGems.txt")
    return
    
EditCurrencyRates:
    OpenCreateDataTextFile("CurrencyRates.txt")
    return
    
EditDropOnlyGems:
    OpenCreateDataTextFile("DropOnlyGems.txt")
    return

3GuiClose:
    Gui, 3:Cancel
    return

UnhandledDlg_ShowItemText:
    Run, Notepad.exe
    WinActivate
    Send, ^v
    return
    
UnhandledDlg_OK:
    Gui, 3:Submit
    return