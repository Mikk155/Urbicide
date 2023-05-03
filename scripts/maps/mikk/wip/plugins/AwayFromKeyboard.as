#include "../maps/mikk/utils"

// Maximun time players can be afk before joining spectator mode (seconds)
const int AFKMaxTime = 300; // 5 minutes

void PluginInit()
{
    g_Module.ScriptInfo.SetAuthor
    (
        "Mikk"
        "\nGithub: github.com/Mikk155"
        "\nDescription: Move to spectator mode players that are 'Away from keyboard' and in case server is full he'll be kicked instead."
    );
    g_Module.ScriptInfo.SetContactInfo
    (
        "\nDiscord: discord.gg/VsNnE3A7j8"
    );
    g_Hooks.RegisterHook( Hooks::Player::ClientSay, @AfkSay );
}

CScheduledFunction@ g_pThink = null;

void MapInit()
{
    if( g_Util.IsStringInFile( "scripts/plugins/AwayFromKeyboard/MapBlackList.txt", string( g_Engine.mapname ) ) )
        return;

    g_CustomEntityFuncs.RegisterCustomEntity( "plugin_afkzone", "plugin_afkzone" );

    g_Scheduler.RemoveTimer( g_pThink );
    @g_pThink = null;

    @g_pThink = g_Scheduler.SetInterval( "AFKThink", 1.0f, g_Scheduler.REPEAT_INFINITE_TIMES );
    
    // Creates the entity that prevent players from getting the afk's keyvalue. -Entity
    RIPENT::LoadRipentFile( "scripts/plugins/mikk/AfkManager/" + string( g_Engine.mapname ) + ".ent" );
}

/*
A entity that you must define a zone with the use of hullsizes. if the player is inside of it then do not count him as a AFK
You can enable flag 1 (start off) to toggle it via trigger. supports UseTypes.
or you can lock it by its master key if you prefeer.

"minhullsize" "min size"
"maxhullsize" "max size"
"master" "multisource"
"targetname" "name"
"spawnflags" "0/1"
"classname" "afkmanager_zone"
"model" "alternative set size by a brush model"
*/

class plugin_afkzone : ScriptBaseEntity, ScriptBaseCustomEntity
{
    private bool Enabled    = true;

    bool KeyValue( const string& in szKey, const string& in szValue )
    {
        ExtraKeyValues(szKey, szValue);
        return true;
    }
    
    void Spawn() 
    {
        self.Precache();

        self.pev.movetype = MOVETYPE_NONE;
        self.pev.solid = SOLID_TRIGGER;
        self.pev.effects |= EF_NODRAW;

        SetBoundaries();

        if( self.pev.SpawnFlagBitSet( 1 ) )
        {
            Enabled = false;
        }

        SetThink( ThinkFunction( this.TriggerThink ) );
        self.pev.nextthink = g_Engine.time + 0.1f;
        
        BaseClass.Spawn();
    }
    
    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value)
    {
        switch(useType)
        {
            case USE_ON:
                Enabled = true;
            break;

            case USE_OFF:
                Enabled = false;
            break;

            default:
                Enabled = !Enabled;
            break;
        }
    }

    void TriggerThink() 
    {
        if( !Enabled || master() )
        {
            self.pev.nextthink = g_Engine.time + 1.0f;
            return;
        }

        for( int iPlayer = 1; iPlayer <= g_PlayerFuncs.GetNumPlayers(); ++iPlayer )
        {
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

            if( pPlayer is null )
                continue;

            if( self.pev.SpawnFlagBitSet( 2 ) || self.Intersects( pPlayer ) )
				g_Util.SetCKV( pPlayer '$i_afktimer', '0' )
        }
        self.pev.nextthink = g_Engine.time + 1.0f;
    }
}

dictionary dictSteamsID;

void AFKThink()
{
    for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

        if( pPlayer is null )
            continue;

        string SteamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());

        // player is in AFK mode
        if( dictSteamsID.exists(SteamID) )
        {
            // If server full disconnect the player
            if( g_PlayerFuncs.GetNumPlayers() == g_Engine.maxClients )
            {
                UTILS::Trigger( "AFK_KICK_MODE", pPlayer, pPlayer, USE_ON, 0.5f );

                NetworkMessage msg(MSG_ONE, NetworkMessages::SVC_STUFFTEXT, pPlayer.edict());
                    msg.WriteString( "disconnect" );
                msg.End();
            }
            // If player is in spec mode tell how to leave afk mode
            else if( pPlayer.GetObserver().IsObserver() )
            {
                UTILS::Trigger( "AFK_EXIT_MODE", pPlayer, pPlayer, USE_ON, 0.5f );
                pPlayer.pev.nextthink = ( g_Engine.time + 2.0 );
            }
            // Move to spectator mode
            else
            {
                pPlayer.GetObserver().StartObserver( pPlayer.pev.origin, pPlayer.pev.angles, false );
            }
        }
		
        int iafktimer = atoi( g_Util.GetCKV( pPlayer '$i_afktimer' ) );

        if( pPlayer.IsAlive() && !pPlayer.IsMoving() )
        {
			g_Util.SetCKV( pPlayer '$i_afktimer', string( iafktimer - 1 ) )

            if( iafktimer == 1 && !pPlayer.GetObserver().IsObserver() )
            {
                dictSteamsID[SteamID] = @pPlayer;
                UTILS::Trigger( "AFK_ENTER_MODE", pPlayer, pPlayer, USE_ON, 0.5f );
            }
        }

        if( pPlayer.IsMoving() || iafktimer <= 0 )
        {
			g_Util.SetCKV( pPlayer '$i_afktimer', string( AFKMaxTime ) )
        }

        if( iafktimer < 11 && iafktimer >= 1 )
        {
            UTILS::Trigger( "AFK_GOING_MODE", pPlayer, pPlayer, USE_ON, 0.5f );
        }
    }
}

HookReturnCode AfkSay( SayParameters@ pParams )
{
    CBasePlayer@ pPlayer = pParams.GetPlayer();
    const CCommand@ args = pParams.GetArguments();

    if( args.Arg(0) == "/afk" || args.Arg(0) == "!afk" )
	{
		if( ExcludedMapList() )
        	UTILS::Trigger( "AFK_TELL_DISABLED", pPlayer, pPlayer, USE_ON, 0.5f );
		else
        	ToggleAfk( pPlayer );
	}

    if( args.Arg(0) == "afk" or args.Arg(0) == "brb" )
	{
		if( ExcludedMapList() )
        	UTILS::Trigger( "AFK_TELL_DISABLED", pPlayer, pPlayer, USE_ON, 0.5f );
		else
        	UTILS::Trigger( "AFK_TELL_MODE", pPlayer, pPlayer, USE_ON, 0.5f );
	}

    return HOOK_CONTINUE;
}

void ToggleAfk( CBasePlayer@ pPlayer )
{
    string SteamID = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());

    if( dictSteamsID.exists(SteamID) )
    {
        dictSteamsID.delete(SteamID);
        UTILS::Trigger( "AFK_LEFT_MODE", pPlayer, pPlayer, USE_ON, 0.5f );
    }
    else
    {
        dictSteamsID[SteamID] = @pPlayer;
		g_Message.Show( pPlayer, 'AFK_ENTER_MODE' );
    }
}


MESSAGE g_Message;

final class MESSAGE
{
	void Show( CBasePlayer@ pActivator, const string& in s = '', const int& in AllPlayers = 0 )
	{
		if( AllPlayers == 1 )
		{
			for( int iPlayer = 1; iPlayer <= g_PlayerFuncs.GetNumPlayers(); ++iPlayer )
			{
				CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

				if( pPlayer is null )
				{
					g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, g_Message.Return( pActivator, pActivator, s ) + "\n" );
				}
			}
		}
		else
		{
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, g_Message.Return( pActivator, pActivator, s ) + "\n" );
		}
	}

	string Return( CBasePlayer@ pPlayer, CBasePlayer@ pActivator, const string& in s = '' )
	{
		string l = g_Util.GetCKV( pPlayer, "$s_language" );
		string m;
		string n = pPlayer.pev.pActivator;

		if( s == 'AFK_ENTER_MODE' )
		{
			if( l == 'spanish' || l == 'spanish spain' ) m = '[AFKManager] ' + n + ' Esta en modo AFK.';
			else if( l == 'portuguese' ) m = '[AFKManager] ' + n + ' Esta no modo AFK.';
			else if( l == 'german' ) m = '[AFKManager] ' + n + ' Ist im AFK-Modus.';
			else if( l == 'french' ) m = '[AFKManager] ' + n + ' Est en mode AFK.';
			else if( l == 'italian' ) m = '[AFKManager] ' + n + ' E in modalita AFK.';
			else if( l == 'esperanto' ) m = '[AFKManager] ' + n + ' stas en AFK-regimo.';
			else m = '[AFKManager] ' + n + ' Is in AFK mode.';
		}
		return m;
	}
}

		
/*
czech
dutch
indonesian
romanian
turkish
albanian
*/