// Custom BuyMenu Kevlar, Redesigned for UT Armor
// Author: Mikk, Nero0
// Model: Epic Games
// Sound: Epic Games
// Script edit, model and sound rip, texture upscale (via AI): Four-Nines
// Ripped via UModel

namespace UT_ARMOR
{

const string W_MODEL 	= "models/fournines/items/w_armor.mdl";
const string PICKUP_SND = "fournines/items/ArmorUT.wav";

class item_utarmor : ScriptBasePlayerItemEntity
{
	private bool Activated = true;
	dictionary g_MaxPlayers;

	void Spawn()
	{ 
		Precache();

		if( self.SetupModel() == false )
			g_EntityFuncs.SetModel( self, W_MODEL );
		else //Custom model
			g_EntityFuncs.SetModel( self, self.pev.model );

        if( self.pev.SpawnFlagBitSet( 384 )  )
		{	
            Activated = false;
		}
		
		BaseClass.Spawn();
	}

	void Precache()
	{
		BaseClass.Precache();

		if( string( self.pev.model ).IsEmpty() )
			g_Game.PrecacheModel( W_MODEL );
		else //Custom model
			g_Game.PrecacheModel( self.pev.model );

		g_SoundSystem.PrecacheSound( PICKUP_SND );
	}
		
	void AddArmor( CBasePlayer@ pPlayer )
	{	
        string steamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
        int pct;

		if( pPlayer is null || pPlayer.pev.armorvalue >= 100 && pPlayer.HasSuit() || !pPlayer.HasSuit() || g_MaxPlayers.exists(steamId)  )
			return;
		
        g_MaxPlayers[steamId] = @pPlayer;

		pPlayer.pev.armorvalue += 100; //int(g_EngineFuncs.CVarGetFloat( "sk_battery" ));
		pPlayer.pev.armorvalue = Math.min( pPlayer.pev.armorvalue, 100 );

		//Battery sound
		g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_ITEM, PICKUP_SND, 1, ATTN_NORM );
					
		NetworkMessage msg( MSG_ONE, NetworkMessages::ItemPickup, pPlayer.edict() );
			msg.WriteString( self.m_iId );
		msg.End();

		// Suit reports new power level
		// For some reason this wasn't working in release build -- round it.
		pct = int(float(pPlayer.pev.armorvalue * 100.0) * (1.0 / 100) + 0.5);
		pct = (pct / 5);
		if (pct > 0)
			pct--;

		//EMIT_SOUND_SUIT(ENT(pev), szcharge);
		pPlayer.SetSuitUpdate( "!HEV_" + pct + "P", false, 30 );
				
		// Trigger targets
		self.SUB_UseTargets( pPlayer, USE_TOGGLE, 0 );

		// Remove entity once the armor point is added
		g_EntityFuncs.Remove( self );

	}

	void Touch( CBaseEntity@ pOther )
	{
		if( pOther is null || !pOther.IsPlayer() || !pOther.IsAlive() || !Activated || self.pev.SpawnFlagBitSet( 256 ) )
			return;
				
		AddArmor( cast<CBasePlayer@>( pOther ) );
	}
		
	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
        if( self.pev.SpawnFlagBitSet( 384 ) && !Activated )
		{	
            Activated = !Activated;
		}

		if( pActivator.IsPlayer() && Activated )
		{
			AddArmor( cast<CBasePlayer@>( pActivator ) );
		}
	}
}

string GetName()
{
	return "item_utarmor";
}

void Register()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "UT_ARMOR::item_utarmor", GetName() ); // register class entity
	g_ItemRegistry.RegisterItem( GetName(), "fournines" );
}

}
