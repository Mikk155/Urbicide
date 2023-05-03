#include "../utils"

enum weapon_flashlight_ANIMATION
{
	FLASHLIGHT_IDLE = 0,
	FLASHLIGHT_DRAW,
	FLASHLIGHT_HOLSTER,
	FLASHLIGHT_SWITCH
};

namespace weapon_flashlight
{
	string DATA_CLASSNAME;

	void Register( const string& in ConfigFile = 'scripts/maps/mikk/config/weapon_flashlight.txt' )
	{
        string line;

        File@ pFile = g_FileSystem.OpenFile( ConfigFile, OpenFile::READ );

        if( pFile is null or !pFile.IsOpen() )
        {
            g_Util.Debug( "weapon_flashlight: Failed to open " + ConfigFile + " no entity registered!" );
            return;
        }

        while( !pFile.EOFReached() )
        {
            pFile.ReadLine( line );
            g_Util.Debug( line );

            if( line.Length() < 1 or line[0] == '/' and line[1] == '/' or line[0] == '{' or line[0] == '}' or line[0] == '#' )
            {
                continue;
            }

            if( line.Find( DATA_CLASSNAME ) >= 0 )
			{
				DATA_CLASSNAME = line.Replace( 'DATA_CLASSNAME ', '' );
            }
        }
        pFile.Close();

		g_CustomEntityFuncs.RegisterCustomEntity( DATA_CLASSNAME, DATA_CLASSNAME );
		g_ItemRegistry.RegisterWeapon( DATA_CLASSNAME, SPR_CAT, A_P_TYPE, A_S_TYPE, A_P_NAME, A_S_NAME );
		g_Game.PrecacheOther( DATA_CLASSNAME );
	}

	const string A_P_NAME 		= ""; //Esto sirve para registrar la municion primaria del arma que utiliza.
	const string A_P_TYPE 		= ""; //Tipo de la municion de la municion primaria.
	const string A_S_NAME 		= ""; //Esto sirve para registrar la municion secundaria del arma que utiliza.
	const string A_S_TYPE 		= ""; //Tipo de la municion de la municion secundaria.

	const string W_MODEL 		= "models/mikk/misc/w_flashlight.mdl"; //Modelo que aparece en el mundo.
	const string P_MODEL 		= "models/mikk/misc/p_flashlight.mdl"; //Modelo que tienen otros jugadores.
	const string V_MODEL 		= "models/mikk/misc/b_flashlight.mdl"; //Model que ve el jugador en primera persona.
	const string SPR_CAT 		= "hcl_weapons"; //Direccion del .spr
	const string A_EXTENSION 	= "onehanded"; //Mirar "https://github.com/baso88/SC_AngelScript/wiki/Animation-Extensions"

	const string EMPTY_S 		= "hlclassic/weapons/357_cock1.wav"; //Sonido al disparar cuando el arma tenga 0/¿?

	const float P_SHOOT_TIME 	= 0.35f; //Tiempo en la cual podemos hacer el siguiente disparo.
	const float DEPLOY_TIME 	= 1.05f; //Tiempo en el cual tardamos en desplegar el arma.

    const int MAX_P_AMMO 		= -1; //Maxima municion primaria.
    const int MAX_P_CLIP 		= -1; //Maxima municion primaria por clip.
    const int MAX_S_AMMO 		= -1; //Maxima municion secundaria.
    const int MAX_S_CLIP 		= -1; //Maxima municion secundaria por ¿clip?.
    const int SLOT       		= 2; //Slot en el cual el arma estara.
    const int POSITION   		= 6; //Posicion del arma en su slot. Arriba o abajo comparando con otras armas.
    const int FLAGS      		= ITEM_FLAG_NOAUTOSWITCHEMPTY; //Mirar ItemFlag. Ejemplo de uso: FLAGS = ITEM_FLAG_NOAUTORELOAD; FLAGS = (ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY);
    const int WEIGHT     		= 17; //Prioridad del arma cuando se va a tomar (Creo que era eso por lo que sirve esto).
}

class weapon_flashlight : ScriptBasePlayerWeaponEntity
{
    private CScheduledFunction@ PlayerLightSchedule = null;
	private CScheduledFunction@ PlayerLessFlashlight = null;
    private bool flashlight = false;

    // private array<string> Sprites = 
	// {

	// };

	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, 'models/mikk/misc/w_flashlight.mdl' );
    }

    void Precache()
    {
		g_Game.PrecacheGeneric( 'sound/' + weapon_flashlight::EMPTY_S );
		g_SoundSystem.PrecacheSound( weapon_flashlight::EMPTY_S );
		g_Game.PrecacheGeneric( 'sound/' + 'items/flashlight1.wav' );
		g_SoundSystem.PrecacheSound( 'items/flashlight1.wav' );
		g_Game.PrecacheModel( weapon_flashlight::W_MODEL );
		g_Game.PrecacheGeneric( weapon_flashlight::W_MODEL );
		g_Game.PrecacheModel( weapon_flashlight::V_MODEL );
		g_Game.PrecacheGeneric( weapon_flashlight::V_MODEL );
		g_Game.PrecacheModel( weapon_flashlight::P_MODEL );
		g_Game.PrecacheGeneric( weapon_flashlight::P_MODEL );
    }

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= weapon_flashlight::MAX_P_AMMO;
		info.iAmmo1Drop	= weapon_flashlight::MAX_P_CLIP;
		info.iMaxAmmo2 	= weapon_flashlight::MAX_S_AMMO;
		info.iAmmo2Drop	= weapon_flashlight::MAX_S_CLIP;
		info.iMaxClip 	= WEAPON_NOCLIP;
		info.iSlot  	= weapon_flashlight::SLOT;
		info.iPosition 	= weapon_flashlight::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags 	= weapon_flashlight::FLAGS;
		info.iWeight 	= weapon_flashlight::WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;
			
		@m_pPlayer = pPlayer;

		NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			message.WriteLong( self.m_iId );
		message.End();

		return true;
	}

	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, weapon_flashlight::EMPTY_S, 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
		
		return false;
	}

	bool Deploy()
	{
		// return self.DefaultDeploy( self.GetV_Model( weapon_flashlight::V_MODEL ), self.GetP_Model( weapon_flashlight::P_MODEL ), FLASHLIGHT_DRAW, weapon_flashlight::A_EXTENSION, 0, weapon_flashlight::DEPLOY_TIME );
		return self.DefaultDeploy( self.GetV_Model( weapon_flashlight::V_MODEL ), self.GetP_Model( weapon_flashlight::P_MODEL ), FLASHLIGHT_DRAW, '' );
    }

	void ItemPreFrame()
	{
		if( m_pPlayer.pev.armorvalue <= 0 && flashlight )
		{
			self.SendWeaponAnim( FLASHLIGHT_SWITCH, 0, 0 );

            flashlight = false;

            g_Scheduler.RemoveTimer( PlayerLightSchedule );
		    @PlayerLightSchedule = @null;

            g_Scheduler.RemoveTimer( PlayerLessFlashlight );
		    @PlayerLessFlashlight = @null;

			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "items/flashlight1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
		}

		BaseClass.ItemPreFrame();
	}

	void Holster( int skipLocal = 0 )
	{
		m_pPlayer.pev.viewmodel = string_t();

        flashlight = false;

		g_Scheduler.RemoveTimer( PlayerLightSchedule );
		@PlayerLightSchedule = @null;

        g_Scheduler.RemoveTimer( PlayerLessFlashlight );
		@PlayerLessFlashlight = @null;

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( ( m_pPlayer.m_afButtonPressed & IN_ATTACK == 0 ) )
			return;

		if( m_pPlayer.pev.armorvalue <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + weapon_flashlight::P_SHOOT_TIME;
			return;
		}

        if ( !flashlight )
        {
            flashlight = true;

			--m_pPlayer.pev.armorvalue;

            @PlayerLightSchedule = @g_Scheduler.SetInterval( @this, "LightPlayerThink", 0.0f, g_Scheduler.REPEAT_INFINITE_TIMES );
			@PlayerLessFlashlight = @g_Scheduler.SetInterval( @this, "LightPlayerLess", 10.0f, g_Scheduler.REPEAT_INFINITE_TIMES );
        }
        else
        {
            flashlight = false;

            g_Scheduler.RemoveTimer( PlayerLightSchedule );
		    @PlayerLightSchedule = @null;

            g_Scheduler.RemoveTimer( PlayerLessFlashlight );
		    @PlayerLessFlashlight = @null;
        }

		self.SendWeaponAnim( FLASHLIGHT_SWITCH, 0, 0 );
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "items/flashlight1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

		self.m_flNextPrimaryAttack = g_Engine.time + weapon_flashlight::P_SHOOT_TIME;
		self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
    }

	void LightPlayerThink()
	{
		LanternDLight( m_pPlayer.GetGunPosition() );
	}

	void LightPlayerLess()
	{
		--m_pPlayer.pev.armorvalue;
	}

	void LanternDLight( Vector& in vecPos )
	{
		int g_iAttenuation = 5;
		int g_iDistanceMax = 2000;
		int iLife		   = 2;

		//Nero Custom Flashlight plugin
        TraceResult iAim;
        g_Utility.TraceLine( vecPos, vecPos + g_Engine.v_forward * g_iDistanceMax, dont_ignore_monsters, m_pPlayer.edict(), iAim );

        float iDist = ( vecPos - iAim.vecEndPos ).Length();
        
        if( iDist > g_iDistanceMax )
            return;

		float iDecay, iAttn;
		iDecay = iDist * 255 / g_iDistanceMax;
		iAttn = 256 + iDecay * g_iAttenuation;

        NetworkMessage flon( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
            flon.WriteByte( TE_DLIGHT );
            flon.WriteCoord( iAim.vecEndPos.x );
            flon.WriteCoord( iAim.vecEndPos.y );
            flon.WriteCoord( iAim.vecEndPos.z );
            flon.WriteByte( int(9) );
			flon.WriteByte( int((255*128) / iAttn) );
			flon.WriteByte( int((255*128) / iAttn) );
			flon.WriteByte( int((255*128)/ iAttn) );
            flon.WriteByte( iLife );
            flon.WriteByte( int(iDecay) );
        flon.End();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		m_pPlayer.GetAutoaimVector( AUTOAIM_2DEGREES );

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( FLASHLIGHT_IDLE, 0, 0 ); 
		
		self.m_flTimeWeaponIdle = g_Engine.time + (40.0/16.0);
	}
}