package com.ludusassistant.app.hero;

public final class Hero {
    public final String id, name, race, faction, rarity, role, ability, gameplay, version, tier;
    public Hero(String id,String name,String race,String faction,String rarity,String role,String ability,String gameplay,String version,String tier){
        this.id=id; this.name=name; this.race=race; this.faction=faction; this.rarity=rarity;
        this.role=role; this.ability=ability; this.gameplay=gameplay; this.version=version; this.tier=tier;
    }
}
