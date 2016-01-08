ParseAffixes(ItemDataAffixes, Item)
{
    Global Globals, Opts, AffixTotals, AffixLines

    ItemDataChunk := ItemDataAffixes

    ItemBaseType := Item.BaseType
    ItemSubType := Item.SubType
    ItemGripType := Item.GripType
    ItemLevel := Item.Level
    ItemQuality := Item.Quality
    
     ; Reset the AffixLines "array" and other vars
    ResetAffixDetailVars()

    ; Keeps track of how many affix lines we have so they can be assembled later.
    ; Acts as a loop index variable when iterating each affix data part.
    NumPrefixes := 0
    NumSuffixes := 0
    
    ; Composition flags
    ;
    ; These are required for descision making later, when guesstimating
    ; sources for parts of a value from composite and/or same name affixes.
    ; They will be set to the line number where they occur in the pre-pass
    ; loop, so that details for that line can be changed later after we
    ; have more clues for possible compositions.
    HasIIQ := 0
    HasIncrArmour := 0
    HasIncrEvasion := 0
    HasIncrEnergyShield := 0
    HasHybridDefences := 0
    HasIncrArmourAndES := 0
    HasIncrArmourAndEvasion := 0
    HasIncrEvasionAndES := 0
    HasIncrLightRadius := 0
    HasIncrAccuracyRating := 0
    HasIncrPhysDmg := 0
    HasToAccuracyRating := 0
    HasStunRecovery := 0
    HasSpellDamage := 0
    HasMaxMana := 0
    HasMultipleCrafted := 0

    ; The following values are used for new style complex affix support
    CAIncAccuracy := 0
    CAIncAccuracyAffixLine := ""
    CAIncAccuracyAffixLineNo := 0
    CAGlobalCritChance := 0
    CAGlobalCritChanceAffixLine := ""
    CAGlobalCritChanceAffixLineNo := 0
    
    ; Max mana already accounted for in case of Composite Prefix+Prefix 
    ; "Spell Damage / Max Mana" + "Max Mana"
    MaxManaPartial =

    ; Accuracy Rating already accounted for in case of 
    ;   Composite Prefix + Composite Suffix: 
    ;       "increased Physical Damage / to Accuracy Rating" +
    ;       "to Accuracy Rating / Light Radius"
    ;   Composite Prefix + Suffix: 
    ;       "increased Physical Damage / to Accuracy Rating" + 
    ;       "to Accuracy Rating"
    ARPartial =
    ARAffixTypePartial =

    ; Partial for the former "Block and Stun Recovery"
    ; Note: with PoE v1.3+ now called just "increased Stun Recovery"
    BSRecPartial =

    ; --- PRE-PASS ---
    
    ; To determine composition flags
    Loop, Parse, ItemDataChunk, `n, `r
    {    
        If StrLen(A_LoopField) = 0
        {
            Break ; Not interested in blank lines
        }
        IfInString, ItemDataChunk, Unidentified
        {
            Break ; Not interested in unidentified items
        }
                
        IfInString, A_LoopField, increased Light Radius
        {
            HasIncrLightRadius := A_Index
            Continue
        }
        IfInString, A_LoopField, increased Quantity
        {
            HasIIQ := A_Index
            Continue
        }
        IfInString, A_LoopField, increased Physical Damage
        {
            HasIncrPhysDmg := A_Index
            Continue
        }
        IfInString, A_LoopField, increased Accuracy Rating
        {
            HasIncrAccuracyRating := A_Index
            Continue
        }
        IfInString, A_LoopField, to Accuracy Rating
        {
            HasToAccuracyRating := A_Index
            Continue
        }
        IfInString, A_LoopField, increased Armour and Evasion
        {
            HasHybridDefences := A_Index
            HasIncrArmourAndEvasion := A_Index
            Continue
        }
        IfInString, A_LoopField, increased Armour and Energy Shield
        {
            HasHybridDefences := A_Index
            HasIncrArmourAndES := A_Index
            Continue
        }
        IfInString, A_LoopField, increased Evasion and Energy Shield
        {
            HasHybridDefences := A_Index
            HasIncrEvasionAndES := A_Index
            Continue
        }
        IfInString, A_LoopField, increased Armour
        {
            HasIncrArmour := A_Index
            Continue
        }
        IfInString, A_LoopField, increased Evasion Rating
        {
            HasIncrEvasion := A_Index
            Continue
        }
        IfInString, A_LoopField, increased Energy Shield
        {
            HasIncrEnergyShield := A_Index
            Continue
        }
        IfInString, A_LoopField, increased Stun Recovery
        {
            HasStunRecovery := A_Index
            Continue
        }
        IfInString, A_LoopField, increased Spell Damage
        {
            HasSpellDamage := A_Index
            Continue
        }
        IfInString, A_LoopField, to maximum Mana
        {
            HasMaxMana := A_Index
            Continue
        }
        IfInString, A_Loopfield, Can have multiple Crafted Mods
        {
            HasMultipleCrafted := A_Index
            Continue
        }
    }

    ; Note: yes, these superlong IfInString structures suck, but hey, 
    ; AHK sucks as an object-oriented scripting language, so bite me.
    ;
    ; But in all seriousness, there are two main parts - Simple and 
    ; Complex Affixes - which could be refactored into their own helper
    ; methods.
    
    ; --- SIMPLE AFFIXES ---

    Loop, Parse, ItemDataChunk, `n, `r
    {
        If StrLen(A_LoopField) = 0
        {
            Break ; Not interested in blank lines
        }
        IfInString, ItemDataChunk, Unidentified
        {
            Break ; Not interested in unidentified items
        }
        
        CurrValue := GetActualValue(A_LoopField)
        CurrTier := 0
        BracketLevel := 0

        ; Suffixes (due to new affixes on Jewels the split between suffixes and prefixes isn't 100% anymore)

        IfInString, A_LoopField, increased Area Damage
        {
            ; Only valid for Jewels at this time
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\AreaDamage.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Attack and Cast Speed
        {
            ; Only valid for Jewels at this time
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\AttackAndCastSpeed.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure increased attack speed
        IfInString, A_LoopField, increased Attack Speed with One Handed Melee Weapons
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\AttackSpeed_Melee1H.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure increased attack speed
        IfInString, A_LoopField, increased Attack Speed with Two Handed Melee Weapons
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\AttackSpeedWithMelee2H.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure increased attack speed
        IfInString, A_LoopField, increased Attack Speed while holding a Shield
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\AttackSpeedHoldingShield.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure increased attack speed
        IfInString, A_LoopField, increased Attack Speed while Dual Wielding
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\AttackSpeedDualWielding.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure increased attack speed
        IfInString, A_LoopField, increased Attack Speed with Bows
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\AttackSpeedWithBows.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure increased attack speed
        IfInString, A_LoopField, increased Attack Speed with Claws
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\AttackSpeedWithClaws.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure increased attack speed
        IfInString, A_LoopField, increased Attack Speed with Maces
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\AttackSpeed_Maces.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure increased attack speed
        IfInString, A_LoopField, increased Attack Speed with Staves
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\AttackSpeed_Staves.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure increased attack speed
        IfInString, A_LoopField, increased Attack Speed with Swords
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\AttackSpeedWithSwords.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure increased attack speed
        IfInString, A_LoopField, increased Attack Speed with Wands
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\AttackSpeedWithWands.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure increased attack speed
        IfInString, A_LoopField, increased Attack Speed with Axes
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\AttackSpeed_Axes.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Attack Speed
        {
            ; Slinkston edit. Cleaned up the code. I think this is a better approach.
            NumSuffixes += 1
            If (ItemSubType == "Wand" or ItemSubType == "Bow")
            {
                ValueRange := LookupAffixData("data\AttackSpeed_BowsAndWands.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else If (ItemBaseType == "Weapon")
            {
                ValueRange := LookupAffixData("data\AttackSpeed_Weapons.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else If (Item.IsJewel)
            {
                ValueRange := LookupAffixData("data\AttackSpeed_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else
            {
                ValueRange := LookupAffixData("data\AttackSpeed_ArmourAndItems.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Accuracy Rating
        {
            If (Item.SubType = "Cobalt Jewel" or Item.SubType = "Crimson Jewel" )
            {
                ; Cobalt and Crimson jewels can't get the combined increased accuracy/crit chance affix
                AffixType := "Suffix"
                ValueRange := LookupAffixData("data\IncrAccuracyRating_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else If (Item.SubType = "Viridian Jewel") {
                ; increased Accuracy Rating on viridian jewels is a complex affix and handled later
                CAIncAccuracy := CurrValue
                CAIncAccuracyAffixLine := A_LoopField
                CAIncAccuracyAffixLineNo := A_Index
                Continue
            } Else {
                AffixType := "Comp. Suffix"
                ValueRange := LookupAffixData("data\IncrAccuracyRating_LightRadius.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            NumSuffixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, to all Attributes 
        {
            NumSuffixes += 1
            If (Item.IsJewel) 
            {
                ValueRange := LookupAffixData("data\ToAllAttributes_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else 
            {
                ValueRange := LookupAffixData("data\ToAllAttributes.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to be handled before pure "to Strength"
        IfInString, A_LoopField, to Strength and Dexterity
        {
            ; Only valid for Jewels at this time
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ToStrengthAndDexterity.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to be handled before pure "to Strength"
        IfInString, A_LoopField, to Strength and Intelligence
        {
            ; Only valid for Jewels at this time
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ToStrengthAndIntelligence.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, to Strength
        {
            NumSuffixes += 1
            If (Item.IsJewel) {
                ValueRange := LookupAffixData("data\ToStrength_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else {
                ValueRange := LookupAffixData("data\ToStrength.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, to Intelligence
        {
            NumSuffixes += 1
            If (Item.IsJewel) {
                ValueRange := LookupAffixData("data\ToIntelligence_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else {
                ValueRange := LookupAffixData("data\ToIntelligence.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, to Dexterity and Intelligence
        {
            ; Only valid on Jewels at this time
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ToDexterityAndIntelligence.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, to Dexterity
        {
            NumSuffixes += 1
            If (Item.IsJewel) {
                ValueRange := LookupAffixData("data\ToDexterity_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else {
                ValueRange := LookupAffixData("data\ToDexterity.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure cast speed
        IfInString, A_LoopField, increased Cast Speed with Cold Skills
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\CastSpeedColdSkills.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure cast speed
        IfInString, A_LoopField, increased Cast Speed with Fire Skills
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\CastSpeedFireSkills.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure cast speed
        IfInString, A_LoopField, increased Cast Speed with Lightning Skills
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\CastSpeedLightningSkills.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure cast speed
        IfInString, A_LoopField, increased Cast Speed while Dual Wielding
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\CastSpeedWhileDualWielding.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure cast speed
        IfInString, A_LoopField, increased Cast Speed while holding a Shield
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\CastSpeedWhileHoldingShield.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure cast speed
        IfInString, A_LoopField, increased Cast Speed while wielding a Staff
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\CastSpeedWhileWieldingStaff.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Cast Speed
        {
            ; Slinkston edit
            If (ItemBaseType == "Weapon")
            {
                ValueRange := LookupAffixData("data\CastSpeedWeapon.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else If (Item.IsJewel) {
                ValueRange := LookupAffixData("data\CastSpeed_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else If (Item.IsAmulet) {
                ValueRange := LookupAffixData("data\CastSpeedAmulets.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else If (Item.IsRing) {
                ValueRange := LookupAffixData("data\CastSpeedRings.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else {
                ; After weapons, jewels, amulets and rings only shields are left. Which can receive a cast speed master mod.
                ; Leaving this as non shield specific if the master mod ever applicable on something else
                ValueRange := LookupAffixData("data\CastSpeed.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            NumSuffixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; This needs to come before "Critical Strike Chance" !
        IfInString, A_LoopField, increased Critical Strike Chance for Spells
        {
            NumSuffixes += 1
            If (Item.IsJewel)
            {
                ValueRange := LookupAffixData("data\SpellCritChance_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else
            {
                ValueRange := LookupAffixData("data\SpellCritChance.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; This needs to come before "Critical Strike Chance" !
        IfInString, A_LoopField, increased Melee Critical Strike Chance
        {
            ; Only valid for jewels at the moment
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\MeleeCritChance.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; This needs to come before "Critical Strike Chance" !
        IfInString, A_LoopField, increased Critical Strike Chance with Elemental Skills
        {
            ; Only valid for jewels at the moment
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\CritChanceElementalSkills.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Critical Strike Chance with Cold Skills
        {
            ; Only valid for jewels at the moment
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\CritChanceColdSkills.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Critical Strike Chance with Fire Skills
        {
            ; Only valid for jewels at the moment
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\CritChanceFireSkills.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Critical Strike Chance with Lightning Skills
        {
            ; Only valid for jewels at the moment
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\CritChanceLightningSkills.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before Critical Strike Chance
        IfInString, A_LoopField, increased Critical Strike Chance with One Handed Melee Weapons
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\CritChanceWithMelee1H.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Critical Strike Chance with Two Handed Melee Weapons
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\CritChanceWithMelee2H.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before Critical Strike Chance
        IfInString, A_LoopField, increased Weapon Critical Strike Chance while Dual Wielding
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\WeaponCritChanceDualWielding.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, Critical Strike Chance
        {
            ; Slinkston edit
            If (ItemBaseType == "Weapon")
            {
                ValueRange := LookupAffixData("data\CritChanceLocal.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else If (Item.SubType = "Cobalt Jewel" or Item.SubType = "Crimson Jewel" )
            {
                ; Cobalt and Crimson jewels can't get the combined increased accuracy/crit chance affix
                ValueRange := LookupAffixData("data\CritChanceGlobal_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else If (Item.SubType = "Viridian Jewel") {
                ; Crit chance on Viridian Jewels is a complex affix that is handled later
                CAGlobalCritChance := CurrValue
                CAGlobalCritChanceAffixLine := A_LoopField
                CAGlobalCritChanceAffixLineNo := A_Index
                Continue
            } Else {
                ValueRange := LookupAffixData("data\CritChanceGlobal.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            NumSuffixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; This needs to come before "Critical Strike Multiplier" !
        IfInString, A_LoopField, increased Melee Critical Strike Multiplier
        {
            ; Only valid for jewels at the moment
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\CritMeleeMultiplier.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; This needs to come before "Critical Strike Multiplier" !
        IfInString, A_LoopField, increased Critical Strike Multiplier for Spells
        {
            ; Only valid for jewels at the moment
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\CritMultiplierSpells.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; This needs to come before "Critical Strike Multiplier" !
        IfInString, A_LoopField, increased Critical Strike Multiplier with Elemental Skills
        {
            ; Only valid for jewels at the moment
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\CritMultiplierElementalSkills.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; This needs to come before "Critical Strike Multiplier" !
        IfInString, A_LoopField, increased Critical Strike Multiplier with Cold Skills
        {
            ; Only valid for jewels at the moment
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\CritMultiplierColdSkills.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; This needs to come before "Critical Strike Multiplier" !
        IfInString, A_LoopField, increased Critical Strike Multiplier with Fire Skills
        {
            ; Only valid for jewels at the moment
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\CritMultiplierFireSkills.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; This needs to come before "Critical Strike Multiplier" !
        IfInString, A_LoopField, increased Critical Strike Multiplier with Lightning Skills
        {
            ; Only valid for jewels at the moment
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\CritMultiplierLightningSkills.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; This needs to come before "Critical Strike Multiplier" !
        IfInString, A_LoopField, increased Critical Strike Multiplier with One Handed Melee Weapons
        {
            ; Only valid for jewels at the moment
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\CritMultiplierWith1HMelee.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; This needs to come before "Critical Strike Multiplier" !
        IfInString, A_LoopField, increased Critical Strike Multiplier with Two Handed Melee Weapons
        {
            ; Only valid for jewels at the moment
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\CritMultiplierWith2HMelee.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; This needs to come before "Critical Strike Multiplier" !
        IfInString, A_LoopField, increased Critical Strike Multiplier while Dual Wielding
        {
            ; Only valid for jewels at the moment
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\CritMultiplierWhileDualWielding.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, Critical Strike Multiplier
        {
            ; Slinkston edit
            If (ItemBaseType == "Weapon")
            {
                ValueRange := LookupAffixData("data\CritMultiplierLocal.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else If (Item.IsJewel) {
                ValueRange := LookupAffixData("data\CritMultiplierGlobal_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else
            {
                ValueRange := LookupAffixData("data\CritMultiplierGlobal.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            NumSuffixes += 1
            Continue
        }
        IfInString, A_LoopField, increased Ignite Duration on Enemies
        {
            ; Only valid for Jewels at this time
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\IgniteDurationEnemies.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, chance to Ignite
        {
            ; Only valid for Jewels at this time
            ; Don't increase number of suffixes, combined with "Ignite Duration on Enemies" this is just 1 suffix
            ;NumSuffixes += 1
            ValueRange := LookupAffixData("data\IgniteChance.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Fire Damage
        {
            If (Item.IsJewel) {
                AffixType := "Prefix"
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\IncrFireDamage_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else {
                AffixType := "Suffix"
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\IncrFireDamage.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Cold Damage
        {
            If (Item.IsJewel) {
                AffixType := "Prefix"
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\IncrColdDamage_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else {
                AffixType := "Suffix"
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\IncrColdDamage.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Lightning Damage
        {
            If (Item.IsJewel) {
                AffixType := "Prefix"
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\IncrLightningDamage_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else {
                AffixType := "Suffix"
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\IncrLightningDamage.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Light Radius
        {
            ValueRange := LookupAffixData("data\LightRadius_AccuracyRating.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Comp. Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, additional Block Chance while Dual Wielding
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\BlockChanceWhileDualWielding.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure chance to block
        IfInString, A_LoopField, additional Chance to Block with Staves
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\ChanceToBlockWithStaves.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
         ; Needs to come before pure chance to block
        IfInString, A_LoopField, additional Chance to Block Spells with Staves
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\ChanceToBlockSpellsWithStaves.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure chance to block
        IfInString, A_LoopField, additional Chance to Block Spells while Dual Wielding
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\ChanceToBlockDualWielding.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure chance to block
        IfInString, A_LoopField, additional Chance to Block Spells with Shields
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\ChanceToBlockSpellsWithShields.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, Chance to Block
        {
            NumSuffixes += 1
            If (Item.IsJewl and InStr(A_LoopField, "Minions have")) {
                ValueRange := LookupAffixData("data\MinionBlockChance.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else {
                ValueRange := LookupAffixData("data\BlockChance.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; This needs to come before plain "increased Damage"
        IfInString, A_LoopField, increased Damage over Time
        {
            ; Only valid on Jewels at this time
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\DamageOverTime.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Damage
        {
            ; Only valid on Jewels at this time
            IfInString, A_LoopField, Minions deal 
            {
                AffixType := "Prefix"
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\IncDamageMinions.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else {
                AffixType := "Suffix"
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\IncDamage.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Freeze Duration on Enemies
        {
            ; Only valid on Jewels at this time
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\FreezeDurationOnEnemies.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, chance to Freeze
        {
            ; Only valid on Jewels at this time
            ; "chance to Freeze" on Jewels is a combined affix with Freeze Duration, so don't increase suffix count
            ; NumSuffixes += 0
            ValueRange := LookupAffixData("data\ChanceToFreeze.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Shock Duration on Enemies
        {
            ; Only valid on Jewels at this time
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ShockDurationOnEnemies.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, chance to Shock
        {
            ; Only valid on Jewels at this time
            ; "chance to Freeze" on Jewels is a combined affix with Freeze Duration, so don't increase suffix count
            ; NumSuffixes += 0
            ValueRange := LookupAffixData("data\ChanceToShock.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, chance to Knock Enemies Back on hit
        {
            ; Only valid on Jewels at this time
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\KnockBackOnHit.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Flask affixes (on belts)
        IfInString, A_LoopField, reduced Flask Charges used
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\FlaskChargesUsed.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Flask Charges gained
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\FlaskChargesGained.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Flask effect duration
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\FlaskDuration.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        
        IfInString, A_LoopField, increased Quantity
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\IIQ.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, Life gained on Kill
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\LifeOnKill.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, Life gained for each Enemy hit ; Cuts off the rest to accommodate both "by Attacks" and "by your Attacks"
        {
            ; Slinkston edit. This isn't necessary at this point in time, but if either were to gain an additional ilvl affix down the road this would already be in place
            If (ItemBaseType == "Weapon") {
                ValueRange := LookupAffixData("data\LifeOnHitLocal.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else If (Item.IsJewel) {
                ValueRange := LookupAffixData("data\LifeOnHit_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else {
                ValueRange := LookupAffixData("data\LifeOnHit.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            NumSuffixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, Energy Shield gained for each Enemy hit by your Attacks
        {
            ; Only available on Jewels at this time
            ValueRange := LookupAffixData("data\ESOnHit.txt", ItemLevel, CurrValue, "", CurrTier)
            NumSuffixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, Life Regenerated per second
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\LifeRegen.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, Mana gained for each Enemy hit by your Attacks
        {
            ; Only found on jewels for now
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ManaOnHit.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, reduced Mana Cost of Skills
        {
            ; Only found on jewels for now
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ReducedManaCost.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, Mana Gained on Kill
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ManaOnKill.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Mana Regeneration Rate
        {
            If (Item.IsJewel) {
                AffixType := "Prefix"
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\ManaRegen_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else {
                AffixType := "Suffix"
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\ManaRegen.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Melee Damage
        {
            ; Only valid on Jewels at this time
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\MeleeDamage.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Projectile Damage
        {
            ; Only on jewels for now
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ProjectileDamage.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Projectile Speed
        {
            NumSuffixes += 1
            If (Item.IsJewel) {
                ValueRange := LookupAffixData("data\ProjectileSpeed_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else {
                ValueRange := LookupAffixData("data\ProjectileSpeed.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, reduced Attribute Requirements
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ReducedAttrReqs.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, to all Elemental Resistances
        {
            NumSuffixes += 1
            If (Item.IsJewel) {
                ; "to all Elemental Resistances" matches multiple affixes
                If InStr(A_LoopField, "Minions have") {
                    ValueRange := LookupAffixData("data\AllResist_Jewels_Minions.txt", ItemLevel, CurrValue, "", CurrTier)
                } Else If InStr(A_LoopField, "Totems gain") {
                    ValueRange := LookupAffixData("data\AllResist_Jewels_Totems.txt", ItemLevel, CurrValue, "", CurrTier)
                } Else {
                    ValueRange := LookupAffixData("data\AllResist_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                }
            } Else {
                ValueRange := LookupAffixData("data\AllResist.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, to Fire and Lightning Resistances
        {
            ; Only valid on Jewels at this time
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\FireAndLightningResist.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, to Fire and Cold Resistances
        {
            ; Only valid on Jewels at this time
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\FireAndColdResist.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, to Fire Resistance
        {
            NumSuffixes += 1
            If (Item.IsJewel) {
                ValueRange := LookupAffixData("data\FireResist_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else {
                ValueRange := LookupAffixData("data\FireResist.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, to Lightning Resistance
        {
            NumSuffixes += 1
            If (Item.IsJewel) {
                ValueRange := LookupAffixData("data\LightningResist_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else {
                ValueRange := LookupAffixData("data\LightningResist.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, to Cold and Lightning Resistances
        {
            ; Only valid on Jewels at this time
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\ColdAndLightningResist.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, to Cold Resistance
        {
            NumSuffixes += 1
            If (Item.IsJewel) {
                ValueRange := LookupAffixData("data\ColdResist_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else {
                ValueRange := LookupAffixData("data\ColdResist.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, to Chaos Resistance
        {
            NumSuffixes += 1
            If (Item.IsJewel) {
                ValueRange := LookupAffixData("data\ChaosResist_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else {
                ValueRange := LookupAffixData("data\ChaosResist.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        If RegExMatch(A_LoopField, ".*to (Cold|Fire|Lightning) and (Cold|Fire|Lightning) Resistances")
        {
            ; Catches two-stone rings and the like which have "+#% to Cold and Lightning Resistances"
            IfInString, A_LoopField, Fire
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\FireResist.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, Lightning
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\LightningResist.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            IfInString, A_LoopField, Cold
            {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\ColdResist.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
        }
        IfInString, A_LoopField, increased Stun Duration on Enemies
        {
            NumSuffixes += 1
            If (Item.IsJewel) {
                ValueRange := LookupAffixData("data\StunDuration_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else {
                ValueRange := LookupAffixData("data\StunDuration.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, reduced Enemy Stun Threshold
        {
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\StunThreshold.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
            Continue
        }
        
        ; Prefixes (due to new affixes on Jewels the split between suffixes and prefixes isn't 100% anymore)
        
        IfInString, A_LoopField, to Armour
        {
            ; Slinkston edit. AR, EV, and ES items are all correct for Armour, Shields, Helmets, Boots, Gloves, and different jewelry.
            ; to Armour has Belt, but does not have Ring or Amulet.
            If (ItemSubType == "Belt")
            {
                ValueRange := LookupAffixData("data\ToArmourBelt.txt", ItemLevel, CurrValue, "", CurrTier)
            }
    Else If (ItemSubtype == "Helmet")
    {
        ValueRange := LookupAffixData("data\ToArmourHelmet.txt", ItemLevel, CurrValue, "", CurrTier)
    }
        Else If (ItemSubtype == "Gloves" or ItemSubType == "Boots")
      {
          ValueRange := LookupAffixData("data\ToArmourGlovesandBoots.txt", ItemLevel, CurrValue, "", CurrTier)
      }
            Else
            {
                ValueRange := LookupAffixData("data\ToArmourArmourandShield.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            NumPrefixes += 1
            Continue
        }
        IfInString, A_LoopField, increased Armour and Evasion
        {
            AffixType := "Prefix"
            AEBracketLevel := 0
            ValueRange := LookupAffixData("data\ArmourAndEvasion.txt", ItemLevel, CurrValue, AEBracketLevel, CurrTier)
            If (HasStunRecovery) 
            {
                AEBracketLevel2 := AEBracketLevel

                AEBracket := LookupAffixBracket("data\HybridDefences_StunRecovery.txt", ItemLevel, CurrValue, AEBracketLevel2)
                If (Not IsValidRange(ValueRange) and IsValidBracket(AEBracket))
                {
                    ValueRange := LookupAffixData("data\HybridDefences_StunRecovery.txt", ItemLevel, CurrValue, AEBracketLevel2, CurrTier)
                }
                AffixType := "Comp. Prefix"
                BSRecBracketLevel := 0
                BSRecValue := ExtractValueFromAffixLine(ItemDataChunk, "increased Stun Recovery")
                BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", AEBracketLevel2, "", BSRecBracketLevel)
                If (Not IsValidBracket(BSRecPartial) or Not IsValidBracket(AEBracket))
                {
                    ; This means that we are actually dealing with a Prefix + Comp. Prefix.
                    ; To get the part for the hybrid defence that is contributed by the straight prefix, 
                    ; lookup the bracket level for the B&S Recovery line and then work out the partials
                    ; for the hybrid stat from the bracket level of B&S Recovery. 
                    ;
                    ; For example: 
                    ;   87% increased Armour and Evasion
                    ;   7% increased Stun Recovery
                    ;
                    ;   1) 7% B&S indicates bracket level 2 (6-7)
                    ;   2) Lookup bracket level 2 from the hybrid stat + block and stun recovery table
                    ;      This works out to be 6-14.
                    ;   3) Subtract 6-14 from 87 to get the rest contributed by the hybrid stat as pure prefix.
                    ;
                    ; Currently when subtracting a range from a single value we just use the range's 
                    ; max as single value. This may need changing depending on circumstance but it
                    ; works for now. EDIT: no longer the case, now uses RangeMid(...). EDIT2: Rest value calc
                    ; now routed through LookupRemainingAffixBracket() which uses trickle-down through all
                    ; three Range... functions. #'s below NOT YET changed to reflect that...
                    ;   87-10 = 77
                    ;   4) lookup affix data for increased Armour and Evasion with value of 77
                    ;
                    ; We now know, this is a Comp. Prefix+Prefix
                    ;
                    BSRecBracketLevel := 0
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", ItemLevel, BSRecValue, BSRecBracketLevel)
                    If (Not IsValidBracket(BSRecPartial))
                    {
                        ; This means that the hybrid stat is a Comp. Prefix (Hybrid)+Prefix and SR is a Comp. Prefix (Hybrid)+Suffix.
                        ;
                        ; For example the following case:
                        ;   Item Level: 58
                        ;   107% increased Armour and Evasion (AE)
                        ;   ...
                        ;   30% increased Stun Recovery (SR)
                        ;
                        ; Based on item level, 33-41 is the max contribution for AE of HybridDefences_StunRecovery (Comp. Prefix),
                        ; 12-13 is the max contribution for Stun Rec of StunRecovery_Hybrid (Comp. Prefix), 23-25 is the max contribution
                        ; for SR of StunRecovery_Suffix (Suffix)
                        ;
                        ; Obviously this is ambiguous and tough to resolve, but we'll try anyway...
                        ;
                        BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", ItemLevel, "", BSRecBracketLevel)
                    }
                   
                    AEBSBracket := LookupAffixBracket("data\HybridDefences_StunRecovery.txt", BSRecBracketLevel)

                    If (Not WithinBounds(AEBSBracket, CurrValue))
                    {                        
                        AEBracket := LookupRemainingAffixBracket("data\ArmourAndEvasion.txt", ItemLevel, CurrValue, AEBSBracket)

                        If (Not IsValidBracket(AEBracket))
                        {
                            AEBracket := LookupAffixBracket("data\HybridDefences_StunRecovery.txt", ItemLevel, CurrValue)
                        }
                        If (IsValidBracket(AEBracket) and WithinBounds(AEBracket, CurrValue))
                        {
                            If (NumPrefixes < 2)
                            {
                                ValueRange := AddRange(AEBSBracket, AEBracket)
                                ValueRange := MarkAsGuesstimate(ValueRange)
                                AffixType := "Comp. Prefix+Prefix"
                                NumPrefixes += 1
                            }
                            Else
                            {
                                ValueRange := LookupAffixData("data\ArmourAndEvasion.txt", ItemLevel, CurrValue, AEBracketLevel2, CurrTier)
                                AffixType := "Prefix"
                            }
                        }
                        Else
                        {                
                            ; Check if it isn't a simple case of Armour and Evasion (Prefix) + Stun Recovery (Suffix)
                            BSRecBracket := LookupAffixBracket("data\StunRecovery_Suffix.txt", ItemLevel, BSRecValue, BSRecBracketLevel, CurrTier)
                            If (IsValidRange(ValueRange) and IsValidBracket(BSRecBracket))
                            {
                                ; -2 means for later that processing this hybrid defence stat 
                                ; determined that Stun Recovery should be a simple suffix
                                BSRecPartial := ""
                                AffixType := "Prefix"
                                ValueRange := LookupAffixData("data\ArmourAndEvasion.txt", ItemLevel, CurrValue, AEBracketLevel, CurrTier)
                            }
                        }
                    }

                    If (WithinBounds(BSRecPartial, BSRecValue))
                    {
                        ; BS Recovery value within bounds, this means BS Rec is all acounted for
                        BSRecPartial =
                    }
                }
            }
            NumPrefixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Armour and Energy Shield
        {
            AffixType := "Prefix"
            AESBracketLevel := 0
            ValueRange := LookupAffixData("data\ArmourAndEnergyShield.txt", ItemLevel, CurrValue, AESBracketLevel, CurrTier)
            If (HasStunRecovery) 
            {
                AESBracketLevel2 := AESBracketLevel

                AESBracket := LookupAffixBracket("data\HybridDefences_StunRecovery.txt", ItemLevel, CurrValue, AESBracketLevel2)
                If (Not IsValidRange(ValueRange) and IsValidBracket(AESBracket))
                {
                    ValueRange := LookupAffixData("data\HybridDefences_StunRecovery.txt", ItemLevel, CurrValue, AESBracketLevel2, CurrTier)
                }
                AffixType := "Comp. Prefix"
                BSRecBracketLevel := 0
                BSRecValue := ExtractValueFromAffixLine(ItemDataChunk, "increased Stun Recovery")
                BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", AESBracketLevel2, "", BSRecBracketLevel)
                If (Not IsValidBracket(BSRecPartial) or Not IsValidBracket(AESBracket))
                {
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_Armour.txt", AESBracketLevel, "", BSRecBracketLevel)
                }
                If (Not IsValidBracket(BSRecPartial))
                {
                    BSRecBracketLevel := 0
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", ItemLevel, BSRecValue, BSRecBracketLevel)
                    If (Not IsValidBracket(BSRecPartial))
                    {
                        BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", ItemLevel, "", BSRecBracketLevel)
                    }

                    AESBSBracket := LookupAffixBracket("data\HybridDefences_StunRecovery.txt", BSRecBracketLevel)

                    If (Not WithinBounds(AESBSBracket, CurrValue))
                    {
                        AESBracket := LookupRemainingAffixBracket("data\ArmourAndEnergyShield.txt", ItemLevel, CurrValue, AESBSBracket)
                        If (Not IsValidBracket(AESBracket))
                        {
                            AESBracket := LookupAffixBracket("data\HybridDefences_StunRecovery.txt", ItemLevel, CurrValue)
                        }
                        If (Not WithinBounds(AESBracket, CurrValue))
                        {
                            ValueRange := AddRange(AESBSBracket, AESBracket)
                            ValueRange := MarkAsGuesstimate(ValueRange)
                            AffixType := "Comp. Prefix+Prefix"
                            NumPrefixes += 1
                        }
                    }
                    If (WithinBounds(BSRecPartial, BSRecValue))
                    {
                        ; BS Recovery value within bounds, this means BS Rec is all acounted for
                        BSRecPartial =
                    }
                }
            }
            NumPrefixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Evasion and Energy Shield
        {
            AffixType := "Prefix"
            EESBracketLevel := 0
            ValueRange := LookupAffixData("data\EvasionAndEnergyShield.txt", ItemLevel, CurrValue, EESBracketLevel, CurrTier)
            If (HasStunRecovery) 
            {
                EESBracketLevel2 := EESBracketLevel

                EESBracket := LookupAffixBracket("data\HybridDefences_StunRecovery.txt", ItemLevel, CurrValue, EESBracketLevel2)
                If (Not IsValidRange(ValueRange) and IsValidBracket(EESBracket))
                {
                    ValueRange := LookupAffixData("data\HybridDefences_StunRecovery.txt", ItemLevel, CurrValue, EESBracketLevel2, CurrTier)
                }

                AffixType := "Comp. Prefix"
                BSRecBracketLevel := 0
                BSRecValue := ExtractValueFromAffixLine(ItemDataChunk, "increased Stun Recovery")
                BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", EESBracketLevel2, "", BSRecBracketLevel)
                If (Not IsValidBracket(BSRecPartial) or Not IsValidBracket(EESBracket))
                {
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", EESBracketLevel, "", BSRecBracketLevel)
                }
                If (Not IsValidBracket(BSRecPartial))
                {
                    BSRecBracketLevel := 0
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", ItemLevel, BSRecValue, BSRecBracketLevel)
                    If (Not IsValidBracket(BSRecPartial))
                    {
                        BSRecPartial := LookupAffixBracket("data\StunRecovery_Hybrid.txt", ItemLevel, "", BSRecBracketLevel)
                    }

                    EESBSBracket := LookupAffixBracket("data\HybridDefences_StunRecovery.txt", BSRecBracketLevel)

                    If (Not WithinBounds(EESBSBracket, CurrValue))
                    {
                        EESBracket := LookupRemainingAffixBracket("data\EvasionAndEnergyShield.txt", ItemLevel, CurrValue, EESBSBracket)
                        
                        If (Not IsValidBracket(EESBracket))
                        {
                            EESBracket := LookupAffixBracket("data\HybridDefences_StunRecovery.txt", ItemLevel, CurrValue)
                        }
                        If (Not WithinBounds(EESBracket, CurrValue))
                        {
                            ValueRange := AddRange(EESBSBracket, EESBracket)
                            ValueRange := MarkAsGuesstimate(ValueRange)
                            AffixType := "Comp. Prefix+Prefix"
                            NumPrefixes += 1
                        }
                    }

                    If (WithinBounds(BSRecPartial, BSRecValue))
                    {
                        ; BS Recovery value within bounds, this means BS Rec is all acounted for
                        BSRecPartial =
                    }
                }
            }
            NumPrefixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Armour
        {
            AffixType := "Prefix"
            IABracketLevel := 0
            If (ItemBaseType == "Item")
            {
                ; Global
                PrefixPath := "data\IncrArmour_Items.txt"
                PrefixPathOther := "data\IncrArmour_WeaponsAndArmour.txt"
            } Else If (Item.IsJewel) 
            {
                PrefixPath := "data\IncrArmour_Jewels.txt"
                PrefixPathOther := "data\IncrArmour_Jewels.txt"
            }
            Else
            {
                ; Local
                PrefixPath := "data\IncrArmour_WeaponsAndArmour.txt"
                PrefixPathOther := "data\IncrArmour_Items.txt"
            }
            ValueRange := LookupAffixData(PrefixPath, ItemLevel, CurrValue, IABracketLevel, CurrTier)
            If (Not IsValidRange(ValueRange))
            {
                ValueRange := LookupAffixData(PrefixPathOther, ItemLevel, CurrValue, IABracketLevel, CurrTier)
            }
            If (HasStunRecovery and not Item.IsJewel) 
            {
                IABracketLevel2 := IABracketLevel

                ASRBracket := LookupAffixBracket("data\Armour_StunRecovery.txt", ItemLevel, CurrValue, IABracketLevel2)
                If (Not IsValidRange(ValueRange) and IsValidBracket(ASRBracket))
                {
                    ValueRange := LookupAffixData("data\Armour_StunRecovery.txt", ItemLevel, CurrValue, IABracketLevel2, CurrTier)
                }

                AffixType := "Comp. Prefix"
                BSRecBracketLevel := 0
                BSRecValue := ExtractValueFromAffixLine(ItemDataChunk, "increased Stun Recovery")
                BSRecPartial := LookupAffixBracket("data\StunRecovery_Armour.txt", IABracketLevel2, "", BSRecBracketLevel)
                If (Not IsValidBracket(BSRecPartial) or Not IsValidBracket(ASRBracket))
                {
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_Armour.txt", IABracketLevel, "", BSRecBracketLevel)
                }
                If (Not IsValidBracket(BSRecPartial))
                {
                    BSRecBracketLevel := 0
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_Armour.txt", ItemLevel, BSRecValue, BSRecBracketLevel)             
                    If (Not IsValidBracket(BSRecPartial))
                    {
                        BSRecPartial := LookupAffixBracket("data\StunRecovery_Armour.txt", ItemLevel, "", BSRecBracketLevel)
                    }

                    IABSBracket := LookupAffixBracket("data\Armour_StunRecovery.txt", BSRecBracketLevel)

                    If (Not WithinBounds(IABSBracket, CurrValue))
                    {
                        IABracket := LookupRemainingAffixBracket(PrefixPath, ItemLevel, CurrValue, IABSBracket)
                        If (Not IsValidBracket(IABracket))
                        {
                            IABracket := LookupAffixBracket(PrefixPath, ItemLevel, CurrValue)
                        }
                        If (Not WithinBounds(IABracket, CurrValue))
                        {
                            ValueRange := AddRange(IABSBracket, IABracket)
                            ValueRange := MarkAsGuesstimate(ValueRange)
                            AffixType := "Comp. Prefix+Prefix"
                            NumPrefixes += 1
                        }
                    }

                    If (WithinBounds(BSRecPartial, BSRecValue))
                    {
                        ; BS Recovery value within bounds, this means BS Rec is all acounted for
                        BSRecPartial =
                    }
                }
            }
            NumPrefixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, to Evasion Rating
        {
            ; Slinkston edit. I am not sure if using 'else if' statements are the best way here, but it seems to work.
            ; AR, EV, and ES items are all correct for Armour, Shields, Helmets, Boots, Gloves, and different jewelry.
            ; to Evasion Rating has Ring, but does not have Belt or Amulet.
            If (ItemSubType == "Ring")
            {
                ValueRange := LookupAffixData("data\ToEvasionRing.txt", ItemLevel, CurrValue, "", CurrTier)
            }
    Else If (ItemSubType == "Helmet")
    {
        ValueRange := LookupAffixData("data\ToEvasionHelmet.txt", ItemLevel, CurrValue, "", CurrTier)
    }
        Else If (ItemSubType == "Gloves" or ItemSubType == "Boots")
      {
          ValueRange := LookupAffixData("data\ToEvasionGlovesandBoots.txt", ItemLevel, CurrValue, "", CurrTier)
      }
            Else
            {
                ValueRange := LookupAffixData("data\ToEvasionArmourandShield.txt", ItemLevel, CurrValue, "", CurrTier)      
            }
            NumPrefixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Evasion Rating
        {
            AffixType := "Prefix"
            IEBracketLevel := 0
            If (ItemBaseType == "Item")
            {
                ; Global
                PrefixPath := "data\IncrEvasion_Items.txt"
                PrefixPathOther := "data\IncrEvasion_Armour.txt"
            } Else If (Item.IsJewel) 
            {
                PrefixPath := "data\IncrEvasion_Jewels.txt"
                PrefixPathOther := "data\IncrEvasion_Jewels.txt"
            }
            Else
            {
                ; Local
                PrefixPath := "data\IncrEvasion_Armour.txt"
                PrefixPathOther := "data\IncrEvasion_Items.txt"
            }
            ValueRange := LookupAffixData(PrefixPath, ItemLevel, CurrValue, IEBracketLevel, CurrTier)
            If (Not IsValidRange(ValueRange))
            {
                ValueRange := LookupAffixData(PrefixPathOther, ItemLevel, CurrValue, IEBracketLevel, CurrTier)
            }
            If (HasStunRecovery and not Item.IsJewel) 
            {
                IEBracketLevel2 := IEBracketLevel

                ; Determine composite bracket level and store in IEBracketLevel2, for example:
                ;   8% increased Evasion
                ;   26% increased Stun Recovery 
                ;   => 8% is bracket level 2 (6-14), so 'B&S Recovery from Evasion' level 2 makes 
                ;      BSRec partial 6-7
                ERSRBracket := LookupAffixBracket("data\Evasion_StunRecovery.txt", ItemLevel, CurrValue, IEBracketLevel2)
                If (Not IsValidRange(ValueRange) and IsValidBracket(ERSRBracket))
                {
                    ValueRange := LookupAffixData("data\Evasion_StunRecovery.txt", ItemLevel, CurrValue, IEBracketLevel2, CurrTier)
                }

                AffixType := "Comp. Prefix"
                BSRecBracketLevel := 0
                BSRecValue := ExtractValueFromAffixLine(ItemDataChunk, "increased Stun Recovery")
                BSRecPartial := LookupAffixBracket("data\StunRecovery_Evasion.txt", IEBracketLevel2, "", BSRecBracketLevel)
                If (Not IsValidBracket(BSRecPartial) or Not IsValidBracket(ERSRBracket))
                {
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_Evasion.txt", IEBracketLevel, "", BSRecBracketLevel)
                }
                If (Not IsValidRange(ValueRange) and (Not IsValidBracket(BSRecPartial) or Not WithinBounds(BSRecPartial, BSRecValue)))
                {
                    BSRecBracketLevel := 0
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_Evasion.txt", ItemLevel, BSRecValue, BSRecBracketLevel)
                    If (Not IsValidBracket(BSRecPartial))
                    {
                        BSRecPartial := LookupAffixBracket("data\StunRecovery_Evasion.txt", ItemLevel, "", BSRecBracketLevel)
                    }
                   
                    IEBSBracket := LookupAffixBracket("data\Evasion_StunRecovery.txt", BSRecBracketLevel)

                    If (Not WithinBounds(IEBSBracket, CurrValue))
                    {
                        IEBracket := LookupRemainingAffixBracket(PrefixPath, ItemLevel, CurrValue, IEBSBracket)
                        If (Not IsValidBracket(IEBracket))
                        {
                            IEBracket := LookupAffixBracket(PrefixPath, ItemLevel, CurrValue, "")
                        }
                        If (Not WithinBounds(IEBracket, CurrValue))
                        {
                            ValueRange := AddRange(IEBSBracket, IEBracket)
                            ValueRange := MarkAsGuesstimate(ValueRange)
                            AffixType := "Comp. Prefix+Prefix"
                            NumPrefixes += 1
                        }
                    }

                    If (WithinBounds(BSRecPartial, BSRecValue))
                    {
                        ; BS Recovery value within bounds, this means BS Rec is all acounted for
                        BSRecPartial =
                    }
                }
            }
            NumPrefixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, to maximum Energy Shield
        {
            ; Slinkston Edit. Seems I may have to do the same for EV and AR.
            ; AR, EV, and ES items are all correct for Armour, Shields, Helmets, Boots, Gloves, and different jewelry.
            ; to max ES is found is all jewelry; Amulet, Belt, and Ring.
            PrefixType := "Prefix"
            If (ItemSubType == "Amulet" or ItemSubType == "Belt")
            {
                ValueRange := LookupAffixData("data\ToMaxESAmuletandBelt.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else If (ItemSubType == "Ring")
            {
                ValueRange := LookupAffixData("data\ToMaxESRing.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else If (ItemSubType == "Gloves" or ItemSubtype == "Boots")
            {
                ValueRange := LookupAffixData("data\ToMaxESGlovesandBoots.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else If (ItemSubType == "Helmet")
            {
                ValueRange := LookupAffixData("data\ToMaxESHelmet.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else
            {
                ValueRange := LookupAffixData("data\ToMaxESArmourandShield.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            NumPrefixes += 1
            Continue
        }
        
        ; Needs to come before increased Energy Shield
        IfInString, A_LoopField, increased Energy Shield Recharge Rate
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\EnergyShieldRechargeRate.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Energy Shield
        {
            AffixType := "Prefix"
            IESBracketLevel := 0
            PrefixPath := "data\IncrEnergyShield.txt"
            ValueRange := LookupAffixData(PrefixPath, ItemLevel, CurrValue, IESBracketLevel, CurrTier)

            If (HasStunRecovery) 
            {
                IESBracketLevel2 := IESBracketLevel

                ESSRBracket := LookupAffixBracket("data\EnergyShield_StunRecovery.txt", ItemLevel, CurrValue, IESBracketLevel2)
                If (Not IsValidRange(ValueRange) and IsValidBracket(ESSRBracket))
                {
                    ValueRange := LookupAffixData("data\EnergyShield_StunRecovery.txt", ItemLevel, CurrValue, IESBracketLevel2, CurrTier)
                }

                AffixType := "Comp. Prefix"
                BSRecBracketLevel := 0
                BSRecPartial := LookupAffixBracket("data\StunRecovery_EnergyShield.txt", IESBracketLevel2, "", BSRecBracketLevel)
                BSRecValue := ExtractValueFromAffixLine(ItemDataChunk, "increased Stun Recovery")
                If (Not IsValidBracket(BSRecPartial) or Not IsValidBracket(ESSRBracket))
                {
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_EnergyShield.txt", IESBracketLevel, "", BSRecBracketLevel)
                }
                If (Not IsValidBracket(BSRecPartial))
                {
                    BSRecBracketLevel := 0
                    BSRecPartial := LookupAffixBracket("data\StunRecovery_EnergyShield.txt", ItemLevel, BSRecValue, BSRecBracketLevel)
                    If (Not IsValidBracket(BSRecPartial))
                    {
                        BSRecPartial := LookupAffixBracket("data\StunRecovery_EnergyShield.txt", ItemLevel, "", BSRecBracketLevel)
                    }
                    IESBSBracket := LookupAffixBracket("data\EnergyShield_StunRecovery.txt", BSRecBracketLevel)

                    If (Not WithinBounds(IEBSBracket, CurrValue))
                    {                    
                        IESBracket := LookupRemainingAffixBracket(PrefixPath, ItemLevel, CurrValue, IESBSBracket)

                        If (Not WithinBounds(IESBracket, CurrValue))
                        {
                            ValueRange := AddRange(IESBSBracket, IESBracket)
                            ValueRange := MarkAsGuesstimate(ValueRange)
                            AffixType := "Comp. Prefix+Prefix"
                            NumPrefixes += 1
                        }
                    }

                    If (WithinBounds(BSRecPartial, BSRecValue))
                    {
                        ; BS Recovery value within bounds, this means BS Rec is all acounted for
                        BSRecPartial =
                    }
                }
            }
            NumPrefixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased maximum Energy Shield
        {
            NumPrefixes += 1
            If (Item.IsJewel) {
                ValueRange := LookupAffixData("data\IncrMaxEnergyShield_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else {
                ValueRange := LookupAffixData("data\IncrMaxEnergyShield_Amulets.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        If RegExMatch(A_LoopField, "Adds \d+?\-\d+? Physical Damage")
        {
            If (ItemBaseType == "Weapon")
            {
                If (ItemSubType == "Bow")
                {
                    ValueRange := LookupAffixData("data\AddedPhysDamage_2H.txt", ItemLevel, CurrValue, "", CurrTier)
                }
                Else
                {
                    If (ItemGripType == "1H") ; One handed weapons
                    {
                        ValueRange := LookupAffixData("data\AddedPhysDamage_1H.txt", ItemLevel, CurrValue, "", CurrTier)
                    }
                    Else
                    {
                        ValueRange := LookupAffixData("data\AddedPhysDamage_2H.txt", ItemLevel, CurrValue, "", CurrTier)
                    }
                }
            }
            Else
            {
                If (ItemSubType == "Amulet")
                {
                    ValueRange := LookupAffixData("data\AddedPhysDamage_Amulets.txt", ItemLevel, CurrValue, "", CurrTier)
                }
                        
                Else
                {
                    If (ItemSubType == "Quiver")
                    {
                        ValueRange := LookupAffixData("data\AddedPhysDamage_Quivers.txt", ItemLevel, CurrValue, "", CurrTier)
                    }
                    Else
                    {
                        If (ItemSubType == "Ring")
                        {
                            ValueRange := LookupAffixData("data\AddedPhysDamage_Rings.txt", ItemLevel, CurrValue, "", CurrTier)
                        }
                        Else
                        {
                            ;Gloves added by Bahnzo
                            If (ItemSubType == "Gloves")
                            {
                                ValueRange := LookupAffixData("data\AddedPhysDamage_Gloves.txt", ItemLevel, CurrValue, "", CurrTier)
                            }
                            Else
                            {
                            ; There is no Else for rare items, but some uniques have added phys damage.
                            ; Just lookup in 1H for now...
                            ValueRange := LookupAffixData("data\AddedPhysDamage_Amulets.txt", ItemLevel, CurrValue, "", CurrTier)
                            }
                        }
                    }
                }
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            NumPrefixes += 1
            Continue
        }
        If RegExMatch(A_LoopField, "Adds \d+?\-\d+? Cold Damage") 
        {
      ; Slinkston edit: Thanks to Moth1 on the forums for the suggestion of nesting the ele dmg and ele dmg to spells!
            If RegExMatch(A_LoopField, "Adds \d+?\-\d+? Cold Damage to Spells")
      {
    If (ItemGripType == "1H")
    {
        ValueRange := LookupAffixData("data\SpellAddedCold1H.txt", ItemLevel, CurrValue, "", CurrTier)
    }
    Else ; 2 handed weapons. This may need to be changed if bows get added spell damage since they are categorized as 1H, but doubtful.
    {
      ValueRange := LookupAffixData("data\SpellAddedCold2H.txt", ItemLevel, CurrValue, "", CurrTier)
    }   
      }     
      Else
      {
    If (ItemSubType == "Amulet" or ItemSubType == "Ring")
    {
        ValueRange := LookupAffixData("data\AddedColdDamage_RingsAndAmulets.txt", ItemLevel, CurrValue, "", CurrTier)
    }
    Else
    {
        If (ItemSubType == "Gloves")
        {
      ValueRange := LookupAffixData("data\AddedColdDamage_Gloves.txt", ItemLevel, CurrValue, "", CurrTier)
        }
      Else
      {
          If (ItemSubType == "Quiver")
          {
        ValueRange := LookupAffixData("data\AddedColdDamage_Quivers.txt", ItemLevel, CurrValue, "", CurrTier)
          }
        Else
        {
            If (ItemGripType == "1H")
            {
          ValueRange := LookupAffixData("data\AddedColdDamage_1H.txt", ItemLevel, CurrValue, "", CurrTier)
            }
          Else
          {
              ValueRange := LookupAffixData("data\AddedColdDamage_2H.txt", ItemLevel, CurrValue, "", CurrTier)
          }
        }
      }
    }
      } 
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            NumPrefixes += 1
            Continue
        }
        If RegExMatch(A_LoopField, "Adds \d+?\-\d+? Fire Damage") 
        {
      ; Slinkston edit: Thanks to Moth1 on the forums for the suggestion of nesting the ele dmg and ele dmg to spells!
            If RegExMatch(A_LoopField, "Adds \d+?\-\d+? Fire Damage to Spells")
      {
    If (ItemGripType == "1H")
    {
        ValueRange := LookupAffixData("data\SpellAddedFire1H.txt", ItemLevel, CurrValue, "", CurrTier)
    }
        Else ; 2 handed weapons. This may need to be changed if bows get added spell damage since they are categorized as 1H, but doubtful.
        {
      ValueRange := LookupAffixData("data\SpellAddedFire2H.txt", ItemLevel, CurrValue, "", CurrTier)
        }   
      
      }
      Else
      {     
    If (ItemSubType == "Amulet" or ItemSubType == "Ring")
    {
        ValueRange := LookupAffixData("data\AddedFireDamage_RingsAndAmulets.txt", ItemLevel, CurrValue, "", CurrTier)
    }
        Else
        {
      If (ItemSubType == "Gloves")
      {
          ValueRange := LookupAffixData("data\AddedFireDamage_Gloves.txt", ItemLevel, CurrValue, "", CurrTier)
      }
          Else
          {
        If (ItemSubType == "Quiver")
        {
            ValueRange := LookupAffixData("data\AddedFireDamage_Quivers.txt", ItemLevel, CurrValue, "", CurrTier)
        }
            Else
            {
          If (ItemGripType == "1H") ; One handed weapons
          {
              ValueRange := LookupAffixData("data\AddedFireDamage_1H.txt", ItemLevel, CurrValue, "", CurrTier)
          }
              Else
              {
            ValueRange := LookupAffixData("data\AddedFireDamage_2H.txt", ItemLevel, CurrValue, "", CurrTier)
              }
            }
          }
        }
      } 
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            NumPrefixes += 1
            Continue
        }
        If RegExMatch(A_LoopField, "Adds \d+?\-\d+? Lightning Damage")
        {
      ; Slinkston edit: Thanks to Moth1 on the forums for the suggestion of nesting the ele dmg and ele dmg to spells!
            If RegExMatch(A_LoopField, "Adds \d+?\-\d+? Lightning Damage to Spells")
      {
    If (ItemGripType == "1H")
    {
        ValueRange := LookupAffixData("data\SpellAddedLightning1H.txt", ItemLevel, CurrValue, "", CurrTier)
    }
        Else ; 2 handed weapons. This may need to be changed if bows get added spell damage since they are categorized as 1H, but doubtful.
        {
      ValueRange := LookupAffixData("data\SpellAddedLightning2H.txt", ItemLevel, CurrValue, "", CurrTier)
        }   
      }
      Else
      {
    If (ItemSubType == "Amulet" or ItemSubType == "Ring")
    {
        ValueRange := LookupAffixData("data\AddedLightningDamage_RingsAndAmulets.txt", ItemLevel, CurrValue, "", CurrTier)
    }
        Else
        {
      If (ItemSubType == "Gloves")
      {
          ValueRange := LookupAffixData("data\AddedLightningDamage_Gloves.txt", ItemLevel, CurrValue, "", CurrTier)
      }
          Else
          { 
        If (ItemSubType == "Quiver")
        {
            ValueRange := LookupAffixData("data\AddedLightningDamage_Quivers.txt", ItemLevel, CurrValue, "", CurrTier)
        }
            Else
            {
          If (ItemGripType == "1H") ; One handed weapons
          {
              ValueRange := LookupAffixData("data\AddedLightningDamage_1H.txt", ItemLevel, CurrValue, "", CurrTier)
          }
              Else
              {
            ValueRange := LookupAffixData("data\AddedLightningDamage_2H.txt", ItemLevel, CurrValue, "", CurrTier)
              }
            }
          }
        }
      } 
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            NumPrefixes += 1
            Continue
        }
        
        If RegExMatch(A_LoopField, "Adds \d+?\-\d+? Chaos Damage") 
        {
            If (ItemGripType == "1H")
            {
                ValueRange := LookupAffixData("data\AddedChaosDamage_1H.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else If (ItemGripType == "2H")
            {
                ValueRange := LookupAffixData("data\AddedChaosDamage_2H.txt", ItemLevel, CurrValue, "", CurrTier)
            } 
            Else If (ItemSubType == "Amulet" or ItemSubType == "Ring")
            {
                ; Master modded prefix
                ValueRange := LookupAffixData("data\AddedChaosDamage_RingsAndAmulets.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            NumPrefixes += 1
            Continue
        }
        
        IfInString, A_LoopField, Physical Damage to Melee Attackers
        {
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\PhysDamagereturn.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Mine Laying Speed
        {
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\MineLayingSpeed.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Totem Damage
        {
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\IncrTotemDamage.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Totem Life
        {
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\IncrTotemLife.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Trap Throwing Speed
        {
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\IncrTrapThrowingSpeed.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Trap Damage
        {
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\IncrTrapDamage.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Chaos Damage
        {
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\IncrChaosDamage.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        If ( InStr(A_LoopField,"increased maximum Life"))
        {
            If InStr(A_LoopField,"Minions have") {
                ValueRange := LookupAffixData("data\MinionIncrMaximumLife.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else {
                ValueRange := LookupAffixData("data\IncrMaximumLife.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            NumPrefixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, to Level of Socketed
        {
            If (ItemBaseType == "Weapon")
            {
                If (ItemSubType == "Bow")
                {
                    ValueRange := LookupAffixData("data\GemLevel_Bow.txt", ItemLevel, CurrValue, "", CurrTier)
                }
                Else
                {
                    If (InStr(A_LoopField, "Fire") or InStr(A_LoopField, "Cold") or InStr(A_LoopField, "Lightning"))
                    {
                        ValueRange := LookupAffixData("data\GemLevel_Elemental.txt", ItemLevel, CurrValue, "", CurrTier)
                    }
                    Else
                    {
                        If (InStr(A_LoopField, "Melee"))
                        {
                            ValueRange := LookupAffixData("data\GemLevel_Melee.txt", ItemLevel, CurrValue, "", CurrTier)
                        }
                        Else
                        {
                            ; Paragorn's
                            ValueRange := LookupAffixData("data\GemLevel.txt", ItemLevel, CurrValue, "", CurrTier)
                        }
                    }
                }
            }
            Else
            {
                If (InStr(A_LoopField, "Minion"))
                {
                    ValueRange := LookupAffixData("data\GemLevel_Minion.txt", ItemLevel, CurrValue, "", CurrTier)
                }
                Else If (InStr(A_LoopField, "Fire") or InStr(A_LoopField, "Cold") or InStr(A_LoopField, "Lightning"))
                {
                    ValueRange := LookupAffixData("data\GemLevel_Elemental.txt", ItemLevel, CurrValue, "", CurrTier)
                }
                Else If (InStr(A_LoopField, "Melee"))
                {
                    ValueRange := LookupAffixData("data\GemLevel_Melee.txt", ItemLevel, CurrValue, "", CurrTier)
                }
            }
            NumPrefixes += 1
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, maximum Life
        {
            ; Slinkston edit
            If (ItemSubType == "Amulet")
            {
                ValueRange := LookupAffixData("data\MaxLifeAmulet.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else If (ItemSubType == "Shield")
            {
                ValueRange := LookupAffixData("data\MaxLifeShield.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else If (ItemSubType == "BodyArmour")
            {
                ValueRange := LookupAffixData("data\MaxLifeBodyArmour.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            ;Bahnzo Edit for Boots, Gloves and Rings
            Else If (ItemSubType == "Boots")
            {
                ValueRange := LookupAffixData("data\MaxLifeBootsGloves.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else If (ItemSubType == "Gloves")
            {
                ValueRange := LookupAffixData("data\MaxLifeBootsGloves.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else If (ItemSubType == "Ring")
            {
                ValueRange := LookupAffixData("data\MaxLifeRing.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            Else
            {
                ValueRange := LookupAffixData("data\MaxLife.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            NumPrefixes += 1
            Continue
        }
        IfInString, A_LoopField, Physical Attack Damage Leeched as
        {
            ; despite the file name this handles both life and mana leech
            NumPrefixes += 1
            If (Item.IsJewel) {
                ValueRange := LookupAffixData("data\LifeLeech_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
            } Else {
                ValueRange := LookupAffixData("data\LifeLeech.txt", ItemLevel, CurrValue, "", CurrTier)
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, Movement Speed
        {
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\MovementSpeed.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
  IfInString, A_LoopField, increased Elemental Damage with Weapons
        {
      ; Slinkston edit. I originally screwed this up , but it is now fixed.
            NumPrefixes += 1
      ValueRange := LookupAffixData("data\IncrWeaponElementalDamage.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }

        ; Flask effects (on belts)
        IfInString, A_LoopField, increased Flask Mana Recovery rate
        {
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\FlaskManaRecoveryRate.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Flask Life Recovery rate
        {
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\FlaskLifeRecoveryRate.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
    }

    ; --- COMPLEX AFFIXES ---

    Loop, Parse, ItemDataChunk, `n, `r
    {
        If StrLen(A_LoopField) = 0
        {
            Break ; Not interested in blank lines
        }
        IfInString, ItemDataChunk, Unidentified
        {
            Break ; Not interested in unidentified items
        }

        CurrValue := GetActualValue(A_LoopField)

        ; "Spell Damage +%" (simple prefix)
        ; "Spell Damage +% (1H)" / "Base Maximum Mana" - Limited to sceptres, wands, and daggers. 
        ; "Spell Damage +% (Staff)" / "Base Maximum Mana"
        IfInString, A_LoopField, increased Spell Damage
        {
            ; Spell damage on Jewels is different and simple, we handle this first
            If (Item.IsJewel and InStr(A_LoopField, "increased Spell Damage while Dual Wielding")){
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\SpellDamageDualWielding_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            } Else If (Item.IsJewel and InStr(A_LoopField, "increased Spell Damage while holding a Shield")){
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\SpellDamageHoldingShield_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            } Else If (Item.IsJewel and InStr(A_LoopField, "increased Spell Damage while wielding a Staff")){
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\SpellDamageWieldingStaff_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            } Else If (Item.IsJewel) {
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\SpellDamage_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            } Else If (Item.IsAmulet) {
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\SpellDamage_Amulets.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            } Else If (Item.SubType == "Shield") {
                NumPrefixes += 1
                ; Shield have the same pure spell damage affixes as 1 handers, but can't get the hybrid spell dmg/mana
                ValueRange := LookupAffixData("data\SpellDamage_1H.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            
            AffixType := "Prefix"
            If (HasMaxMana)
            {
                SDBracketLevel := 0
                MMBracketLevel := 0
                MaxManaValue := ExtractValueFromAffixLine(ItemDataChunk, "maximum Mana")
                If (ItemSubType == "Staff")
                {
                    SpellDamageBracket := LookupAffixBracket("data\SpellDamage_MaxMana_Staff.txt", ItemLevel, CurrValue, SDBracketLevel)
                    If (Not IsValidBracket(SpellDamageBracket))
                    {
                        AffixType := "Comp. Prefix+Prefix"
                        NumPrefixes += 1
                        
                        ; Need to find the bracket level by looking at max mana value instead
                        MaxManaBracket := LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", ItemLevel, MaxManaValue, MMBracketLevel)
                        If (Not IsValidBracket(MaxManaBracket))
                        {
                            ; This actually means that both the "increased Spell Damage" line and 
                            ; the "to maximum Mana" line are made up of Composite Prefix + Prefix.
                            ;
                            ; I haven't seen such an item yet, but you never know. In any case this
                            ; is completely ambiguous and can't be resolved. Mark line with EstInd
                            ; so user knows she needs to take a look at it.
                            AffixType := "Comp. Prefix+Comp. Prefix"
                            ValueRange := StrPad(EstInd, Opts.ValueRangeFieldWidth + StrLen(EstInd), "left")
                        }
                        Else
                        {
                            SpellDamageBracketFromComp := LookupAffixBracket("data\SpellDamage_MaxMana_Staff.txt", MMBracketLevel)
                            SpellDamageBracket := LookupRemainingAffixBracket("data\SpellDamage_Staff.txt", ItemLevel, CurrValue, SpellDamageBracketFromComp, SDBracketLevel)
                            ValueRange := AddRange(SpellDamageBracket, SpellDamageBracketFromComp)
                            ValueRange := MarkAsGuesstimate(ValueRange)
                        }
                    }
                    Else
                    {
                        ValueRange := LookupAffixData("data\SpellDamage_MaxMana_Staff.txt", ItemLevel, CurrValue, BracketLevel, CurrTier)
                        MaxManaBracket := LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", BracketLevel)
                        AffixType := "Comp. Prefix"
                    }
                }
                Else
                {
                    SpellDamageBracket := LookupAffixBracket("data\SpellDamage_MaxMana_1H.txt", ItemLevel, CurrValue, SDBracketLevel)
                    If (Not IsValidBracket(SpellDamageBracket))
                    {
                        AffixType := "Comp. Prefix+Prefix"
                        NumPrefixes += 1
                        
                        ; Need to find the bracket level by looking at max mana value instead
                        MaxManaBracket := LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", ItemLevel, MaxManaValue, MMBracketLevel)
                        If (Not IsValidBracket(MaxManaBracket))
                        {
                            MaxManaBracket := LookupAffixBracket("data\MaxMana.txt", ItemLevel, MaxManaValue, MMBracketLevel)
                            If (IsValidBracket(MaxManaBracket))
                            {
                                AffixType := "Prefix"
                                If (ItemSubType == "Staff")
                                {
                                    ValueRange := LookupAffixData("data\SpellDamage_Staff.txt", ItemLevel, CurrValue, SDBracketLevel, CurrTier)
                                }
                                Else
                                {
                                    ValueRange := LookupAffixData("data\SpellDamage_1H.txt", ItemLevel, CurrValue, SDBracketLevel, CurrTier)
                                }
                                ValueRange := StrPad(ValueRange, Opts.ValueRangeFieldWidth, "left")
                            }
                            Else
                            {
                                ; Must be 1H Spell Damage and Max Mana + 1H Spell Damage (+ Max Mana)
                                SD1HBracketLevel := 0
                                SpellDamage1HBracket := LookupAffixBracket("data\SpellDamage_1H.txt", ItemLevel, "", SD1HBracketLevel)
                                If (IsValidBracket(SpellDamage1HBracket)) 
                                {
                                    SpellDamageBracket := LookupRemainingAffixBracket("data\SpellDamage_MaxMana_1H.txt", ItemLevel, CurrValue, SpellDamage1HBracket, SDBracketLevel)
                                    If (IsValidBracket(SpellDamageBracket))
                                    {
                                        MaxManaBracket := LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", SDBracketLevel, "", MMBracketLevel)
                                        
                                        ; Check if max mana can be covered fully with the partial max mana bracket from Spell Damage Max Mana 1H
                                        MaxManaBracketRem := LookupRemainingAffixBracket("data\MaxMana.txt", ItemLevel, MaxManaValue, MaxManaBracket)
                                        If (Not IsValidBracket(MaxManaBracketRem))
                                        {
                                            ; Nope, try again: check highest spell damage max mana first then spell damage
                                            SD1HBracketLevel := 0
                                            SpellDamageBracket := LookupAffixBracket("data\SpellDamage_MaxMana_1H.txt", ItemLevel, "", SDBracketLevel)
                                            SpellDamage1HBracket := LookupRemainingAffixBracket("data\SpellDamage_1H.txt", ItemLevel, CurrValue, SpellDamageBracket, SD1HBracketLevel)
                                            MaxManaBracket := LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", SDBracketLevel, "", MMBracketLevel)
                                            ; Check if max mana can be covered fully with the partial max mana bracket from Spell Damage Max Mana 1H
                                            MaxManaBracketRem := LookupRemainingAffixBracket("data\MaxMana.txt", ItemLevel, MaxManaValue, MaxManaBracket)
                                            ValueRange := AddRange(SpellDamageBracket, SpellDamage1HBracket)
                                            ValueRange := MarkAsGuesstimate(ValueRange)
                                        }
                                        Else
                                        {
                                            ValueRange := AddRange(SpellDamageBracket, SpellDamage1HBracket)
                                            ValueRange := MarkAsGuesstimate(ValueRange)
                                        }
                                    }
                                    Else
                                    {
                                        SD1HBracketLevel := 0
                                        SpellDamageBracket := LookupAffixBracket("data\SpellDamage_MaxMana_1H.txt", ItemLevel, "", SDBracketLevel)
                                        SpellDamage1HBracket := LookupRemainingAffixBracket("data\SpellDamage_1H.txt", ItemLevel, CurrValue, SpellDamageBracket, SD1HBracketLevel)
                                        MaxManaBracket := LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", SDBracketLevel, "", MMBracketLevel)
                                        ; Check if max mana can be covered fully with the partial max mana bracket from Spell Damage Max Mana 1H
                                        MaxManaBracketRem := LookupRemainingAffixBracket("data\MaxMana.txt", ItemLevel, MaxManaValue, MaxManaBracket)
                                        ValueRange := AddRange(SpellDamageBracket, SpellDamage1HBracket)
                                        ValueRange := MarkAsGuesstimate(ValueRange)
                                    }
                                }
                                Else
                                {
                                    ShowUnhandledCaseDialog()
                                    ValueRange := StrPad("n/a", Opts.ValueRangeFieldWidth, "left")
                                }
                            }
                        }
                        Else
                        {
                            SpellDamageBracketFromComp := LookupAffixBracket("data\SpellDamage_MaxMana_1H.txt", MMBracketLevel)
                            SpellDamageBracket := LookupRemainingAffixBracket("data\SpellDamage_1H.txt", ItemLevel, CurrValue, SpellDamageBracketFromComp, SDBracketLevel)
                            ValueRange := AddRange(SpellDamageBracket, SpellDamageBracketFromComp)
                            ValueRange := MarkAsGuesstimate(ValueRange)
                        }
                    }
                    Else
                    {
                        ValueRange := LookupAffixData("data\SpellDamage_MaxMana_1H.txt", ItemLevel, CurrValue, BracketLevel, CurrTier)
                        MaxManaBracket := LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", BracketLevel)
                        AffixType := "Comp. Prefix"
                    }
                }
                ; If MaxManaValue falls within bounds of MaxManaBracket this means the max mana value is already fully accounted for
                If (WithinBounds(MaxManaBracket, MaxManaValue))
                {
                    MaxManaPartial =
                }
                Else
                {
                    MaxManaPartial := MaxManaBracket
                }
            }
            Else
            {
                If (ItemSubType == "Staff")
                {
                    ValueRange := LookupAffixData("data\SpellDamage_Staff.txt", ItemLevel, CurrValue, "", CurrTier)
                }
                Else
                {
                    ValueRange := LookupAffixData("data\SpellDamage_1H.txt", ItemLevel, CurrValue, "", CurrTier)
                }
                NumPrefixes += 1
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }
        
        ; Needs to come before maximum Mana
        IfInString, A_LoopField, increased maximum Mana
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\IncrMaximumMana.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        
        ; "Base Maximum Mana" (simple Prefix)
        ; "1H Spell Damage" / "Base Maximum Mana" (complex Prefix)
        ; "Staff Spell Damage" / "Base Maximum Mana" (complex Prefix)
        IfInString, A_LoopField, maximum Mana
        {
            AffixType := "Prefix"
            If (ItemBaseType == "Weapon")
            {
                If (HasSpellDamage)
                {
                    If (MaxManaPartial and Not WithinBounds(MaxManaPartial, CurrValue))
                    {
                        NumPrefixes += 1
                        AffixType := "Comp. Prefix+Prefix"

                        ValueRange := LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", ItemLevel, CurrValue)
                        MaxManaRest := CurrValue-RangeMid(MaxManaPartial)

                        If (MaxManaRest >= 15) ; 15 because the lowest possible value at this time for Max Mana is 15 at bracket level 1
                        {
                            ; Lookup remaining Max Mana bracket that comes from Max Mana being concatenated as simple prefix
                            ValueRange1 := LookupAffixBracket("data\MaxMana.txt", ItemLevel, MaxManaRest)
                            ValueRange2 := MaxManaPartial

                            ; Add these ranges together to get an estimated range
                            ValueRange := AddRange(ValueRange1, ValueRange2)
                            ValueRange := MarkAsGuesstimate(ValueRange)
                        }
                        Else
                        {
                            ; Could be that the spell damage affix is actually a pure spell damage affix
                            ; (w/o the added max mana) so this would mean max mana is a pure prefix - if 
                            ; NumPrefixes allows it, ofc...
                            If (NumPrefixes < 3)
                            {
                                AffixType := "Prefix"
                                ValueRange := LookupAffixData("data\MaxMana.txt", ItemLevel, CurrValue, "", CurrTier)
                                ChangeAffixDetailLine("increased Spell Damage", "Comp. Prefix", "Prefix")
                            }
                        }
                    }
                    Else
                    {
                        ; It's on a weapon, there is Spell Damage but no MaxManaPartial or NumPrefixes already is 3
                        AffixType := "Comp. Prefix"
                        ValueRange := LookupAffixBracket("data\MaxMana_SpellDamage_StaffAnd1H.txt", ItemLevel, CurrValue)
                        If (Not IsValidBracket(ValueRange))
                        {
                            ; incr. Spell Damage is actually a Prefix and not a Comp. Prefix,
                            ; so Max Mana must be a normal Prefix as well then
                            AffixType := "Prefix"
                            ValueRange := LookupAffixData("data\MaxMana.txt", ItemLevel, CurrValue, "", CurrTier)
                        }
                        Else
                        {
                            ValueRange := MarkAsGuesstimate(ValueRange)
                        }
                    }
                    ; Check if we still need to increment for the Spell Damage part
                    If (NumPrefixes < 3)
                    {
                        NumPrefixes += 1
                    }
                }
                Else
                {
                    ; It's on a weapon but there is no Spell Damage, which makes it a simple Prefix
                    Goto, SimpleMaxManaPrefix
                }
            }
            Else
            {
                ; Armour... 
                ; Max Mana cannot appear on belts but I won't exclude them for now 
                ; to future-proof against when max mana on belts might be added.
                Goto, SimpleMaxManaPrefix
            }

            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue

        SimpleMaxManaPrefix:
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\MaxMana.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Melee Physical Damage while holding a Shield
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\IncrMeleePhysDamageHoldingShield.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        IfInString, A_LoopField, increased Physical Weapon Damage while Dual Wielding
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\IncrPhysWeaponDamageDualWielding.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure increased Physical Damage
        IfInString, A_LoopField, increased Physical Damage with Axes
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\IncrPhysicalDamageWithAxes.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure increased Physical Damage
        IfInString, A_LoopField, increased Physical Damage with Bows
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\IncrPhysicalDamageWithBows.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure increased Physical Damage
        IfInString, A_LoopField, increased Physical Damage with Claws
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\IncrPhysicalDamageWithClaws.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure increased Physical Damage
        IfInString, A_LoopField, increased Physical Damage with Daggers
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\IncrPhysicalDamageWithDaggers.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure increased Physical Damage
        IfInString, A_LoopField, increased Physical Damage with Maces
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\IncrPhysicalDamage_Maces.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure increased Physical Damage
        IfInString, A_LoopField, increased Physical Damage with Staves
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\IncrPhysicalDamageWithStaves.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure increased Physical Damage
        IfInString, A_LoopField, increased Physical Damage with Swords
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\IncrPhysicalDamageWithSwords.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure increased Physical Damage
        IfInString, A_LoopField, increased Physical Damage with Two Handed Melee Weapons
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\IncrPhysicalDamage_Melee2H.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure increased Physical Damage
        IfInString, A_LoopField, increased Physical Damage with One Handed Melee Weapons
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\IncrPhysicalDamage1HMelee.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; Needs to come before pure increased Physical Damage
        IfInString, A_LoopField, increased Physical Damage with Wands
        {
            ; Only valid for Jewels at this time
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\IncrPhysicalDamageWands.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
            Continue
        }
        ; "Local Physical Damage +%" (simple Prefix) 
        ; "Local Physical Damage +%" / "Local Accuracy Rating" (complex Prefix)
        ; - on Weapons (local)and Jewels (global)
        ; - needs to come before Accuracy Rating stuff (!)
        IfInString, A_LoopField, increased Physical Damage
        {
            If (Item.IsJewel) {
                ; On jewels Increased Physical Damage is always a simple suffixes
                ; To prevent prefixes on jewels triggering the code below we handle jewels here and than continue to the next affix
                NumPrefixes += 1
                ValueRange := LookupAffixData("data\IncrPhysDamage_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue
            }
            
            AffixType := "Prefix"
            IPDPath := "data\IncrPhysDamage.txt"
            If (HasToAccuracyRating)
            {
                ARIPDPath := "data\AccuracyRating_IncrPhysDamage.txt"
                IPDARPath := "data\IncrPhysDamage_AccuracyRating.txt"
                ARValue := ExtractValueFromAffixLine(ItemDataChunk, "to Accuracy Rating")
                ARPath := "data\AccuracyRating_Global.txt"
                If (ItemBaseType == "Weapon")
                {
                    ARPath := "data\AccuracyRating_Local.txt"
                }

                ; Look up IPD bracket, and use its bracket level to cross reference the corresponding
                ; AR bracket. If both check out (are within bounds of their bracket level) case is
                ; simple: Comp. Prefix (IPD / AR)
                IPDBracketLevel := 0
                IPDBracket := LookupAffixBracket(IPDARPath, ItemLevel, CurrValue, IPDBracketLevel)
                ARBracket := LookupAffixBracket(ARIPDPath, IPDBracketLevel)
                
                If (HasIncrLightRadius)
                {
                    LRValue := ExtractValueFromAffixLine(ItemDataChunk, "increased Light Radius")
                    ; First check if the AR value that comes with the Comp. Prefix AR / Light Radius 
                    ; already covers the complete AR value. If so, from that follows that the Incr. 
                    ; Phys Damage value can only be a Damage Scaling prefix.
                    LRBracketLevel := 0
                    LRBracket := LookupAffixBracket("data\LightRadius_AccuracyRating.txt", ItemLevel, LRValue, LRBracketLevel)
                    ARLRBracket := LookupAffixBracket("data\AccuracyRating_LightRadius.txt", LRBracketLevel)
                    If (IsValidBracket(ARLRBracket))
                    {
                        If (WithinBounds(ARLRBracket, ARValue) and WithinBounds(IPDBracket, CurrValue))
                        {
                            Goto, SimpleIPDPrefix
                        }
                    }
                }

                If (IsValidBracket(IPDBracket) and IsValidBracket(ARBracket))
                {
                    Goto, CompIPDARPrefix
                }

                If (Not IsValidBracket(IPDBracket))
                {
                    IPDBracket := LookupAffixBracket(IPDPath, ItemLevel, CurrValue)
                    ARBracket := LookupAffixBracket(ARPath, ItemLevel, ARValue)  ; Also lookup AR as if it were a simple Suffix
                    ARIPDBracket := LookupAffixBracket(ARIPDPath, ItemLevel, ARValue, ARBracketLevel)

                    If (IsValidBracket(IPDBracket) and IsValidBracket(ARBracket) and NumPrefixes < 3)
                    {
                        HasIncrPhysDmg := 0
                        Goto, SimpleIPDPrefix
                    }
                    ARBracketLevel := 0
                    ARBracket := LookupAffixBracket(ARIPDPath, ItemLevel, ARValue, ARBracketLevel)
                    If (IsValidBracket(ARBracket))
                    {
                        IPDARBracket := LookupAffixBracket(IPDARPath, ARBracketLevel)
                        IPDBracket := LookupRemainingAffixBracket(IPDPath, ItemLevel, CurrValue, IPDARBracket)
                        If (IsValidBracket(IPDBracket))
                        {
                            ValueRange := AddRange(IPDARBracket, IPDBracket)
                            ValueRange := MarkAsGuesstimate(ValueRange)
                            ARAffixTypePartial := "Comp. Prefix"
                            Goto, CompIPDARPrefixPrefix
                        }
                    }
                    If (Not IsValidBracket(IPDBracket) and IsValidBracket(ARBracket))
                    {
                        If (Not WithinBounds(ARBracket, ARValue))
                        {
                            ARRest := ARValue - RangeMid(ARBracket)
                        }
                        IPDBracket := LookupRemainingAffixBracket(IPDPath, ItemLevel, CurrValue, IPDARBracket, IPDBracketLevel)
                        If (IsValidBracket(IPDBracket))
                        {
                            ValueRange := AddRange(IPDARBracket, IPDBracket)
                            ValueRange := MarkAsGuesstimate(ValueRange)
                            ARAffixTypePartial := "Comp. Prefix"
                            Goto, CompIPDARPrefixPrefix
                        }
                        Else If (IsValidBracket(IPDARBracket) and NumPrefixes < 3)
                        {
                            IPDBracket := LookupRemainingAffixBracket(IPDPath, ItemLevel, IPDRest, IPDARBracket)
                            If (IsValidBracket(IPDBracket))
                            {
                                NumPrefixes += 1
                                ValueRange := AddRange(IPDARBracket, IPDBracket)
                                ValueRange := MarkAsGuesstimate(ValueRange)
                                ARAffixTypePartial := "Comp. Prefix"
                                Goto, CompIPDARPrefixPrefix
                            }

                        }
                    }
                    If ((Not IsValidBracket(IPDBracket)) and (Not IsValidBracket(ARBracket)))
                    {
                        IPDBracket := LookupAffixBracket(IPDPath, ItemLevel, "")
                        IPDARBracket := LookupRemainingAffixBracket(IPDARPath, ItemLevel, CurrValue, IPDBracket, ARBracketLevel)
                        ARBracket := LookupAffixBracket(ARIPDPath, ARBracketLevel, "")
                        ValueRange := AddRange(IPDARBracket, IPDBracket)
                        ValueRange := MarkAsGuesstimate(ValueRange)
                        Goto, CompIPDARPrefixPrefix
                    }
                }

                If ((Not IsValidBracket(IPDBracket)) and (Not IsValidBracket(ARBracket)))
                {
                    HasIncrPhysDmg := 0
                    Goto, CompIPDARPrefixPrefix
                }

                If (IsValidBracket(ARBracket))
                {
                    ; AR bracket not found in the composite IPD/AR table
                    ARValue := ExtractValueFromAffixLine(ItemDataChunk, "to Accuracy Rating")
                    ARBracket := LookupAffixBracket(ARPath, ItemLevel, ARValue)

                    Goto, CompIPDARPrefix
                }
                If (IsValidBracket(IPDBracket))
                {
                    ; AR bracket was found in the comp. IPD/AR table, but not the IPD bracket
                    Goto, SimpleIPDPrefix
                }
                Else
                {
                    ValueRange := LookupAffixData(IPDPath, ItemLevel, CurrValue, "", CurrTier)
                }
            }
            Else
            {
                Goto, SimpleIPDPrefix
            }
            
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue

       SimpleIPDPrefix:
            NumPrefixes += 1
            ValueRange := LookupAffixData("data\IncrPhysDamage.txt", ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        CompIPDARPrefix:
            AffixType := "Comp. Prefix"
            ValueRange := LookupAffixData(IPDARPath, ItemLevel, CurrValue, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            ARPartial := ARBracket
            Continue
        CompIPDARPrefixPrefix:
            NumPrefixes += 1
            AffixType := "Comp. Prefix+Prefix"
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            ARPartial := ARBracket
            Continue
        }
        
        IfInString, A_LoopField, increased Stun Recovery
        {
            If (Item.IsJewel) {
                ; On jewels Stun Recovery is always a simple suffixes
                ; To prevent prefixes on jewels triggering the code below we handle jewels here and than continue to the next affix
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\StunRecovery_Suffix_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue
            }
            
            AffixType := "Prefix"
            If (HasHybridDefences)
            {
                AffixType := "Comp. Prefix"
                BSRecAffixPath := "data\StunRecovery_Hybrid.txt"
                BSRecAffixBracket := LookupAffixBracket(BSRecAffixPath, ItemLevel, CurrValue)
                If (Not IsValidBracket(BSRecAffixBracket))
                {
                    CompStatAffixType =
                    If (HasIncrArmourAndEvasion)
                    {
                        PartialAffixString := "increased Armour and Evasion"
                    }
                    If (HasIncrEvasionAndES) 
                    {
                        PartialAffixString := "increased Evasion and Energy Shield"
                    }
                    If (HasIncrArmourAndES)
                    {
                        PartialAffixString := "increased Armour and Energy Shield"
                    }
                    CompStatAffixType := GetAffixTypeFromProcessedLine(PartialAffixString)
                    If (BSRecPartial)
                    {
                        If (WithinBounds(BSRecPartial, CurrValue))
                        {
                            IfInString, CompStatAffixType, Comp. Prefix
                            {
                                AffixType := CompStatAffixType
                            }
                        }
                        Else
                        {
                            If (NumSuffixes < 3)
                            {
                                AffixType := "Comp. Prefix+Suffix"
                                BSRecAffixBracket := LookupRemainingAffixBracket("data\StunRecovery_Suffix.txt", ItemLevel, CurrValue, BSRecPartial)
                                If (Not IsValidBracket(BSRecAffixBracket))
                                {
                                    AffixType := "Comp. Prefix+Prefix"
                                    BSRecAffixBracket := LookupAffixBracket("data\StunRecovery_Prefix.txt", ItemLevel, CurrValue)
                                    If (Not IsValidBracket(BSRecAffixBracket))
                                    {
                                        If (CompStatAffixType == "Comp. Prefix+Prefix" and NumSuffixes < 3)
                                        {
                                            AffixType := "Comp. Prefix+Suffix"
                                            BSRecSuffixBracket := LookupAffixBracket("data\StunRecovery_Suffix.txt", ItemLevel, BSRest)
                                            NumSuffixes += 1
                                            If (Not IsValidBracket(BSRecSuffixBracket))
                                            {
                                                ; TODO: properly deal with this quick fix!
                                                ;
                                                ; if this point is reached this means that the parts that give to 
                                                ; increased armor/evasion/es/hybrid + stun recovery need to fully be
                                                ; re-evaluated.
                                                ;
                                                ; take an ilvl 62 item with these 2 lines:
                                                ;
                                                ;   118% increased Armour and Evasion
                                                ;   24% increased Stun Recovery
                                                ;
                                                ; Since it's ilvl 62, we assume the hybrid + stun recovery bracket to be the
                                                ; highest possible (lvl 60 bracket), which is 42-50. So that's max 50 of the 
                                                ; 118 dealth with.
                                                ; Consequently, that puts the stun recovery partial at 14-15 for the lvl 60 bracket.
                                                ; This now leaves, 68 of hybrid defence to account for, which we can do by assuming
                                                ; the remainder to come from a hybrid defence prefix. So that's incr. Armour and Evasion
                                                ; identified as CP+P
                                                ; However, here come's the problem, our lvl 60 bracket had 14-15 stun recovery which
                                                ; assuming max, leaves 9 remainder (24-15) to account for. Should be easy, right?
                                                ; Just assume the rest comes from a stun recovery suffix and look it up. Except the
                                                ; lowest possible entry for a stun recovery suffix is 11! Leaving us with the issues that
                                                ; we know that CP+P is right for the hybrid + stun recovery line and CP+S is right for the
                                                ; stun recovery line. 
                                                ; Most likely, what is wrong is the assumption earlier to take the highest possible
                                                ; hybrid + stun recovery bracket. Problem is that wasn't apparent when hybrid defences
                                                ; was processed.
                                                ; At this point, a quick fix what I am doing is I just look up the complete stun recovery
                                                ; value as if it were a suffix completely but still mark it as CP+S.
                                                ; To deal with this correctly I would need to reprocess the hybrid + stun recovery line here
                                                ; with a different ratio of the CP part to the P part to get a lower BSRecPartial.
                                                ;
                                                BSRecSuffixBracket := LookupAffixBracket("data\StunRecovery_Suffix.txt", ItemLevel, CurrValue)
                                                ValueRange := LookupAffixBracket("data\StunRecovery_Suffix.txt", ItemLevel, CurrValue)
                                                ValueRange := MarkAsGuesstimate(ValueRange)
                                            }
                                            Else
                                            {
                                                ValueRange := AddRange(BSRecSuffixBracket, BSRecPartial)
                                                ValueRange := MarkAsGuesstimate(ValueRange)
                                            }
                                        } 
                                        Else
                                        {
                                            AffixType := "Suffix"
                                            ValueRange := LookupAffixData("data\StunRecovery_Suffix.txt", ItemLevel, CurrValue, "", CurrTier)
                                            If (NumSuffixes < 3)
                                            {
                                                NumSuffixes += 1
                                            }
                                            ChangeAffixDetailLine(PartialAffixString, "Comp. Prefix" , "Prefix")
                                        }
                                    }
                                    Else
                                    {
                                        If (NumPrefixes < 3)
                                        {
                                            NumPrefixes += 1
                                        }
                                    }
                                }
                                Else
                                {
                                    NumSuffixes += 1
                                    ValueRange := AddRange(BSRecPartial, BSRecAffixBracket)
                                    ValueRange := MarkAsGuesstimate(ValueRange)
                                }
                            }
                        }
                    }
                    Else
                    {
                        ; Simple Stun Rec suffix
                        AffixType := "Suffix"
                        ValueRange := LookupAffixData("data\StunRecovery_Suffix.txt", ItemLevel, CurrValue, "", CurrTier)
                        NumSuffixes += 1
                    }
                }
                Else
                {
                    ValueRange := LookupAffixData(BSRecAffixPath, ItemLevel, CurrValue, "", CurrTier)
                }
            }
            Else
            {
                AffixType := "Comp. Prefix"
                If (HasIncrArmour)
                {
                    PartialAffixString := "increased Armour"
                    BSRecAffixPath := "data\StunRecovery_Armour.txt"
                }
                If (HasIncrEvasion) 
                {
                    PartialAffixString := "increased Evasion Rating"
                    BSRecAffixPath := "data\StunRecovery_Evasion.txt"
                }
                If (HasIncrEnergyShield)
                {
                    PartialAffixString := "increased Energy Shield"
                    BSRecAffixPath := "data\StunRecovery_EnergyShield.txt"
                }
                BSRecAffixBracket := LookupAffixBracket(BSRecAffixPath, ItemLevel, CurrValue)
                If (Not IsValidBracket(BSRecAffixBracket))
                {
                    CompStatAffixType := GetAffixTypeFromProcessedLine(PartialAffixString)
                    If (BSRecPartial)
                    {
                        If (WithinBounds(BSRecPartial, CurrValue))
                        {
                            IfInString, CompStatAffixType, Comp. Prefix
                            {
                                AffixType := CompStatAffixType
                            }
                        }
                        Else
                        {
                            If (NumSuffixes < 3)
                            {
                                AffixType := "Comp. Prefix+Suffix"
                                BSRecAffixBracket := LookupRemainingAffixBracket("data\StunRecovery_Suffix.txt", ItemLevel, CurrValue, BSRecPartial)
                                If (Not IsValidBracket(BSRecAffixBracket))
                                {
                                    AffixType := "Comp. Prefix+Prefix"
                                    BSRecAffixBracket := LookupAffixBracket("data\StunRecovery_Prefix.txt", ItemLevel, CurrValue)
                                    If (Not IsValidBracket(BSRecAffixBracket))
                                    {
                                        AffixType := "Suffix"
                                        ValueRange := LookupAffixData("data\StunRecovery_Suffix.txt", ItemLevel, CurrValue, "", CurrTier)
                                        If (NumSuffixes < 3)
                                        {
                                            NumSuffixes += 1
                                        }
                                        ChangeAffixDetailLine(PartialAffixString, "Comp. Prefix" , "Prefix")
                                    }
                                    Else
                                    {
                                        If (NumPrefixes < 3)
                                        {
                                            NumPrefixes += 1
                                        }
                                    }

                                } 
                                Else
                                {
                                    NumSuffixes += 1
                                    ValueRange := AddRange(BSRecPartial, BSRecAffixBracket)
                                    ValueRange := MarkAsGuesstimate(ValueRange)
                                }
                            }
                        }
                    }
                    Else
                    {
                        BSRecSuffixPath := "data\StunRecovery_Suffix.txt"
                        BSRecSuffixBracket := LookupAffixBracket(BSRecSuffixPath, ItemLevel, CurrValue)
                        If (IsValidBracket(BSRecSuffixBracket))
                        {
                            AffixType := "Suffix"
                            ValueRange := LookupAffixData(BSRecSuffixPath, ItemLevel, CurrValue, "", CurrTier)
                            If (NumSuffixes < 3)
                            {
                                NumSuffixes += 1
                            }
                        }
                        Else
                        {
                            BSRecPrefixPath := "data\StunRecovery_Prefix.txt"
                            BSRecPrefixBracket := LookupAffixBracket(BSRecPrefixPath, ItemLevel, CurrValue)
                            ValueRange := LookupAffixData(BSRecPrefixPath, ItemLevel, CurrValue, "", CurrTier)
                        }
                    }
                }
                Else
                {
                    ValueRange := LookupAffixData(BSRecAffixPath, ItemLevel, CurrValue, "", CurrTier)
                }
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }
        
        ; AR is one tough beast... currently there are the following affixes affecting AR:
        ;   1) "Accuracy Rating" (Suffix)
        ;   2) "Local Accuracy Rating" (Suffix)
        ;   3) "Light Radius / + Accuracy Rating" (Suffix) - only the first 2 entries, bc last entry combines LR with #% increased Accuracy Rating instead!
        ;   4) "Local Physical Dmg +% / Local Accuracy Rating" (Prefix)

        ; The difficulty lies in those cases that combine multiples of these affixes into one final display value.
        ; Currently I try and tackle this by using a trickle-through partial balance approach. That is, go from
        ; most special case to most normal, while subtracting the value that each case most likely contributes
        ; until you have a value left that can be found in the most nominal case.
        ;
        ; Important to note here: 
        ;   ARPartial will be set during the "increased Physical Damage" case above
        
        IfInString, A_LoopField, to Accuracy Rating
        {
            ; Trickle-through order:
            ;   1) increased AR, Light Radius, all except Belts, Comp. Suffix
            ;   2) to AR, Light Radius, all except Belts, Comp. Suffix
            ;   3) increased Phys Damage, to AR, Weapons, Prefix
            ;   4) to AR, all except Belts, Suffix

            ValueRangeAR := "0-0"
            AffixType := ""
            IPDAffixType := GetAffixTypeFromProcessedLine("increased Physical Damage")
            If (HasIncrLightRadius and Not HasIncrAccuracyRating) 
            {
                ; "of Shining" and "of Light"
                LightRadiusValue := ExtractValueFromAffixLine(ItemDataChunk, "increased Light Radius")
                
                ; Get bracket level of the light radius so we can look up the corresponding AR bracket
                BracketLevel := 0
                LookupAffixBracket("data\LightRadius_AccuracyRating.txt", ItemLevel, LightRadiusValue, BracketLevel)
                ARLRBracket := LookupAffixBracket("data\AccuracyRating_LightRadius.txt", BracketLevel)

                AffixType := AffixType . "Comp. Suffix"
                ValueRange := LookupAffixData("data\AccuracyRating_LightRadius.txt", ItemLevel, CurrValue, "", CurrTier)
                NumSuffixes += 1

                If (ARPartial)
                {
                    ; Append this affix' contribution to our partial AR range
                    ARPartial := AddRange(ARPartial, ARLRBracket)
                }
                ; Test if candidate range already covers current  AR value
                If (WithinBounds(ARLRBracket, CurrValue))
                {
                    Goto, FinalizeAR
                }
                Else
                {
                    AffixType := "Comp. Suffix+Suffix"
                    If (HasIncrPhysDmg)
                    {
                        If (ARPartial)
                        {
                            CombinedRange := AddRange(ARLRBracket, ARPartial)
                            AffixType := "Comp. Prefix+Comp. Suffix"
                            
                            If (WithinBounds(CombinedRange, CurrValue))
                            {
                                If (NumPrefixes < 3)
                                {
                                    NumPrefixes += 1
                                }
                                ValueRange := CombinedRange
                                ValueRange := MarkAsGuesstimate(ValueRange)
                                Goto, FinalizeAR
                            }
                            Else
                            {
                                NumSuffixes -= 1
                            }
                        }

                        If (InStr(IPDAffixType, "Comp. Prefix"))
                        {
;                            AffixType := "Comp. Prefix+Comp. Suffix+Suffix"
                            If (NumPrefixes < 3)
                            {
                                NumPrefixes += 1
                            }
                        }
                    }
                    ARBracket := LookupRemainingAffixBracket("data\AccuracyRating_Global.txt", ItemLevel, CurrValue, ARLRBracket)
                    ValueRange := AddRange(ARBracket, ARLRBracket)
                    ValueRange := MarkAsGuesstimate(ValueRange)
                    NumSuffixes += 1
                    Goto, FinalizeAR
                }
            }
            If (ItemBaseType == "Weapon" and HasIncrPhysDmg)
            {
                ; This is one of the trickiest cases currently (EDIT: nope, I have seen trickier stuff still ;D)
                ;
                ; If this If-construct is reached that means the item has multiple composites:
                ;   "To Accuracy Rating / Increased Light Radius" and 
                ;   "Increased Physical Damage / To Accuracy Rating". 
                ; 
                ; On top of that it might also contain part "To Accuracy Rating" suffix, all of which are 
                ; concatenated into one single "to Accuracy Rating" entry. 
                ; Currently it handles most cases, if not all, but I still have a feeling I am missing 
                ; something... (EDIT: a feeling I won't be able to shake ever with master crafted affixes now)
                ;
                ; GGG, if you are reading this: please add special markup for affix compositions!
                ;
                If (ARPartial)
                {
                    If (WithinBounds(ARPartial, CurrValue))
                    {
                        AffixType := "Comp. Prefix"
                        If (NumPrefixes < 3)
                        {
                            NumPrefixes += 1
                        }
                        ValueRange := LookupAffixData("data\AccuracyRating_IncrPhysDamage.txt", ItemLevel, RangeMid(ARPartial), "", CurrTier)
                        Goto, FinalizeAR
                    }

                    ARPartialMid := RangeMid(ARPartial)
                    ARRest := CurrValue - ARPartialMid
                    If (ItemSubType == "Mace" and ItemGripType == "2H")
                    {
                        ARBracket := LookupAffixBracket("data\AccuracyRating_Global.txt", ItemLevel, ARRest)
                    }
                    Else
                    {
                        ARBracket := LookupAffixBracket("data\AccuracyRating_Local.txt", ItemLevel, ARRest)
                    }
                    
                    If (IsValidBracket(ARBracket))
                    {
                        AffixType := "Comp. Prefix+Suffix"
                        If (NumSuffixes < 3) 
                        {
                            NumSuffixes += 1
                        }
                        Else
                        {
                            AffixType := "Comp. Prefix"
                            If (NumPrefixes < 3)
                            {
                                NumPrefixes += 2
                            }
                        }
                        NumPrefixes += 1
                        ValueRange := AddRange(ARBracket, ARPartial)
                        ValueRange := MarkAsGuesstimate(ValueRange)

                        Goto, FinalizeAR
                    }
                }
                Else
                {
                    ActualValue := CurrValue
                }

                ValueRangeAR := LookupAffixBracket("data\AccuracyRating_Global.txt", ItemLevel, ActualValue)
                If (IsValidBracket(ValueRangeAR))
                {
                    If (NumPrefixes >= 3)
                    {
                        AffixType := "Suffix"
                        If (NumSuffixes < 3)
                        {
                            NumSuffixes += 1
                        }
                        ValueRange := LookupAffixData("data\AccuracyRating_Local.txt", ItemLevel, ActualValue, "", CurrTier)
                    }
                    Else
                    {
                        IfInString, IPDAffixType, Comp. Prefix
                        {
                            AffixType := "Comp. Prefix"
                        }
                        Else
                        {
                            AffixType := "Prefix"
                        }
                        NumPrefixes += 1
                    }
                    Goto, FinalizeAR
                }
                Else
                {
                    ARValueRest := CurrValue - (RangeMid(ValueRangeAR))
                    If (HasIncrLightRadius and Not HasIncrAccuracyRating)
                    {
                        AffixType := "Comp. Prefix+Comp. Suffix+Suffix"
                    }
                    Else
                    {
                        AffixType := "Comp. Prefix+Suffix"
                    }
                    NumPrefixes += 1
                    NumSuffixes += 1
                    ;~ ValueRange := LookupAffixData("data\AccuracyRating_IncrPhysDamage.txt", ItemLevel, CurrValue, "", CurrTier)
                    ValueRange := AddRange(ARPartial, ValueRangeAR)
                    ValueRange := MarkAsGuesstimate(ValueRange)
                }
                ; NumPrefixes should be incremented already by "increased Physical Damage" case
                Goto, FinalizeAR
            }
            AffixType := "Suffix"
            ValueRange := LookupAffixData("data\AccuracyRating_Global.txt", ItemLevel, CurrValue, "", CurrTier)
            NumSuffixes += 1
            Goto, FinalizeAR

        FinalizeAR:
            If (StrLen(ARAffixTypePartial) > 0 and (Not InStr(AffixType, ARAffixTypePartial)))
            {
                AffixType := ARAffixTypePartial . "+" . AffixType
                If (InStr(ARAffixTypePartial, "Prefix") and NumPrefixes < 3)
                {
                    NumPrefixes += 1
                }
                Else If (InStr(ARAffixTypePartial, "Suffix") and NumSuffixes < 3)
                {
                    NumSuffixes += 1
                }
                ARAffixTypePartial =
            }
            AppendAffixInfo(MakeAffixDetailLine(A_LoopField, AffixType, ValueRange, CurrTier), A_Index)
            Continue
        }

        IfInString, A_LoopField, increased Rarity
        {
            ; Jewels have rarity only as a Suffix
            If (Item.IsJewel) {
                Goto, FinalizeIIRAsSuffix
            }
            ActualValue := CurrValue
            If (NumSuffixes <= 3)
            {
                ValueRange := LookupAffixBracket("data\IIR_Suffix.txt", ItemLevel, ActualValue)
                ValueRangeAlt := LookupAffixBracket("data\IIR_Prefix.txt", ItemLevel, ActualValue)
            }
            Else
            {
                ValueRange := LookupAffixBracket("data\IIR_Prefix.txt", ItemLevel, ActualValue)
                ValueRangeAlt := LookupAffixBracket("data\IIR_Suffix.txt", ItemLevel, ActualValue)
            }
            If (Not IsValidBracket(ValueRange))
            {
                If (Not IsValidBracket(ValueRangeAlt))
                {
                    NumPrefixes += 1
                    NumSuffixes += 1
                    ; Try to reverse engineer composition of both ranges
                    PrefixDivisor := 1
                    SuffixDivisor := 1
                    Loop
                    {
                        ValueRangeSuffix := LookupAffixBracket("data\IIR_Suffix.txt", ItemLevel, Floor(ActualValue/SuffixDivisor))
                        ValueRangePrefix := LookupAffixBracket("data\IIR_Prefix.txt", ItemLevel, Floor(ActualValue/PrefixDivisor))
                        If (Not IsValidBracket(ValueRangeSuffix))
                        {
                            SuffixDivisor += 0.25
                        }
                        If (Not IsValidBracket(ValueRangePrefix))
                        {
                            PrefixDivisor += 0.25
                        }
                        If ((IsValidBracket(ValueRangeSuffix)) and (IsValidBracket(ValueRangePrefix)))
                        {
                            Break
                        }
                    }
                    ValueRange := AddRange(ValueRangePrefix, ValueRangeSuffix)
                    Goto, FinalizeIIRAsPrefixAndSuffix
                }
                Else
                {
                    ValueRange := ValueRangePrefix
                    Goto, FinalizeIIRAsPrefix
                }
            }
            Else
            {
                If (NumSuffixes >= 3) {
                    Goto, FinalizeIIRAsPrefix
                }
                Goto, FinalizeIIRAsSuffix
            }

            FinalizeIIRAsPrefix:
                ; Slinkston edit
    If (ItemSubType == "Ring" or ItemSubType == "Amulet")
    {
        ValueRange := LookupAffixData("data\IIR_PrefixRingAndAmulet.txt", ItemLevel, ActualValue, "", CurrTier)
    }
        Else
        {
      ValueRange := LookupAffixData("data\IIR_Prefix.txt", ItemLevel, ActualValue, "", CurrTier)
        }
                NumPrefixes += 1
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix", ValueRange, CurrTier), A_Index)
                Continue

            FinalizeIIRAsSuffix:
                NumSuffixes += 1
                If (Item.IsJewel) {
                    ValueRange := LookupAffixData("data\IIR_Suffix_Jewels.txt", ItemLevel, CurrValue, "", CurrTier)
                } Else {
                    ValueRange := LookupAffixData("data\IIR_Suffix.txt", ItemLevel, ActualValue, "", CurrTier)
                }
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Suffix", ValueRange, CurrTier), A_Index)
                Continue

            FinalizeIIRAsPrefixAndSuffix:
                ValueRange := MarkAsGuesstimate(ValueRange)
                AppendAffixInfo(MakeAffixDetailLine(A_LoopField, "Prefix+Suffix", ValueRange, CurrTier), A_Index)
                Continue
        }
    }
    
    ; --- CRAFTED --- (Preliminary Support)
    
    Loop, Parse, ItemDataChunk, `n, `r
    {    
        If StrLen(A_LoopField) = 0
        {
            Break ; Not interested in blank lines
        }
        IfInString, ItemDataChunk, Unidentified
        {
            Break ; Not interested in unidentified items
        }
                
        IfInString, A_LoopField, Can have multiple Crafted Mods
        {
            AppendAffixInfo(A_Loopfield, A_Index)
        }
        IfInString, A_LoopField, to Weapon range
        {
            AppendAffixInfo(A_Loopfield, A_Index)
        }
    }
    
    ; --- COMPLEX AFFIXES JEWELS ---
    ; The plan was to use a recursive function to test all possible combinations in a way that could be easily adapted for any complex affix. 
    ; Unfortunately AutoHotkey doesn't like combining recursive functions and ByRef.  
    ; https://autohotkey.com/board/topic/70635-byref-limitation/
    ; Until this problem in AutoHotkey is solved or an alternative, universal, method is found the code below handles accuracy/crit chance on jewels only.
    If (Item.SubType == "Viridian Jewel" and (CAIncAccuracy or CAGlobalCritChance)) {
        If (CAIncAccuracy and CAGlobalCritChance) {
            If (Item.Rarity == 2 or NumSuffixes == 1) {
                ; On jewels with another suffix already or jewels that can only have 1 suffix (magic items) that single suffix must be the combined one
                NumSuffixes += 1
                ValueRange := LookupAffixData("data\CritChanceGlobal_Jewels_Acc.txt", ItemLevel, CAGlobalCritChance, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(CAGlobalCritChanceAffixLine, "Comp. Suffix", ValueRange, CurrTier), CAGlobalCritChanceAffixLineNo)
                NextAffixPos += 1
                ValueRange := LookupAffixData("data\IncrAccuracyRating_Jewels_Crit.txt", ItemLevel, CAIncAccuracy, "", CurrTier)
                AppendAffixInfo(MakeAffixDetailLine(CAIncAccuracyAffixLine, "Comp. Suffix", ValueRange, CurrTier), CAIncAccuracyAffixLineNo)
            } Else {
                ; Item has both increased accuracy and global crit chance and can have 2 suffixes: complex affix possible
                
                has_combined_acc_crit := 0
                
                If (CAIncAccuracy >= 6 and CAIncAccuracy <= 9) {
                    ; Accuracy is the result of the combined accuracy/crit_chance affix
                    has_combined_acc_crit := 1
                    NumSuffixes += 1
                    ValueRange := "   6-10    6-10"
                    AffixType := "Comp. Suffix"
                } Else If (CAIncAccuracy = 10) {
                    ; IncAccuracy can be either the combined affix or pure accuracy
                    If ((CAGlobalCritChance >= 6 and CAGlobalCritChance <= 7) or (CAGlobalCritChance >= 14)) {
                        ; Because the global crit chance is only possible with the combined affix the accuracy has to be the result of that
                        has_combined_acc_crit := 1
                        ValueRange := "   6-10    6-10"
                        AffixType := "Comp. Suffix"
                    } Else If (CAGlobalCritChance >= 11 and CAGlobalCritChance <= 12) {
                        ; Global crit chance can only be the pure affix, this means accuracy can't be the combined affix
                        ValueRange := "  10-14   10-14"
                        AffixType := "Suffix"
                    } Else {
                        ValueRange := "   6-14    6-14"
                        AffixType := "Comp. Suffix"
                        ; TODO: fix handling unknown number of affixes
                    }
                    NumSuffixes += 1
                } Else If (CAIncAccuracy >= 11 and CAIncAccuracy <= 14) {
                    ; Increased accuracy can only be the pure accuracy roll
                    NumSuffixes += 1
                    ValueRange := "  10-14   10-14"
                    AffixType := "Suffix"
                } Else If (CAIncAccuracy >= 16) {
                    ; Increased accuracy can only be a combination of the complex and pure affixes
                    has_combined_acc_crit := 1
                    NumSuffixes += 2
                    ValueRange := "  16-24   16-24"
                    AffixType := "Comp. Suffix"
                }
                
                AppendAffixInfo(MakeAffixDetailLine(CAIncAccuracyAffixLine, AffixType, ValueRange, 1), CAIncAccuracyAffixLineNo)
                NextAffixPos += 1
                
                If (CAGlobalCritChance >= 6 and CAGlobalCritChance <= 7) {
                    ; Crit chance is the result of the combined accuracy/crit_chance affix
                    ; don't update suffix count, should this should have already been done during Inc Accuracy detection
                    ; NumSuffixes += 1
                    ValueRange := "   6-10    6-10"
                    AffixType := "Comp. Suffix"
                } Else If (CAGlobalCritChance >= 8 and CAGlobalCritChance <= 10) {
                    ; Crit chance can be either the combined affix or pure crit chance
                    If ((CAIncAccuracy >= 6 and CAIncAccuracy <= 9) or (CAIncAccuracy >= 16)) {
                        ; Because the inc accuracy is only possible with the combined affix the global crit chance also has to be the result of that
                        ; don't update suffix count, should this should have already been done during Inc Accuracy detection
                        ; NumSuffixes += 1
                        ValueRange := "   6-10    6-10"
                        AffixType := "Comp. Suffix"
                    } Else If (CAIncAccuracy >= 11 and CAIncAccuracy <= 14) {
                        ; Inc Accuracy can only be the pure affix, this means global crit chance can't be the combined affix
                        NumSuffixes += 1
                        ValueRange := "   8-12    8-12"
                        AffixType := "Suffix"
                    } Else {
                        ; TODO: fix handling unknown number of affixes
                        ValueRange := "   6-12    6-12"
                        AffixType := "Comp. Suffix"
                    }
                    NumSuffixes += 1
                } Else If (CAGlobalCritChance >= 11 and CAGlobalCritChance <= 12) {
                    ; Crit chance can only be the pure crit chance roll
                    NumSuffixes += 1
                    ValueRange := "   8-12    8-12"
                    AffixType := "Suffix"
                } Else If (CAGlobalCritChance >= 14) {
                    ; Crit chance can only be a combination of the complex and pure affixes
                    NumSuffixes += 1
                    ValueRange := "  14-22   14-22"
                    AffixType := "Comp. Suffix"
                }
                
                AppendAffixInfo(MakeAffixDetailLine(CAGlobalCritChanceAffixLine, AffixType, ValueRange, 1), CAGlobalCritChanceAffixLineNo)
                NextAffixPos += 1
            }
        } Else If (CAGlobalCritChance) {
            ; The item only has a global crit chance affix so it isn't complex
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\CritChanceGlobal_Jewels.txt", ItemLevel, CAGlobalCritChance, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(CAGlobalCritChanceAffixLine, "Suffix", ValueRange, CurrTier), CAGlobalCritChanceAffixLineNo)
            NextAffixPos += 1
        } Else {
            ; The item only has an increased accuracy affix so it isn't complex
            NumSuffixes += 1
            ValueRange := LookupAffixData("data\IncrAccuracyRating_Jewels.txt", ItemLevel, CAIncAccuracy, "", CurrTier)
            AppendAffixInfo(MakeAffixDetailLine(CAIncAccuracyAffixLine, "Suffix", ValueRange, CurrTier), CAIncAccuracyAffixLineNo)
            NextAffixPos += 1
        }
    }
    
    AffixTotals.NumPrefixes := NumPrefixes
    AffixTotals.NumSuffixes := NumSuffixes
}