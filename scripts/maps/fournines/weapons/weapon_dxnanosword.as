// Deus Ex Nano Sword Script
/* Model Credits
/ Model: Ion Storm
/ Textures: Ion Storm, Upscaled by Four-Nines
/ Animations: Nexon, Four-Nines (rigging)
/ Sounds: Ion Storm
/ Script: KernCore, Four-Nines (edit stuff)
/ Sprites: Ion Storm, Four-Nines
/ Hand Rig: Four-Nines, Norman and DNIO071 (Remappable hands)
*/


namespace DX_NANOSWORD
{

// Animations
enum DX_NanoSword_Animation
{
    IDLE = 0,
    SWIPE_LIGHT,
	SWIPE_LIGHT2,
	SWIPE_LIGHT3,
    DRAW,
    SWIPE_HEAVY,
	SWIPE_HEAVY2
};

// Models
const string MODEL_VIEW = "models/fournines/weapons/v_nanosword.mdl";
const string MODEL_WORLD = "models/fournines/weapons/w_nanosword.mdl";
const string MODEL_PLAYER = "models/fournines/weapons/p_nanosword.mdl";

const string SPR_CAT  	= "fournines/melee/"; //Weapon category used to get the sprite's location

// Sounds
const string SOUND_DRAW = "sounds/fournines/weapons/nanosword_draw.wav";
const string SOUND_SWING = "sounds/fournines/weapons/nanosword_swing.wav";
const string SOUND_IMPACT = "sounds/fournines/weapons/nanosword_impact.wav";

// Weapon stats
int DAMAGE_LIGHT = 40;
int DAMAGE_HEAVY = 90;
float ATTACK_DELAY_LIGHT = 0.5;
float ATTACK_DELAY_HEAVY = 1.2;
// Information
int MAX_CARRY   	= -1;
int MAX_CLIP    	= WEAPON_NOCLIP;
int DEFAULT_GIVE 	= 0;
int WEIGHT      	= 5;
int FLAGS       	= -1;
uint SLOT       	= 0;
uint POSITION   	= 26;
string AMMO_TYPE 	= "";
float SLASH_DIST 	= 64.0f;
float STAB_DIST  	= 48.0f;

class WeaponNanoSword : ScriptBasePlayerWeaponEntity
{
    private CBasePlayer@ m_pPlayer;
    private bool m_bEnergyActive;

    void Spawn()
    {
        Precache();
        g_EntityFuncs.SetModel(self, MODEL_WORLD);
        self.FallInit();
    }

    void Precache()
    {
        g_Game.PrecacheModel(MODEL_VIEW);
        g_Game.PrecacheModel(MODEL_WORLD);
        g_Game.PrecacheModel(MODEL_PLAYER);
        g_SoundSystem.PrecacheSound(SOUND_DRAW);
        g_SoundSystem.PrecacheSound(SOUND_SWING);
        g_SoundSystem.PrecacheSound(SOUND_IMPACT);
    }

    bool Deploy()
    {
        return self.DefaultDeploy(self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), DX_NanoSword_Animation::DRAW, "crowbar");
    }

    void PrimaryAttack()
    {
        if (!Swing(DAMAGE_LIGHT, ATTACK_DELAY_LIGHT, SOUND_SWING, DX_NanoSword_Animation::SWIPE_LIGHT))
            return;
    }

    void SecondaryAttack()
    {
        if (!Swing(DAMAGE_HEAVY, ATTACK_DELAY_HEAVY, SOUND_SWING, DX_NanoSword_Animation::SWIPE_HEAVY))
            return;
    }

    bool Swing(int damage, float delay, const string& in sound, DX_NanoSword_Animation animation)
    {
        TraceResult tr;
        Math.MakeVectors(m_pPlayer.pev.v_angle);
        Vector vecSrc = m_pPlayer.GetGunPosition();
        Vector vecEnd = vecSrc + g_Engine.v_forward * 64;

        g_Utility.TraceLine(vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr);

        if (tr.flFraction >= 1.0)
        {
            self.m_flNextPrimaryAttack = g_Engine.time + delay;
            g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, sound, 1.0, ATTN_NORM, 0, PITCH_NORM);
            return false;
        }

        CBaseEntity@ pHit = g_EntityFuncs.Instance(tr.pHit);
        if (pHit !is null)
        {
            g_WeaponFuncs.ClearMultiDamage();
            pHit.TraceAttack(m_pPlayer.pev, damage, g_Engine.v_forward, tr, DMG_SLASH);
            g_WeaponFuncs.ApplyMultiDamage(m_pPlayer.pev, m_pPlayer.pev);
        }

        g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, SOUND_IMPACT, 1.0, ATTN_NORM, 0, PITCH_NORM);
        self.m_flNextPrimaryAttack = g_Engine.time + delay;
        return true;
    }

    void WeaponIdle()
    {
        self.ResetEmptySound();
        self.SendWeaponAnim(DX_NanoSword_Animation::IDLE);
    }
}

string GetNanoSwordName()
{
    return "weapon_dxnanosword";
}

void RegisterNanoSword()
{
    g_CustomEntityFuncs.RegisterCustomEntity("DX_NANOSWORD::WeaponNanoSword", GetNanoSwordName());
    g_ItemRegistry.RegisterWeapon(GetNanoSwordName(), "deusex");
}
}
