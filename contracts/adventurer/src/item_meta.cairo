use core::serde::Serde;
use integer::{
    U128IntoFelt252, Felt252IntoU256, Felt252TryIntoU64, U256TryIntoFelt252, u256_from_felt252,
};
use traits::{TryInto, Into};
use option::OptionTrait;
use debug::PrintTrait;

use pack::pack::{pack_value, unpack_value, U256TryIntoU32, U256TryIntoU16, U256TryIntoU8};
use pack::constants::{pow, mask};

use super::adventurer::{Adventurer, IAdventurer, ImplAdventurer};
use super::bag::{Bag, BagActions, LootStatistics};

mod STORAGE {
    const INDEX_1: u8 = 1;
    const INDEX_2: u8 = 2;
    const INDEX_3: u8 = 3;
    const INDEX_4: u8 = 4;
    const INDEX_5: u8 = 5;
    const INDEX_6: u8 = 6;
    const INDEX_7: u8 = 7;
    const INDEX_8: u8 = 8;
    const INDEX_9: u8 = 9;
    const INDEX_10: u8 = 10;
}

#[derive(Drop, Copy, Serde)]
struct LootDescription {
    id: u8, // 7 bits
    name_prefix: u8, // 7 bits
    name_suffix: u8, // 5 bits
    item_suffix: u8, // 4 bit
}

// Player can have a total of 20 items. We map the items index to a slot in the metadata
#[derive(Drop, Copy, Serde)]
struct LootDescriptionStorage {
    item_1: LootDescription,
    item_2: LootDescription,
    item_3: LootDescription,
    item_4: LootDescription,
    item_5: LootDescription,
    item_6: LootDescription,
    item_7: LootDescription,
    item_8: LootDescription,
    item_9: LootDescription,
    item_10: LootDescription,
}

// LootStatistics meta only is set once and is filled up as items are found
// There is no swapping of positions
// When an item is found we find the next available slot and set it on the LootStatistics NOT in the metadata -> this saves gas
// We only set the metadata when an item is upgraded
trait ILootDescription {
    fn pack(self: LootDescriptionStorage) -> felt252;
    fn unpack(packed: felt252) -> LootDescriptionStorage;

    // takes LootStatistics and sets the metadata slot for that item
    // 1. Find highest slot from equipped and unequipped items
    // 2. Return LootStatistics with slot which is then saved on the Adventurer/Bag

    // this could be somewhere else
    // this needs to be run when an item is found/purchased
    fn get_loot_description_slot(
        adventurer: Adventurer, bag: Bag, loot_statistics: LootStatistics
    ) -> LootStatistics;

    // on contract side we check if item.metadata > 10 if it is pass in second metadata storage
    fn set_loot_description(
        ref self: LootDescriptionStorage,
        loot_statistics: LootStatistics,
        loot_description: LootDescription
    ) -> LootDescriptionStorage;

    fn get_loot_description(
        self: LootDescriptionStorage, loot_statistics: LootStatistics
    ) -> LootDescription;
}


impl ImplLootDescription of ILootDescription {
    fn get_loot_description(
        self: LootDescriptionStorage, loot_statistics: LootStatistics
    ) -> LootDescription {
        if loot_statistics.metadata == STORAGE::INDEX_1 {
            return self.item_1;
        } else if loot_statistics.metadata == STORAGE::INDEX_2 {
            return self.item_2;
        } else if loot_statistics.metadata == STORAGE::INDEX_3 {
            return self.item_3;
        } else if loot_statistics.metadata == STORAGE::INDEX_4 {
            return self.item_4;
        } else if loot_statistics.metadata == STORAGE::INDEX_5 {
            return self.item_5;
        } else if loot_statistics.metadata == STORAGE::INDEX_6 {
            return self.item_6;
        } else if loot_statistics.metadata == STORAGE::INDEX_7 {
            return self.item_7;
        } else if loot_statistics.metadata == STORAGE::INDEX_8 {
            return self.item_8;
        } else if loot_statistics.metadata == STORAGE::INDEX_9 {
            return self.item_9;
        } else {
            return self.item_10;
        }
    }

    fn pack(self: LootDescriptionStorage) -> felt252 {
        let mut packed = 0;
        packed = packed | pack_value(self.item_1.id.into(), pow::TWO_POW_244);
        packed = packed | pack_value(self.item_1.name_prefix.into(), pow::TWO_POW_238);
        packed = packed | pack_value(self.item_1.name_suffix.into(), pow::TWO_POW_233);
        packed = packed | pack_value(self.item_1.item_suffix.into(), pow::TWO_POW_229);

        packed = packed | pack_value(self.item_2.id.into(), pow::TWO_POW_222);
        packed = packed | pack_value(self.item_2.name_prefix.into(), pow::TWO_POW_215);
        packed = packed | pack_value(self.item_2.name_suffix.into(), pow::TWO_POW_210);
        packed = packed | pack_value(self.item_2.item_suffix.into(), pow::TWO_POW_206);

        packed = packed | pack_value(self.item_3.id.into(), pow::TWO_POW_199);
        packed = packed | pack_value(self.item_3.name_prefix.into(), pow::TWO_POW_192);
        packed = packed | pack_value(self.item_3.name_suffix.into(), pow::TWO_POW_187);
        packed = packed | pack_value(self.item_3.item_suffix.into(), pow::TWO_POW_183);

        packed = packed | pack_value(self.item_4.id.into(), pow::TWO_POW_176);
        packed = packed | pack_value(self.item_4.name_prefix.into(), pow::TWO_POW_169);
        packed = packed | pack_value(self.item_4.name_suffix.into(), pow::TWO_POW_164);
        packed = packed | pack_value(self.item_4.item_suffix.into(), pow::TWO_POW_160);

        packed = packed | pack_value(self.item_5.id.into(), pow::TWO_POW_153);
        packed = packed | pack_value(self.item_5.name_prefix.into(), pow::TWO_POW_146);
        packed = packed | pack_value(self.item_5.name_suffix.into(), pow::TWO_POW_141);
        packed = packed | pack_value(self.item_5.item_suffix.into(), pow::TWO_POW_137);

        packed = packed | pack_value(self.item_6.id.into(), pow::TWO_POW_130);
        packed = packed | pack_value(self.item_6.name_prefix.into(), pow::TWO_POW_123);
        packed = packed | pack_value(self.item_6.name_suffix.into(), pow::TWO_POW_118);
        packed = packed | pack_value(self.item_6.item_suffix.into(), pow::TWO_POW_114);

        packed = packed | pack_value(self.item_7.id.into(), pow::TWO_POW_107);
        packed = packed | pack_value(self.item_7.name_prefix.into(), pow::TWO_POW_100);
        packed = packed | pack_value(self.item_7.name_suffix.into(), pow::TWO_POW_95);
        packed = packed | pack_value(self.item_7.item_suffix.into(), pow::TWO_POW_91);

        packed = packed | pack_value(self.item_8.id.into(), pow::TWO_POW_84);
        packed = packed | pack_value(self.item_8.name_prefix.into(), pow::TWO_POW_77);
        packed = packed | pack_value(self.item_8.name_suffix.into(), pow::TWO_POW_72);
        packed = packed | pack_value(self.item_8.item_suffix.into(), pow::TWO_POW_68);

        packed = packed | pack_value(self.item_9.id.into(), pow::TWO_POW_61);
        packed = packed | pack_value(self.item_9.name_prefix.into(), pow::TWO_POW_54);
        packed = packed | pack_value(self.item_9.name_suffix.into(), pow::TWO_POW_49);
        packed = packed | pack_value(self.item_9.item_suffix.into(), pow::TWO_POW_45);

        packed = packed | pack_value(self.item_10.id.into(), pow::TWO_POW_38);
        packed = packed | pack_value(self.item_10.name_prefix.into(), pow::TWO_POW_31);
        packed = packed | pack_value(self.item_10.name_suffix.into(), pow::TWO_POW_26);
        packed = packed | pack_value(self.item_10.item_suffix.into(), pow::TWO_POW_22);

        packed.try_into().unwrap()
    }
    fn unpack(packed: felt252) -> LootDescriptionStorage {
        let packed = packed.into();

        LootDescriptionStorage {
            item_1: LootDescription {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_244, mask::MASK_7))
                    .unwrap(),
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_238, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_233, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_229, mask::MASK_4)
                )
                    .unwrap(),
                }, item_2: LootDescription {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_222, mask::MASK_7))
                    .unwrap(),
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_215, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_210, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_206, mask::MASK_4)
                )
                    .unwrap(),
                }, item_3: LootDescription {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_199, mask::MASK_7))
                    .unwrap(),
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_192, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_187, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_183, mask::MASK_4)
                )
                    .unwrap(),
                }, item_4: LootDescription {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_176, mask::MASK_7))
                    .unwrap(),
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_169, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_164, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_160, mask::MASK_4)
                )
                    .unwrap(),
                }, item_5: LootDescription {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_153, mask::MASK_7))
                    .unwrap(),
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_146, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_141, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_137, mask::MASK_4)
                )
                    .unwrap(),
                }, item_6: LootDescription {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_130, mask::MASK_7))
                    .unwrap(),
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_123, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_118, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_114, mask::MASK_4)
                )
                    .unwrap(),
                }, item_7: LootDescription {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_107, mask::MASK_7))
                    .unwrap(),
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_100, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_95, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_91, mask::MASK_4)
                )
                    .unwrap(),
                }, item_8: LootDescription {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_84, mask::MASK_7))
                    .unwrap(),
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_77, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_72, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_68, mask::MASK_4)
                )
                    .unwrap(),
                }, item_9: LootDescription {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_61, mask::MASK_7))
                    .unwrap(),
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_54, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_49, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_45, mask::MASK_4)
                )
                    .unwrap(),
                }, item_10: LootDescription {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_38, mask::MASK_7))
                    .unwrap(),
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_31, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_26, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_22, mask::MASK_4)
                )
                    .unwrap(),
            }
        }
    }
    fn get_loot_description_slot(
        adventurer: Adventurer, bag: Bag, loot_statistics: LootStatistics
    ) -> LootStatistics {
        // check slots

        let mut slot = 0;

        if adventurer.weapon.metadata >= slot {
            slot = adventurer.weapon.metadata;
        }
        if adventurer.head.metadata >= slot {
            slot = adventurer.head.metadata;
        }
        if adventurer.chest.metadata >= slot {
            slot = adventurer.chest.metadata;
        }
        if adventurer.hand.metadata >= slot {
            slot = adventurer.hand.metadata;
        }
        if adventurer.foot.metadata >= slot {
            slot = adventurer.foot.metadata;
        }
        if adventurer.ring.metadata >= slot {
            slot = adventurer.ring.metadata;
        }
        if adventurer.neck.metadata >= slot {
            slot = adventurer.neck.metadata;
        }
        if adventurer.waist.metadata >= slot {
            slot = adventurer.waist.metadata;
        }

        if bag.item_1.metadata >= slot {
            slot = bag.item_1.metadata;
        }
        if bag.item_2.metadata >= slot {
            slot = bag.item_2.metadata;
        }
        if bag.item_3.metadata >= slot {
            slot = bag.item_3.metadata;
        }
        if bag.item_4.metadata >= slot {
            slot = bag.item_4.metadata;
        }
        if bag.item_5.metadata >= slot {
            slot = bag.item_5.metadata;
        }
        if bag.item_6.metadata >= slot {
            slot = bag.item_6.metadata;
        }
        if bag.item_7.metadata >= slot {
            slot = bag.item_7.metadata;
        }
        if bag.item_8.metadata >= slot {
            slot = bag.item_8.metadata;
        }
        if bag.item_9.metadata >= slot {
            slot = bag.item_9.metadata;
        }
        if bag.item_10.metadata >= slot {
            slot = bag.item_10.metadata;
        }
        if bag.item_11.metadata >= slot {
            slot = bag.item_11.metadata;
        }
        if bag.item_12.metadata >= slot {
            slot = bag.item_12.metadata;
        }

        // if no slots -> return first index which is 0
        if slot == 1 {
            LootStatistics { id: loot_statistics.id, xp: loot_statistics.xp, metadata: 1 }
        } else {
            LootStatistics { id: loot_statistics.id, xp: loot_statistics.xp, metadata: slot + 1 }
        }
    }

    fn set_loot_description(
        ref self: LootDescriptionStorage,
        loot_statistics: LootStatistics,
        loot_description: LootDescription
    ) -> LootDescriptionStorage {
        // TODO:
        // @loothere: should we generate the prefix here or up in the contract?
        if loot_statistics.metadata == STORAGE::INDEX_1 {
            self.item_1 = loot_description;
            self
        } else if loot_statistics.metadata == STORAGE::INDEX_2 {
            self.item_2 = loot_description;
            self
        } else if loot_statistics.metadata == STORAGE::INDEX_3 {
            self.item_3 = loot_description;
            self
        } else if loot_statistics.metadata == STORAGE::INDEX_4 {
            self.item_4 = loot_description;
            self
        } else if loot_statistics.metadata == STORAGE::INDEX_5 {
            self.item_5 = loot_description;
            self
        } else if loot_statistics.metadata == STORAGE::INDEX_6 {
            self.item_6 = loot_description;
            self
        } else if loot_statistics.metadata == STORAGE::INDEX_7 {
            self.item_7 = loot_description;
            self
        } else if loot_statistics.metadata == STORAGE::INDEX_8 {
            self.item_8 = loot_description;
            self
        } else if loot_statistics.metadata == STORAGE::INDEX_9 {
            self.item_9 = loot_description;
            self
        } else {
            self.item_10 = loot_description;
            self
        }
        self
    }
}
