/*
    Sorry for my edit but i can't leave any "if" without his {keys}
    
    

INSTALL:

#include "mikk/entities/point_checkpoint"

void MapInit()
{
    RegisterPointCheckPointEntity(); // Call bellow game_text_custom!
}

*/

// YOU NEED 
// Must include https://github.com/Outerbeast/Entities-and-Gamemodes/blob/master/respawndead_keepweapons.as
// FOR THIS SCRIPT WORK. thanks for your atemption.

#include "../../respawndead_keepweapons"

dictionary keyvalues;
HUDTextParams SpawnCountHudText;

void RegisterPointCheckPointEntity()
{
    g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, @PlayerUseSpawn::PlayerUse );
    g_CustomEntityFuncs.RegisterCustomEntity( "point_checkpoint", "point_checkpoint" );
    g_Game.PrecacheOther( "point_checkpoint" );

    keyvalues =    
    {
        { "message", "Press 'E' key or 'Primary attack' to respawn"},
        { "message_spanish", "Presione la tecla 'E' o 'ataque primario' para reaparecer"},
        { "message_portuguese", "Pressione a tecla 'E' ou 'Ataque primario' para reaparecer"},
        { "message_french", "Appuyez sur la touche 'E' ou 'Attaque principale' pour reapparaitre"},
        { "message_italian", "Premi il tasto 'E' o 'Attacco primario' per rigenerarti"},
        { "message_esperanto", "Premu la 'E' au 'Prima atako' klavon por reakiri"},
        { "message_german", "Drucken Sie die 'E'-Taste oder 'Primarangriff', um zu respawnen"},
        { "x", "-1"},
        { "y", "0.67"},
        { "effect", "0"},
        { "holdtime", "1"},
        { "fadeout", "0"},
        { "fadein", "0"},
        { "channel", "7"},
        { "fxtime", "0"},
        { "color", "255 0 0"},
        { "color2", "100 100 100"},
        { "spawnflags", "2"}, // No echo console + activator only
        { "targetname", "GZ_IZL_HOWTOUSE"}
    };
    if( g_CustomEntityFuncs.IsCustomEntity( "game_text_custom" ) )
    { g_EntityFuncs.CreateEntity( "game_text_custom", keyvalues, true ); }
    else{ g_EntityFuncs.CreateEntity( "game_text", keyvalues, true ); }
}

/*
* point_checkpoint
* This point entity represents a point in the world where players can trigger a checkpoint
* Dead players are revived

Outerbeast: - additional fixes and improvements were made, still WIP.
I've signed every change I made, just ctrl+f "Outerbeast"
*/

enum PointCheckpointFlags
{
    SF_CHECKPOINT_REUSABLE         = 1 << 0,    //This checkpoint is reusable
    SF_CHECKPOINT_STARTINACTIVE    = 1 << 1,    //This checkpoint starts disabled, trigger to enable - Outerbeast
    SF_DONT_EQUIP_SPAWNED        = 1 << 2,    //Disable spawned players from triggering game_player_equips - Outerbeast
    SF_TRIGGERED_MSG            = 1 << 3    //Print a chat message showing a checkpoint was triggered - Outerbeast
}

class point_checkpoint : ScriptBaseAnimating
{
    private CSprite@ m_pSprite;
    private string m_sActivationMusic = "../media/valve.mp3"; // Class member so it can be customisable - Outerbeast
    private int m_iNextPlayerToRevive = 1;
    
    // How much time between being triggered and starting the revival of dead players
    private float m_flDelayBeforeStart             = 2;
    
    // Time between player revive
    private float m_flDelayBetweenRevive         = 0.4;
    
    // How much time before this checkpoint becomes active again, if SF_CHECKPOINT_REUSABLE is set
    private float m_flDelayBeforeReactivation     = 120;     
    
    // When we started a respawn
    private float m_flRespawnStartTime;                    
    
    // Show Xenmaker-like effect when the checkpoint is spawned?
    private bool m_fSpawnEffect                    = true; 
    // Keep track of whether the entity is initialised or not - Outerbeast
    private bool m_bInitialised                    = false;
    
    // They hunger thing
    private Vector m_vecLightningStart = Vector(0,0,0);
    
    bool KeyValue( const string& in szKey, const string& in szValue )
    {
        if( szKey == "m_flDelayBeforeStart" )
        {
            m_flDelayBeforeStart = atof( szValue );
            return true;
        }
        else if( szKey == "m_flDelayBetweenRevive" )
        {
            m_flDelayBetweenRevive = atof( szValue );
            return true;
        }
        else if( szKey == "m_flDelayBeforeReactivation" )
        {
            m_flDelayBeforeReactivation = atof( szValue );
            return true;
        }
        else if( szKey == "minhullsize" )
        {
            g_Utility.StringToVector( self.pev.vuser1, szValue );
            return true;
        }
        else if( szKey == "maxhullsize" )
        {
            g_Utility.StringToVector( self.pev.vuser2, szValue );
            return true;
        }
        else if( szKey == "m_fSpawnEffect" )
        {
            m_fSpawnEffect = atoi( szValue ) != 0;
            return true;
        }
        else if( szKey == "m_sActivationMusic" ) // Key to change activation music to something other than valve theme - Outerbeast
        {
            m_sActivationMusic = szValue;
            return true;
        }
        else
            return BaseClass.KeyValue( szKey, szValue );
    }
    
    // If youre gonna use this in your script, make sure you don't try
    // to access invalid animations. -zode
    void SetAnim( int animIndex ) 
    {
        self.pev.sequence = animIndex;
        self.pev.frame = 0;
        self.ResetSequenceInfo();
    }
    
    void Precache()
    {
        BaseClass.Precache();
        
        // Allow for custom models
        if( string( self.pev.model ).IsEmpty() )
        {
            g_Game.PrecacheModel( "models/common/lambda.mdl" );
        }
        else if(string(g_Engine.mapname).StartsWith ( "th_" ) )
        {
            g_Game.PrecacheModel( "models/hunger/umbrella.mdl" );
            g_Game.PrecacheModel("sprites/lgtning.spr");
            g_SoundSystem.PrecacheSound( "hunger/checkpointjingle.mp3" );
        }
        else
        {
            g_Game.PrecacheModel( self.pev.model );
        }
        
        g_Game.PrecacheModel( "sprites/exit1.spr" );
        g_Game.PrecacheModel( "sprites/fexplo1.spr" ); // Outerbeast: Fix for precache host error in CreateSpawnEffect()
        
        g_SoundSystem.PrecacheSound( m_sActivationMusic );
        g_SoundSystem.PrecacheSound( "debris/beamstart7.wav" );
        g_SoundSystem.PrecacheSound( "ambience/port_suckout1.wav" );
        
        if( string( self.pev.message ).IsEmpty() )
        {
            self.pev.message = "debris/beamstart4.wav";
        }
        else
        {
            g_SoundSystem.PrecacheSound( self.pev.message );
        }
    }
    
    void Spawn()
    {
        Precache();
        
        self.pev.movetype         = MOVETYPE_NONE;
        self.pev.solid             = SOLID_TRIGGER;
        
        self.pev.framerate         = 1.0f;
        
        // Enabled by default
        self.pev.health            = 1.0f;
        
        // Not activated by default
        self.pev.frags            = 0.0f;
        
        // Allow for custom models
        if( string( self.pev.model ).IsEmpty() )
        {
            g_EntityFuncs.SetModel( self, "models/common/lambda.mdl" );
        }
        else if(string(g_Engine.mapname).StartsWith ( "th_" ) )
        {
            g_EntityFuncs.SetModel( self, "models/hunger/umbrella.mdl" );
            m_sActivationMusic = string( "hunger/checkpointjingle.mp3" );
        }
        else if(string(g_Engine.mapname).StartsWith ( "aom" ) )
        {
            g_EntityFuncs.SetModel( self, "models/aomdc/lambda_custom.mdl" );
            m_sActivationMusic = string( "aomdc/misc/checkpoint.wav" );
            m_fSpawnEffect = false;
        }
        else
        {
            g_EntityFuncs.SetModel( self, self.pev.model );
        }
        
        g_EntityFuncs.SetOrigin( self, self.pev.origin );
        
        // Custom hull size
        if( self.pev.vuser1 != g_vecZero && self.pev.vuser2 != g_vecZero )
        {
            g_EntityFuncs.SetSize( self.pev, self.pev.vuser1, self.pev.vuser2 );
        }
        else
        {
            g_EntityFuncs.SetSize( self.pev, Vector( -64, -64, -36 ), Vector( 64, 64, 36 ) );
        }

        SetAnim( 0 ); // set sequence to 0 aka idle
        
        if ( g_SurvivalMode.MapSupportEnabled() && !g_SurvivalMode.IsActive() )
        {
            SetEnabled( false );
        }
        else
        {
            SetEnabled( true );
        }

        if( self.GetTargetname() != "" && self.pev.SpawnFlagBitSet( SF_CHECKPOINT_STARTINACTIVE ) )
        {
            m_bInitialised = false;
            self.pev.rendermode = 2;
            self.pev.renderamt = 100.0f;
            self.pev.framerate = 0.0f;
        }
        else
        {
            m_bInitialised = Initialise();
        }
    }
    
    // Outerbeast: Moving certain spawn instructions to its own method.
    bool Initialise()
    {
        // Entity should expect direct trigger to activate itself
        // If the map supports survival mode but survival is not active yet,
        // spawn disabled checkpoint
        //if ( IsEnabled() )
        //{
            // Fire netname entity on spawn (if specified and checkpoint is enabled)
            if ( !string( self.pev.netname ).IsEmpty() )
            {
                g_EntityFuncs.FireTargets( self.pev.netname, self, self, USE_TOGGLE );
            }

            // Create Xenmaker-like effect
            if ( m_fSpawnEffect )
            {
                CreateSpawnEffect();
            }
        //}
        // Visual fx to indicate the checkpoint is not available at this time
        self.pev.rendermode = self.m_iOriginalRenderMode;
        self.pev.renderamt = self.m_flOriginalRenderAmount;
        self.pev.framerate = 1.0f;

        SetThink( ThinkFunction( this.IdleThink ) );
        self.pev.nextthink = g_Engine.time + 0.1f;

        return true;
    }

    void CreateSpawnEffect()
    {
        int iBeamCount = 8;
        Vector vBeamColor = Vector(217,226,146);
        int iBeamAlpha = 128;
        float flBeamRadius = 256;

        Vector vLightColor = Vector(39,209,137);
        float flLightRadius = 160;

        Vector vStartSpriteColor = Vector(65,209,61);
        float flStartSpriteScale = 1.0f;
        float flStartSpriteFramerate = 12;
        int iStartSpriteAlpha = 255;

        Vector vEndSpriteColor = Vector(159,240,214);
        float flEndSpriteScale = 1.0f;
        float flEndSpriteFramerate = 12;
        int iEndSpriteAlpha = 255;
        // create the clientside effect
        // Outerbeast: This causes precache host error. "sprites/fexplo1.spr" is flagged.
        NetworkMessage msg( MSG_PVS, NetworkMessages::TE_CUSTOM, pev.origin );
            msg.WriteByte( 2 );
            msg.WriteVector( pev.origin );
            // for the beams
            msg.WriteByte( iBeamCount );
            msg.WriteVector( vBeamColor );
            msg.WriteByte( iBeamAlpha );
            msg.WriteCoord( flBeamRadius );
            // for the dlight
            msg.WriteVector( vLightColor );
            msg.WriteCoord( flLightRadius );
            // for the sprites
            msg.WriteVector( vStartSpriteColor );
            msg.WriteByte( int( flStartSpriteScale*10 ) );
            msg.WriteByte( int( flStartSpriteFramerate ) );
            msg.WriteByte( iStartSpriteAlpha );
            
            msg.WriteVector( vEndSpriteColor );
            msg.WriteByte( int( flEndSpriteScale*10 ) );
            msg.WriteByte( int( flEndSpriteFramerate ) );
            msg.WriteByte( iEndSpriteAlpha );
        msg.End();
    }
    // Trigger directly - Outerbeast
    void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
    {    // If the entity was not initialised at this point, do and wait for next trigger
        if( !m_bInitialised )
        {
            m_bInitialised = Initialise();
            return;
        }

        self.Touch( pActivator !is null ? pActivator : ( pCaller !is null ? pCaller : self ) );
    }

    void Touch( CBaseEntity@ pOther )
    {
        if( !m_bInitialised || !IsEnabled() || IsActivated() || !pOther.IsPlayer() )
        {
            return;
        }
        
        // Option to indicate a checkpoint was used in chat - Outerbeast
        if( self.pev.SpawnFlagBitSet( SF_TRIGGERED_MSG ) )
        {
            if(string(g_Engine.mapname).StartsWith ( "aom" ) )
            {
                g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "Checkpoint reached..\n" );
            }
            else
            {
                g_Game.AlertMessage( at_logged, "CHECKPOINT: \"%1\" activated Checkpoint\n", pOther.pev.netname );
                g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "" + pOther.pev.netname + " activated a Checkpoint.\n" );
            }
        }
        // Set activated
        self.pev.frags = 1.0f;

        if(string(g_Engine.mapname).StartsWith ( "th_" ) )
        {
            if (string(self.pev.netname).IsEmpty())
            {
                TraceResult tr;
                g_EngineFuncs.MakeVectors(self.pev.angles);
                g_Utility.TraceLine(self.pev.origin, self.pev.origin+g_Engine.v_up*4096, ignore_monsters, self.edict(), tr);
                // dont care if we didint hit skybox, itll look like it came from the sky anyways
                m_vecLightningStart = tr.vecEndPos;
            }
            else
            {
                CBaseEntity@ targetEntity = null;
                while((@targetEntity = g_EntityFuncs.FindEntityByTargetname(targetEntity, string(self.pev.netname))) !is null)
                {
                    m_vecLightningStart = targetEntity.pev.origin;
                }
            }
        }
        
        g_SoundSystem.EmitSound( self.edict(), CHAN_STATIC, m_sActivationMusic, 1.0f, ATTN_NONE ); // Change to use custom activation music if set - Outerbeast

        self.pev.rendermode        = kRenderTransTexture;
        self.pev.renderamt        = 255;
        
        SetThink( ThinkFunction( this.FadeThink ) );
        self.pev.nextthink = g_Engine.time + 0.1f;
        
        // Trigger targets
        self.SUB_UseTargets( pOther, USE_TOGGLE, 0 );
        // Killtarget, cause we can. - Outerbeast
        if( string( self.m_iszKillTarget ) != "" && string( self.m_iszKillTarget ) != self.GetTargetname() )
        {
            do
                g_EntityFuncs.Remove( g_EntityFuncs.FindEntityByTargetname( null, string( self.m_iszKillTarget ) ) );
            while( g_EntityFuncs.FindEntityByTargetname( null, string( self.m_iszKillTarget ) ) !is null );
        }
    }
    
    bool IsEnabled() const { return self.pev.health != 0.0f; }
    
    bool IsActivated() const { return self.pev.frags != 0.0f; }
    
    void SetEnabled( const bool bEnabled )
    {
        if( bEnabled == IsEnabled() )
        {
            return;
        }
        
        if ( bEnabled && !IsActivated() )
        {
            self.pev.effects &= ~EF_NODRAW;
        }
        else
        {
            self.pev.effects |= EF_NODRAW;
        }
        
        self.pev.health = bEnabled ? 1.0f : 0.0f;
    }
    
    // GeckoN: Idle Think - just to make sure the animation gets updated properly.
    // Should fix the "checkpoint jitter" issue.
    void IdleThink()
    {
        self.StudioFrameAdvance();
        self.pev.nextthink = g_Engine.time + 0.1;
    }
    
    void FadeThink()
    {
        if ( self.pev.renderamt > 0 )
        {
            self.StudioFrameAdvance();
            
            self.pev.renderamt -= 20;
            
            if ( self.pev.renderamt < 0 )
            {
                self.pev.renderamt = 0;
            }
            
            self.pev.nextthink = g_Engine.time + 0.1f;
        }
        else
        {
            SetThink( ThinkFunction( this.RespawnStartThink ) );
            self.pev.nextthink = g_Engine.time + m_flDelayBeforeStart;
            
            m_flRespawnStartTime = g_Engine.time;
        
            // Make this entity invisible
            self.pev.effects |= EF_NODRAW;
            
            self.pev.renderamt = 255;
        }
    }
    
    void RespawnStartThink()
    {
        //Clean up the old sprite if needed
        if( m_pSprite !is null )
        {
            g_EntityFuncs.Remove( m_pSprite );
        }
        
        m_iNextPlayerToRevive = 1;
        
        if(string(g_Engine.mapname).StartsWith ( "aom" ) )
        {
            @m_pSprite = g_EntityFuncs.CreateSprite( "sprites/null.spr", self.pev.origin, true, 10 );
        }
        else
        {
            @m_pSprite = g_EntityFuncs.CreateSprite( "sprites/exit1.spr", self.pev.origin, true, 10 );
        }
        
        m_pSprite.TurnOn();
        m_pSprite.pev.rendermode = kRenderTransAdd;
        m_pSprite.pev.renderamt = 128;
    
        g_SoundSystem.EmitSound( self.edict(), CHAN_STATIC, "debris/beamstart7.wav", 1.0f, ATTN_NORM );
        
        SetThink( ThinkFunction( this.RespawnThink ) );
        self.pev.nextthink = g_Engine.time + 0.1f;
    }
    
    //Revives 1 player every m_flDelayBetweenRevive seconds, if any players need reviving.
    void RespawnThink()
    {
        CBasePlayer@ pPlayer;
        
        for( ; m_iNextPlayerToRevive <= g_Engine.maxClients; ++m_iNextPlayerToRevive )
        {
            @pPlayer = g_PlayerFuncs.FindPlayerByIndex( m_iNextPlayerToRevive );
            
            //Only respawn if the player died before this checkpoint was activated
            //Prevents exploitation
            if( pPlayer !is null && !pPlayer.IsAlive() && pPlayer.m_fDeadTime < m_flRespawnStartTime )
            {
                //Revive player and move to this checkpoint
                pPlayer.GetObserver().RemoveDeadBody();
                pPlayer.SetOrigin( self.pev.origin );
                pPlayer.Revive();
                
                //Call player equip
                //Only disable default giving if there are game_player_equip entities in give mode
                if( !self.pev.SpawnFlagBitSet( SF_DONT_EQUIP_SPAWNED ) ) // Condition so that this is optional via a flag - Outerbeast
                {
                    CBaseEntity @pEquipEntity = null;
                    while ( ( @pEquipEntity = g_EntityFuncs.FindEntityByClassname( pEquipEntity, "game_player_equip" ) ) !is null  )
                    {
                        pEquipEntity.Use( pPlayer, self, USE_TOGGLE, 0.0f ); // Outerbeast: this used to be Touch( pPlayer ) which is incorrect. This should be fixed now
                    }
                }
                
                else if(string(g_Engine.mapname).StartsWith ( "th_" ) )
                {
                    LightningEffect( pPlayer );
                }
                
                // Outerbeast: trigger "message" for every player spawned - wanted to use "target" but its already being used in Touch() ( see Line 227 )
                // -Mikk that's really useful anyways.
                if( string( self.pev.message ) != "" && string( self.pev.message ) != self.GetTargetname() )
                {
                    g_EntityFuncs.FireTargets( self.pev.message, pPlayer, self, USE_TOGGLE );
                }
                //Congratulations, and celebrations, YOU'RE ALIVE!
                g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_ITEM, self.pev.message, 1.0f, ATTN_NORM );
                
                ++m_iNextPlayerToRevive; //Make sure to increment this to avoid unneeded loop
                break;
            }
            // Now save living people's lifes -Mikk
            else if( pPlayer !is null && pPlayer.IsAlive() )
            {
                CustomKeyvalues@ ckvSpawns = pPlayer.GetCustomKeyvalues();
                int kvSpawnIs = ckvSpawns.GetKeyvalue("$i_pointcheckpoint").GetInteger();
                ckvSpawns.SetKeyvalue("$i_pointcheckpoint", kvSpawnIs + 1 );
            }
        }
        
        //All players have been checked, close portal after 5 seconds.
        if( m_iNextPlayerToRevive > g_Engine.maxClients )
        {
            SetThink( ThinkFunction( this.StartKillSpriteThink ) );
            
            self.pev.nextthink = g_Engine.time + 5.0f;
        }
        //Another player could require reviving
        else
        {
            self.pev.nextthink = g_Engine.time + m_flDelayBetweenRevive;
        }
    }
    
    void StartKillSpriteThink()
    {
        g_SoundSystem.EmitSound( self.edict(), CHAN_STATIC, "ambience/port_suckout1.wav", 1.0f, ATTN_NORM );
        
        SetThink( ThinkFunction( this.KillSpriteThink ) );
        self.pev.nextthink = g_Engine.time + 3.0f;
    }
    
    void CheckReusable()
    {
        if( self.pev.SpawnFlagBitSet( SF_CHECKPOINT_REUSABLE ) )
        {
            SetThink( ThinkFunction( this.ReenableThink ) );
            self.pev.nextthink = g_Engine.time + m_flDelayBeforeReactivation;
        }
        else
            SetThink( null );
    }
    
    void KillSpriteThink()
    {
        if( m_pSprite !is null )
        {
            g_EntityFuncs.Remove( m_pSprite );
            @m_pSprite = null;
        }
        
        CheckReusable();
    }
    
    void ReenableThink()
    {
        if ( IsEnabled() )
        {
            //Make visible again
            self.pev.effects &= ~EF_NODRAW;
        }
        
        self.pev.frags = 0.0f;
        
        SetThink( ThinkFunction( this.RespawnThink ) );
        self.pev.nextthink = g_Engine.time + 0.1f;
    }
    
    void LightningEffect( CBasePlayer@ pPlayer )
    {
        NetworkMessage message(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
            message.WriteByte(TE_BEAMPOINTS);
            message.WriteCoord(m_vecLightningStart.x);
            message.WriteCoord(m_vecLightningStart.y);
            message.WriteCoord(m_vecLightningStart.z);
            message.WriteCoord(pPlayer.pev.origin.x);
            message.WriteCoord(pPlayer.pev.origin.y);
            message.WriteCoord(pPlayer.pev.origin.z);
            message.WriteShort(g_EngineFuncs.ModelIndex("sprites/lgtning.spr"));
            message.WriteByte(0);
            message.WriteByte(20);    // framerate
            message.WriteByte(1);    // life
            message.WriteByte(24);    // width
            message.WriteByte(80);    // noise
            message.WriteByte(172);    // colors
            message.WriteByte(255); 
            message.WriteByte(255); 
            message.WriteByte(255);    // brightness
            message.WriteByte(0);    // scroll
        message.End();
    }
}

// Namespace for living peoples
namespace PlayerUseSpawn
{
    HookReturnCode PlayerUse( CBasePlayer@ pPlayer, uint& out uiFlags )
    {
        CustomKeyvalues@ ckvSpawns = pPlayer.GetCustomKeyvalues();
        int kvSpawnIs = ckvSpawns.GetKeyvalue("$i_pointcheckpoint").GetInteger();

        if( pPlayer is null or kvSpawnIs <= 0 )
        {
            return HOOK_CONTINUE;
        }

        SpawnCountHudText.x = 0.05;
        SpawnCountHudText.y = 0.05;
        SpawnCountHudText.effect = 0;
        SpawnCountHudText.r1 = RGBA_SVENCOOP.r;
        SpawnCountHudText.g1 = RGBA_SVENCOOP.g;
        SpawnCountHudText.b1 = RGBA_SVENCOOP.b;
        SpawnCountHudText.a1 = 0;
        SpawnCountHudText.r2 = RGBA_SVENCOOP.r;
        SpawnCountHudText.g2 = RGBA_SVENCOOP.g;
        SpawnCountHudText.b2 = RGBA_SVENCOOP.b;
        SpawnCountHudText.a2 = 0;
        SpawnCountHudText.fadeinTime = 0; 
        SpawnCountHudText.fadeoutTime = 0.25;
        SpawnCountHudText.holdTime = 0.2;
        SpawnCountHudText.fxTime = 0;
        SpawnCountHudText.channel = 6;

        g_PlayerFuncs.HudMessage(pPlayer, SpawnCountHudText, "Checkpoints: " + kvSpawnIs +"" );

        if( !pPlayer.IsAlive() && pPlayer.GetObserver().IsObserver() )
        {
            g_EntityFuncs.FireTargets( "GZ_IZL_HOWTOUSE", pPlayer, pPlayer, USE_ON );
        
            if( pPlayer.m_afButtonLast & IN_ATTACK != 0 || pPlayer.m_afButtonLast & IN_USE != 0  )
            {
                pPlayer.GetObserver().RemoveDeadBody(); //Remove the dead player body

                // This way for prevent players get stuck when the map does a forced teleport -Mikk
                g_PlayerFuncs.RespawnPlayer( pPlayer, false, true );

                // Must include https://github.com/Outerbeast/Entities-and-Gamemodes/blob/master/respawndead_keepweapons.as
                RESPAWNDEAD_KEEPWEAPONS::ReEquipCollected( pPlayer, true );
                
                ckvSpawns.SetKeyvalue("$i_pointcheckpoint", kvSpawnIs - 1 );
            }
        }
        return HOOK_CONTINUE;
    }
}    // End of namespace