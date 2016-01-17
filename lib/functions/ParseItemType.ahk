ParseItemType(ItemDataStats, ItemDataNamePlate, ByRef BaseType, ByRef SubType, ByRef GripType)
{
    ; Grip type only matters for weapons at this point. For all others it will be 'None'.
    GripType = None

    ; Check stats section first as weapons usually have their sub type as first line
    Loop, Parse, ItemDataStats, `n, `r
    {
        IfInString, A_LoopField, One Handed Axe
        {
            BaseType = Weapon
            SubType = Axe
            GripType = 1H
            return
        }
        IfInString, A_LoopField, Two Handed Axe
        {
            BaseType = Weapon
            SubType = Axe
            GripType = 2H
            return
        }
        IfInString, A_LoopField, One Handed Mace
        {
            BaseType = Weapon
            SubType = Mace
            GripType = 1H
            return
        }
        IfInString, A_LoopField, Two Handed Mace
        {
            BaseType = Weapon
            SubType = Mace
            GripType = 2H
            return
        }
        IfInString, A_LoopField, Sceptre
        {
            BaseType = Weapon
            SubType = Sceptre
            GripType = 1H
            return
        }
        IfInString, A_LoopField, Staff
        {
            BaseType = Weapon
            SubType = Staff
            GripType = 2H
            return
        }
        IfInString, A_LoopField, One Handed Sword
        {
            BaseType = Weapon
            SubType = Sword
            GripType = 1H
            return
        }
        IfInString, A_LoopField, Two Handed Sword
        {
            BaseType = Weapon
            SubType = Sword
            GripType = 2H
            return
        }
        IfInString, A_LoopField, Dagger
        {
            BaseType = Weapon
            SubType = Dagger
            GripType = 1H
            return
        }
        IfInString, A_LoopField, Claw
        {
            BaseType = Weapon
            SubType = Claw
            GripType = 1H
            return
        }
        IfInString, A_LoopField, Bow
        {
            ; Not really sure if I should classify bow as 2H (because that would make sense)
            ; but you can equip a quiver in 2nd hand slot, so it could be 1H?
            BaseType = Weapon
            SubType = Bow
            GripType = 1H
            return
        }
        IfInString, A_LoopField, Wand
        {
            BaseType = Weapon
            SubType = Wand
            GripType = 1H
            return
        }
    }

    ; Check name plate section 
    Loop, Parse, ItemDataNamePlate, `n, `r
    {
        ; a few cases that cause incorrect id later
        ; and thus should come first
        ; Note: still need to work on proper id for 
        ; all armour types.
        IfInString, A_LoopField, Ringmail Gloves
        {
            BaseType = Armour
            SubType = Gloves
            return
        }
        IfInString, A_LoopField, Ringmail Boots
        {
            BaseType = Armour
            SubType = Gloves
            return
        }
        If (RegExMatch(A_LoopField, "Ringmail$"))
        {
            BaseType = Armour
            SubType = BodyArmour
            return
        }
        IfInString, A_LoopField, Mantle
        {
            BaseType = Armour
            SubType = BodyArmour
            return
        }
        IfInString, A_LoopField, Shell
        {
            BaseType = Armour
            SubType = BodyArmour
            return
        }
        
        ; Belts, Amulets, Rings, Quivers, Flasks
        IfInString, A_LoopField, Rustic Sash
        {
            BaseType = Item
            SubType = Belt
            return
        }
        IfInString, A_LoopField, Belt
        {
            BaseType = Item
            SubType = Belt
            return
        }
        If (InStr(A_LoopField, "Amulet") or InStr(A_LoopField, "Talisman"))
        {
            BaseType = Item
            SubType = Amulet
            return
        }
        
        If(RegExMatch(A_LoopField, "\bRing\b"))
        {
            BaseType = Item
            SubType = Ring
            return
        }
        IfInString, A_LoopField, Quiver
        {
            BaseType = Item
            SubType = Quiver
            return
        }
        IfInString, A_LoopField, Flask
        {
            BaseType = Item
            SubType = Flask
            return
        }
        IfInString, A_LoopField, %A_Space%Map
        {
            Global matchList
            BaseType = Map      
            Loop % matchList.MaxIndex()
            {
                Match := matchList[A_Index]
                IfInString, A_LoopField, %Match%
                {
                    SubType = %Match%
                    return
                }
            }
            
            SubType = Unknown%A_Space%Map
            return
        }
        ; Dry Peninsula fix
        IfInString, A_LoopField, Dry%A_Space%Peninsula
        {
            BaseType = Map
            SubType = Dry%A_Space%Peninsula
            return
        }       
    
    ; Jewels
    IfInString, A_LoopField, Cobalt%A_Space%Jewel
        {
            BaseType = Jewel
            SubType = Cobalt Jewel
            return
        }
    IfInString, A_LoopField, Crimson%A_Space%Jewel
        {
            BaseType = Jewel
            SubType = Crimson Jewel
            return
        }
    IfInString, A_LoopField, Viridian%A_Space%Jewel
        {
            BaseType = Jewel
            SubType = Viridian Jewel
            return
        }
    
        ; Shields 
        IfInString, A_LoopField, Shield
        {
            BaseType = Armour
            SubType = Shield
            return
        }
        IfInString, A_LoopField, Buckler
        {
            BaseType = Armour
            SubType = Shield
            return
        }
        IfInString, A_LoopField, Bundle
        {
            BaseType = Armour
            SubType = Shield
            return
        }
        IfInString, A_LoopField, Gloves
        {
            BaseType = Armour
            SubType = Gloves
            return
        }
        IfInString, A_LoopField, Mitts
        {
            BaseType = Armour
            SubType = Gloves
            return
        }
        IfInString, A_LoopField, Gauntlets
        {
            BaseType = Armour
            SubType = Gloves
            return
        }

        ; Helmets
        IfInString, A_LoopField, Helmet
        {
            BaseType = Armour
            SubType = Helmet
            return
        }
        IfInString, A_LoopField, Helm
        {
            BaseType = Armour
            SubType = Helmet
            return
        }
        If (InStr(A_LoopField, "Hat") and (Not InStr(A_LoopField, "Hate")))
        {
            BaseType = Armour
            SubType = Helmet
            return
        }
        IfInString, A_LoopField, Mask
        {
            BaseType = Armour
            SubType = Helmet
            return
        }
        IfInString, A_LoopField, Hood
        {
            BaseType = Armour
            SubType = Helmet
            return
        }
        IfInString, A_LoopField, Ursine Pelt
        {
            BaseType = Armour
            SubType = Helmet
            return
        }
        IfInString, A_LoopField, Lion Pelt
        {
            BaseType = Armour
            SubType = Helmet
            return
        }
        IfInString, A_LoopField, Circlet
        {
            BaseType = Armour
            SubType = Helmet
            return
        }
        IfInString, A_LoopField, Sallet
        {
            BaseType = Armour
            SubType = Helmet
            return
        }
        IfInString, A_LoopField, Burgonet
        {
            BaseType = Armour
            SubType = Helmet
            return
        }
        IfInString, A_LoopField, Bascinet
        {
            BaseType = Armour
            SubType = Helmet
            return
        }
        IfInString, A_LoopField, Crown
        {
            BaseType = Armour
            SubType = Helmet
            return
        }
        IfInString, A_LoopField, Cage
        {
            BaseType = Armour
            SubType = Helmet
            return
        }
        IfInString, A_LoopField, Tricorne
        {
            BaseType = Armour
            SubType = Helmet
            return
        }
        
        ; Boots
        IfInString, A_LoopField, Boots
        {
            BaseType = Armour
            SubType = Boots
            return
        }
        IfInString, A_LoopField, Greaves
        {
            BaseType = Armour
            SubType = Boots
            return
        }   
        IfInString, A_LoopField, Slippers
        {
            BaseType = Armour
            SubType = Boots
            return
        }                   
    }

    ; TODO: need a reliable way to determine sub type for armour
    ; right now it's just determine anything else first if it's
    ; not that, it's armour.
    BaseType = Armour
    SubType = Armour
}