/*

// INSTALLATION:

    "plugin"
    {
        "name" "env_bloodpuddle"
        "script" "../maps/mikk/plugins/env_bloodpuddle"
    }

*/
#include "../env_bloodpuddle"
void MapInit()
{
    env_bloodpuddle::MapInit();
}

void PluginInit()
{
    g_Module.ScriptInfo.SetAuthor( 'Gaftherman' );
    g_Module.ScriptInfo.SetContactInfo( g_Util.GetDiscord() );
}