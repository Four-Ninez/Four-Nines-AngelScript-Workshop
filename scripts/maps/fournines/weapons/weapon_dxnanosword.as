/* Deus Ex Nano Sword Script
/ Since it doesn't have any weapon base, the code is a little mess, so yeah
/ Credits
/ Model: Ion Storm
/ Textures: Ion Storm, Upscaled by Four-Nines
/ Animations: Nexon
/ Sounds: Ion Storm
/ Script: KernCore (CSCZ Machete used as a base for a script), Four-Nines
/ HUD Sprite: Four-Nines
/ Hand Rig: Four-Nines, Norman and DNIO071 (Remappable hands)
*/

namespace DX_NANOSWORD
{
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

    const string MODEL_VIEW = "models/fournines/weapons/v_nanosword.mdl";
    const string MODEL_WORLD = "models/fournines/weapons/w_nanosword.mdl";
    const string MODEL_PLAYER = "models/fournines/weapons/p_nanosword.mdl";

    const string SOUND_DRAW = "fournines/weapons/nanosword_draw.wav";
    const string SOUND_SWING = "fournines/weapons/nanosword_swing.wav";
    const string SOUND_IMPACT = "fournines/weapons/nanosword_impact.wav";
    const string SOUND_HITWALL = "fournines/weapons/nanosword_hitwall.wav";

    const int DAMAGE_LIGHT = 40;
    const int DAMAGE_HEAVY = 90;
    const float ATTACK_DELAY_LIGHT = 0.5;
    const float ATTACK_DELAY_HEAVY = 1.2;

    const int MAX_CARRY = -1;
    const int MAX_CLIP = WEAPON_NOCLIP;
    const int DEFAULT_GIVE = 0;
    const int WEIGHT = 5;
    const int FLAGS = ITEM_FLAG_SELECTONEMPTY;
    const uint SLOT = 0;
    const uint POSITION = 16;
    const string AMMO_TYPE = "";
    const float SLASH_DIST = 64.0f;

    class WeaponNanoSword : ScriptBasePlayerWeaponEntity
    {
        private CBasePlayer@ m_pPlayer
        {
            get const { return cast<CBasePlayer@>(self.m_hPlayer.GetEntity()); }
            set { self.m_hPlayer = EHandle(@value); }
        }

        private TraceResult m_trHit; // Stores the trace result for decal placement
        private int m_iSwing;       // Tracks the swing animation state

        void Spawn()
        {
            Precache();
            g_EntityFuncs.SetModel(self, MODEL_WORLD);
            self.FallInit();
            self.pev.flags |= FLAGS;
            m_iSwing = 0; // Reset swing counter
        }

        void Precache()
        {
            g_Game.PrecacheModel(MODEL_VIEW);
            g_Game.PrecacheModel(MODEL_WORLD);
            g_Game.PrecacheModel(MODEL_PLAYER);
            g_SoundSystem.PrecacheSound(SOUND_DRAW);
            g_SoundSystem.PrecacheSound(SOUND_SWING);
            g_SoundSystem.PrecacheSound(SOUND_IMPACT);
            g_SoundSystem.PrecacheSound(SOUND_HITWALL);
            g_Game.PrecacheGeneric("sprites/fournines/weapons/weapon_dxnanosword.txt");
            g_Game.PrecacheGeneric("sprites/fournines/weapons/640hudnanosword.spr");
        }

        bool GetItemInfo(ItemInfo& out info)
        {
            info.iMaxAmmo1 = MAX_CARRY;
            info.iAmmo1Drop = MAX_CLIP;
            info.iMaxAmmo2 = -1;
            info.iAmmo2Drop = -1;
            info.iMaxClip = MAX_CLIP;
            info.iSlot = SLOT;
            info.iPosition = POSITION;
            info.iId = g_ItemRegistry.GetIdForName(self.pev.classname);
            info.iFlags = FLAGS;
            info.iWeight = WEIGHT;
            return true;
        }

        bool Deploy()
        {
            g_SoundSystem.EmitSound(m_pPlayer.edict(), CHAN_ITEM, SOUND_DRAW, 1, ATTN_NORM);
            return self.DefaultDeploy(self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), DRAW, "crowbar");
        }

        void PrimaryAttack()
        {
            if (!Swing(true)) // Attempt to swing
            {
                // If the swing didn't hit, try again after a short delay
                SetThink(ThinkFunction(this.SwingAgain));
                pev.nextthink = g_Engine.time + 0.1f;
            }
        }

        void SecondaryAttack()
        {
            if (!HeavySwing(true)) // Attempt to perform a heavy swing
            {
                // If the swing didn't hit, try again after a short delay
                SetThink(ThinkFunction(this.HeavySwingAgain));
                pev.nextthink = g_Engine.time + 0.1f;
            }
        }

        private bool Swing(bool fFirst)
        {
            bool fDidHit = false;

            TraceResult tr;

            // Calculate the start and end points of the swing
            Math.MakeVectors(m_pPlayer.pev.v_angle);
            Vector vecSrc = m_pPlayer.GetGunPosition();
            Vector vecEnd = vecSrc + g_Engine.v_forward * SLASH_DIST;

            // Perform a line trace to check for hits
            g_Utility.TraceLine(vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr);

            // If the line trace didn't hit anything, perform a hull trace
            if (tr.flFraction >= 1.0f)
            {
                g_Utility.TraceHull(vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr);
                if (tr.flFraction < 1.0f)
                {
                    // Adjust the trace result for hull intersections
                    CBaseEntity@ pHit = g_EntityFuncs.Instance(tr.pHit);
                    if (pHit is null || pHit.IsBSPModel())
                        g_Utility.FindHullIntersection(vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict());
                    vecEnd = tr.vecEndPos;
                }
            }

            // If the swing didn't hit anything
            if (tr.flFraction >= 1.0f)
            {
                if (fFirst)
                {
                    // Play miss animation
                    switch ((m_iSwing++) % 3)
                    {
                        case 0: self.SendWeaponAnim(DX_NanoSword_Animation::SWIPE_LIGHT); break;
                        case 1: self.SendWeaponAnim(DX_NanoSword_Animation::SWIPE_LIGHT2); break;
                        case 2: self.SendWeaponAnim(DX_NanoSword_Animation::SWIPE_LIGHT3); break;
                    }
                    self.m_flNextPrimaryAttack = g_Engine.time + ATTACK_DELAY_LIGHT;
                    self.m_flTimeWeaponIdle = g_Engine.time + 2.0f;

                    // Play miss sound
                    g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, SOUND_SWING, 1.0, ATTN_NORM, 0, PITCH_NORM);

                    // Play player attack animation
                    m_pPlayer.SetAnimation(PLAYER_ATTACK1);
                }
            }
            else
            {
                // The swing hit something
                fDidHit = true;

                CBaseEntity@ pEntity = g_EntityFuncs.Instance(tr.pHit);

                // Play hit animation
                switch ((m_iSwing++) % 3)
                {
                    case 0: self.SendWeaponAnim(DX_NanoSword_Animation::SWIPE_LIGHT); break;
                    case 1: self.SendWeaponAnim(DX_NanoSword_Animation::SWIPE_LIGHT2); break;
                    case 2: self.SendWeaponAnim(DX_NanoSword_Animation::SWIPE_LIGHT3); break;
                }

                self.m_flNextPrimaryAttack = g_Engine.time + ATTACK_DELAY_LIGHT;
                self.m_flTimeWeaponIdle = g_Engine.time + 2.0f;

                // Play player attack animation
                m_pPlayer.SetAnimation(PLAYER_ATTACK1);

                // Apply damage to the hit entity
                g_WeaponFuncs.ClearMultiDamage();
                pEntity.TraceAttack(m_pPlayer.pev, DAMAGE_LIGHT, g_Engine.v_forward, tr, DMG_SLASH);
                g_WeaponFuncs.ApplyMultiDamage(m_pPlayer.pev, m_pPlayer.pev);

                // Play hit sound
                if (pEntity !is null && pEntity.IsAlive())
                {
                    g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, SOUND_IMPACT, 1.0, ATTN_NORM, 0, PITCH_NORM);
                }
                else
                {
                    // Play wall hit sound
                    g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, SOUND_HITWALL, 1.0, ATTN_NORM, 0, PITCH_NORM);
                }

                // Store the trace result for decal placement
                m_trHit = tr;
                SetThink(ThinkFunction(this.Smack));
                pev.nextthink = g_Engine.time + 0.2f; // Delay decal placement
            }

            // Force the player to return to the weapon's idle animation after the attack
            m_pPlayer.SetAnimation(PLAYER_IDLE);
            return fDidHit;
        }


        private void SwingAgain()
        {
            Swing(false);
        }

        private bool HeavySwing(bool fFirst)
        {
            bool fDidHit = false;
        
            TraceResult tr;
        
            // Calculate the start and end points of the swing
            Math.MakeVectors(m_pPlayer.pev.v_angle);
            Vector vecSrc = m_pPlayer.GetGunPosition();
            Vector vecEnd = vecSrc + g_Engine.v_forward * SLASH_DIST;
        
            // Perform a line trace to check for hits
            g_Utility.TraceLine(vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr);
        
            // If the line trace didn't hit anything, perform a hull trace
            if (tr.flFraction >= 1.0f)
            {
                g_Utility.TraceHull(vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr);
                if (tr.flFraction < 1.0f)
                {
                    // Adjust the trace result for hull intersections
                    CBaseEntity@ pHit = g_EntityFuncs.Instance(tr.pHit);
                    if (pHit is null || pHit.IsBSPModel())
                        g_Utility.FindHullIntersection(vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict());
                    vecEnd = tr.vecEndPos;
                }
            }
        
            // If the swing didn't hit anything
            if (tr.flFraction >= 1.0f)
            {
                if (fFirst)
                {
                    // Play miss animation for heavy attack
                    switch ((m_iSwing++) % 2)
                    {
                        case 0: self.SendWeaponAnim(DX_NanoSword_Animation::SWIPE_HEAVY); break;
                        case 1: self.SendWeaponAnim(DX_NanoSword_Animation::SWIPE_HEAVY2); break;
                    }
                    self.m_flNextSecondaryAttack = g_Engine.time + ATTACK_DELAY_HEAVY;
                    self.m_flTimeWeaponIdle = g_Engine.time + 2.0f;
        
                    // Play miss sound for heavy attack
                    g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, SOUND_SWING, 1.0, ATTN_NORM, 0, PITCH_NORM);
        
                    // Play player attack animation
                    m_pPlayer.SetAnimation(PLAYER_ATTACK1);
                }
            }
            else
            {
                // The swing hit something
                fDidHit = true;
        
                CBaseEntity@ pEntity = g_EntityFuncs.Instance(tr.pHit);
        
                // Play hit animation for heavy attack
                switch ((m_iSwing++) % 2)
                {
                    case 0: self.SendWeaponAnim(DX_NanoSword_Animation::SWIPE_HEAVY); break;
                    case 1: self.SendWeaponAnim(DX_NanoSword_Animation::SWIPE_HEAVY2); break;
                }
        
                // Set the delay for the next heavy attack
                self.m_flNextSecondaryAttack = g_Engine.time + ATTACK_DELAY_HEAVY;
                self.m_flTimeWeaponIdle = g_Engine.time + 2.0f;
        
                // Play player attack animation
                m_pPlayer.SetAnimation(PLAYER_ATTACK1);
        
                // Apply damage to the hit entity
                g_WeaponFuncs.ClearMultiDamage();
                pEntity.TraceAttack(m_pPlayer.pev, DAMAGE_HEAVY, g_Engine.v_forward, tr, DMG_SLASH);
                g_WeaponFuncs.ApplyMultiDamage(m_pPlayer.pev, m_pPlayer.pev);
        
                // Play hit sound
                if (pEntity !is null && pEntity.IsAlive())
                {
                    g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, SOUND_IMPACT, 1.0, ATTN_NORM, 0, PITCH_NORM);
                }
                else
                {
                    // Play wall hit sound
                    g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, SOUND_HITWALL, 1.0, ATTN_NORM, 0, PITCH_NORM);
                }
        
                // Store the trace result for decal placement
                m_trHit = tr;
                SetThink(ThinkFunction(this.Smack));
                pev.nextthink = g_Engine.time + 0.2f; // Delay decal placement
            }
        
            // Force the player to return to the weapon's idle animation after the attack
            m_pPlayer.SetAnimation(PLAYER_IDLE);
            return fDidHit;
        }

        private void HeavySwingAgain()
        {
            HeavySwing(false);
        }

        // Place a decal on the surface that was hit
        private void Smack()
        {
            g_WeaponFuncs.DecalGunshot(m_trHit, BULLET_PLAYER_CROWBAR);
        }
    }

    string GetNanoSwordName()
    {
        return "weapon_dxnanosword";
    }

    void Register()
    {
        g_CustomEntityFuncs.RegisterCustomEntity("DX_NANOSWORD::WeaponNanoSword", GetNanoSwordName());
        g_ItemRegistry.RegisterWeapon(GetNanoSwordName(), "fournines/weapons");
    }
}