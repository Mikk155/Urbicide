#include 'mikk/player_command'

void PluginInit()
{
    g_Module.ScriptInfo.SetAuthor( 'Mikk' );
    g_Module.ScriptInfo.SetContactInfo( 'github.com/Mikk155' );
}
namespace player_connect
{
    void Register()
    {
        g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ClientPutInServer );
        // g_Hooks.RegisterHook( Hooks::Player::ClientConnected, @ClientConnected );
    }

    HookReturnCode ClientConnect( CBasePlayer@ pPlayer )
    {
        if( pPlayer !is null )
        {
            g_Util.Trigger( 'game_playerconnect', pPlayer, pPlayer, USE_TOGGLE, 0.0f );
        }
        return HOOK_CONTINUE;
    }

    HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer )
    {
        if( pPlayer !is null )
        {
            g_Util.Trigger( 'game_playerconnected', pPlayer, pPlayer, USE_TOGGLE, 0.0f );
        }
        return HOOK_CONTINUE;
    }
}