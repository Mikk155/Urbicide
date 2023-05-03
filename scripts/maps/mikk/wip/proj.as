#include "utils"
namespace NIHILANTH
{
    void ProjRegister()
    {
        g_CustomEntityFuncs.RegisterCustomEntity( "NIHILANTH::Implosion", "nih_implosion" );
		g_Game.PrecacheOther( 'nih_implosion' );
    }

    class Implosion : ScriptBaseEntity
    {
        private string model = "sprites/exit1.spr";

        void Precache()
        {
            g_Game.PrecacheModel( model );
            g_Game.PrecacheGeneric( model );

            g_SoundSystem.PrecacheSound( sound_message );
            g_Game.PrecacheGeneric( "sound/" + sound_message );

            BaseClass.Precache();
        }

        void Implosion()
        {
            g_Scheduler.SetTimeout( this, "Expansion", 0.8f );
            NetworkMessage Message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
                Message.WriteByte( TE_IMPLOSION );
                Message.WriteCoord( self.pev.origin.x );
                Message.WriteCoord( self.pev.origin.y );
                Message.WriteCoord( self.pev.origin.z );
                Message.WriteByte( 128 );
                Message.WriteByte( 100 );
                Message.WriteByte( 20 );
            Message.End();
        }

        void Expansion()
        {
            NetworkMessage Message( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
                Message.WriteByte(TE_BEAMDISK);
                Message.WriteCoord( self.pev.origin.x );
                Message.WriteCoord( self.pev.origin.y );
                Message.WriteCoord( self.pev.origin.z );
                Message.WriteCoord( self.pev.origin.x );
                Message.WriteCoord( self.pev.origin.y );
                Message.WriteCoord( self.pev.origin.z + 128.0f );
                Message.WriteShort( g_EngineFuncs.ModelIndex( model ) );
                Message.WriteByte( 0 );
                Message.WriteByte( 16 ); // Seems to have no effect, or at least i didn't notice
                Message.WriteByte( 10 );
                Message.WriteByte(1); // "width" - has no effect
                Message.WriteByte(0); // "noise" - has no effect
                Message.WriteByte( 0 ); // R
                Message.WriteByte( 100 ); // G
                Message.WriteByte( 0 ); // B
                Message.WriteByte( 200 ); // A
                Message.WriteByte( 0 ); // < 10 seems to have no effect while > 10 just expands it alot
            Message.End();
            // Damage player in radius 128.0f
        }
    }
}
// End of namespace