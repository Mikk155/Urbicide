#include "mikk/config_classic_mode"
#include "mikk/env_bloodpuddle"
#include "mikk/env_scanner"
#include "mikk/monster_dmg_inflictor"
#include "mikk/player_data"
#include "mikk/trigger_changecvar"
#include "mikk/trigger_hurt_remote"
#include "mikk/trigger_individual"
#include "mikk/trigger_multiple"
#include "mikk/trigger_sound"
#include "mikk/trigger_changevalue"

void MapInit()
{
    config_classic_mode::Register();
    env_bloodpuddle::Register();
    RegisterCScanner();
    trigger_changecvar::Register();
    trigger_sound::Register();
    XENDHGun::Register();
    g_CustomEntityFuncs.RegisterCustomEntity( "CBaseEntities::CBaseGibs", "monster_bodypart" );
    g_CustomEntityFuncs.RegisterCustomEntity( "CBaseEntities::CBaseKate", "monster_kate" );
    g_CustomEntityFuncs.RegisterCustomEntity( "CBaseEntities::CBaseGame", "monster_kate" );
}

void TrainingRoom( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
{
    g_EntityFuncs.FireTargets( ( g_EngineFuncs.IsMapValid( "hl_t00" ) ) ? "hl_t00_rl" : "hl_t00_msg", null, null, USE_TOGGLE, 0.0f );
}

namespace CBaseEntities
{
    class CBaseGibs : ScriptBaseEntity
    {
        void Spawn()
        {
            string zModel = ( self.pev.frags == 0 ) ? "models/hgibs.mdl" : "models/agibs.mdl";

            g_EntityFuncs.SetModel( self, ( string( self.pev.model ).IsEmpty() ) ? zModel : string( self.pev.model ) );

            /*if( self.pev.frags == 0 )
            {
                g_EntityFuncs.SetModel( self, ( string( self.pev.model ).IsEmpty() ? ) "models/hgibs.mdl" : string( self.pev.model ) );
            }
            else
            {
                g_EntityFuncs.SetModel( self, ( string( self.pev.message ).IsEmpty() ? ) "models/agibs.mdl" : string( self.pev.message ) );
            }*/

            self.pev.movetype = MOVETYPE_TOSS;
            self.pev.solid = SOLID_NOT;
            self.pev.friction = 0;

            g_EntityFuncs.SetOrigin( self, self.pev.origin );
            g_EntityFuncs.SetBodygroup( 0, int( Math.RandomLong( self.pev.health, ( self.pev.max_health == 0 ) ? 10 : self.pev.max_health ) ) )
        }

        void Precache()
        {
            g_Game.PrecacheModel( ( string( self.pev.model ).IsEmpty() ? ) "models/hgibs.mdl" : string( self.pev.model ) );
            g_Game.PrecacheGeneric( ( string( self.pev.model ).IsEmpty() ? ) "models/hgibs.mdl" : string( self.pev.model ) );
            g_Game.PrecacheModel( ( string( self.pev.message ).IsEmpty() ? ) "models/agibs.mdl" : string( self.pev.message ) );
            g_Game.PrecacheGeneric( ( string( self.pev.message ).IsEmpty() ? ) "models/agibs.mdl" : string( self.pev.message ) );
            BaseClass.Precache();
        }
    }

    class CBaseGame : ScriptBaseEntity
    {
        void Spawn()
        {
            self.pev.movetype = MOVETYPE_NONE;
            self.pev.solid = SOLID_TRIGGER;
            self.pev.targetname = "kate_ends_this_level";

            g_EntityFuncs.SetModel( self, self.pev.model );
            g_EntityFuncs.SetOrigin( self, self.pev.origin );

            SetTouchFunction( this.TouchFunction );
        }

        void TouchFunction( CBaseEntity@ pOther )
        {
            if( pOther is null )
            {
                return;
            }
            else if( pOther.IsPlayer() )
            {
                g_EntityFuncs.FireTargets( self.pev.message, pOther, self, USE_ON, 0.0f );
            }
            else if( pOther.IsMonster() && string( pOther.pev.model ).EndsWith( "kate.mdl" ) )
            {
                if( string( pOther.pev.targetname).IsEmpty() )
                {
                    pOther.pev.targetname = "this_is_kate";
                }

                dictionary keyvalues =
                {
                    { "targetname", "kate_health_store" },
                    { "netname", "kate_health" },
                    { "target", pOther.GetTargetname() },
                    { "message", "health" },
                    { "m_iszTrigger", "kate_ends_this_level" }
                };

                CBaseEntity@ pSave = g_EntityFuncs.CreateEntity( "trigger_save", keyvalues, false );
                
                if( pSave !is null )
                {
                    pSave.Use( pOther, self, USE_ON, 0.0f );
                }
            }
            
            void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
            {
                g_EngineFuncs.ChangeLevel( self.pev.netname );
            }
        }
    }

    class CBaseKate : ScriptBaseMonsterEntity
    {
        int CurrentHealth;

		void Precache()
		{
			g_Game.PrecacheModel( "models/mikk/azure/kate.mdl" );
		}
		
        void Spawn( void )
        {
            Precache();

            dictionary keyvalues = {
                { "model", "models/mikk/azure/kate.mdl" },
                { "soundlist", "../mikk/azure/kate.txt" },
                { "displayname", "Kate" },
                { "freeroam", "1" },
                { "health", string( CurrentHealth ) }
            };

            CBaseEntity@ pEntity = g_EntityFuncs.CreateEntity( "monster_kate", keyvalues, false );

            CBaseMonster@ pKate = pEntity.MyMonsterPointer();

            pKate.pev.origin = self.pev.origin;
            pKate.pev.angles = self.pev.angles;
            pKate.pev.targetname = self.pev.targetname;
            pKate.pev.spawnflags = self.pev.spawnflags;
            pKate.m_iTriggerCondition = self.m_iTriggerCondition;
            pKate.m_iszTriggerTarget = self.m_iszTriggerTarget;

            g_EntityFuncs.DispatchSpawn( pKate.edict() );

            g_EntityFuncs.Remove( self );
        }
    }
}

namespace XENDHGun
{
    const string ViewModel 			= "models/hlclassic/pov/v_dualhgun.mdl";
    const string WorldModel 		= "models/hlclassic/w_hgun.mdl";
    const string PlayerModel 		= "models/hlclassic/p_hgun.mdl";

    const int DHGUN_MAX_CLIP 		= 50;
    const int DHGUN_WEIGHT 			= 20;

    const float DHGUN_DELAY_RECHARGE 	= 1.5f;

    enum Animation
    {
        DHGUN_IDLE1 = 0,
        DHGUN_IDLE2,
        DHGUN_IDLE3,
        DHGUN_FIDGETSWAY_L,
        DHGUN_FIDGETSWAY_R,
        DHGUN_FIDGETSHAKE_L,
        DHGUN_FIDGETSHAKE_R,
        DHGUN_DOWN,
        DHGUN_UP,
        DHGUN_SHOOT_R,
        DHGUN_SHOOT_L
    };

    enum Firemode
    {
        FIREMODE_TRACK = 0,
        FIREMODE_FAST
    };

    const array<string> pFireSounds =
    {
        "agrunt/ag_fire1.wav",
        "agrunt/ag_fire2.wav",
        "agrunt/ag_fire3.wav"
    };

    class weapon_hornetgundual : ScriptBasePlayerWeaponEntity
    {
        protected CBasePlayer@ m_pPlayer
        {
            get const { return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
            set { self.m_hPlayer = EHandle( @value ); }
        }

        private float m_flRechargeTimeR, m_flRechargeTimeL;
        private int m_iFirePhase;
        private int m_iRight;

        private int iMuzzleFlash;

        void Spawn()
        {
            self.Precache();
            g_EntityFuncs.SetModel( self, WorldModel );
            
            self.m_iDefaultAmmo = DHGUN_MAX_CLIP;
            self.m_iDefaultSecAmmo = DHGUN_MAX_CLIP;
            m_iFirePhase = 0;

            self.FallInit();
        }

        void Precache()
        {
            self.PrecacheCustomModels();

            g_Game.PrecacheModel( ViewModel );
            g_Game.PrecacheModel( PlayerModel );
            g_Game.PrecacheModel( WorldModel );

            iMuzzleFlash = g_Game.PrecacheModel( "sprites/muz4.spr" );

            for( uint i = 0; i < pFireSounds.length(); i++ ) // firing sounds
            {
                g_SoundSystem.PrecacheSound( pFireSounds[i] ); // cache
                g_Game.PrecacheGeneric( "sound/" + pFireSounds[i] ); // client has to download
            }

            g_Game.PrecacheGeneric( "sprites/" + "pov/320hud2.spr" );
            g_Game.PrecacheGeneric( "sprites/" + "pov/320hudpv1.spr" );
            g_Game.PrecacheGeneric( "sprites/" + "pov/640hud7.spr" );
            g_Game.PrecacheGeneric( "sprites/" + "pov/640hudpv2.spr" );
            g_Game.PrecacheGeneric( "sprites/" + "pov/640hudpv5.spr" );

            g_Game.PrecacheGeneric( "sprites/" + "pov/weapon_hornetgundual.txt" );

            g_Game.PrecacheOther( "hornet" );
            g_Game.PrecacheOther( "customhornet" );
        }

        bool GetItemInfo( ItemInfo& out info )
        {
            info.iMaxAmmo1 	= DHGUN_MAX_CLIP;
            info.iMaxAmmo2 	= DHGUN_MAX_CLIP;
            info.iMaxClip 	= WEAPON_NOCLIP;
            info.iSlot 		= 3;
            info.iPosition 	= 7;
            info.iFlags 	= ITEM_FLAG_NOAUTOSWITCHEMPTY | ITEM_FLAG_NOAUTORELOAD;
            info.iWeight 	= DHGUN_WEIGHT;

            return true;
        }

        bool AddToPlayer( CBasePlayer@ pPlayer )
        {
            if( !BaseClass.AddToPlayer( pPlayer ) )
                return false;

            @m_pPlayer = pPlayer;

            NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
                message.WriteLong( g_ItemRegistry.GetIdForName( self.pev.classname ) );
            message.End();

            return true;
        }

        bool Deploy()
        {
            bool bResult;
            {
                bResult = self.DefaultDeploy( self.GetV_Model( ViewModel ), self.GetP_Model( PlayerModel ), DHGUN_UP, "uzis" );
                self.m_flNextPrimaryAttack = g_Engine.time + 1.0f;
                m_flRechargeTimeR = g_Engine.time + 1.5;
                m_flRechargeTimeL = g_Engine.time + 1.0;
                self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack;
                self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack;
                return bResult;
            }
        }

        void Holster( int skiplocal )
        {
            self.m_fInReload = false;
            SetThink( null );

            if( m_pPlayer.m_rgAmmo( self.PrimaryAmmoIndex()) <= 0 )
                m_pPlayer.m_rgAmmo( self.PrimaryAmmoIndex(), 1 );

            if( m_pPlayer.m_rgAmmo( self.SecondaryAmmoIndex()) <= 0 )
                m_pPlayer.m_rgAmmo( self.SecondaryAmmoIndex(), 1 );
            
            BaseClass.Holster( skiplocal );
        }
        
        float WeaponTimeBase()
        {
            return g_Engine.time;
        }


        private void ResetUzisAnim()
        {
            SetThink( null );
            m_pPlayer.m_szAnimExtension = "uzis";
        }


        void PrimaryAttack()
        {
            Reload();
            
            DHGunFire( FIREMODE_TRACK, 0.135 );
        }

        void SecondaryAttack()
        {
            Reload();
            
            DHGunFire( FIREMODE_FAST, 0.1 );
        }

        void DHGunFire( int iFireMode, float flNextAttack )
        {
            Math.MakeVectors( m_pPlayer.pev.v_angle );

            Vector vecSrc = m_pPlayer.GetGunPosition() + g_Engine.v_forward * 20 + g_Engine.v_up * -10;
            
            //KernCore: Hardcoded Player Model Stuff
            m_pPlayer.m_szAnimExtension = (self.m_iClip % 2 == 0) ? "uzis_right" : "uzis_left";
            SetThink( ThinkFunction( this.ResetUzisAnim ) );
            self.pev.nextthink = g_Engine.time + (6.0/24.0);
            //KernCore: End

            switch( ( m_iRight++ ) % 2 )
            {
                case 0:
                {
                    if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
                        return;

                    vecSrc = vecSrc + g_Engine.v_right * 8;

                    NetworkMessage message( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecSrc );
                        message.WriteByte( TE_SPRITE );
                        message.WriteCoord( vecSrc.x );		// pos
                        message.WriteCoord( vecSrc.y );
                        message.WriteCoord( vecSrc.z );
                        message.WriteShort( iMuzzleFlash );	// model
                        message.WriteByte( 3 );			// size * 10
                        message.WriteByte( 128 );		// brightness
                    message.End();

                    self.SendWeaponAnim( DHGUN_SHOOT_R );
                    m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );

                    if( iFireMode == FIREMODE_FAST )
                    {
                        m_iFirePhase++;
                        switch( m_iFirePhase )
                        {
                        case 1: vecSrc = vecSrc + g_Engine.v_up * 8; break;
                        case 2:
                            vecSrc = vecSrc + g_Engine.v_up * 8;
                            vecSrc = vecSrc + g_Engine.v_right * 8;
                            break;
                        case 3: vecSrc = vecSrc + g_Engine.v_right * 8; break;
                        case 4:
                            vecSrc = vecSrc + g_Engine.v_up * -8;
                            vecSrc = vecSrc + g_Engine.v_right * 8;
                            break;
                        case 5: vecSrc = vecSrc + g_Engine.v_up * -8; break;
                        case 6:
                            vecSrc = vecSrc + g_Engine.v_up * -8;
                            vecSrc = vecSrc + g_Engine.v_right * -8;
                            break;
                        case 7: vecSrc = vecSrc + g_Engine.v_right * -8; break;
                        case 8:
                            vecSrc = vecSrc + g_Engine.v_up * 8;
                            vecSrc = vecSrc + g_Engine.v_right * -8;
                            m_iFirePhase = 0;
                            break;
                        }

                        m_pPlayer.pev.punchangle.x = Math.RandomFloat( 0.0, -2.0 );
                    }

                    m_flRechargeTimeR = g_Engine.time + 0.8;
                }
                break;
                case 1:
                {
                    if( m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) <= 0 )
                        return;

                    vecSrc = vecSrc + g_Engine.v_right * -8;

                    NetworkMessage message( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecSrc );
                        message.WriteByte( TE_SPRITE );
                        message.WriteCoord( vecSrc.x );		// pos
                        message.WriteCoord( vecSrc.y );
                        message.WriteCoord( vecSrc.z );
                        message.WriteShort( iMuzzleFlash );	// model
                        message.WriteByte( 3 );			// size * 10
                        message.WriteByte( 128 );		// brightness
                    message.End();

                    self.SendWeaponAnim( DHGUN_SHOOT_L );
                    m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) - 1 );

                    if( iFireMode == FIREMODE_FAST )
                    {
                        m_iFirePhase++;
                        switch( m_iFirePhase )
                        {
                        case 1:
                            vecSrc = vecSrc + g_Engine.v_up * -8;
                            vecSrc = vecSrc + g_Engine.v_right * 8;
                            break;
                        case 2: vecSrc = vecSrc + g_Engine.v_right * 8; break;
                        case 3:
                            vecSrc = vecSrc + g_Engine.v_up * 8;
                            vecSrc = vecSrc + g_Engine.v_right * 8;
                            break;
                        case 4: vecSrc = vecSrc + g_Engine.v_up * 8; break;
                        case 5:
                            vecSrc = vecSrc + g_Engine.v_up * 8;
                            vecSrc = vecSrc + g_Engine.v_right * -8;
                            break;
                        case 6: vecSrc = vecSrc + g_Engine.v_right * -8; break;
                        case 7:
                            vecSrc = vecSrc + g_Engine.v_up * -8;
                            vecSrc = vecSrc + g_Engine.v_right * -8;
                            break;
                        case 8:
                            vecSrc = vecSrc + g_Engine.v_up * -8;
                            m_iFirePhase = 0;
                            break;
                        }

                        m_pPlayer.pev.punchangle.x = Math.RandomFloat( 0.0, -2.0 );
                    }

                    m_flRechargeTimeL = g_Engine.time + 0.8;
                }
                break;
            }

            CBaseEntity@ cbeHornet = null;
            if( iFireMode == FIREMODE_FAST )
            {
                @cbeHornet = g_EntityFuncs.Create( "customhornet", vecSrc, m_pPlayer.pev.v_angle, false, m_pPlayer.edict() );
                if( cbeHornet !is null )
                {
                    cbeHornet.pev.dmg = 10;
                    @cbeHornet.pev.owner = @m_pPlayer.edict();

                    cbeHornet.pev.velocity = g_Engine.v_forward * 1200;
                    cbeHornet.pev.angles = Math.VecToAngles( cbeHornet.pev.velocity );

                    CHornet@ pHornet = cast<CHornet@>( CastToScriptClass( cbeHornet ) );
                    pHornet.SetThink( ThinkFunction(pHornet.StartDart) );
                }
            }
            else
            {
                @cbeHornet = g_EntityFuncs.Create( "hornet", vecSrc, m_pPlayer.pev.v_angle, false, m_pPlayer.edict() );
                if( cbeHornet !is null )
                {
                    cbeHornet.pev.dmg = 10;
                    @cbeHornet.pev.owner = @m_pPlayer.edict();
                    cbeHornet.pev.velocity = g_Engine.v_forward * 300;
                }
            }

            g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pFireSounds[Math.RandomLong(0, pFireSounds.length()-1)], 1.0, ATTN_NORM, 0, PITCH_NORM );

            m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
            m_pPlayer.m_iWeaponFlash = DIM_GUN_FLASH;

            m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

            self.m_flNextPrimaryAttack = g_Engine.time + flNextAttack;
            self.m_flNextSecondaryAttack = g_Engine.time + flNextAttack;
            self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
        }

        private void SetNextUzisAnim()
        {
            SetThink( null );
            m_pPlayer.m_szAnimExtension = "uzis_left";

            SetThink( ThinkFunction( this.ResetUzisAnim ) );
            self.pev.nextthink = g_Engine.time + (34.0/14.0);
        }

        void Reload()
        {
            if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= DHGUN_MAX_CLIP )
            {
                while( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) < DHGUN_MAX_CLIP && m_flRechargeTimeR < g_Engine.time )
                {
                    m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) + 1 );
                    m_flRechargeTimeR += 1.5f;
                }
            }

            if( m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) <= DHGUN_MAX_CLIP )
            {
                while( m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) < DHGUN_MAX_CLIP && m_flRechargeTimeL < g_Engine.time )
                {
                    m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) + 1 );
                    m_flRechargeTimeL += 1.5f;
                }
            }
        }

        void WeaponIdle()
        {
        
            Reload();
            
            if( self.m_flTimeWeaponIdle > g_Engine.time )
                return;

            int iAnim;
            float flRand = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  0, 1 );
            if (flRand <= 0.75)
            {
                switch( Math.RandomLong(0,2) )
                {
                case 0: iAnim = DHGUN_IDLE1; break;
                case 1: iAnim = DHGUN_IDLE2; break;
                case 2: iAnim = DHGUN_IDLE3; break;
                }
                self.m_flTimeWeaponIdle = g_Engine.time + 30.0 / 16 * (2);
            }
            else if (flRand <= 0.875)
            {
                switch( Math.RandomLong(0,1) )
                {
                case 0: iAnim = DHGUN_FIDGETSWAY_L; break;
                case 1: iAnim = DHGUN_FIDGETSWAY_R; break;
                }
                self.m_flTimeWeaponIdle = g_Engine.time + 40.0 / 16.0;
            }
            else
            {
                switch( Math.RandomLong(0,1) )
                {
                case 0: iAnim = DHGUN_FIDGETSHAKE_L; break;
                case 1: iAnim = DHGUN_FIDGETSHAKE_R; break;
                }
                self.m_flTimeWeaponIdle = g_Engine.time + 35.0 / 16.0;
            }
            self.SendWeaponAnim( iAnim );
        }

        /*CBasePlayerItem@ DropItem() 
        {
            return null;
        }*/
    }

    void Register()
    {
        //CustomHornet::Register();
        g_CustomEntityFuncs.RegisterCustomEntity( "CHornet", "customhornet" );
        g_CustomEntityFuncs.RegisterCustomEntity( "XENDHGun::weapon_hornetgundual", "weapon_hornetgundual" );
        g_ItemRegistry.RegisterWeapon( "weapon_hornetgundual", "pov", "hornet", "customhornet" );
    }

} //namespace XENDHGun END



//
// Author: Gaftherman
// Taken and ported from: https://github.com/SamVanheer/halflife-updated/blob/master/dlls/rat.cpp
//
// ===================================
//
// Why is this here?
// 1.- I use it as a base to create enemies.
// 2.- Do not really expect more point for which I stand out because I did it.
//
// Usage: In your map script include this
//	#include "../monster_rat_custom"
// and in your MapInit() {...}
//	"MonsterRatCustom::Register();"
//
// ===================================
//

namespace MonsterRatCustom
{
	//=========================================================
	// Monster's Anim Events Go Here
	//=========================================================

	class CRatCustom : ScriptBaseMonsterEntity
	{
		//=========================================================
		// Classify - indicates this monster's place in the 
		// relationship table.
		//=========================================================
		int	Classify()
		{
			return	self.GetClassification( CLASS_INSECT );
		}

		//=========================================================
		// SetYawSpeed - allows each sequence to have a different
		// turn rate associated with it.
		//=========================================================
		void SetYawSpeed()
		{
			int ys;

			switch ( self.m_Activity )
			{
				case ACT_IDLE:

				default: ys = 45; break;
			}

			self.pev.yaw_speed = ys;
		}

		//=========================================================
		// Spawn
		//=========================================================
		void Spawn()
		{
			Precache( );

			g_EntityFuncs.SetModel( self, "models/bigrat.mdl");
			g_EntityFuncs.SetSize( self.pev, Vector( 0, 0, 0 ), Vector( 0, 0, 0 ) );

			pev.solid				= SOLID_SLIDEBOX;
			pev.movetype			= MOVETYPE_STEP;
			self.m_bloodColor		= BLOOD_COLOR_RED;
			self.pev.health			= 8;
			pev.view_ofs			= Vector ( 0, 0, 3 );// position of the eyes relative to monster's origin.
			self.m_flFieldOfView	= 0.5;// indicates the width of this monster's forward view cone ( as a dotproduct result )
			self.m_MonsterState		= MONSTERSTATE_NONE;

			self.m_FormattedName	= "Rat";

			self.MonsterInit();
		}

		//=========================================================
		// Precache - precaches all resources this monster needs
		//=========================================================
		void Precache()
		{
			g_Game.PrecacheModel("models/bigrat.mdl");
		}	

		//=========================================================
		// AI Schedules Specific to this monster
		//=========================================================
	}

	void Register()
	{
		g_CustomEntityFuncs.RegisterCustomEntity("MonsterRatCustom::CRatCustom", "monster_rat_custom");
	}
}