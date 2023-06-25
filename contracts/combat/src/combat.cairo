use core::option::OptionTrait;
use integer::{
    U8IntoU16, U16IntoU64, U8IntoU64, U64TryIntoU16, U64TryIntoU8, U8IntoU128, U128TryIntoU8,
    U128TryIntoU16, u16_sqrt
};
use core::traits::DivEq;
use super::constants::CombatEnums::{Tier, Type, Slot, WeaponEffectiveness};
use super::constants::CombatSettings;
use core::debug::PrintTrait;

// SpecialPowers contains special names for combat items
#[derive(Drop, Copy, Serde)]
struct SpecialPowers {
    prefix1: u8,
    prefix2: u8,
    suffix: u8,
}

// CombatSpec is used for combat calculations 
#[derive(Drop, Copy, Serde)]
struct CombatSpec {
    tier: Tier,
    item_type: Type,
    level: u16,
    special_powers: SpecialPowers,
}

// Combat is a trait that provides functions for calculating damage during on-chain combat
trait ICombat {
    fn calculate_damage(
        weapon: CombatSpec,
        armor: CombatSpec,
        minimum_damage: u16,
        strength_boost: u16,
        is_critical_hit: bool,
        entropy: u128,
    ) -> u16;

    fn get_attack_hp(weapon: CombatSpec) -> u16;
    fn get_armor_hp(armor: CombatSpec) -> u16;

    fn get_weapon_effectiveness(weapon_type: Type, armor_type: Type) -> WeaponEffectiveness;
    fn get_elemental_bonus(damage: u16, weapon_effectiveness: WeaponEffectiveness) -> u16;

    fn is_critical_hit(luck: u8, entropy: u128) -> bool;
    fn critical_hit_bonus(damage: u16, entropy: u128) -> u16;

    fn get_name_prefix1_bonus(
        damage: u16, weapon_prefix1: u8, armor_prefix1: u8, entropy: u128, 
    ) -> u16;
    fn get_name_prefix2_bonus(
        base_damage: u16, weapon_prefix2: u8, armor_prefix2: u8, entropy: u128, 
    ) -> u16;
    fn get_name_damage_bonus(
        base_damage: u16, weapon_name: SpecialPowers, armor_name: SpecialPowers, entropy: u128
    ) -> u16;

    fn get_strength_bonus(damage: u16, strength: u16) -> u16;
    fn get_random_level(
        adventurer_level: u8, entropy: u128, range_increase_interval: u8, level_multiplier: u8
    ) -> u8;
    fn get_enemy_starting_health(
        adventurer_level: u8,
        minimum_health: u8,
        entropy: u128,
        range_increase_interval: u8,
        level_multiplier: u8
    ) -> u16;
    fn get_random_damage_location(entropy: u128, ) -> Slot;
    fn get_xp_reward(defeated_entity: CombatSpec) -> u16;
    fn get_level_from_xp(xp: u16) -> u8;

    fn tier_to_u8(tier: Tier) -> u8;
    fn u8_to_tier(item_type: u8) -> Tier;

    fn type_to_u8(item_type: Type) -> u8;
    fn u8_to_type(item_type: u8) -> Type;

    fn slot_to_u8(slot: Slot) -> u8;
    fn u8_to_slot(item_type: u8) -> Slot;

    fn ability_based_avoid_threat(adventurer_level: u8, relevant_stat: u8, entropy: u128) -> bool;
}

// ImplCombat is an implementation of the Combat trait
// It provides functions for calculating combat damage
impl ImplCombat of ICombat {
    // calculate_damage calculates the damage done by an entity wielding a weapon against an entity wearing armor
    // @param weapon: the weapon used to attack
    // @param armor: the armor worn by the defender
    // @param minimum_damage: the minimum damage that can be done
    // @param strength_boost: the strength boost of the attacker
    // @param is_critical_hit: whether or not the attack was a critical hit
    // @param weapon_effectiveness: the effectiveness of the weapon against the armor
    // @param entropy: the entropy used to calculate critical hit bonus and name prefix bonus
    // @return u16: the damage done by the attacker
    fn calculate_damage(
        weapon: CombatSpec,
        armor: CombatSpec,
        minimum_damage: u16,
        strength_boost: u16,
        is_critical_hit: bool,
        entropy: u128,
    ) -> u16 {
        // get base damage
        let base_attack_hp = ImplCombat::get_attack_hp(weapon);
        let armor_hp = ImplCombat::get_armor_hp(armor);

        let weapon_effectiveness = ImplCombat::get_weapon_effectiveness(
            weapon.item_type, armor.item_type
        );

        // get elemental adjusted attack
        let elemental_adjusted_attack = ImplCombat::get_elemental_bonus(
            base_attack_hp, weapon_effectiveness
        );

        // if attack was critical hit
        let mut critical_hit_bonus = 0;
        if (is_critical_hit) {
            // add critical hit bonus
            critical_hit_bonus = ImplCombat::critical_hit_bonus(base_attack_hp, entropy);
        }

        // get special name damage bonus
        let name_prefix_bonus = ImplCombat::get_name_damage_bonus(
            base_attack_hp, weapon.special_powers, armor.special_powers, entropy
        );

        // get adventurer strength bonus
        let strength_bonus = ImplCombat::get_strength_bonus(base_attack_hp, strength_boost);

        // total attack hit points
        let total_attack = elemental_adjusted_attack
            + critical_hit_bonus
            + name_prefix_bonus
            + strength_bonus;

        // if the total attack is greater than the armor HP plus the minimum damage
        // this is both to prevent underflow of attack-armor but also to ensure
        // that the minimum damage is always done
        if (total_attack > (armor_hp + minimum_damage)) {
            // return total attack
            return total_attack - armor_hp;
        } else {
            // otreturn total attack
            return minimum_damage;
        }
    }

    // get_attack_hp calculates the attack HP of a weapon
    // @param weapon: the weapon used to attack
    // @return u16: the attack HP of the weapon
    fn get_attack_hp(weapon: CombatSpec) -> u16 {
        match weapon.tier {
            Tier::T1(()) => {
                return weapon.level * CombatSettings::WEAPON_TIER_DAMAGE_MULTIPLIER::T1;
            },
            Tier::T2(()) => {
                return weapon.level * CombatSettings::WEAPON_TIER_DAMAGE_MULTIPLIER::T2;
            },
            Tier::T3(()) => {
                return weapon.level * CombatSettings::WEAPON_TIER_DAMAGE_MULTIPLIER::T3;
            },
            Tier::T4(()) => {
                return weapon.level * CombatSettings::WEAPON_TIER_DAMAGE_MULTIPLIER::T4;
            },
            Tier::T5(()) => {
                return weapon.level * CombatSettings::WEAPON_TIER_DAMAGE_MULTIPLIER::T5;
            }
        }
    }

    // get_armor_hp calculates the armor HP of a piece of armor
    // @param armor: the armor worn by the defender
    // @return u16: the armor HP of the armor
    fn get_armor_hp(armor: CombatSpec) -> u16 {
        match armor.tier {
            Tier::T1(()) => {
                return armor.level * CombatSettings::ARMOR_TIER_DAMAGE_MULTIPLIER::T1;
            },
            Tier::T2(()) => {
                return armor.level * CombatSettings::ARMOR_TIER_DAMAGE_MULTIPLIER::T2;
            },
            Tier::T3(()) => {
                return armor.level * CombatSettings::ARMOR_TIER_DAMAGE_MULTIPLIER::T3;
            },
            Tier::T4(()) => {
                return armor.level * CombatSettings::ARMOR_TIER_DAMAGE_MULTIPLIER::T4;
            },
            Tier::T5(()) => {
                return armor.level * CombatSettings::ARMOR_TIER_DAMAGE_MULTIPLIER::T5;
            }
        }
    }

    // adjust_damage_for_elemental adjusts the base damage for elemental effects
    // @param damage: the base damage done by the attacker
    // @param weapon_effectiveness: the effectiveness of the weapon against the armor
    // @return u16: the base damage done by the attacker adjusted for elemental effects
    fn get_elemental_bonus(damage: u16, weapon_effectiveness: WeaponEffectiveness) -> u16 {
        // CombatSettings::ELEMENTAL_DAMAGE_BONUS determines impact of elemental damage
        // default setting is 2 which results in -50%, 0%, or 50% damage bonus for elemental
        let elemental_damage_effect = damage / CombatSettings::ELEMENTAL_DAMAGE_BONUS;

        // adjust base damage based on weapon effectiveness
        match weapon_effectiveness {
            WeaponEffectiveness::Weak(()) => {
                return damage - elemental_damage_effect;
            },
            WeaponEffectiveness::Fair(()) => {
                return damage;
            },
            WeaponEffectiveness::Strong(()) => {
                let elemental_adjusted_damage = damage + elemental_damage_effect;
                if (elemental_adjusted_damage < CombatSettings::STRONG_ELEMENTAL_BONUS_MIN) {
                    return CombatSettings::STRONG_ELEMENTAL_BONUS_MIN;
                } else {
                    return elemental_adjusted_damage;
                }
            }
        }
    }

    // get_weapon_effectiveness returns a WeaponEffectiveness enum indicating the effectiveness of the weapon against the armor
    // the effectiveness is determined by the weapon type and the armor type
    // @param weapon_type: the type of weapon used to attack
    // @param armor_type: the type of armor worn by the defender
    // @return WeaponEffectiveness: the effectiveness of the weapon against the armor
    fn get_weapon_effectiveness(weapon_type: Type, armor_type: Type) -> WeaponEffectiveness {
        match weapon_type {
            // Magic is strong against metal, fair against cloth, and weak against hide
            Type::Magic_or_Cloth(()) => {
                match armor_type {
                    Type::Magic_or_Cloth(()) => {
                        return WeaponEffectiveness::Fair(());
                    },
                    Type::Gun_or_Hide(()) => {
                        return WeaponEffectiveness::Weak(());
                    },
                    Type::Bludgeon_or_Metal(()) => {
                        return WeaponEffectiveness::Strong(());
                    },
                    // should not happen but compiler requires exhaustive match
                    Type::Necklace(()) => {
                        return WeaponEffectiveness::Fair(());
                    },
                    // should not happen but compiler requires exhaustive match
                    Type::Ring(()) => {
                        return WeaponEffectiveness::Fair(());
                    }
                }
            },
            // Gun is strong against cloth, fair against hide, and weak against metal
            Type::Gun_or_Hide(()) => {
                match armor_type {
                    Type::Magic_or_Cloth(()) => {
                        return WeaponEffectiveness::Strong(());
                    },
                    Type::Gun_or_Hide(()) => {
                        return WeaponEffectiveness::Fair(());
                    },
                    Type::Bludgeon_or_Metal(()) => {
                        return WeaponEffectiveness::Weak(());
                    },
                    // should not happen but compiler requires exhaustive match
                    Type::Necklace(()) => {
                        return WeaponEffectiveness::Fair(());
                    },
                    // should not happen but compiler requires exhaustive match
                    Type::Ring(()) => {
                        return WeaponEffectiveness::Fair(());
                    }
                }
            },
            // Bludgeon is strong against hide, fair against metal, and weak against cloth
            Type::Bludgeon_or_Metal(()) => {
                match armor_type {
                    Type::Magic_or_Cloth(()) => {
                        return WeaponEffectiveness::Weak(());
                    },
                    Type::Gun_or_Hide(()) => {
                        return WeaponEffectiveness::Strong(());
                    },
                    Type::Bludgeon_or_Metal(()) => {
                        return WeaponEffectiveness::Fair(());
                    },
                    // should not happen but compiler requires exhaustive match
                    Type::Necklace(()) => {
                        return WeaponEffectiveness::Fair(());
                    },
                    // should not happen but compiler requires exhaustive match
                    Type::Ring(()) => {
                        return WeaponEffectiveness::Fair(());
                    }
                }
            },
            Type::Necklace(()) => {
                return WeaponEffectiveness::Fair(());
            },
            Type::Ring(()) => {
                return WeaponEffectiveness::Fair(());
            },
        }
    }

    // is_critical_hit determines if an attack is a critical hit
    // @param luck: the luck of the adventurer
    // @param entropy: the entropy used to create random outcome
    // @return bool: true if the attack is a critical hit, false otherwise
    fn is_critical_hit(luck: u8, entropy: u128) -> bool {
        // maximum luck is governed by CombatSettings::MAX_CRITICAL_HIT_LUCK
        // current setting is 50. With Luck at 50, player has 50% chance of critical hit
        let mut effective_luck = luck;
        if (luck > CombatSettings::MAX_CRITICAL_HIT_LUCK) {
            effective_luck = CombatSettings::MAX_CRITICAL_HIT_LUCK;
        }

        // critical hit chance is whole number of luck / 10
        // so the chance of getting a critical hit increases every 10 luck
        let mut critical_hit_chance: u8 = effective_luck / 10;

        // critical hit random number is modulo the max critical hit chance
        // this will result in a number between 0 and 5
        let critical_hit_outcome = entropy % U8IntoU128::into((6 - critical_hit_chance));

        // if the critical hit random number is 0 (no remainder)
        if (critical_hit_outcome == 0) {
            // return true
            return true;
        } else {
            // otherwise return false
            return false;
        }
    }

    // get_critical_hit_damage_bonus returns the bonus damage done by a critical hit
    // @param base_damage: the base damage done by the attacker
    // @param entropy: entropy for randomizing critical hit damage bonus
    // @return u16: the bonus damage done by a critical hit
    fn critical_hit_bonus(damage: u16, entropy: u128) -> u16 {
        // divide base damage by 4 to get 25% of original damage
        let damage_boost_base = damage / 4;

        // damage multplier is 1-4 which will equate to a 25-100% damage boost
        let damage_multplier = U128TryIntoU16::try_into(entropy % 4).unwrap();

        // multiply base damage boost (25% of original damage) by damage multiplier (1-4)
        return damage_boost_base * (damage_multplier + 1);
    }

    // get_name_prefix1_bonus returns the bonus damage done by a weapon as a result of the first part of its name
    // @param damage: the base damage done by the attacker
    // @param weapon_name: the name of the weapon used to attack
    // @param armor_name: the name of the armor worn by the defender
    // @param entropy: entropy for randomizing name prefix damage bonus
    // @return u16: the bonus damage done by a name prefix
    fn get_name_prefix1_bonus(
        damage: u16, weapon_prefix1: u8, armor_prefix1: u8, entropy: u128, 
    ) -> u16 {
        // is the weapon does not have a prefix
        if (weapon_prefix1 == 0) {
            // return zero
            return 0;
        // if the weapon prefix is the same as the armor prefix
        } else if (weapon_prefix1 == armor_prefix1) {
            let damage_multplier = U128TryIntoU16::try_into(entropy % 4).unwrap();

            // result will be base damage * (4-7) which will equate to a 4-7x damage bonus
            return damage * (damage_multplier + 4);
        }

        // fall through return zero
        0
    }

    // get_name_prefix2_bonus returns the bonus damage done by a weapon as a result of the second part of its name
    // @param base_damage: the base damage done by the attacker
    // @param weapon_name: the name of the weapon used by the attacker
    // @param armor_name: the name of the armor worn by the defender
    // @param entropy: entropy for randomizing name prefix 2 damage bonus
    // @return u16: the bonus damage done by a weapon as a result of the second part of its name
    fn get_name_prefix2_bonus(
        base_damage: u16, weapon_prefix2: u8, armor_prefix2: u8, entropy: u128, 
    ) -> u16 {
        // is the weapon does not have a prefix
        if (weapon_prefix2 == 0) {
            // return zero
            return 0;
        // if the weapon prefix is the same as the armor prefix
        } else if (weapon_prefix2 == armor_prefix2) {
            // divide base damage by 4 to get 25% of original damage
            let damage_boost_base = base_damage / 4;

            // damage multplier is 1-4 which will equate to a 25-100% damage boost
            let damage_multplier = U128TryIntoU16::try_into(entropy % 4).unwrap();

            // multiply base damage boost (25% of original damage) by damage multiplier (1-4)
            return damage_boost_base * (damage_multplier + 1);
        }

        // fall through return zero
        0
    }

    // get_special_name_damage_bonus returns the bonus damage for special item
    // @param base_damage: the base damage done by the attacker
    // @param weapon_name: the name of the weapon used by the attacker
    // @param armor_name: the name of the armor worn by the defender
    // @param entropy: entropy for randomizing special item damage bonus
    // @return u16: the bonus damage done by a special item
    fn get_name_damage_bonus(
        base_damage: u16, weapon_name: SpecialPowers, armor_name: SpecialPowers, entropy: u128
    ) -> u16 {
        let name_prefix1_bonus = ImplCombat::get_name_prefix1_bonus(
            base_damage, weapon_name.prefix1, armor_name.prefix1, entropy
        );

        let name_prefix2_bonus = ImplCombat::get_name_prefix2_bonus(
            base_damage, weapon_name.prefix2, armor_name.prefix2, entropy
        );

        // return the sum of the name prefix and name suffix bonuses
        return name_prefix1_bonus + name_prefix2_bonus;
    }

    // get_adventurer_strength_bonus returns the bonus damage for adventurer strength
    // @param strength: the strength stat of the adventurer
    // @param damage: the original damage done by the attacker
    // @return u16: the bonus damage done by adventurer strength
    fn get_strength_bonus(damage: u16, strength: u16) -> u16 {
        if (strength == 0) {
            // if the adventurer has no strength, return zero
            return 0;
        } else {
            // each strength stat point is worth 20% of the original damage
            return (damage * strength * 20) / 100;
        }
    }

    // get_random_level returns a random level scoped for the adventurere Level
    // @param adventurer_level: the level of the adventurer
    // @param entropy: entropy for randomizing entity level
    // @param range_increase_interval: the interval at which the max level of entitys will increase
    // @param level_multiplier: the multiplier for the entity level
    // @return u8: the random level scoped for the adventurer level
    fn get_random_level(
        adventurer_level: u8, entropy: u128, range_increase_interval: u8, level_multiplier: u8
    ) -> u8 {
        // If adventurer has not exceeded the difficult cliff level
        if (adventurer_level <= range_increase_interval) {
            // return the adventurer level
            return adventurer_level;
        }

        // If adventurer has exceeded the difficult cliff level
        // the entity level will be randomnly scoped around the adventurer level
        // the max level of entitys will increase every N levels based on 
        // the DIFFICULTY_CLIFF setting. The higher this setting, the less frequently the max level will increase
        let entity_level_multplier = 1 + (adventurer_level / range_increase_interval);

        // maximum range of the entity level will be the above multplier * the entity difficulty
        let entity_level_range = U8IntoU128::into(entity_level_multplier * level_multiplier);

        // calculate the entity level 
        let entity_level_boost = entropy % entity_level_range;

        // add the entity level boost to the adventurer level - difficulty cliff
        // this will produce a level between (adventurer level - difficulty cliff) and entity_level_multplier * entity_constants::Settings::entity_LEVEL_RANGE
        let entity_level = entity_level_boost
            + U8IntoU128::into((adventurer_level - entity_level_multplier));

        // return the entity level as a u16
        return U128TryIntoU8::try_into(entity_level).unwrap();
    }

    // get_enemy_starting_health returns the starting health for an entity
    // @param 
    fn get_enemy_starting_health(
        adventurer_level: u8,
        minimum_health: u8,
        entropy: u128,
        range_increase_interval: u8,
        level_multiplier: u8
    ) -> u16 {
        // enemy starting health increases every N adventurer levels
        let health_multiplier = adventurer_level / range_increase_interval;

        // max health is based on adventurer level and the level multplier
        // if the range_increase_interval is 5 for example and the adventurer is on
        // level 20, the max enemy health will be 5 * (level multiplier)
        let max_health = U8IntoU128::into((1 + health_multiplier) * level_multiplier);

        // the remainder of entropy divided by max_health provides entity health
        // we then add 1 to minimum_health to prevent starting health of zero
        return U128TryIntoU16::try_into(
            U8IntoU128::into(adventurer_level + minimum_health) + (entropy % max_health)
        )
            .unwrap();
    }


    // get_level_from_xp returns the level for a given xp
    // @param xp: the xp to get the level for
    // @return u8: the level for the given xp
    fn get_level_from_xp(xp: u16) -> u8 {
        if (xp > 0) {
            return u16_sqrt(xp);
        } else {
            return 1;
        }
    }

    // get_xp_reward returns the xp reward for defeating an entity
    // @param defeated_entity: the entity that was defeated
    // @return u16: the xp reward for defeating the entity
    fn get_xp_reward(defeated_entity: CombatSpec) -> u16 {
        match defeated_entity.tier {
            Tier::T1(()) => {
                return CombatSettings::XP_MULTIPLIER::T1 * defeated_entity.level;
            },
            Tier::T2(()) => {
                return CombatSettings::XP_MULTIPLIER::T2 * defeated_entity.level;
            },
            Tier::T3(()) => {
                return CombatSettings::XP_MULTIPLIER::T3 * defeated_entity.level;
            },
            Tier::T4(()) => {
                return CombatSettings::XP_MULTIPLIER::T4 * defeated_entity.level;
            },
            Tier::T5(()) => {
                return CombatSettings::XP_MULTIPLIER::T5 * defeated_entity.level;
            }
        }
    }

    fn get_random_damage_location(entropy: u128, ) -> Slot {
        // generate random damage location based on Item Slot which has
        // armor in slots 2-6 inclusive
        let damage_location = 2 + (entropy % 6);
        return ImplCombat::u8_to_slot(U128TryIntoU8::try_into(damage_location).unwrap());
    }

    fn tier_to_u8(tier: Tier) -> u8 {
        match tier {
            Tier::T1(()) => 1,
            Tier::T2(()) => 2,
            Tier::T3(()) => 3,
            Tier::T4(()) => 4,
            Tier::T5(()) => 5,
        }
    }
    fn type_to_u8(item_type: Type) -> u8 {
        match item_type {
            Type::Magic_or_Cloth(()) => 1,
            Type::Gun_or_Hide(()) => 2,
            Type::Bludgeon_or_Metal(()) => 3,
            Type::Necklace(()) => 4,
            Type::Ring(()) => 5,
        }
    }
    fn u8_to_type(item_type: u8) -> Type {
        if (item_type == 1) {
            return Type::Magic_or_Cloth(());
        } else if (item_type == 2) {
            return Type::Gun_or_Hide(());
        } else if (item_type == 3) {
            return Type::Bludgeon_or_Metal(());
        } else if (item_type == 4) {
            return Type::Necklace(());
        }
        return Type::Ring(());
    }
    fn u8_to_tier(item_type: u8) -> Tier {
        if (item_type == 1) {
            return Tier::T1(());
        } else if (item_type == 2) {
            return Tier::T2(());
        } else if (item_type == 3) {
            return Tier::T3(());
        } else if (item_type == 4) {
            return Tier::T4(());
        }
        return Tier::T5(());
    }
    fn slot_to_u8(slot: Slot) -> u8 {
        match slot {
            Slot::Weapon(()) => 1,
            Slot::Chest(()) => 2,
            Slot::Head(()) => 3,
            Slot::Waist(()) => 4,
            Slot::Foot(()) => 5,
            Slot::Hand(()) => 6,
            Slot::Neck(()) => 7,
            Slot::Ring(()) => 8,
        }
    }
    fn u8_to_slot(item_type: u8) -> Slot {
        if (item_type == 1) {
            return Slot::Weapon(());
        } else if (item_type == 2) {
            return Slot::Chest(());
        } else if (item_type == 3) {
            return Slot::Head(());
        } else if (item_type == 4) {
            return Slot::Waist(());
        } else if (item_type == 5) {
            return Slot::Foot(());
        } else if (item_type == 6) {
            return Slot::Hand(());
        } else if (item_type == 7) {
            return Slot::Neck(());
        } else {
            return Slot::Ring(());
        }
    }

    // ability_based_avoid_threat returns whether or not the adventurer can avoid the threat
    // @param adventurer_level: the level of the adventurer
    // @param relevant_stat: the stat that is relevant to the threat
    // @param entropy: the entropy to use for the random number generator
    // @return bool: whether or not the adventurer can avoid the threat
    fn ability_based_avoid_threat(adventurer_level: u8, relevant_stat: u8, entropy: u128) -> bool {
        // number of sides of the die will be based on adventurer_level
        // so the higher the adventurer level, the more sides the die has
        let dice_roll = 1 + (U128TryIntoU8::try_into(entropy).unwrap() % adventurer_level);

        // in order to avoid the threat, the adventurer must roll a number less than or equal
        // to the the relevant stat + difficulty cliff.
        // The difficulty cliff serves as a starting cushion for the adventurer before which
        // they can avoid all threats. Once the difficulty cliff has been passed, the adventurer
        // must invest in the proper stats to avoid threats.{Intelligence for obstalce, Wisdom for Criminal ambushes}
        return (dice_roll <= (relevant_stat + CombatSettings::DIFFICULTY_CLIFF::NORMAL));
    }
}
