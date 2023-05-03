/*
    Script original: https://github.com/JulianR0/TPvP/blob/master/src/map_scripts/hl_weapons/weapon_hlsnark.as


INSTALL:

#include "mikk/weapon_monster"

void MapInit()
{
    weapon_monster::Register( "monster_classname" );
}

*/

dictionary g_fileload;

void RegisterSnarks( const string ConstConfigFile )
{
    string StringConfigFile = ConstConfigFile;
    if( StringConfigFile == "" ) StringConfigFile = "mikk/weapons/weapon_snark";

    string line, key, value;

    File@ pFile = g_FileSystem.OpenFile( "scripts/maps/" + StringConfigFile + ".txt", OpenFile::READ );

    if( pFile is null or !pFile.IsOpen() )
        return;

    while( !pFile.EOFReached() )
    {
        pFile.ReadLine( line );

        if( line.Length() < 1 or line[0] == '/' and line[1] == '/' )
            continue;

        key = line.SubString( 0, line.Find( '" "') );
        key.Replace( '"', '' );

        value = line.SubString( line.Find( '" "'), line.Length() );
        value.Replace( '" "', '' );
        value.Replace( '"', '' );

        g_fileload[ key ] = value;
    }
    pFile.Close();

    g_CustomEntityFuncs.RegisterCustomEntity( "BaseWeaponSnarkCustom", string( g_fileload[ "classname" ] ) );
    g_ItemRegistry.RegisterWeapon( string( g_fileload[ "classname" ] ), string( g_fileload[ "sprite" ] ), "Snarks" );
}

const int SNARK_DEFAULT_GIVE = 5;
const int SNARK_MAX_CARRY = 15;
const int SNARK_MAX_CLIP = WEAPON_NOCLIP;
const int SNARK_WEIGHT = 5;

const float SQUEEK_DETONATE_DELAY = 15.0;

enum w_squeak_e
{
    WSQUEAK_IDLE1 = 0,
    WSQUEAK_FIDGET,
    WSQUEAK_JUMP,
    WSQUEAK_RUN,
};

enum squeak_e
{
    SQUEAK_IDLE1 = 0,
    SQUEAK_FIDGETFIT,
    SQUEAK_FIDGETNIP,
    SQUEAK_DOWN,
    SQUEAK_UP,
    SQUEAK_THROW
};

class BaseWeaponSnarkCustom : ScriptBasePlayerWeaponEntity
{
    private CBasePlayer@ m_pPlayer = null;
    
    int m_fJustThrown;
    
    void Spawn()
    {
        Precache();
        g_EntityFuncs.SetModel( self, "models/hl/w_sqknest.mdl" );
        
        self.m_iDefaultAmmo = SNARK_DEFAULT_GIVE;

        self.FallInit(); // get ready to fall down.
    }
    
    void Precache()
    {    
        g_Game.PrecacheModel( "models/hl/w_sqknest.mdl" );
        g_Game.PrecacheModel( "models/hl/v_squeak.mdl" );
        g_Game.PrecacheModel( "models/hl/p_squeak.mdl" );
        
        g_SoundSystem.PrecacheSound( "squeek/sqk_hunt2.wav" );
        g_SoundSystem.PrecacheSound( "squeek/sqk_hunt3.wav" );
        
        g_Game.PrecacheOther( "monster_hlsnark" );
        
        g_Game.PrecacheGeneric( "sprites/hl_weapons/weapon_hlsnark.txt" );
    }
    
    float WeaponTimeBase()
    {
        return g_Engine.time; //g_WeaponFuncs.WeaponTimeBase();
    }
    
    bool GetItemInfo( ItemInfo& out info )
    {
        info.iMaxAmmo1     = SNARK_MAX_CARRY;
        info.iMaxAmmo2     = -1;
        info.iMaxClip     = SNARK_MAX_CLIP;
        info.iSlot         = 4;
        info.iPosition     = 7;
        info.iFlags     = ( ITEM_FLAG_LIMITINWORLD | ITEM_FLAG_EXHAUSTIBLE );
        info.iWeight     = SNARK_WEIGHT;
        
        return true;
    }
    
    bool AddToPlayer( CBasePlayer@ pPlayer )
    {
        if( !BaseClass.AddToPlayer( pPlayer ) )
            return false;
        
        @m_pPlayer = pPlayer;
        
        return true;
    }
    
    bool Deploy()
    {
        // play hunt sound
        float flRndSound = Math.RandomFloat( 0, 1 );
        
        if ( flRndSound <= 0.5 )
            g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "squeek/sqk_hunt2.wav", 1, ATTN_NORM, 0, 100 );
        else 
            g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "squeek/sqk_hunt3.wav", 1, ATTN_NORM, 0, 100 );
        
        m_pPlayer.m_iWeaponVolume = QUIET_GUN_VOLUME;
        
        return self.DefaultDeploy( "models/hl/v_squeak.mdl", "models/hl/p_squeak.mdl", SQUEAK_UP, "squeak" );
    }
    
    void Holster( int skiplocal /* = 0 */ )
    {
        m_pPlayer.m_flNextAttack = WeaponTimeBase() + 0.5;
        self.SendWeaponAnim( SQUEAK_DOWN );
    }
    
    void InactiveItemPostFrame()
    {
        if ( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 )
        {
            self.DestroyItem();
            self.pev.nextthink = g_Engine.time + 0.1;
        }
    }
    
    void PrimaryAttack()
    {
        if ( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
        {
            g_EngineFuncs.MakeVectors( m_pPlayer.pev.v_angle );
            TraceResult tr;
            Vector trace_origin;

            // HACK HACK:  Ugly hacks to handle change in origin based on new physics code for players
            // Move origin up if crouched and start trace a bit outside of body ( 20 units instead of 16 )
            trace_origin = m_pPlayer.pev.origin;
            
            int bCheck = m_pPlayer.pev.flags;
            if ( ( bCheck &= FL_DUCKING ) == FL_DUCKING )
            {
                trace_origin = trace_origin - ( VEC_HULL_MIN - VEC_DUCK_HULL_MIN );
            }
            
            // find place to toss monster
            g_Utility.TraceLine( trace_origin + g_Engine.v_forward * 20, trace_origin + g_Engine.v_forward * 64, dont_ignore_monsters, null, tr );
            
            if ( tr.fAllSolid == 0 && tr.fStartSolid == 0 && tr.flFraction > 0.25 )
            {
                // player "shoot" animation
                self.SendWeaponAnim( SQUEAK_THROW );
                m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
                
                CBaseEntity@ pSqueak = g_EntityFuncs.Create( "monster_hlsnark", tr.vecEndPos, m_pPlayer.pev.v_angle, false, m_pPlayer.edict() );
                pSqueak.pev.velocity = g_Engine.v_forward * 200 + m_pPlayer.pev.velocity;
                
                // play hunt sound
                float flRndSound = Math.RandomFloat( 0, 1 );
                
                if ( flRndSound <= 0.5 )
                    g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "squeek/sqk_hunt2.wav", 1, ATTN_NORM, 0, 105 );
                else 
                    g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "squeek/sqk_hunt3.wav", 1, ATTN_NORM, 0, 105 );

                m_pPlayer.m_iWeaponVolume = QUIET_GUN_VOLUME;
                
                int iAmmo = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );
                m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, --iAmmo );
                
                m_fJustThrown = 1;
                
                self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.3;
                self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.0;
            }
        }
    }
    
    void WeaponIdle()
    {
        if ( self.m_flTimeWeaponIdle > WeaponTimeBase() )
            return;

        if ( m_fJustThrown == 1 )
        {
            m_fJustThrown = 0;

            if ( m_pPlayer.m_rgAmmo( self.PrimaryAmmoIndex() ) == 0 )
            {
                self.RetireWeapon();
                return;
            }

            self.SendWeaponAnim( SQUEAK_UP );
            self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 );
            return;
        }
        
        int iAnim;
        float flRand = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 0, 1 );
        if ( flRand <= 0.75 )
        {
            iAnim = SQUEAK_IDLE1;
            self.m_flTimeWeaponIdle = WeaponTimeBase() + 30.0 / 16 * ( 2 );
        }
        else if ( flRand <= 0.875 )
        {
            iAnim = SQUEAK_FIDGETFIT;
            self.m_flTimeWeaponIdle = WeaponTimeBase() + 70.0 / 16.0;
        }
        else
        {
            iAnim = SQUEAK_FIDGETNIP;
            self.m_flTimeWeaponIdle = WeaponTimeBase() + 80.0 / 16.0;
        }
        self.SendWeaponAnim( iAnim );
    }
}