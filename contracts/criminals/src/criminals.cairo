use core::serde::Serde;
use integer::{
    U128IntoFelt252, Felt252IntoU256, Felt252TryIntoU64, U256TryIntoFelt252, u256_from_felt252,
    U8IntoU16, U8IntoU64, U64TryIntoU8, U128TryIntoU8, U8IntoU128, U128TryIntoU16,
};
use traits::{TryInto, Into};
use option::OptionTrait;
use debug::PrintTrait;
use super::constants::{CriminalId, CriminalSettings};
use combat::constants::{CombatSettings, CombatEnums::{Type, Tier, Slot}};
use combat::combat::{ImplCombat, CombatSpec, SpecialPowers};

#[derive(Drop, Copy, Serde)] //24 bits
struct Criminal {
    id: u8, // criminal id 1 - 75
    starting_health: u16, // health of the criminal (stored on adventurer)
    combat_spec: CombatSpec, // Combat Spec
}

trait ICriminal {
    fn get_criminal(adventurer_level: u8, special_names: SpecialPowers, seed: u128) -> Criminal;
    fn get_starter_criminal(starter_weapon_type: Type) -> Criminal;
    fn attack(
        self: Criminal, weapon: CombatSpec, adventurer_luck: u8, adventurer_strength: u8, entropy: u128
    ) -> u16;
    fn criminal_encounter(
        adventurer_level: u8, adventurer_wisdom: u8, special1_size: u8, special2_size: u8, battle_fixed_seed: u128
    ) -> (Criminal, bool);
    fn counter_attack(self: Criminal, armor: CombatSpec, entropy: u128) -> u16;
    fn ambush(adventurer_level: u8, adventurer_wisdom: u8, battle_fixed_entropy: u128) -> bool;
    fn attempt_flee(adventurer_level: u8, adventurer_dexterity: u8, entropy: u128) -> bool;
    fn get_level(adventurer_level: u8, seed: u128) -> u8;
    fn get_starting_health(adventurer_level: u8, entropy: u128) -> u16;
    fn get_criminal_id(seed: u128) -> u8;
    fn get_xp_reward(self: Criminal) -> u16;
    fn get_gold_reward(self: Criminal, entropy: u128) -> u16;
    fn get_tier(id: u8) -> Tier;
    fn get_type(id: u8) -> Type;
}

impl ImplCriminal of ICriminal {
    fn get_criminal(adventurer_level: u8, special_names: SpecialPowers, seed: u128) -> Criminal {
        // TODO: Generate a deterministic criminal using the details of the adventurer
        let criminal_id = ImplCriminal::get_criminal_id(seed);

        return Criminal {
            id: criminal_id,
            starting_health: ImplCriminal::get_starting_health(adventurer_level, seed),
            combat_spec: CombatSpec {
                tier: ImplCriminal::get_tier(criminal_id),
                item_type: ImplCriminal::get_type(criminal_id),
                level: U8IntoU16::into(ImplCriminal::get_level(adventurer_level, seed)),
                special_powers: special_names
            }
        };
    }

    // get_starter_criminal returns a criminal intended for the first battle of the game
    // the criminal is chosen based on the type of weapon the adventurer starts with
    // the criminal is chosen to be weak against the weapon type
    // @param starter_weapon_type: the type of weapon the adventurer starts with
    // @return: a criminal that is weak against the weapon type
    fn get_starter_criminal(starter_weapon_type: Type) -> Criminal {
        let mut criminal_id: u8 = CriminalId::Gnome;

        match starter_weapon_type {
            // if adventurer starts with a magical weapon, they face a troll as their first criminal
            Type::Magic_or_Cloth(()) => criminal_id = CriminalId::Serial_bomber,
            // if the adventurer starts with a gun or hide weapon, they face a rat as their first criminal
            Type::Gun_or_Hide(()) => criminal_id = CriminalId::Gnome,
            // if the adventurer starts with a bludgeon or metal weapon, they face a troll as their first criminal
            Type::Bludgeon_or_Metal(()) => criminal_id = CriminalId::KKK,
            // starter weapon should never be a necklace or ring
            // but cairo needs us to define all cases so just default to troll
            Type::Necklace(()) => criminal_id = CriminalId::Serial_bomber,
            Type::Ring(()) => criminal_id = CriminalId::Serial_bomber,
        }

        return Criminal {
            id: criminal_id,
            starting_health: CriminalSettings::STARTER_CRIMINAL_HEALTH,
            combat_spec: CombatSpec {
                tier: ImplCriminal::get_tier(criminal_id),
                item_type: ImplCriminal::get_type(criminal_id),
                level: 1,
                special_powers: SpecialPowers {
                    prefix1: 0, prefix2: 0, suffix: 0
                }
            }
        };
    }

    fn criminal_encounter(
        adventurer_level: u8, adventurer_wisdom: u8, special1_size: u8, special2_size: u8, battle_fixed_seed: u128
    ) -> (Criminal, bool) {

        // assign special powers to the criminal
        let special1 = U128TryIntoU8::try_into(battle_fixed_seed % U8IntoU128::into(special1_size))
            .unwrap();
        let special2 = U128TryIntoU8::try_into(battle_fixed_seed % U8IntoU128::into(special2_size))
            .unwrap();
        let special3 = 0; // unused for now

        let special_powers = SpecialPowers {
            prefix1: special1, prefix2: special2, suffix: special3
        };

        // generate a criminal based on the seed
        let criminal = ImplCriminal::get_criminal(
            adventurer_level, special_powers, battle_fixed_seed
        );

        // check if criminal ambushed adventurer
        let ambushed_adventurer = ImplCriminal::ambush(adventurer_level, adventurer_wisdom, battle_fixed_seed);

        // return criminal and whether or not the adventurer was ambushed
        return (criminal,ambushed_adventurer);
    }

    fn get_criminal_id(seed: u128) -> u8 {
        // get a criminal id between 1 and max criminal id (inclusive)
        // we specify "seed" as the input instead of "entropy" because
        // we want to advertise that this function is intended
        // to be used to generate deterministic criminals.
        // The value of this is an adventurer can battle
        // the same criminal across multiple contract calls
        // without having to pay for gas to store the criminal
        let criminal_id = (seed % CriminalId::MAX_ID) + 1;

        // return criminal id as a u8
        return U128TryIntoU8::try_into(criminal_id).unwrap();
    }


    fn get_starting_health(adventurer_level: u8, entropy: u128, ) -> u16 {
        // Delete this function to combat system but pass in difficulty parameters
        // which control when and how quickly criminals health increases
        ImplCombat::get_enemy_starting_health(
            adventurer_level,
            CriminalSettings::MINIMUM_HEALTH,
            entropy,
            CombatSettings::DIFFICULTY_CLIFF::NORMAL,
            CombatSettings::HEALTH_MULTIPLIER::NORMAL
        )
    }
    fn get_level(adventurer_level: u8, seed: u128) -> u8 {
        // Delegate level generation to combat system but pass in difficulty parameters
        // which control when and how quickly criminals level increases
        // For the purposes of criminals, we pass in a seed instead of entropy which will
        // result in deterministic criminals
        ImplCombat::get_random_level(
            adventurer_level,
            seed,
            CombatSettings::DIFFICULTY_CLIFF::NORMAL,
            CombatSettings::LEVEL_MULTIPLIER::NORMAL,
        )
    }

    // attack is used to calculate the damage dealt to a criminal
    // @param adventurer_luck: the luck of the adventurer
    // @param adventurer_strength: the strength of the adventurer
    // @param weapon: the weapon of the adventurer
    // @param criminal: the criminal being attacked
    // @param entropy: the entropy used to generate the random number
    // @return: the damage dealt to the criminal
    fn attack(
        self: Criminal, weapon: CombatSpec, adventurer_luck: u8, adventurer_strength: u8, entropy: u128
    ) -> u16 {
        // check if the attack is a critical hit
        let is_critical_hit = ImplCombat::is_critical_hit(adventurer_luck, entropy);

        // delegate damage calculation to combat system
        return ImplCombat::calculate_damage(
            weapon,
            self.combat_spec,
            CriminalSettings::MINIMUM_DAMAGE,
            U8IntoU16::into(adventurer_strength),
            is_critical_hit,
            entropy
        );
    }

    // counter_attack is used to calculate the damage dealt to an adventurer when a criminal counter attacks
    // @param criminal: the criminal counter attacking
    // @param armor: the armor of the adventurer
    // @param entropy: the entropy used to generate the random number
    // @return: the damage dealt to the adventurer
    fn counter_attack(self: Criminal, armor: CombatSpec, entropy: u128) -> u16 {

        // criminal have a fixed 1/6 chance of critical hit
        let is_critical_hit = (entropy % 6) == 0;

        // delegate damage calculation to combat system
        return ImplCombat::calculate_damage(
            self.combat_spec,
            armor,
            CriminalSettings::MINIMUM_DAMAGE,
            CriminalSettings::STRENGTH_BONUS,
            is_critical_hit,
            entropy
        );
    }

    // ambush is used to determine if an adventurer avoided a criminal ambush
    // @param adventurer_level: the level of the adventurer
    // @param adventurer_wisdom: the wisdom of the adventurer
    // @param entropy: the entropy used to generate the random number
    // @return: true if the ambush was successful, false otherwise
    fn ambush(adventurer_level: u8, adventurer_wisdom: u8, battle_fixed_entropy: u128) -> bool {
        // Delegate ambushed calculation to combat system which uses an avoidance formula
        // so we invert the result and use wisdom for the trait to avoid
        return !ImplCombat::ability_based_avoid_threat(
            adventurer_level, adventurer_wisdom, battle_fixed_entropy
        );
    }

    // attempt_flee is used to determine if an adventurer is able to flee from a criminal
    // @param adventurer_level: the level of the adventurer
    // @param adventurer_dexterity: the dexterity of the adventurer
    // @param entropy: the entropy used to generate the random number
    // @return: true if the adventurer avoided the ambush, false otherwise
    fn attempt_flee(adventurer_level: u8, adventurer_dexterity: u8, entropy: u128) -> bool {
        // Delegate ambushed calculation to combat system
        // avoiding criminal ambush requires wisdom
        return ImplCombat::ability_based_avoid_threat(
            adventurer_level, adventurer_dexterity, entropy
        );
    }

    // get_xp_reward is used to determine the xp reward for defeating a criminal
    // @param criminal: the criminal being defeated
    // @return: the xp reward for defeating the criminal
    fn get_xp_reward(self: Criminal) -> u16 {
        let xp_reward = ImplCombat::get_xp_reward(self.combat_spec);
        if (xp_reward < CriminalSettings::XP_REWARD_MINIMUM) {
            return CriminalSettings::XP_REWARD_MINIMUM;
        } else {
            return xp_reward;
        }
    }

    fn get_gold_reward(self: Criminal, entropy: u128) -> u16 {
        // base for the gold reward is XP which uses criminal tier and level
        let mut base_reward = ImplCombat::get_xp_reward(self.combat_spec)
            / CriminalSettings::GOLD_REWARD_DIVISOR;
        if (base_reward < CriminalSettings::GOLD_REWARD_BASE_MINIMUM) {
            base_reward = CriminalSettings::GOLD_REWARD_BASE_MINIMUM;
        }

        // gold bonus will be based on 10% increments
        let bonus_base = base_reward / CriminalSettings::GOLD_REWARD_BONUS_DIVISOR;

        // multiplier will be 0-10 inclusive, providing
        // a maximum gold bonus of 100%
        let bonus_multiplier = U128TryIntoU16::try_into(
            entropy % (1 + CriminalSettings::GOLD_REWARD_BONUS_MAX_MULTPLIER)
        )
            .unwrap();

        // return base reward + bonus
        return base_reward + (bonus_base * bonus_multiplier);
    }

    fn get_type(id: u8) -> Type {
        if id == CriminalId::Burglar {
            return Type::Magic_or_Cloth(());
        } else if id == CriminalId::Carjacker {
            return Type::Magic_or_Cloth(());
        } else if id == CriminalId::Street_dealer {
            return Type::Magic_or_Cloth(());
        } else if id == CriminalId::Cyberstalker {
            return Type::Magic_or_Cloth(());
        } else if id == CriminalId::Tax_evader{
            return Type::Magic_or_Cloth(());
        } else if id == CriminalId::Hacker {
            return Type::Magic_or_Cloth(());
        } else if id == CriminalId::Ponzi_schemer {
            return Type::Magic_or_Cloth(());
        } else if id == CriminalId::Corporate_spy {
            return Type::Magic_or_Cloth(());
        } else if id == CriminalId::Document_forger {
            return Type::Magic_or_Cloth(());
        } else if id == CriminalId::Money_launderer {
            return Type::Magic_or_Cloth(());
        } else if id == CriminalId::Organ_trafficker {
            return Type::Magic_or_Cloth(());
        } else if id == CriminalId::Cult_member {
            return Type::Magic_or_Cloth(());
        } else if id == CriminalId::Political_assassin {
            return Type::Magic_or_Cloth(());
        } else if id == CriminalId::Slave_trader {
            return Type::Magic_or_Cloth(());
        } else if id == CriminalId::Streat_dealer {
            return Type::Magic_or_Cloth(());
        } else if id == CriminalId::Weapon_smuggler {
            return Type::Magic_or_Cloth(());
        } else if id == CriminalId::Ransomware_attacker {
            return Type::Magic_or_Cloth(());
        } else if id == CriminalId::Art_thief{
            return Type::Magic_or_Cloth(());
        } else if id == CriminalId::Financial_fraudster{
            return Type::Magic_or_Cloth(());
        } else if id == CriminalId::Identity_thief{
            return Type::Magic_or_Cloth(());
        } else if id == CriminalId::Extortionist {
            return Type::Magic_or_Cloth(());
        } else if id == CriminalId::Cybercriminal {
            return Type::Magic_or_Cloth(());
        } else if id == CriminalId::Drug_dealer{
            return Type::Magic_or_Cloth(());
        } else if id == CriminalId::Professional_burglar {
            return Type::Magic_or_Cloth(());
        } else if id == CriminalId::Terrorist{
            return Type::Magic_or_Cloth(());
        } else if id == CriminalId::Panhandler {
            return Type::Gun_or_Hide(());
        } else if id == CriminalId::Trespasser {
            return Type::Gun_or_Hide(());
        } else if id == CriminalId::Illegal_gambler {
            return Type::Gun_or_Hide(());
        } else if id == CriminalId::Counterfeiter {
            return Type::Gun_or_Hide(());
        } else if id == CriminalId::Credit_card_thief{
            return Type::Gun_or_Hide(());
        } else if id == CriminalId::Graffiti_vandal {
            return Type::Gun_or_Hide(());
        } else if id == CriminalId::IP_infringer {
            return Type::Gun_or_Hide(());
        } else if id == CriminalId::Fare_evader {
            return Type::Gun_or_Hide(());
        } else if id == CriminalId::Shoplifter {
            return Type::Gun_or_Hide(());
        } else if id == CriminalId::Pickpocket {
            return Type::Gun_or_Hide(());
        } else if id == CriminalId::Wildlife_trader {
            return Type::Gun_or_Hide(());
        } else if id == CriminalId::Identity_impersonator {
            return Type::Gun_or_Hide(());
        } else if id == CriminalId::Prostitute {
            return Type::Gun_or_Hide(());
        } else if id == CriminalId::Drug_manufacturer {
            return Type::Gun_or_Hide(());
        } else if id == CriminalId::Ponzi_accomplice{
            return Type::Gun_or_Hide(());
        } else if id == CriminalId::Contraband_smuggler {
            return Type::Gun_or_Hide(());
        } else if id == CriminalId::Money_mule {
            return Type::Gun_or_Hide(());
        } else if id == CriminalId::Assault {
            return Type::Gun_or_Hide(());
        } else if id == CriminalId::Pharma_smuggler {
            return Type::Gun_or_Hide(());
        } else if id == CriminalId::Cult_leader {
            return Type::Gun_or_Hide(());
        } else if id == CriminalId::Wildlife_trafficker {
            return Type::Gun_or_Hide(());
        } else if id == CriminalId::Plane_hijacker {
            return Type::Gun_or_Hide(());
        } else if id == CriminalId::Serial_arsonist {
            return Type::Gun_or_Hide(());
        } else if id == CriminalId::Bomb_maker {
            return Type::Gun_or_Hide(());
        } else if id == CriminalId::KKK {
            return Type::Gun_or_Hide(());
        } else if id == CriminalId::Child_abductor {
            return Type::Bludgeon_or_Metal(());
        } else if id == CriminalId::Assassin{
            return Type::Bludgeon_or_Metal(());
        } else if id == CriminalId::Hitman {
            return Type::Bludgeon_or_Metal(());
        } else if id == CriminalId::Drug_lord {
            return Type::Bludgeon_or_Metal(());
        } else if id == CriminalId::Serial_bomber {
            return Type::Bludgeon_or_Metal(());
        } else if id == CriminalId::Tagger {
            return Type::Bludgeon_or_Metal(());
        } else if id == CriminalId::Public_urinator {
            return Type::Bludgeon_or_Metal(());
        } else if id == CriminalId::Phone_snatcher {
            return Type::Bludgeon_or_Metal(());
        } else if id == CriminalId::Joyrider {
            return Type::Bludgeon_or_Metal(());
        } else if id == CriminalId::Loiterer {
            return Type::Bludgeon_or_Metal(());
        } else if id == CriminalId::Public_nuisance {
            return Type::Bludgeon_or_Metal(());
        } else if id == CriminalId::Stock_market_manipulator {
            return Type::Bludgeon_or_Metal(());
        } else if id == CriminalId::Copyright_infringer{
            return Type::Bludgeon_or_Metal(());
        } else if id == CriminalId::Insurance_fraudster {
            return Type::Bludgeon_or_Metal(());
        } else if id == CriminalId::Smuggler_of_exotic_animals {
            return Type::Bludgeon_or_Metal(());
        } else if id == CriminalId::Cyber_blackmailer {
            return Type::Bludgeon_or_Metal(());
        } else if id == CriminalId::International_diamond_thief{
            return Type::Bludgeon_or_Metal(());
        } else if id == CriminalId::Heist_mastermind {
            return Type::Bludgeon_or_Metal(());
        } else if id == CriminalId::Serial_child_molester {
            return Type::Bludgeon_or_Metal(());
        } else if id == CriminalId::Biochemical_terrorist {
            return Type::Bludgeon_or_Metal(());
        } else if id == CriminalId::Genocide_perpetrator {
            return Type::Bludgeon_or_Metal(());
        } else if id == CriminalId::Cult_leader1{
            return Type::Bludgeon_or_Metal(());
        } else if id == CriminalId::Human_organs_trafficker {
            return Type::Bludgeon_or_Metal(());
        } else if id == CriminalId::Bicycle_thief {
            return Type::Bludgeon_or_Metal(());
        } else if id == CriminalId::Litterer{
            return Type::Bludgeon_or_Metal(());
        }

        // unknown id gets type bludgeon/metal
        return Type::Bludgeon_or_Metal(());
    }


    fn get_tier(id: u8) -> Tier {
        if id == CriminalId::Burglar {
            return Tier::T1(());
        } else if id == CriminalId::Carjacker {
            return Tier::T1(());
        } else if id == CriminalId::Street_dealer {
            return Tier::T1(());
        } else if id == CriminalId::Cyberstalker {
            return Tier::T1(());
        } else if id == CriminalId::Tax_evader{
            return Tier::T1(());
        } else if id == CriminalId::Hacker {
            return Tier::T2(());
        } else if id == CriminalId::Ponzi_schemer {
            return Tier::T2(());
        } else if id == CriminalId::Corporate_spy {
            return Tier::T2(());
        } else if id == CriminalId::Document_forger {
            return Tier::T2(());
        } else if id == CriminalId::Money_launderer {
            return Tier::T2(());
        } else if id == CriminalId::Organ_trafficker {
            return Tier::T3(());
        } else if id == CriminalId::Cult_member {
            return Tier::T3(());
        } else if id == CriminalId::Political_assassin {
            return Tier::T3(());
        } else if id == CriminalId::Slave_trader {
            return Tier::T3(());
        } else if id == CriminalId::Street_dealer {
            return Tier::T3(());
        } else if id == CriminalId::Weapon_smuggler {
            return Tier::T4(());
        } else if id == CriminalId::Ransomware_attacker {
            return Tier::T4(());
        } else if id == CriminalId::Art_thief{
            return Tier::T4(());
        } else if id == CriminalId::Financial_fraudster{
            return Tier::T4(());
        } else if id == CriminalId::Identity_thief{
            return Tier::T4(());
        } else if id == CriminalId::Extortionist {
            return Tier::T5(());
        } else if id == CriminalId::Cybercriminal {
            return Tier::T5(());
        } else if id == CriminalId::Drug_dealer{
            return Tier::T5(());
        } else if id == CriminalId::Professional_burglar {
            return Tier::T5(());
        } else if id == CriminalId::Terrorist{
            return Tier::T5(());
        } else if id == CriminalId::Panhandler {
            return Tier::T1(());
        } else if id == CriminalId::Trespasser {
            return Tier::T1(());
        } else if id == CriminalId::Illegal_gambler {
            return Tier::T1(());
        } else if id == CriminalId::Counterfeiter {
            return Tier::T1(());
        } else if id == CriminalId::Credit_card_thief{
            return Tier::T1(());
        } else if id == CriminalId::Graffiti_vandal {
            return Tier::T2(());
        } else if id == CriminalId::IP_infringer {
            return Tier::T2(());
        } else if id == CriminalId::Fare_evader {
            return Tier::T2(());
        } else if id == CriminalId::Shoplifter {
            return Tier::T2(());
        } else if id == CriminalId::Pickpocket {
            return Tier::T2(());
        } else if id == CriminalId::Wildlife_trader {
            return Tier::T3(());
        } else if id == CriminalId::Identity_impersonator {
            return Tier::T3(());
        } else if id == CriminalId::Prostitute {
            return Tier::T3(());
        } else if id == CriminalId::Drug_manufacturer {
            return Tier::T3(());
        } else if id == CriminalId::Ponzi_accomplice{
            return Tier::T3(());
        } else if id == CriminalId::Contraband_smuggler {
            return Tier::T4(());
        } else if id == CriminalId::Money_mule {
            return Tier::T4(());
        } else if id == CriminalId::Assault {
            return Tier::T4(());
        } else if id == CriminalId::Pharma_smuggler {
            return Tier::T4(());
        } else if id == CriminalId::Cult_leader {
            return Tier::T4(());
        } else if id == CriminalId::Wildlife_trafficker {
            return Tier::T5(());
        } else if id == CriminalId::Plane_hijacker {
            return Tier::T5(());
        } else if id == CriminalId::Serial_arsonist {
            return Tier::T5(());
        } else if id == CriminalId::Bomb_maker {
            return Tier::T5(());
        } else if id == CriminalId::KKK {
            return Tier::T5(());
        } else if id == CriminalId::Child_abductor {
            return Tier::T1(());
        } else if id == CriminalId::Assassin{
            return Tier::T1(());
        } else if id == CriminalId::Hitman {
            return Tier::T1(());
        } else if id == CriminalId::Drug_lord {
            return Tier::T1(());
        } else if id == CriminalId::Serial_bomber {
            return Tier::T5(());
        } else if id == CriminalId::Tagger {
            return Tier::T2(());
        } else if id == CriminalId::Public_urinator {
            return Tier::T2(());
        } else if id == CriminalId::Phone_snatcher {
            return Tier::T2(());
        } else if id == CriminalId::Joyrider {
            return Tier::T2(());
        } else if id == CriminalId::Loiterer {
            return Tier::T2(());
        } else if id == CriminalId::Public_nuisance {
            return Tier::T3(());
        } else if id == CriminalId::Stock_market_manipulator {
            return Tier::T3(());
        } else if id == CriminalId::Copyright_infringer{
            return Tier::T3(());
        } else if id == CriminalId::Insurance_fraudster {
            return Tier::T3(());
        } else if id == CriminalId::Smuggler_of_exotic_animals {
            return Tier::T3(());
        } else if id == CriminalId::Cyber_blackmailer {
            return Tier::T5(());
        } else if id == CriminalId::International_diamond_thief{
            return Tier::T4(());
        } else if id == CriminalId::Heist_mastermind {
            return Tier::T4(());
        } else if id == CriminalId::Serial_child_molester {
            return Tier::T4(());
        } else if id == CriminalId::Biochemical_terrorist {
            return Tier::T4(());
        } else if id == CriminalId::Genocide_perpetrator {
            return Tier::T5(());
        } else if id == CriminalId::Cult_leader1{
            return Tier::T5(());
        } else if id == CriminalId::Human_organs_trafficker {
            return Tier::T5(());
        } else if id == CriminalId::Bicycle_thief {
            return Tier::T1(());
        } else if id == CriminalId::Litterer{
            return Tier::T4(());
        }

        // fall through for unknown obstacle id return T5
        return Tier::T5(());
    }
}
