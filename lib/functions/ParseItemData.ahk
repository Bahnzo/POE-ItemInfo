; ########### MAIN PARSE FUNCTION ##############

; Invocation stack (simplified) for full item parse:
;
;   (timer watches clipboard contents)
;   (on clipboard changed) ->
;
;   ParseClipBoardChanges() 
;       PreProcessContents()
;       ParseItemData()
;           (get item details by calling many other Parse... functions)
;           ParseAffixes()
;               (on affix match found) ->
;                   LookupAffixData()
;                       AssembleValueRangeFields()
;                   LookupAffixBracket()
;                   LookupRemainingAffixBracket()
;                   AppendAffixInfo(MakeAffixDetailLine()) ; appends to global AffixLines table
;           (is Weapon) ->
;               AssembleDamageDetails()
;           AssembleAffixDetails() ; uses global AffixLines table
;       PostProcessData()
;       ShowToolTip()
;
ParseItemData(ItemDataText, ByRef RarityLevel="")
{    
    Global Item, ItemData, AffixTotals, uniqueMapList, mapList, matchList

    ItemDataPartsIndexLast = 
    ItemDataPartsIndexAffixes = 
    ItemDataPartsLast = 
    ItemDataNamePlate =
    ItemDataStats =
    ItemDataAffixes = 
    ItemDataRequirements =
    ItemDataRarity =
    ItemDataLinks =
    ItemName =
    ItemTypeName =
    ItemQuality =
    ItemLevel =
    ItemMaxSockets =
    ItemBaseType =
    ItemSubType =
    ItemGripType =
    BaseLevel =
    RarityLevel =  
    TempResult =

    Item.IsWeapon := False
    Item.IsQuiver := False
    Item.IsFlask := False
    Item.IsGem := False
    Item.IsCurrency := False
    Item.IsUnidentified := False
    Item.IsBelt := False
    Item.IsRing := False
    Item.IsUnsetRing := False
    Item.IsBow := False
    Item.IsAmulet := False
    Item.IsSingleSocket := False
    Item.IsFourSocket := False   
    Item.IsThreeSocket := False
    Item.IsMap := False
    Item.IsJewel := False
    Item.IsUnique := False
    Item.IsRare := False
    Item.IsCorrupted := False
    Item.IsMirrored := False
    Item.HasEffect := False
    
    ResetAffixDetailVars()
    
    ItemData.FullText := ItemDataText

    IfInString, ItemDataText, Corrupted
    {
        Item.IsCorrupted := True
    }
    
    ; AHK only allows splitting on single chars, so first 
    ; replace the split string (\r\n--------\r\n) with AHK's escape char (`)
    ; then do the actual string splitting...
    StringReplace, TempResult, ItemDataText, `r`n--------`r`n, ``, All
    StringSplit, ItemDataParts, TempResult, ``,

    ItemData.NamePlate := ItemDataParts1
    ItemData.Stats := ItemDataParts2
    
    ItemDataIndexLast := ItemDataParts0
    ItemDataPartsLast := ItemDataParts%ItemDataIndexLast%
    ItemData.ClearParts()
    Loop, %ItemDataParts0%
    {
        ItemData.Parts[A_Index] := ItemDataParts%A_Index%
    }
    ItemData.PartsLast := ItemDataPartsLast
    ItemData.IndexLast := ItemDataIndexLast
    
    ; ItemData.Requirements := GetItemDataChunk(ItemDataText, "Requirements:")
    ; ParseRequirements(ItemData.Requirements, RequiredLevel, RequiredAttributes, RequiredAttributeValues)

    ParseItemName(ItemData.NamePlate, ItemName, ItemTypeName)
    If (Not ItemName) 
    {
        return
    }
    Item.Name := ItemName
    Item.TypeName := ItemTypeName

    IfInString, ItemDataText, Unidentified
    {
        If (Item.Name != "Scroll of Wisdom")
        {
            Item.IsUnidentified := True
        }
    }

    Item.Quality := ParseQuality(ItemData.Stats)
    
    ; This function should return the second part of the "Rarity: ..." line
    ; in the case of "Rarity: Unique" it should return "Unique"
    ItemData.Rarity := ParseRarity(ItemData.NamePlate)

    ItemData.Links := ParseLinks(ItemDataText)

    Item.IsUnique := False
    If (InStr(ItemData.Rarity, "Unique"))
    {
        Item.IsUnique := True
    }

    If (InStr(ItemData.Rarity, "Rare"))
    {
        Item.IsRare := True
    }

    Item.IsGem := (InStr(ItemData.Rarity, "Gem")) 
    Item.IsCurrency := (InStr(ItemData.Rarity, "Currency"))
    
    If (Not (InStr(ItemDataText, "Itemlevel:") or InStr(ItemDataText, "Item Level:")) and Not Item.IsGem and Not Item.IsCurrency)
    {
        return Item.Name
    }
    
    If (Item.IsGem)
    {
        RarityLevel := 0
        Item.Level := ParseGemLevel(ItemDataText, "Level:")
        ItemLevelWord := "Gem Level:"
        Item.BaseType := "Jewelry"
    }
    Else
    {
      
        If (Item.IsCurrency and Opts.ShowCurrencyValueInChaos == 1)
        {
            ValueInChaos := ConvertCurrency(Item.Name, ItemData.Stats)
            If (ValueInChaos)
            {
                CurrencyDetails := ValueInChaos . " Chaos"
            }
        }
        Else If (Not Item.IsCurrency)
        {
            RarityLevel := CheckRarityLevel(ItemData.Rarity)
            Item.Level := ParseItemLevel(ItemDataText)
            ItemLevelWord := "Item Level:"
            ParseItemType(ItemData.Stats, ItemData.NamePlate, ItemBaseType, ItemSubType, ItemGripType)
            Item.BaseType := ItemBaseType
            Item.SubType := ItemSubType
            Item.GripType := ItemGripType
        }
    }
    
    Item.RarityLevel := RarityLevel

    Item.IsBow := (Item.SubType == "Bow")
    Item.IsFlask := (Item.SubType == "Flask")
    Item.IsBelt := (Item.SubType == "Belt")
    Item.IsRing := (Item.SubType == "Ring")
    Item.IsUnsetRing := (Item.IsRing and InStr(ItemData.NamePlate, "Unset Ring"))
    Item.IsAmulet := (Item.SubType == "Amulet")
    Item.IsTalisman := (Item.IsAmulet and InStr(ItemData.NamePlate, "Talisman") and !InStr(ItemData.NamePlate, "Amulet"))
    Item.IsSingleSocket := (IsUnsetRing)
    Item.IsFourSocket := (Item.SubType == "Gloves" or Item.SubType == "Boots" or Item.SubType == "Helmet")
    Item.IsThreeSocket := ((Item.GripType == "1H" or Item.SubType == "Shield") and Not Item.IsBow)
    Item.IsQuiver := (Item.SubType == "Quiver")
    Item.IsWeapon := (Item.BaseType == "Weapon")
    Item.IsMap := (Item.BaseType == "Map")
    Item.IsJewel := (Item.BaseType == "Jewel")
    Item.IsMirrored := (ItemIsMirrored(ItemDataText) and Not Item.IsCurrency)
    Item.HasEffect := (InStr(ItemData.PartsLast, "Has"))
    
    If Item.IsTalisman {
        Loop, Read, %A_ScriptDir%\data\TalismanTiers.txt 
        {  
            ; This loop retrieves each line from the file, one at a time.
            StringSplit, TalismanData, A_LoopReadLine, |,
            If InStr(ItemData.NamePlate, TalismanData1) {
                Item.TalismanTier := TalismanData2
            }
        }
    }
    
    ItemDataIndexAffixes := ItemData.IndexLast - GetNegativeAffixOffset(Item)
    If (ItemDataIndexAffixes <= 0)
    {
        ; ItemDataParts doesn't have the parts/text we need. Bail. 
        ; This might be because the clipboard is completely empty.
        return 
    }
    ItemData.Affixes := ItemDataParts%ItemDataIndexAffixes%
    ItemData.IndexAffixes := ItemDataIndexAffixes
    
    ItemData.Stats := ItemDataParts2

    If (Item.IsFlask) 
    {
        ParseFlaskAffixes(ItemData.Affixes)
    }
    Else If (RarityLevel > 1 and RarityLevel < 4)
    {
        ParseAffixes(ItemData.Affixes, Item)
    }
    NumPrefixes := AffixTotals.NumPrefixes
    NumSuffixes := AffixTotals.NumSuffixes
    TotalAffixes := NumPrefixes + NumSuffixes
    AffixTotals.NumTotals := TotalAffixes

    ; Start assembling the text for the tooltip
    TT := Item.Name 
    If (Item.TypeName)
    {
        TT := TT . "`n" . Item.TypeName 
    }
    
    If (Item.IsCurrency)
    {
        TT := TT . "`n" . CurrencyDetails
        Goto, ParseItemDataEnd
    }

    If (Opts.ShowItemLevel == 1 and Not (Item.IsMap or Item.IsCurrency))
    {
        TT := TT . "`n"
        TT := TT . ItemLevelWord . "   " . StrPad(Item.Level, 3, Side="left")
        
        If Item.IsTalisman {
            TT := TT . "`nTalisman Tier: " . StrPad(Item.TalismanTier, 2, Side="left")
        }
        If (Not Item.IsFlask)
        {
            ;;Item.BaseLevel := CheckBaseLevel(Item.TypeName)
      
      ;;Hixxie: fixed! Shows base level for any item rarity, rings/jewelry, etc
      If(Item.RarityLevel < 3)
      {
        Item.BaseLevel := CheckBaseLevel(Item.Name)
      }
      else if (Item.IsUnidentified)
      {
        Item.BaseLevel := CheckBaseLevel(Item.Name)
      }
      Else
      {
        Item.BaseLevel := CheckBaseLevel(Item.TypeName)
      }
      
            If (Item.BaseLevel)
            {
                TT := TT . "`n" . "Base Level:   " . StrPad(Item.BaseLevel, 3, Side="left")
            }
        }
    }
    
    If (Opts.ShowMaxSockets == 1 and Not (Item.IsFlask or Item.IsGem or Item.IsCurrency or Item.IsBelt or Item.IsQuiver or Item.IsMap or Item.IsJewel or Item.IsAmulet))
    {
        If (Item.Level >= 50)
        {
            Item.MaxSockets := 6
        }
        Else If (Item.Level >= 35)
        {
            Item.MaxSockets := 5
        }
        Else If (Item.Level >= 25)
        {
            Item.MaxSockets := 4
        }
        Else If (Item.Level >= 1)
        {
            Item.MaxSockets := 3
        }
        Else
        {
            Item.MaxSockets := 2
        }
        
        If(Item.IsFourSocket and Item.MaxSockets > 4)
        {
            Item.MaxSockets := 4
        }
        Else If(Item.IsThreeSocket and Item.MaxSockets > 3)
        {
            Item.MaxSockets := 3
        }
        Else If(Item.IsSingleSocket)
        {
            Item.MaxSockets := 1
        }

        If (Not Item.IsRing or Item.IsUnsetRing)
        {
            TT := TT . "`n"
            TT := TT . "Max Sockets:    "
            TT := TT . Item.MaxSockets
        }
    }
    
    If (Opts.ShowGemEvaluation == 1 and Item.IsGem)
    {
        SepAdded := False
        If (Item.Quality > 0)
        {
            TT = %TT%`n--------
            SepAdded := True
            TT := TT . "`n" . "+" . Item.Quality . "`%"
        }
        If (Item.Quality >= Opts.GemQualityValueThreshold or GemIsValuable(Item.Name))
        {
            If (Not SepAdded)
            {
                TT = %TT%`n--------
                SepAdded := True
            }
            TT = %TT%`nValuable
        }
        If (GemIsDropOnly(Item.Name))
        {
            If (Not SepAdded)
            {
                TT = %TT%`n--------
                SepAdded := True
            }
            TT = %TT%`nDrop Only
        }
    }

    If (Opts.ShowDamageCalculations == 1 and Item.IsWeapon)
    {
        TT := TT . AssembleDamageDetails(ItemDataText)
    }
 
    If (Item.IsMap)
    {
    Item.MapLevel := ParseMapLevel(ItemDataText)
      
    ;;hixxie fixed
    MapLevelText := Item.MapLevel
    TT = %TT%`nMap Level: %MapLevelText%
    
        If (Item.IsUnique)
        {
            MapDescription := uniqueMapList[Item.SubType]
        }
        Else
        {
            MapDescription := mapList[Item.SubType]
        }

        TT = %TT%`n%MapDescription%
    }
    
    If (RarityLevel > 1 and RarityLevel < 4) 
    {
        ; Append affix info if rarity is greater than normal (white)
        ; Affix total statistic
        If (Opts.ShowAffixTotals = 1)
        {
            If (NumPrefixes = 1) 
            {
                WordPrefixes = Prefix
            }
            Else
            {
                WordPrefixes = Prefixes
            }
            If (NumSuffixes = 1) 
            {
                WordSuffixes = Suffix
            }
            Else
            {
                WordSuffixes = Suffixes
            }

            PrefixLine = 
            If (NumPrefixes > 0) 
            {
                PrefixLine = `n   %NumPrefixes% %WordPrefixes%
            }

            SuffixLine =
            If (NumSuffixes > 0)
            {
                SuffixLine = `n   %NumSuffixes% %WordSuffixes%
            }

            AffixStats =
            If (TotalAffixes > 0 and Not Item.IsUnidentified)
            {
                AffixStats = Affixes (%TotalAffixes%):%PrefixLine%%SuffixLine%
                TT = %TT%`n--------`n%AffixStats%
            }
        }
        
        ; Detailed affix range infos
        If (Opts.ShowAffixDetails == 1)
        {
            If (Not Item.IsFlask and Not Item.IsUnidentified and Not Item.IsMap)
            {
                AffixDetails := AssembleAffixDetails()
                TT = %TT%`n--------%AffixDetails%
           }
        }
    }
    Else If (ItemData.Rarity == "Unique")
    {
        If (FindUnique(Item.Name) == False and Not Item.IsUnidentified)
        {
            TT = %TT%`n--------`nUnique item currently not supported
        }
        Else If (Opts.ShowAffixDetails == True and Not Item.IsUnidentified)
        {
            ParseUnique(Item.Name)
            AffixDetails := AssembleAffixDetails()
            TT = %TT%`n--------%AffixDetails%
        }
    }
    
    If (Item.IsUnidentified and (Item.Name != "Scroll of Wisdom") and Not Item.IsMap)
    {
        TT = %TT%`n--------`nUnidentified
    }

    If ((Item.IsUnique and (Opts.ShowUniqueEvaluation == 1) and UniqueIsValuable(Item.Name)) or (Opts.MarkHighLinksAsValuable == 1 and (Item.IsUnique or Item.IsRare) and ItemData.Links >= 5))
    {
        TT = %TT%`n--------`nValuable
    }

    If (Item.IsMirrored)
    {
        TT = %TT%`n--------`nMirrored
    }
    
    If (Opts.ShowDarkShrineInfo == 1 and (RarityLevel == 3 or RarityLevel == 2))
    {
        TT = %TT%`n--------`nPossible DarkShrine effects:
        
        DarkShrineInfo := AssembleDarkShrineInfo()
        TT = %TT%%DarkShrineInfo%
    }
    
    return TT
    
    ParseItemDataEnd:
        return TT
}