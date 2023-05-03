#include 'utils'
#include 'utils/customentity'
namespace monster_dead
{
    void ScriptInfo()
    {
        g_Information.SetInformation
        ( 
            'Script: monster_dead\n' +
            'Description: Dead monster prop\n' +
            'Author: Mikk\n' +
            'Discord: ' + g_Information.GetDiscord( 'mikk' ) + '\n'
            'Server: ' + g_Information.GetDiscord() + '\n'
            'Github: ' + g_Information.GetGithub()
        );
    }

    void Register()
    {
        g_CustomEntityFuncs.RegisterCustomEntity( 'monster_dead::monster_dead','monster_dead' );
    }

    class monster_dead : ScriptBaseMonsterEntity, ScriptBaseCustomEntity
    {
        private float m_fHealth = 8;
        private int m_iPoseIndex, m_iTakeDamage, bloodcolor;
        bool KeyValue( const string& in szKey, const string& in szValue ) 
        {
            ExtraKeyValues( szKey, szValue );
            if( szKey == "m_fHealth" )
            {
                m_fHealth = atof( szValue );
            }
            if( szKey == "m_iPoseIndex" )
            {
                m_iPoseIndex = atoi( szValue );
            }
            if( szKey == "m_iTakeDamage" )
            {
                m_iTakeDamage = atoi( szValue );
            }
            if( szKey == "bloodcolor" )
            {
                bloodcolor = atoi( szValue );
            }
            else return BaseClass.KeyValue( szKey, szValue );
            return true;
        }

        void Precache()
        {
            CustomModelPrecache();
            BaseClass.Precache();
        }

        void Spawn()
        {
            CustomModelSet();

            self.MonsterInitDead();

            self.pev.health = ( self.pev.health <= 0 ) ? m_fHealth : self.pev.health;
            // self.pev.takedamage = m_iTakeDamage; no anda
            // self.m_bloodColor 	= BLOOD_COLOR_RED;no anda
            self.m_bloodColor 	= bloodcolor;
            self.pev.solid = SOLID_SLIDEBOX;
            self.pev.movetype 	= MOVETYPE_STEP;
            self.SetClassification( CLASS_HUMAN_PASSIVE );

            Precache();
            BaseClass.Spawn();
        }
    }
}