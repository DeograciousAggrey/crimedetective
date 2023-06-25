use core::result::ResultTrait;
use core::serde::Serde;
use integer::{U64IntoU128, U16IntoU128, U128TryIntoU8, U8IntoU128, u16_overflowing_sub};
use traits::{TryInto, Into};
use option::OptionTrait;
use debug::PrintTrait;

use pack::pack::{
    pack_value, unpack_value, U256TryIntoU32, U256TryIntoU16, U256TryIntoU8, U256TryIntoU64,
};
use pack::constants::{MASK_16, pow, MASK_8, MASK_BOOL, mask};

use lootitems::loot::{Loot, ILoot, ImplLoot};
use lootitems::statistics::{constants, item_tier, item_type};

use super::exploration::ExploreUtils;
use super::constants::adventurer_constants::{
    STARTING_GOLD, StatisticIndex, POTION_PRICE, STARTING_HEALTH, CHARISMA_DISCOUNT,
    MINIMUM_ITEM_PRICE, MINIMUM_POTION_PRICE, ITEM_XP_MULTIPLIER
};
use super::constants::discovery_constants::DiscoveryEnums::{ExploreResult, TreasureDiscovery};
use super::item_meta::{LootStatistics, LootDescription};

use combat::combat::{ImplCombat, CombatSpec, SpecialPowers};
use combat::constants::CombatEnums::{Type, Tier, Slot};

use obstacles::obstacle::{ImplObstacle, Obstacle};
use criminals::criminal::{ImplCriminal, Criminal};
use criminals::constants::CriminalSettings;

#[derive(Drop, Copy, Serde)]
struct Adventurer {
    last_action: u16, // 3 bits
    health: u16, // 9 bits     
    xp: u16, // 13 bits
    // Physical
    strength: u8, // 5 bits
    dexterity: u8, //  5 bits
    vitality: u8, //  5 bits
    // Mental
    intelligence: u8, //  5 bits
    wisdom: u8, //  5 bits
    charisma: u8, //  5 bits
    // equipped
    gold: u16, // 9 bits
    weapon: LootStatistics, // 24 bits
    chest: LootStatistics, // 24 bits
    head: LootStatistics, // 24 bits
    waist: LootStatistics, // 24 bits
    foot: LootStatistics, // 24 bits
    hand: LootStatistics, // 24 bits
    neck: LootStatistics, // 24 bits
    ring: LootStatistics, // 24 bits
    // Criminal health
    criminal_health: u16,
    stat_upgrade_available: u8, // 3 bits
}

#[generate_trait]
impl ImplAdventurer of IAdventurer {
    fn charisma_potion_discount(self: Adventurer) -> u16 {
        CHARISMA_DISCOUNT * self.charisma.into()
    }

    fn charisma_item_discount(self: Adventurer) -> u16 {
        CHARISMA_DISCOUNT * self.charisma.into()
    }

    fn get_item_cost(self: Adventurer, item_cost: u16) -> u16 {
        if (u16_overflowing_sub(item_cost, self.charisma_item_discount()).is_ok()) {
            let cost = item_cost - self.charisma_item_discount();

            if (cost < MINIMUM_ITEM_PRICE) {
                MINIMUM_ITEM_PRICE
            } else {
                cost
            }
        } else {
            MINIMUM_ITEM_PRICE
        }
    }

    fn get_potion_cost(ref self: Adventurer) -> u16 {
        // check if we overflow
        if (u16_overflowing_sub(
            POTION_PRICE * self.get_level().into(), self.charisma_potion_discount()
        )
            .is_ok()) {
            let price = POTION_PRICE * self.get_level().into() - self.charisma_potion_discount();

            // check if less than the base price - this can only happen rarely
            if (price < MINIMUM_POTION_PRICE) {
                MINIMUM_POTION_PRICE
            } else {
                price
            }
        } else {
            MINIMUM_POTION_PRICE
        }
    }
    fn add_statistic(ref self: Adventurer, value: u8) -> Adventurer {
        assert(value < 6, 'Index out of bounds');
        if (value == StatisticIndex::STRENGTH) {
            self.add_strength(1)
        } else if (value == StatisticIndex::DEXTERITY) {
            self.add_dexterity(1)
        } else if (value == StatisticIndex::VITALITY) {
            self.add_vitality(1)
        } else if (value == StatisticIndex::INTELLIGENCE) {
            self.add_intelligence(1)
        } else if (value == StatisticIndex::WISDOM) {
            self.add_wisdom(1)
        } else {
            self.add_charisma(1)
        }
    }
    // get_random_explore returns a random number between 0 and 3 based on provided entropy
    // @param entropy: entropy for generating random explore
    // @return u64: A random number between 0 and 3 denoting the outcome of the explore
    fn get_random_explore(entropy: u128) -> ExploreResult {
        let result = entropy % 3;
        if (result == 0) {
            return ExploreResult::Criminal(());
        } else if (result == 1) {
            return ExploreResult::Obstacle(());
        } else {
            return ExploreResult::Treasure(());
        }
    }
    fn deduct_gold(ref self: Adventurer, value: u16) -> Adventurer {
        self.gold -= value;

        if (self.gold < 0) {
            self.gold = 0;
        }

        self
    }
    fn check_gold(self: Adventurer, value: u16) -> bool {
        self.gold >= value
    }

    // get_item_at_slot returns the item at a given item slot
    // @param self: Adventurer to check
    // @param slot: Slot to check
    // @return LootStatistics: Item at slot
    fn get_item_at_slot(self: Adventurer, slot: Slot) -> LootStatistics {
        match slot {
            Slot::Weapon(()) => self.weapon,
            Slot::Chest(()) => self.chest,
            Slot::Head(()) => self.head,
            Slot::Waist(()) => self.waist,
            Slot::Foot(()) => self.foot,
            Slot::Hand(()) => self.hand,
            Slot::Neck(()) => self.neck,
            Slot::Ring(()) => self.ring,
        }
    }

    // is_slot_free checks if an item slot is free for an adventurer
    // @param self: Adventurer to check
    // @param item: Item to check
    // @return bool: True if slot is free, false if not
    fn is_slot_free(self: Adventurer, item: LootStatistics) -> bool {
        let slot = ImplLoot::get_slot(item.id);
        match slot {
            Slot::Weapon(()) => self.weapon.id == 0,
            Slot::Chest(()) => self.chest.id == 0,
            Slot::Head(()) => self.head.id == 0,
            Slot::Waist(()) => self.waist.id == 0,
            Slot::Foot(()) => self.foot.id == 0,
            Slot::Hand(()) => self.hand.id == 0,
            Slot::Neck(()) => self.neck.id == 0,
            Slot::Ring(()) => self.ring.id == 0,
        }
    }
    fn get_criminal(self: Adventurer) -> u8 {
        // TODO: return Criminal struct generated from xp
        return 1;
    }

    fn get_level(self: Adventurer) -> u8 {
        return ImplCombat::get_level_from_xp(self.xp);
    }

    // criminal_encounter psuedo discovers a criminal for an adventurer
    // since the criminal is generated at runtime, we simply need to set the
    // criminals health which will enable the contract to detect the adventurer is in a battle
    // allowing adventurer to call "attack"
    // @param self: Adventurer to discover criminal for
    // @param entropy: Entropy for generating criminal
    // @return Adventurer: Adventurer with criminal discovered
    fn criminal_encounter(ref self: Adventurer, battle_fixed_seed: u128) -> Criminal {
        // generate battle fixed entropy by combining adventurer xp and adventurer entropy
        let battle_fixed_entropy: u128 = self
            .get_battle_fixed_entropy(U128TryIntoU64::try_into(battle_fixed_seed).unwrap());

        // generate special names for criminal using Loot name schema. 
        // We use Loot names because the combat system will deal bonus damage for matching names (these are the items super powers)
        // We do this here instead of in criminal to prevent criminal from depending on Loot
        let prefix1 = U128TryIntoU8::try_into(
            battle_fixed_entropy % U8IntoU128::into(constants::NamePrefixLength)
        )
            .unwrap();
        let prefix2 = U128TryIntoU8::try_into(
            battle_fixed_entropy % U8IntoU128::into(constants::NameSuffixLength)
        )
            .unwrap();

        // use the randomly generated prefixes but set suffic to 0
        let special_names = SpecialPowers { prefix1: prefix1, prefix2: prefix2, suffix: 0 };

        // get criminal using battle fixed seed
        // this is important because in the context of this call
        // the player has just encountered the criminal and will 
        // subsequently be calling "attack" to attack the criminal
        // to enable the adventurer state to fit in a single 252felt, we
        // don't store anything about the criminal in the adventurer state
        // except it's health. Instead the criminal is generated at run-time
        // via the battle_fixed_seed
        let criminal = ImplCriminal::get_criminal(self.get_level(), special_names, battle_fixed_seed);

        // otherwise generate random starting health for the criminal
        self.add_criminal(criminal.starting_health);

        // return criminal
        return criminal;
    }

    fn discover_treasure(ref self: Adventurer, entropy: u128) -> (TreasureDiscovery, u16) {
        // generate random item discovery
        let item_type = ExploreUtils::get_random_treasury_discovery(self, entropy);

        match item_type {
            TreasureDiscovery::Gold(()) => {
                let gold_amount = ExploreUtils::get_gold_discovery(self, entropy);
                // add the gold to the adventurer
                self.increase_gold(gold_amount);
                return (TreasureDiscovery::Gold(()), gold_amount);
            },
            TreasureDiscovery::XP(()) => {
                let xp_amount = ExploreUtils::get_xp_discovery(
                    self, entropy
                ); // add the xp to the adventurer
                self.increase_adventurer_xp(xp_amount); // if the discovery is an item
                return (TreasureDiscovery::XP(()), xp_amount);
            },
            TreasureDiscovery::Health(()) => {
                let health_amount = ExploreUtils::get_health_discovery(
                    self, entropy
                ); // add the health to the adventurer
                self.add_health(health_amount);
                return (TreasureDiscovery::Health(()), health_amount);
            },
        }
    }

// TODO: implement this function
    fn attack(ref self: Adventurer, entropy: u128) -> Adventurer {
        // get criminal from adventurer
        // combat::calculate_damage_to_criminal(adventurer, criminal, adventurer_entropy, game_entropy);
        // if criminal is dead, add xp to adventurer and items
        // if criminal is not dead, calculate damage to adventurer and return adventurer
        //      the adventurer will have updated health for both adventurer and criminal
        return self;
    }

    // TODO: implement this function
    fn flee(ref self: Adventurer, entropy: u128) -> Adventurer {
        // combat::attempt_flee(adventurer, adventurer_entropy, game_entropy;
        // if successful, return adventurer with adventurer.criminal_health = 0;
        // if not successful, process criminal counter_attack and return adventurer
        return self;
    }


    // luck 
    fn get_luck(self: Adventurer) -> u8 {
        // get greatness of aventurers equipped necklace
        let necklace_greatness = ImplLoot::get_greatness_level(self.neck.xp);
        // get greatness of aventurers equipped ring
        let ring_greatness = ImplLoot::get_greatness_level(self.neck.xp);

        // luck is combined greatness of equipped jewlery
        return necklace_greatness + ring_greatness;
    }

    // in_battle returns true if the adventurer is in battle
    // @param self: Adventurer the adventurer to check if in battle
    // @return bool true if the adventurer is in battle, false otherwise
    fn in_battle(self: Adventurer) -> bool {
        if self.criminal_health > 0 {
            true
        } else {
            false
        }
    }

    // deduct_criminal_health deducts the criminal health from the adventurer
    // if the criminal health is less than 0, it sets the criminal health to 0
    // @param self: Adventurer the adventurer to deduct the criminal health from
    // @param value: u16 the amount to deduct from the criminal health
    // @return Adventurer the adventurer with the criminal health deducted
    fn deduct_criminal_health(ref self: Adventurer, amount: u16) -> Adventurer {
        let mut new_criminal_health = self.criminal_health - amount;

        // check if killed
        if new_criminal_health < 0 {
            self.criminal_health = 0;
        } else {
            self.criminal_health = new_criminal_health;
        }
        self
    }
    fn add_criminal(ref self: Adventurer, value: u16) -> Adventurer {
        self.criminal_health = value;
        self
    }
    fn add_health(ref self: Adventurer, value: u16) -> Adventurer {
        // TODO: overflow check
        self.health = self.health + value;

        self
    }

    fn increase_gold(ref self: Adventurer, value: u16) -> Adventurer {
        // TODO: overflow check
        self.gold = self.gold + value;

        self
    }
    fn deduct_health(ref self: Adventurer, value: u16) -> Adventurer {
        // if amount to deduct is greater than or equal to health of adventurer
        if value >= self.health {
            // set adventurer health to zero
            self.health = 0;
        } else {
            // otherwise deduct amount
            self.health -= value;
        }

        // return adventurer
        self
    }
    fn increase_adventurer_xp(ref self: Adventurer, value: u16) -> Adventurer {
        let previous_level = self.get_level();
        self.xp = self.xp + value;
        let new_level = self.get_level();
        // add the difference between previous level and new level to stat upgrades
        self.stat_upgrade_available += (new_level - previous_level);
        self
    }
    fn add_strength(ref self: Adventurer, value: u8) -> Adventurer {
        self.strength = self.strength + value;
        self
    }
    fn add_dexterity(ref self: Adventurer, value: u8) -> Adventurer {
        self.dexterity = self.dexterity + value;
        self
    }
    fn add_vitality(ref self: Adventurer, value: u8) -> Adventurer {
        self.vitality = self.vitality + value;
        self
    }
    fn add_intelligence(ref self: Adventurer, value: u8) -> Adventurer {
        self.intelligence = self.intelligence + value;
        self
    }
    fn add_wisdom(ref self: Adventurer, value: u8) -> Adventurer {
        self.wisdom = self.wisdom + value;
        self
    }
    fn add_charisma(ref self: Adventurer, value: u8) -> Adventurer {
        self.charisma = self.charisma + value;
        self
    }
    fn add_item(ref self: Adventurer, value: LootStatistics) -> Adventurer {
        let slot = ImplLoot::get_slot(value.id);
        match slot {
            Slot::Weapon(()) => self.add_weapon(value),
            Slot::Chest(()) => self.add_chest(value),
            Slot::Head(()) => self.add_head(value),
            Slot::Waist(()) => self.add_waist(value),
            Slot::Foot(()) => self.add_foot(value),
            Slot::Hand(()) => self.add_hand(value),
            Slot::Neck(()) => self.add_neck(value),
            Slot::Ring(()) => self.add_ring(value),
        }
        self
    }
    fn add_weapon(ref self: Adventurer, value: LootStatistics) -> Adventurer {
        self.weapon = value;
        self
    }
    fn add_chest(ref self: Adventurer, value: LootStatistics) -> Adventurer {
        self.chest = value;
        self
    }
    fn add_head(ref self: Adventurer, value: LootStatistics) -> Adventurer {
        self.head = value;
        self
    }
    fn add_waist(ref self: Adventurer, value: LootStatistics) -> Adventurer {
        self.waist = value;
        self
    }
    fn add_foot(ref self: Adventurer, value: LootStatistics) -> Adventurer {
        self.foot = value;
        self
    }
    fn add_hand(ref self: Adventurer, value: LootStatistics) -> Adventurer {
        self.hand = value;
        self
    }
    fn add_neck(ref self: Adventurer, value: LootStatistics) -> Adventurer {
        self.neck = value;
        self
    }
    fn add_ring(ref self: Adventurer, value: LootStatistics) -> Adventurer {
        self.ring = value;
        self
    }

    // increase_item_xp is used to increase the xp of all items that are equipped
    // this is used when the adventurer kills a criminal or takes damage from an obstacle
    // @param self: Adventurer - the adventurer calling the function
    // @param value: u16 - the amount of xp to increase the items by
    // @return Adventurer - the adventurer with the updated items
    fn increase_item_xp(ref self: Adventurer, value: u16) -> Adventurer {
        let xp_increase = value * ITEM_XP_MULTIPLIER;
        if self.weapon.id > 0 {
            self.weapon.xp = self.weapon.xp + value;
        }
        if self.chest.id > 0 {
            self.chest.xp = self.chest.xp + value;
        }
        if self.head.id > 0 {
            self.head.xp = self.head.xp + value;
        }
        if self.waist.id > 0 {
            self.waist.xp = self.waist.xp + value;
        }
        if self.foot.id > 0 {
            self.foot.xp = self.foot.xp + value;
        }
        if self.hand.id > 0 {
            self.hand.xp = self.hand.xp + value;
        }
        if self.neck.id > 0 {
            self.neck.xp = self.neck.xp + value;
        }
        if self.ring.id > 0 {
            self.ring.xp = self.ring.xp + value;
        }
        self
    }

    // create a new adventurer from a starting item and a block number
    // the block number is used to set the last action
    // the starting item is used to set the starting weapon
    // @param starting_item: the id of the starting item
    // @param block_number: the block number of the block that the adventurer was created in
    // @return Adventurer: the new adventurer
    fn new(starting_item: u8, block_number: u64) -> Adventurer {
        let last_action: u16 = (block_number % 512).try_into().unwrap();

        return Adventurer {
            last_action: last_action,
            health: STARTING_HEALTH,
            xp: 0,
            strength: 0,
            dexterity: 0,
            vitality: 0,
            intelligence: 0,
            wisdom: 0,
            charisma: 0,
            gold: STARTING_GOLD,
            weapon: LootStatistics {
                id: starting_item, xp: 0, metadata: 1, 
                }, chest: LootStatistics {
                id: 0, xp: 0, metadata: 0, 
                }, head: LootStatistics {
                id: 0, xp: 0, metadata: 0, 
                }, waist: LootStatistics {
                id: 0, xp: 0, metadata: 0, 
                }, foot: LootStatistics {
                id: 0, xp: 0, metadata: 0, 
                }, hand: LootStatistics {
                id: 0, xp: 0, metadata: 0, 
                }, neck: LootStatistics {
                id: 0, xp: 0, metadata: 0, 
                }, ring: LootStatistics {
                id: 0, xp: 0, metadata: 0, 
            }, criminal_health: CriminalSettings::STARTER_CRIMINAL_HEALTH, stat_upgrade_available: 0,
        };
    }


    // get_battle_fixed_entropy provides an entropy source that is fixed during battle
    // it intentionally does not use game_entropy as that could change during battle and this
    // entropy allows us to simulate a persistent battle without having to store criminal
    // details on-chain.
    fn get_battle_fixed_entropy(self: Adventurer, adventurer_entropy: u64) -> u128 {
        return U16IntoU128::into(self.xp) + U64IntoU128::into(adventurer_entropy);
    }

    fn get_random_armor_slot(entropy: u128) -> Slot {
        // get a number between 0 and 5 inclusive
        let slot = entropy % 6;

        // return slot for each outcome
        if (slot == 1) {
            return Slot::Chest(());
        } else if (slot == 2) {
            return Slot::Head(());
        } else if (slot == 3) {
            return Slot::Waist(());
        } else if (slot == 4) {
            return Slot::Foot(());
        } else if (slot == 5) {
            return Slot::Hand(());
        }

        // fall through to Hand
        return Slot::Hand(());
    }

    // pack the adventurer into a single felt252
    // this is used to store the adventurer in the contract
    // @return the packed adventurer
    fn pack(self: Adventurer) -> felt252 {
        let mut packed = 0;
        packed = packed | pack_value(self.last_action.into(), pow::TWO_POW_242);
        packed = packed | pack_value(self.health.into(), pow::TWO_POW_233);
        packed = packed | pack_value(self.xp.into(), pow::TWO_POW_220);
        packed = packed | pack_value(self.strength.into(), pow::TWO_POW_215);
        packed = packed | pack_value(self.dexterity.into(), pow::TWO_POW_210);
        packed = packed | pack_value(self.vitality.into(), pow::TWO_POW_205);
        packed = packed | pack_value(self.intelligence.into(), pow::TWO_POW_200);
        packed = packed | pack_value(self.wisdom.into(), pow::TWO_POW_195);
        packed = packed | pack_value(self.charisma.into(), pow::TWO_POW_190);
        packed = packed | pack_value(self.gold.into(), pow::TWO_POW_181);

        packed = packed | pack_value(self.weapon.id.into(), pow::TWO_POW_174);
        packed = packed | pack_value(self.weapon.xp.into(), pow::TWO_POW_165);
        packed = packed | pack_value(self.weapon.metadata.into(), pow::TWO_POW_160);

        packed = packed | pack_value(self.chest.id.into(), pow::TWO_POW_153);
        packed = packed | pack_value(self.chest.xp.into(), pow::TWO_POW_144);
        packed = packed | pack_value(self.chest.metadata.into(), pow::TWO_POW_139);

        packed = packed | pack_value(self.head.id.into(), pow::TWO_POW_132);
        packed = packed | pack_value(self.head.xp.into(), pow::TWO_POW_123);
        packed = packed | pack_value(self.head.metadata.into(), pow::TWO_POW_118);

        packed = packed | pack_value(self.waist.id.into(), pow::TWO_POW_111);
        packed = packed | pack_value(self.waist.xp.into(), pow::TWO_POW_102);
        packed = packed | pack_value(self.waist.metadata.into(), pow::TWO_POW_97);

        packed = packed | pack_value(self.foot.id.into(), pow::TWO_POW_90);
        packed = packed | pack_value(self.foot.xp.into(), pow::TWO_POW_81);
        packed = packed | pack_value(self.foot.metadata.into(), pow::TWO_POW_76);

        packed = packed | pack_value(self.hand.id.into(), pow::TWO_POW_69);
        packed = packed | pack_value(self.hand.xp.into(), pow::TWO_POW_60);
        packed = packed | pack_value(self.hand.metadata.into(), pow::TWO_POW_55);

        packed = packed | pack_value(self.neck.id.into(), pow::TWO_POW_48);
        packed = packed | pack_value(self.neck.xp.into(), pow::TWO_POW_39);
        packed = packed | pack_value(self.neck.metadata.into(), pow::TWO_POW_34);

        packed = packed | pack_value(self.ring.id.into(), pow::TWO_POW_27);
        packed = packed | pack_value(self.ring.xp.into(), pow::TWO_POW_18);
        packed = packed | pack_value(self.ring.metadata.into(), pow::TWO_POW_13);

        packed = packed | pack_value(self.criminal_health.into(), pow::TWO_POW_3);

        packed = packed | pack_value(self.stat_upgrade_available.into(), 1);

        packed.try_into().unwrap()
    }

    // unpack a felt252 into an Adventurer
    // @param packed: felt252
    // @return Adventurer
    fn unpack(packed: felt252) -> Adventurer {
        let packed = packed.into();

        Adventurer {
            last_action: U256TryIntoU16::try_into(
                unpack_value(packed, pow::TWO_POW_242, mask::MASK_9)
            )
                .unwrap(),
            health: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_233, mask::MASK_10))
                .unwrap(),
            xp: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_220, mask::MASK_13))
                .unwrap(),
            strength: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_215, mask::MASK_5))
                .unwrap(),
            dexterity: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_210, mask::MASK_5))
                .unwrap(),
            vitality: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_205, mask::MASK_5))
                .unwrap(),
            intelligence: U256TryIntoU8::try_into(
                unpack_value(packed, pow::TWO_POW_200, mask::MASK_5)
            )
                .unwrap(),
            wisdom: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_195, mask::MASK_5))
                .unwrap(),
            charisma: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_190, mask::MASK_5))
                .unwrap(),
            gold: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_181, mask::MASK_9))
                .unwrap(),
            weapon: LootStatistics {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_174, mask::MASK_7))
                    .unwrap(),
                xp: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_165, mask::MASK_9))
                    .unwrap(),
                metadata: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_160, mask::MASK_5)
                )
                    .unwrap(),
                }, chest: LootStatistics {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_153, mask::MASK_7))
                    .unwrap(),
                xp: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_144, mask::MASK_9))
                    .unwrap(),
                metadata: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_139, mask::MASK_5)
                )
                    .unwrap(),
                }, head: LootStatistics {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_132, mask::MASK_7))
                    .unwrap(),
                xp: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_123, mask::MASK_9))
                    .unwrap(),
                metadata: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_118, mask::MASK_5)
                )
                    .unwrap(),
                }, waist: LootStatistics {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_111, mask::MASK_7))
                    .unwrap(),
                xp: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_102, mask::MASK_9))
                    .unwrap(),
                metadata: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_97, mask::MASK_5)
                )
                    .unwrap(),
                }, foot: LootStatistics {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_90, mask::MASK_7))
                    .unwrap(),
                xp: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_81, mask::MASK_9))
                    .unwrap(),
                metadata: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_76, mask::MASK_5)
                )
                    .unwrap(),
                }, hand: LootStatistics {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_69, mask::MASK_7))
                    .unwrap(),
                xp: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_60, mask::MASK_9))
                    .unwrap(),
                metadata: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_55, mask::MASK_5)
                )
                    .unwrap(),
                }, neck: LootStatistics {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_48, mask::MASK_7))
                    .unwrap(),
                xp: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_39, mask::MASK_9))
                    .unwrap(),
                metadata: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_34, mask::MASK_5)
                )
                    .unwrap(),
                }, ring: LootStatistics {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_27, mask::MASK_7))
                    .unwrap(),
                xp: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_18, mask::MASK_9))
                    .unwrap(),
                metadata: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_13, mask::MASK_5)
                )
                    .unwrap(),
            },
            criminal_health: U256TryIntoU16::try_into(
                unpack_value(packed, pow::TWO_POW_3, mask::MASK_10)
            )
                .unwrap(),
            stat_upgrade_available: U256TryIntoU8::try_into(unpack_value(packed, 1, mask::MASK_3))
                .unwrap(),
        }
    }
}
