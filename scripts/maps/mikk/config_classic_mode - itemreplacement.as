#include 'utils/CUtils'
#include 'utils/CGetInformation'
#include 'utils/Reflection'
#include "utils/ScriptBaseCustomEntity"

namespace config_classic_mode
{
    void Register()
    {
        g_CustomEntityFuncs.RegisterCustomEntity( 'config_classic_mode::config_classic_mode','config_classic_mode' );
        g_ClassicMode.EnableMapSupport();

        g_ScriptInfo.SetInformation
        ( 
            g_ScriptInfo.ScriptName( 'config_classic_mode' ) +
            g_ScriptInfo.Description( 'Allow to configurate classic mode for models that the game does not support' ) +
            g_ScriptInfo.Wiki( 'config_classic_mode' ) +
            g_ScriptInfo.Author( 'Mikk' ) +
            g_ScriptInfo.GetDiscord() +
            g_ScriptInfo.GetGithub()
        );
    }

    enum config_classic_mode_spawnflags
    {
        RESTART_NOW = 1,
        FORCE_REMAP = 2
    }

    class config_classic_mode : ScriptBaseEntity, ScriptBaseCustomEntity
    {
        private string
        m_iszTargetOnToggle,
        m_iszTargetOnFail,
        m_iszTargetOnEnable,
        m_iszTargetOnDisable,
        m_iszConfigFile;

        private float m_iThinkTime;

        dictionary g_KeyValues;

        bool KeyValue( const string& in szKey, const string& in szValue ) 
        {
            ExtraKeyValues( szKey, szValue );

            g_KeyValues[ szKey ] = szValue;

            if( szKey == 'm_iszTargetOnToggle' )
            {
                m_iszTargetOnToggle = szValue;
            }
            else if( szKey == 'm_iszTargetOnFail' )
            {
                m_iszTargetOnFail = szValue;
            }
            else if( szKey == 'm_iszTargetOnEnable' )
            {
                m_iszTargetOnEnable = szValue;
            }
            else if( szKey == 'm_iszTargetOnDisable' )
            {
                m_iszTargetOnDisable = szValue;
            }
            else if( szKey == 'm_iThinkTime' )
            {
                m_iThinkTime = atof( szValue );
            }
            else if( szKey == 'm_iszConfigFile' )
            {
                m_iszConfigFile = szValue;
            }
            return true;
        }

        const array<string> strKeyValues
        {
            get const { return g_KeyValues.getKeys(); }
        }

        void Precache()
        {
            if( g_ClassicMode.IsEnabled() )
            {
                for(uint ui = 0; ui < strKeyValues.length(); ui++)
                {
                    string Key = string( strKeyValues[ui] );
                    string Value = string( g_KeyValues[ Key ] );

                    if( Key.StartsWith( 'models/' ) )
                    {
                        g_Game.PrecacheModel( Value );
                        g_Util.Debug( '[config_classic_mode] Precached model "' + Value + '"' );
                    }
                }
            }

            BaseClass.Precache();
        }

        void PreSpawn()
        {
            if( !m_iszConfigFile.IsEmpty() )
            {
                g_KeyValues = g_Util.GetKeyAndValue( 'scripts/maps/' + m_iszConfigFile, g_KeyValues );
            }

            BaseClass.PreSpawn();
        }

        void Spawn()
        {
            if( g_Util.GetNumberOfEntities( self.GetClassname() ) > 1 )
            {
                g_Util.Debug( self.GetClassname() + '[config_classic_mode] WARNING! There is more than one config_classic_mode entity in this map!.' );
            }

            for(uint ui = 0; ui < strKeyValues.length(); ui++)
            {
                string Key = string( strKeyValues[ui] );
                string Value = string( g_KeyValues[ Key ] );

                if( g_ClassicMode.IsEnabled() )
                {
                    if( Key.StartsWith( 'models/' ) )
                    {
                        dictionary g_changemodel;
                        g_changemodel [ 'target' ] = '!activator';
                        g_changemodel [ 'model' ] = Value;
                        g_changemodel [ 'targetname' ] =  'CCM_' + Key;
                        g_EntityFuncs.CreateEntity( 'trigger_changemodel', g_changemodel, true );
                        g_Util.Debug( '[config_classic_mode] Created trigger_changemodel replaces "' + Key + '" -> "' + Value + '"' );
                    }
                }
                if( Key.StartsWith( 'weapon_' ) )
                {
                    g_Util.Debug( '[config_classic_mode] Remapped "' + Key + '" -> "' + Value + '"' );
                }
            }
            g_ClassicMode.SetItemMappings( @g_ItemMappings );

            g_Util.Trigger( ( g_ClassicMode.IsEnabled() ) ? m_iszTargetOnEnable : m_iszTargetOnDisable , self, self, USE_TOGGLE, delay );

            SetThink( ThinkFunction( this.Think ) );
            self.pev.nextthink = g_Engine.time + 0.1f;

            BaseClass.Spawn();
        }

        void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
        {
            if( IsLockedByMaster() )
            {
                return;
            }
            else
            if( g_ClassicMode.IsEnabled() && useType == USE_ON || !g_ClassicMode.IsEnabled() && useType == USE_OFF )
            {
                g_Util.Trigger( m_iszTargetOnFail, ( pActivator !is null ) ? pActivator : self, self, useType, delay );
                return;
            }

            g_ClassicMode.SetShouldRestartOnChange( spawnflag( RESTART_NOW ) );

            g_ClassicMode.Toggle();

            g_Util.Trigger( m_iszTargetOnToggle, ( pActivator !is null ) ? pActivator : self, self, useType, delay );
        }

        void Think()
        {
            if( g_ClassicMode.IsEnabled() )
            {
                for(uint ui = 0; ui < strKeyValues.length(); ui++)
                {
                    string Key = string( strKeyValues[ui] );
                    string Value = string( g_KeyValues[ Key ] );

                    CBaseEntity@ pEntity = null;

                    while( ( @pEntity = g_EntityFuncs.FindEntityByString( pEntity, 'model', Key ) ) !is null )
                    {
                        if( pEntity !is null && g_Util.GetCKV( pEntity, '$i_classic_mode_ignore' ) != '1' )
                        {
                            g_Util.Debug( '[config_classic_mode] replaced "' + string( pEntity.pev.model ) + "' -> '" + string( Value ) + '"' );
                            g_Util.Trigger( 'CCM_' + Key, pEntity, self, USE_ON, 0.0f );
                        }
                    }
                }
            }

            if( g_ClassicMode.IsEnabled() || spawnflag( FORCE_REMAP ) )
            {
                for(uint ui = 0; ui < strKeyValues.length(); ui++)
                {
                    string Key = string( strKeyValues[ui] );
                    string Value = string( g_KeyValues[ Key ] );

                    CBaseEntity@ pEntity = null;

                    while( ( @pEntity = g_EntityFuncs.FindEntityClassname( pEntity, 'weapon_*' ) ) !is null )
                    {
                        if( pEntity !is null && g_Util.GetCKV( pEntity, '$i_classic_mode_ignore' ) != '1' )
                        {
                            CBaseEntity@ pWeapon = cast<CBasePlayerWeapon>( pEntity );

                            if( pWeapon !is null )
                            {
                                g_DictItemMapping[ 'soundlist' ] = '';
                                g_DictItemMapping[ 'CustomSpriteDir' ] = '';
                                g_DictItemMapping[ 'IsNotAmmoItem' ] = '';
                                dictionary g_DictItemMapping;
                                // g_DictItemMapping[ 'wpn_v_model' ] = pWeapon.GetV_Model();
                                // g_DictItemMapping[ 'wpn_w_model' ] = pWeapon.GetW_Model();
                                // g_DictItemMapping[ 'wpn_p_model' ] = pWeapon.GetP_Model();
                                if( pWeapon.m_flCustomDmg > 0 ) 
                                {
                                    g_DictItemMapping[ 'dmg' ] = string( pWeapon.m_flCustomDmg );
                                }
                                if( pWeapon.pev.dmg > 0 ) 
                                {
                                    g_DictItemMapping[ 'dmg' ] = string( pWeapon.pev.dmg );
                                }
                                g_DictItemMapping[ 'exclusiveHold' ] = string( pWeapon.m_bExclusiveHold );
                                g_DictItemMapping[ 'delay' ] = string( pWeapon.m_flDelay );
                                g_DictItemMapping[ 'killtarget' ] = pWeapon.m_iszKillTarget;
                                g_DictItemMapping[ 'm_flCustomRespawnTime' ] = string( pWeapon.GetRespawnTime() );
                                g_DictItemMapping[ 'angles' ] = pWeapon.pev.angles.ToString();
                                g_DictItemMapping[ 'origin' ] = pWeapon.pev.origin.ToString();
                                g_DictItemMapping[ 'targetname' ] = pWeapon.pev.targetname;
                                g_DictItemMapping[ 'rendercolor' ] = pWeapon.pev.rendercolor.ToString();
                                g_DictItemMapping[ 'target' ] = pWeapon.pev.target;
                                g_DictItemMapping[ 'rendermode' ] = string( pWeapon.pev.rendermode );
                                g_DictItemMapping[ 'renderamt' ] = string( pWeapon.pev.renderamt );
                                g_DictItemMapping[ 'renderfx' ] = string( pWeapon.pev.renderfx );
                                g_DictItemMapping[ 'spawnflags' ] = string( pWeapon.pev.spawnflags );
                                g_DictItemMapping[ 'model' ] = string( pWeapon.pev.model );
                                g_DictItemMapping[ 'movetype' ] = string( pWeapon.pev.movetype );
                                CBaseEntity@ pNewWeapon = g_EntityFuncs.CreateEntity( Value, g_DictItemMapping, true );

                                if( pNewWeapon !is null )
                                {
                                    g_Util.Debug( '[config_classic_mode] replaced "' + string( pWeapon.pev.classname ) + "' -> '" + string( Value ) + '"' );
                                    g_EntityFuncs.SetOrigin( pNewWeapon, pWeapon.pev.origin );
                                    g_EntityFuncs.Remove( pWeapon );
                                }
                            }
                        }
                    }
                }
            }

            self.pev.nextthink = g_Engine.time + m_iThinkTime + 0.1f;
        }
    }
}