
#include "utils"
#include "utils/customentity"

namespace player_data
{
    void Register()
    {
        g_CustomEntityFuncs.RegisterCustomEntity( "player_data::player_data", "player_data" );

        g_ScriptInfo.SetInformation
        ( 
            g_ScriptInfo.ScriptName( 'player_data' ) +
            g_ScriptInfo.Description( '' ) +
            g_ScriptInfo.Wiki( 'player_data' ) +
            g_ScriptInfo.Author( 'Mikk' ) +
            g_ScriptInfo.GetGithub() +
            g_ScriptInfo.GetDiscord()
        );
    }

    enum player_data_spawnflags
    {
        NO_USAGE = 0,
        ALL_PLAYERS = 1
    }

    enum player_data_condition
    {
        NONE = 0,
        HASSUIT = 1,
        STEAMIDIS = 2,
        HASLONGJUMP = 3,
        ISADMIN = 4,
        ISOWNER = 5,
        ISADMINNOROWNER = 6,
        ISALIVE = 7,
        ISONLADDER = 8,
        ISWITHINRADIUS = 9,
        FLASHLIGHTON = 10,
        ISOBSERVER = 11,
        ISOBSERVERNHASCORPSE = 12,
        ISMOVING = 13,
        HASNAMEDITEM = 14,
        INTERSECTS = 15,
    }

    class player_data : ScriptBaseEntity, ScriptBaseCustomEntity
    {
        private string m_iszTrueCase, m_iszFalseCase, m_iszComparator;
        private int m_iCondition;

        bool KeyValue( const string& in szKey, const string& in szValue )
        {
            if( szKey == "m_iszTrueCase" )
            {
                m_iszTrueCase = szValue;
            }
            else if( szKey == "m_iszFalseCase" )
            {
                m_iszFalseCase = szValue;
            }
            else if( szKey == "m_iszComparator" )
            {
                m_iszComparator = szValue;
            }
            else if( szKey == "m_iCondition" )
            {
                m_iCondition = atoi( szValue );
            }
            return true;
        }

        void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
        {
            if( IsLockedByMaster() )
            {
                if( spawnflag( ALL_PLAYERS ) )
                {
                    for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
                    {
                        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

                        VerifyData( pPlayer );
                    }
                }
                else
                {
                    VerifyData( ( pActivator.IsPlayer() ? cast<CBasePlayer@>( pActivator ) : null ) );
                }
            }
        }

        void VerifyData( CBasePlayer@ pPlayer )
        {
            if( pPlayer !is null )
            {
                bool blcondition = false;

                if( condition( m_iCondition, pPlayer ) )
                {
                    g_Util.Trigger( m_iszTrueCase, pPlayer, self, USE_TOGGLE, delay );
                }
                else
                {
                    g_Util.Trigger( m_iszFalseCase, pPlayer, self, USE_TOGGLE, delay );
                }
            }
        }

        bool condition( int iCondition,  CBasePlayer@ pPlayer  )
        {
            if( iCondition == HASSUIT
            and pPlayer.HasSuit() )
            {
                return true;
            }else
            if( iCondition == STEAMIDIS
            and string( g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() ) ) == m_iszComparator )
            {
                    return true;
            }else
            if( iCondition == HASLONGJUMP
            and pPlayer.m_fLongJump )
            {
                    return true;
            }else
            if( iCondition == ISADMIN
            and g_PlayerFuncs.AdminLevel( pPlayer ) == 1 )
            {
                    return true;
            }else
            if( iCondition == ISOWNER
            and g_PlayerFuncs.AdminLevel( pPlayer ) == 2 )
            {
                    return true;
            }else
            if( iCondition == ISADMINNOROWNER
            and g_PlayerFuncs.AdminLevel( pPlayer ) > 0 )
            {
                    return true;
            }else
            if( iCondition == ISALIVE
            and pPlayer.IsAlive() )
            {
                    return true;
            }else
            if( iCondition == ISONLADDER
            and pPlayer.IsOnLadder() )
            {
                    return true;
            }else
            if( iCondition == ISWITHINRADIUS
            and ( ( self.pev.origin - pPlayer.pev.origin ).Length() <= atoi( m_iszComparator ) ) )
            {
                    return true;
            }else
            if( iCondition == FLASHLIGHTON
            and pPlayer.FlashlightIsOn() )
            {
                    return true;
            }else
            if( iCondition == ISOBSERVER
            and pPlayer.GetObserver().IsObserver() )
            {
                    return true;
            }else
            if( iCondition == ISOBSERVERNHASCORPSE
            and pPlayer.GetObserver().IsObserver() && pPlayer.GetObserver().HasCorpse() )
            {
                    return true;
            }else
            if( iCondition == ISMOVING
            and pPlayer.IsMoving() )
            {
                    return true;
            }else
            if( iCondition == HASNAMEDITEM )
            {
                CBasePlayerItem@ pItem = pPlayer.HasNamedPlayerItem( m_iszComparator );

                if( pItem is null )
                {
                    return true;
                }
            }else
            if( iCondition == INTERSECTS )
            {
                CBaseEntity@ pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, m_iCondition );

                if( pEntity is null )
                {
                    if( pEntity.Intersects( pPlayer ) )
                    {
                        return true;
                    }
                }
            }
            return false;
        }
    }
}