enum WEAPON_HCL_USP_ANIMATION
{
	USP_IDLE1 = 0,
	USP_IDLE2,
	USP_IDLE3,
	USP_SHOOT,
    USP_SHOOT_EMPTY,
    USP_RELOAD_EMPTY,
    USP_RELOAD,
    USP_DRAW, 
    USP_HOLSTER
};

namespace WEAPON_HCL_USP
{
	const string W_NAME   		= "weapon_hcl_usp"; //Esto sirve para registrar el arma.
	const string A_P_NAME 		= "ammo_glock"; //Esto sirve para registrar la municion primaria del arma que utiliza.
	const string A_P_TYPE 		= "9mm"; //Tipo de la municion de la municion primaria.
	const string A_S_NAME 		= ""; //Esto sirve para registrar la municion secundaria del arma que utiliza.
	const string A_S_TYPE 		= ""; //Tipo de la municion de la municion secundaria.

	const string W_MODEL 		= "models/mikk/hcl/world/w_usp.mdl"; //Modelo que aparece en el mundo.
	const string P_MODEL 		= "models/mikk/hcl/player/p_usp.mdl"; //Modelo que tienen otros jugadores.
	const string V_MODEL 		= "models/mikk/hcl/view/v_usp.mdl"; //Model que ve el jugador en primera persona.
	const string SPR_CAT 		= "hcl_weapons"; //Direccion del .spr
	const string A_EXTENSION 	= "onehanded"; //Mirar "https://github.com/baso88/SC_AngelScript/wiki/Animation-Extensions"

	const string EMPTY_S 		= "hlclassic/weapons/357_cock1.wav"; //Sonido al disparar cuando el arma tenga 0/¿?

	const float P_SHOOT_TIME 	= 0.10f; //Tiempo en la cual podemos hacer el siguiente disparo.
	const float DEPLOY_TIME 	= 1.05f; //Tiempo en el cual tardamos en desplegar el arma.

	const float RELOAD_TIME		= 2.03f; //Tiempo en el cual tardas en recargar un clip.
	const float RELOAD_TIME_EMPTY = 2.03f; //Tiempo en el cual tardas en recargar un clip cuando la municion este en 0/¿?.

	const int P_AMMO_SPAWN		= 17; //Municion primaria que se toma al recoger el arma.
	const int S_AMMO_SPAWN		= 0; //Municion secundaria que se toma al recoger el arma.

    const int MAX_P_AMMO 		= 250; //Maxima municion primaria.
    const int MAX_P_CLIP 		= 17; //Maxima municion primaria por clip.
    const int MAX_S_AMMO 		= -1; //Maxima municion secundaria.
    const int MAX_S_CLIP 		= -1; //Maxima municion secundaria por ¿clip?.
    const int SLOT       		= 1; //Slot en el cual el arma estara.
    const int POSITION   		= 6; //Posicion del arma en su slot. Arriba o abajo comparando con otras armas.
    const int FLAGS      		= ITEM_FLAG_NOAUTOSWITCHEMPTY; //Mirar ItemFlag. Ejemplo de uso: FLAGS = ITEM_FLAG_NOAUTORELOAD; FLAGS = (ITEM_FLAG_NOAUTORELOAD | ITEM_FLAG_NOAUTOSWITCHEMPTY);
    const int WEIGHT     		= 17; //Prioridad del arma cuando se va a tomar (Creo que era eso por lo que sirve esto).

	const int NUM_SHOTS	 		= 1; //Numero de disparos al ¿dispara?.
	const int MAX_DISTANCE 		= 8192; //Maxima distancia a la cual llegara la bala disparada.
	const int BULLET_C_DAMAGE 	= 16; //Daño del arma customizable.

	const int SHELL_MODEL 		= g_Game.PrecacheModel( "models/shell.mdl" ); //Modelo del la bala al ser disparada ¿pq no en string xdn't?.

	const float PUNCH_ANGLE_X 	= 1.5f; //Al disparar la mira se va a mover un poco en el angulo x

	const Vector FIRE_BULLET_VEC_SPREAD_IN_AIR	= VECTOR_CONE_6DEGREES; //Vector del disparo mientras esta en el aire (Osea, cuanto se va a espacir las balas ).
	const Vector FIRE_BULLET_VEC_SPREAD_IN_DUCK = VECTOR_CONE_1DEGREES; //Vector del disparo mientras esta agachado (Osea, cuanto se va a espacir las balas ).
	const Vector FIRE_BULLET_VEC_SPREAD_MOVING 	= VECTOR_CONE_3DEGREES; //Vector del disparo mientras se mueve (Osea, cuanto se va a espacir las balas ).
	const Vector FIRE_BULLET_VEC_SPREAD_DEFAULT	= VECTOR_CONE_2DEGREES; //Vector del disparo mientras no hace nada (Osea, cuanto se va a espacir las balas ).
	const Vector SHELL_EJECT 					= Vector( 20, -10, 7 ); //Vector cuando expulsa la bala.

	void Register()
	{
		g_CustomEntityFuncs.RegisterCustomEntity( W_NAME, W_NAME ); // Register the weapon entity
		//g_CustomEntityFuncs.RegisterCustomEntity( A_NAME, A_NAME ); // Register the ammo entity
		g_ItemRegistry.RegisterWeapon( W_NAME, SPR_CAT, A_P_TYPE, A_S_TYPE, A_P_NAME, A_S_NAME ); // Register the weapon
	}
}

class weapon_hcl_usp : ScriptBasePlayerWeaponEntity, HCLBASE::WeaponBase
{
	private int GetBodygroup()
	{
		return 0;
	}

    private array<string> Sounds  = 
	{
		WEAPON_HCL_USP::EMPTY_S,
        "hlclassic/weapons/pl_gun1.wav",
        "hlclassic/weapons/pl_gun2.wav"
	};
    private array<string> Models = 
	{
		WEAPON_HCL_USP::W_MODEL, 
		WEAPON_HCL_USP::P_MODEL,
		WEAPON_HCL_USP::V_MODEL
	};
    private array<string> Sprites = 
	{
		"sprites/ofch1.spr"
	};

	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}

	void Spawn()
	{
        Precache();
        DefaultSpawn( WEAPON_HCL_USP::W_MODEL, WEAPON_HCL_USP::P_AMMO_SPAWN, WEAPON_HCL_USP::S_AMMO_SPAWN );
    }

    void Precache()
    {
        HCLBASE_PRECACHE::PrecacheSound( Sounds );
        HCLBASE_PRECACHE::PrecacheModel( Models ); 
        HCLBASE_PRECACHE::PrecacheSprite( Sprites );
    }

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= WEAPON_HCL_USP::MAX_P_AMMO;
		info.iAmmo1Drop	= WEAPON_HCL_USP::MAX_P_CLIP;
		info.iMaxAmmo2 	= WEAPON_HCL_USP::MAX_S_AMMO;
		info.iAmmo2Drop	= WEAPON_HCL_USP::MAX_S_CLIP;
		info.iMaxClip 	= WEAPON_HCL_USP::MAX_P_CLIP;
		info.iSlot  	= WEAPON_HCL_USP::SLOT;
		info.iPosition 	= WEAPON_HCL_USP::POSITION;
		info.iId     	= g_ItemRegistry.GetIdForName( self.pev.classname );
		info.iFlags 	= WEAPON_HCL_USP::FLAGS;
		info.iWeight 	= WEAPON_HCL_USP::WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		return DefaultAddToPlayer( pPlayer );
	}

	bool PlayEmptySound()
	{
		return DefaultPlayEmptySound( WEAPON_HCL_USP::EMPTY_S );
	}

	bool Deploy()
	{
        return DefaultDeploy( WEAPON_HCL_USP::V_MODEL, WEAPON_HCL_USP::P_MODEL, USP_DRAW, WEAPON_HCL_USP::A_EXTENSION, GetBodygroup(), WEAPON_HCL_USP::DEPLOY_TIME );
    }

	void Holster( int skipLocal = 0 )
	{
        DefaultHolster();

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( ( m_pPlayer.m_afButtonPressed & IN_ATTACK == 0 ) )
			return;

		if( self.m_iClip <= 0 || m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;
			return;
		}

		m_pPlayer.m_iWeaponVolume = QUIET_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = DIM_GUN_FLASH;

		--self.m_iClip;
        ++m_iShotsFired;

		if( self.m_iClip != 0 )
			self.SendWeaponAnim( USP_SHOOT );
		else
			self.SendWeaponAnim( USP_SHOOT_EMPTY );

		switch( Math.RandomLong( 0, 1 ) )
		{
			case 0: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/pl_gun1.wav", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) ); break;
			case 1: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/pl_gun2.wav", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) ); break;
		}

		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc   	= m_pPlayer.GetGunPosition();
		Vector vecAiming 	= m_pPlayer.GetAutoaimVector( AUTOAIM_2DEGREES );
        Vector vecAcc       = RealisticVecAcc( WEAPON_HCL_USP::FIRE_BULLET_VEC_SPREAD_DEFAULT, WEAPON_HCL_USP::FIRE_BULLET_VEC_SPREAD_IN_AIR, WEAPON_HCL_USP::FIRE_BULLET_VEC_SPREAD_IN_DUCK, WEAPON_HCL_USP::FIRE_BULLET_VEC_SPREAD_MOVING ) * (m_iShotsFired * 0.25f);

		m_pPlayer.FireBullets( WEAPON_HCL_USP::NUM_SHOTS, vecSrc, vecAiming, vecAcc, WEAPON_HCL_USP::MAX_DISTANCE, BULLET_PLAYER_CUSTOMDAMAGE, 0, WEAPON_HCL_USP::BULLET_C_DAMAGE );

        m_pPlayer.pev.punchangle.x -= WEAPON_HCL_USP::PUNCH_ANGLE_X;

		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		self.m_flNextPrimaryAttack = WeaponTimeBase() + WEAPON_HCL_USP::P_SHOOT_TIME;

		DynamicLight( m_pPlayer.EyePosition() + g_Engine.v_forward * 64, 14, Vector(255, 232, 156), 1, 100 );

		ShellEject( m_pPlayer, WEAPON_HCL_USP::SHELL_MODEL, WEAPON_HCL_USP::SHELL_EJECT );

		DecalGunshot( WEAPON_HCL_USP::NUM_SHOTS, vecAiming, vecSrc, vecAcc, WEAPON_HCL_USP::MAX_DISTANCE, BULLET_PLAYER_CUSTOMDAMAGE );

		self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.9f;
	}

	void Reload()
	{
		if( self.m_iClip == WEAPON_HCL_USP::MAX_P_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			return;

		if( self.m_iClip == 0 )
			DefaultReload( WEAPON_HCL_USP::MAX_P_CLIP, USP_RELOAD_EMPTY, WEAPON_HCL_USP::RELOAD_TIME_EMPTY, GetBodygroup() );
		else
			DefaultReload( WEAPON_HCL_USP::MAX_P_CLIP, USP_RELOAD, WEAPON_HCL_USP::RELOAD_TIME, GetBodygroup() );

		//Set 3rd person reloading animation -Sniper
		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle < WeaponTimeBase() ) 
            m_iShotsFired = 0;
		
		self.ResetEmptySound();

		m_pPlayer.GetAutoaimVector( AUTOAIM_2DEGREES );

		if( self.m_flTimeWeaponIdle > WeaponTimeBase() || self.m_iClip == 0)
			return;

		switch( Math.RandomLong( 0, 2 ) )
		{
			case 0: self.SendWeaponAnim( USP_IDLE1, 0, GetBodygroup() ); break;
			case 1: self.SendWeaponAnim( USP_IDLE2, 0, GetBodygroup() ); break;
			case 2: self.SendWeaponAnim( USP_IDLE3, 0, GetBodygroup() ); break;
		}

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 );
	}

	void ItemPreFrame()
	{
		CustomCrosshair();

		BaseClass.ItemPreFrame();
	}

	void CustomCrosshair()
	{
		HUDSpriteParams params;
		params.channel = 4;

		// Default mode is additive, so no flag is needed to assign it
		params.flags = HUD_ELEM_SCR_CENTER_X | HUD_ELEM_SCR_CENTER_Y |HUD_ELEM_DYNAMIC_ALPHA;
		params.spritename = "ofch1.spr";
		params.left = 0;
		params.top = 0;
		params.width = 24;
		params.height = 24;
		params.color1 = RGBA_SVENCOOP; //¿Mb hacer que el jugador pueda tener su crosshair de el color que quiera?
		params.frame = 0;
		params.numframes = 1;
		params.framerate = 0;
		params.fadeinTime = 0;
		params.fadeoutTime = 0;
		params.holdTime = 0;
		params.effect = HUD_EFFECT_NONE;

		g_PlayerFuncs.HudCustomSprite( m_pPlayer, params );
	}
}