; Instead of polluting the default namespace with Globals, create our own Globals "namespace".
class Globals {
    
    Set(name, value) {
        Globals[name] := value
    }
    
    Get(name, value_default="") {
        result := Globals[name]
        If (result == "") {
            result := value_default
        }
        return result
    }
}
Globals.Set("AHKVersionRequired", AHKVersionRequired)
Globals.Set("ReleaseVersion", ReleaseVersion)
Globals.Set("DataDir", A_ScriptDir . "\data")
