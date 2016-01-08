class UserOptions {

    OnlyActiveIfPOEIsFront := 1     ; Set to 1 to make it so the script does nothing if Path of Exile window isn't the frontmost.
                                    ; If 0, the script also works if PoE isn't frontmost. This is handy for have the script parse
                                    ; textual item representations appearing somewhere else, like in the forums or text files. 

    ShowItemLevel := 1              ; Show item level and the item type's base level (enabled by default change to 0 to disable)
    ShowMaxSockets := 1             ; Show the max sockets based on ilvl and type
    ShowDamageCalculations := 1     ; Show damage projections (for weapons only)

    ShowAffixTotals := 1            ; Show total affix statistics
    ShowAffixDetails := 1           ; Show detailed info about affixes
    ShowAffixLevel := 0             ; Show item level of the affix 
    ShowAffixBracket := 1           ; Show range for the affix' bracket as is on the item
    ShowAffixMaxPossible := 1       ; Show max possible bracket for an affix based on the item's item level
    ShowAffixBracketTier := 1       ; Show a T# indicator of the tier the affix bracket is in. 
                                    ; T1 being the highest possible, T2 second-to-highest and so on
                                    
    ShowAffixBracketTierTotal := 1  ; Appends the total number of tiers for a given affix in parentheses T/#Total
                                    ; T4/8 would represent the fourth highest tier, in eight total tiers.
                  
  ShowDarkShrineInfo := 0     ; Appends info about DarkShrine effects of affixes to rares

    TierRelativeToItemLevel := 0    ; When determining the affix bracket tier, take item level into consideration.
                                    ; However, this also means that the lower the item level the less the diversity
                                    ; of possible affix tiers since there aren't as many possibilities. This will 
                                    ; give the illusion that a low level item might be really, really good when it 
                                    ; has all T1 but in reality it can only have T1 since it's item level is so low
                                    ; it can only ever take the first bracket. 
                                    ; 
                                    ; If this option is set to 0, the tiers will always display relative to the full
                                    ; range of tiers available, ignoring the item level.

    ShowCurrencyValueInChaos := 1   ; Convert the value of currency items into chaos orbs. 
                                    ; This is based on the rates defined in <datadir>\CurrencyRates.txt
                                    ; You should edit this file with the current currency rates.

    ShowUniqueEvaluation := 1       ; Display reminder when a unique is valuable. 
                                    ; This is based on <datadir>\ValuableUniques.txt
                                    ; You can edit this file to suit your own needs.

    ShowGemEvaluation := 1          ; Display reminder when a gem is valuable and/or drop only. 
                                    ; This is based on <datadir>\ValuableGems.txt and <datadir>\DropOnlyGems.txt
                                    ; You can edit these files to suit your own needs.

    GemQualityValueThreshold := 10  ; If the gem's added quality exceeds this value, consider it valuable regardless of which gem it is.

    MaxSpanStartingFromFirst := 1   ; When showing max possible, don't just show the highest possible affix bracket 
                                    ; but construct a pseudo range which spans the lower bound of the lowest possible 
                                    ; bracket to the upper bound of the highest possible one. 
                                    ;
                                    ; This is usually what you want to see when evaluating an item's worth. The exception 
                                    ; being when you want to reroll an affix to the highest possible value within it's
                                    ; current bracket - then you need to see the affix range that is actually on the item 
                                    ; right now.

    CompactDoubleRanges := 1        ; Show double ranges as "1-172" instead of "1-8 to 160-172"
    CompactAffixTypes := 1          ; Use compact affix type designations: Suffix = S, Prefix = P, Comp. Suffix = CS, Comp. Prefix = CP

    MarkHighLinksAsValuable := 1    ; Mark rares or uniques with 5L or 6L as valuable.

    MirrorAffixLines := 1           ; Show a copy of the affix line in question when showing affix details. 
                                    ;
                                    ; For example, would display "Prefix, 5-250" instead of "+246 to Accuracy Rating, Prefix, 5-250". 
                                    ; Since the affixes are processed in order one can attribute which is which to the ordering of 
                                    ; the lines in the tooltip to the item data in game.

    MirrorLineFieldWidth := 18      ; Mirrored affix line width. Set to a number above 0 to truncate (or pad) to this many characters. 
                                    ; Appends AffixDetailEllipsis when truncating.
    ValueRangeFieldWidth := 7       ; Width of field that displays the affix' value range(s). Set to a number larger than 0 to truncate (or pad) to this many characters. 
                                    ;
                                    ; Keep in mind that there are sometimes double ranges to be displayed. Like for example on an axe, implicit physical damage might
                                    ; have a lower bound range and a upper bound range. In this case the lower bound range can have at most a 3 digit minimum value,
                                    ; and at most a 3 digit maximum value. To then display just the lower bound (which constitutes one value range field), you would need
                                    ; at least 7 characters (ex: 132-179). To complete the example here is how it would look like with 2 fields (lower and upper bound)
                                    ; 132-179 168-189. Note that you don't need to set 15 as option value to display both fields correctly. As the name implies the option
                                    ; is per field, so a value of 8 can display two 8 character wide fields correctly.

    AffixDetailDelimiter := " "     ; Field delimiter for affix detail lines. This is put between value range fields. If this value were set to a comma, the above
                                    ; double range example would become 132-179,168-189.

    AffixDetailEllipsis := "…"      ; If the MirrorLineFieldWidth is set to a value that is smaller than the actual length of the affix line text
                                    ; the affix line will be cut off and this text will be appended at the end to indicate tha the line was truncated.
                                    ;
                                    ; Usually this is set to the ASCII or Unicode value of the three dot ellipsis (alt code: 0133).
                                    ; Note that the correct display of text characters outside the ASCII standard depend on the file encoding and the 
                                    ; AHK version used. For best results, save this file as ANSI encoding which can be read and displayed correctly by
                                    ; either ANSI based AutoHotkey or Unicode based AutoHotkey.
                                    ;
                                    ; Example: assume the affix line to be mirrored is '+#% increased Spell Damage'.
                                    ; If the MirrorLineFieldWidth is set to 18, this field would be shown as '+#% increased Spel…'

    PutResultsOnClipboard := 0      ; Put result text on clipboard (overwriting the textual representation the game put there to begin with)

    ; Pixels mouse must move to auto-dismiss tooltip
    MouseMoveThreshold := 40

    ; Set this to 1 if you want to have the tooltip disappear after the time frame set below.
    ; Otherwise you will have to move the mouse by 5 pixels for the tip to disappear.
    UseTooltipTimeout := 0

    ;How many ticks to wait before removing tooltip. 1 tick = 100ms. Example, 50 ticks = 5secends, 75 Ticks = 7.5Secends
    ToolTipTimeoutTicks := 150

    ; Font size for the tooltip, leave empty for default
    FontSize := 11

    ; Displays the tooltip in virtual screen space at fixed coordinates.
    ; Virtual screen space means the complete desktop frame, including any secondary monitors.
    DisplayToolTipAtFixedCoords := 0
    
    ; Coordinates relative to top left corner, increasing by going down and to the right.
    ; Only used if DisplayToolTipAtFixedCoords is 1.
    ScreenOffsetX := 0
    ScreenOffsetY := 0

    ScanUI()
    {
        this.OnlyActiveIfPOEIsFront := GuiGet("OnlyActiveIfPOEIsFront") 
        this.ShowItemLevel := GuiGet("ShowItemLevel") 
        this.ShowMaxSockets := GuiGet("ShowMaxSockets") 
        this.ShowDamageCalculations := GuiGet("ShowDamageCalculations") 
        this.ShowAffixTotals := GuiGet("ShowAffixTotals") 
        this.ShowAffixDetails := GuiGet("ShowAffixDetails") 
        this.ShowAffixLevel := GuiGet("ShowAffixLevel") 
        this.ShowAffixBracket := GuiGet("ShowAffixBracket") 
        this.ShowAffixMaxPossible := GuiGet("ShowAffixMaxPossible") 
        this.ShowAffixBracketTier := GuiGet("ShowAffixBracketTier") 
        this.ShowAffixBracketTierTotal := GuiGet("ShowAffixBracketTierTotal") 
        this.TierRelativeToItemLevel := GuiGet("TierRelativeToItemLevel")
        this.ShowDarkShrineInfo := GuiGet("ShowDarkShrineInfo")
        this.ShowCurrencyValueInChaos := GuiGet("ShowCurrencyValueInChaos")
        this.DisplayToolTipAtFixedCoords := GuiGet("DisplayToolTipAtFixedCoords")
        this.ScreenOffsetX := GuiGet("ScreenOffsetX")
        this.ScreenOffsetY := GuiGet("ScreenOffsetY")
        this.ShowUniqueEvaluation := GuiGet("ShowUniqueEvaluation") 
        this.ShowGemEvaluation := GuiGet("ShowGemEvaluation") 
        this.GemQualityValueThreshold := GuiGet("GemQualityValueThreshold") 
        this.MaxSpanStartingFromFirst := GuiGet("MaxSpanStartingFromFirst") 
        this.CompactDoubleRanges := GuiGet("CompactDoubleRanges") 
        this.CompactAffixTypes := GuiGet("CompactAffixTypes") 
        this.MarkHighLinksAsValuable := GuiGet("MarkHighLinksAsValuable") 
        this.MirrorAffixLines := GuiGet("MirrorAffixLines") 
        this.MirrorLineFieldWidth := GuiGet("MirrorLineFieldWidth") 
        this.ValueRangeFieldWidth := GuiGet("ValueRangeFieldWidth") 
        this.AffixDetailDelimiter := GuiGet("AffixDetailDelimiter")
        this.AffixDetailEllipsis := GuiGet("AffixDetailEllipsis") 
        this.PutResultsOnClipboard := GuiGet("PutResultsOnClipboard")  
        this.MouseMoveThreshold := GuiGet("MouseMoveThreshold") 
        this.UseTooltipTimeout := GuiGet("UseTooltipTimeout") 
        this.ToolTipTimeoutTicks := GuiGet("ToolTipTimeoutTicks") 
        this.FontSize := GuiGet("FontSize")
    }
}
Opts := new UserOptions()
