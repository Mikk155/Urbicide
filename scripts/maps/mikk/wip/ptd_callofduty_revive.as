#include "utils"
namespace call_of_duty_revive
{
	int AliveTime = 10;
	const string iszModel = 'models/mikk/misc/revive.mdl';
	bool Register = g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, @call_of_duty_revive::PlayerKilled );
	int Precache = g_Game.PrecacheModel( iszModel );

    HookReturnCode PlayerKilled( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib )
    {
        if( pPlayer !is null )
        {
			dictionary g_keyvalues =
			{
				// { "renderamt", '0' },
				// { "rendermode", '5' },
				{ "health", '1' },
				{ "max_health", '1' },
				{ "is_player_ally", '0' },
				{ "classify", string( pPlayer.Classify() ) },
				{ "is_not_revivable", '0' },
				{ "model", iszModel },
				{ "targetname", string( pPlayer.entindex() ) }
			};
			CBaseEntity@ pEntity = g_EntityFuncs.CreateEntity( "monster_generic", g_keyvalues );

			if( pEntity !is null )
			{
				g_Scheduler.SetTimeout( "VerifyPlayerDead", 0.5f, @pPlayer, @pEntity );
			}
		}

        return HOOK_CONTINUE;
    }
	
	void VerifyPlayerDead( CBasePlayer@ pPlayer, CBaseEntity@ pCorpse )
	{
		if( pPlayer.pev.FlagBitSet( FL_ONGROUND ) )
			g_Scheduler.SetTimeout( "InitPlayerDead", 0.1f, @pPlayer, @pCorpse );
		else
			g_Scheduler.SetTimeout( "VerifyPlayerDead", 0.1f, @pPlayer, @pCorpse );
	}

	void InitPlayerDead( CBasePlayer@ pPlayer, CBaseEntity@ pCorpse )
	{
		if( atoi( g_Util.GetCKV( pPlayer, "$f_ptd_codrev" ) ) == 0 )
		{
			pPlayer.GetObserver().RemoveDeadBody();
			pPlayer.Revive();
			g_Util.SetCKV( pPlayer, "$f_ptd_codrev", AliveTime );

			pPlayer.pev.solid = SOLID_NOT;
			pPlayer.pev.rendermode = kRenderTransAlpha;
			pPlayer.pev.flags |= FL_NOTARGET | FL_GODMODE | FL_DUCKING | FL_SPECTATOR;
			pPlayer.pev.renderamt = 100;

            g_EntityFuncs.SetOrigin( pCorpse, pPlayer.pev.origin );
			pCorpse.TakeDamage( pPlayer.pev, pPlayer.pev, 1.0f, DMG_GENERIC );

			// g_Util.SetCKV( pPlayer, "$v_ptd_codrev", pPlayer.pev.origin.ToString() );
            g_EntityFuncs.SetOrigin( pPlayer, pCorpse.pev.origin );

			g_Scheduler.SetTimeout( "Think", 0.0f, @pPlayer, @pCorpse );
		}
	}

	void Think( CBasePlayer@ pPlayer, CBaseEntity@ pCorpse )
	{
		if( atoi( g_Util.GetCKV( pPlayer, "$f_ptd_codrev" ) ) > 0 )
		{
			if( pCorpse.IsAlive() )
			{
				g_Util.SetCKV( pPlayer, "$f_ptd_codrev", 0 );
				g_Scheduler.SetTimeout( "Respawned", 0.0f, @pPlayer, @pCorpse );
			}
			else
			{
				g_Util.SetCKV( pPlayer, "$f_ptd_codrev", atof( g_Util.GetCKV( pPlayer, "$f_ptd_codrev" ) ) - 0.1f );
				g_Scheduler.SetTimeout( "Think", 0.1f, @pPlayer, @pCorpse );
			}
		}
		else
		{
			g_EntityFuncs.Remove( pCorpse );
			pPlayer.GetObserver().StartObserver( pPlayer.pev.origin, pPlayer.pev.angles, false );
		}
	}

	void Respawned( CBasePlayer@ pPlayer, CBaseEntity@ pCorpse )
	{
		g_EntityFuncs.Remove( pCorpse );
		pPlayer.pev.rendermode  = kRenderNormal;
		pPlayer.pev.renderamt = 255;
		pPlayer.pev.flags &= ~FL_NOTARGET;
		pPlayer.pev.flags &= ~FL_GODMODE;
		pPlayer.pev.flags &= ~FL_DUCKING;
		pPlayer.pev.flags &= ~FL_SPECTATOR;
		pPlayer.pev.solid = SOLID_SLIDEBOX;
		// Vector VecPos;
		// g_Utility.StringToVector( VecPos, g_Util.GetCKV( pPlayer, "$v_ptd_codrev" ) );
        // g_EntityFuncs.SetOrigin( pPlayer, VecPos );
	}
}