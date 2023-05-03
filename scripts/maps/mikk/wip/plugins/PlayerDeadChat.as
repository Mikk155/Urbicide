/*

// INSTALLATION:

    "plugin"
    {
        "name" "PlayerDeadChat"
        "script" "../maps/mikk/plugins/PlayerDeadChat"
    }
    
// OR as a map_script

#include "mikk/plugins/PlayerDeadChat"

*/
#include "../utils"
void PluginInit()
{
    g_Module.ScriptInfo.SetAuthor( 'Mikk' );
    g_Module.ScriptInfo.SetContactInfo( g_Util.GetDiscord() );
}

bool blRegister = g_Hooks.RegisterHook( Hooks::Player::ClientSay, @PlayerDeadChat::ClientSay );

namespace PlayerDeadChat
{
    HookReturnCode ClientSay( SayParameters@ pParams )
    {
        CBasePlayer@ pPlayer = pParams.GetPlayer();

        if( pPlayer.IsAlive() )
            return HOOK_CONTINUE;

        const CCommand@ args = pParams.GetArguments();
        string FullSentence = pParams.GetCommand();

        pParams.ShouldHide = true;

        for( int iPlayer = 1; iPlayer <= g_PlayerFuncs.GetNumPlayers(); ++iPlayer )
        {
            CBasePlayer@ pDeadPlayers = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

            if( !pDeadPlayers.IsAlive() )
            {
                g_PlayerFuncs.ClientPrint( pDeadPlayers, HUD_PRINTTALK, "[DEAD] "+pPlayer.pev.netname+": "+FullSentence+"\n" );
            }
        }
        return HOOK_CONTINUE;
    }
}