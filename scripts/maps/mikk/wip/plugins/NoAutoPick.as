/*

// INSTALLATION:

    "plugin"
    {
        "name" "NoAutoPick"
        "script" "../maps/mikk/plugins/NoAutoPick"
    }
    
// OR as a map_script

#include "mikk/plugins/NoAutoPick"

*/
#include "../utils"
void PluginInit()
{
    g_Module.ScriptInfo.SetAuthor( "Mikk" );
    g_Module.ScriptInfo.SetContactInfo( g_Util.GetDiscord() );
}

CScheduledFunction@ g_Think = g_Scheduler.SetInterval( "NoAutoPick", 0.5f, g_Scheduler.REPEAT_INFINITE_TIMES );

array<string> Items = { "weapon_*", "item_healthkit", "item_battery", "weaponbox", "ammo_*" };

enum NoAutoPick_spawnflags
{
    TOUCH_ONLY = 128,
    USE_ONLY = 256,
    ONLY_IN_LOS = 512
}

void NoAutoPick()
{
    for( uint i = 0; i < Items.length(); ++i )
    {
        CBaseEntity@ pItem = null;
        while( ( @pItem = g_EntityFuncs.FindEntityByClassname(pItem, Items[i] ) ) !is null)
        {
            if( pItem !is null
            and !pItem.pev.SpawnFlagBitSet( ONLY_IN_LOS )
            and !pItem.pev.SpawnFlagBitSet( TOUCH_ONLY )
            and !pItem.pev.SpawnFlagBitSet( USE_ONLY ) )
            {
                pItem.pev.spawnflags = USE_ONLY;
            }
        }
    }
}