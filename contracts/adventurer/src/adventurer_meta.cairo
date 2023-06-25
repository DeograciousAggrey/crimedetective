use core::serde::Serde;
use integer::{
    U128IntoFelt252, Felt252IntoU256, Felt252TryIntoU64, U256TryIntoFelt252, u256_from_felt252,
    U256TryIntoU32, U256TryIntoU128, U256TryIntoU16, U256TryIntoU8, U256TryIntoU64
};
use traits::{TryInto, Into};
use option::OptionTrait;
use debug::PrintTrait;

use pack::pack::{pack_value, unpack_value};
use pack::constants::{pow, mask};

#[derive(Drop, Copy, Serde)]
struct AdventurerMetadata {
    name: u32,
    home_realm: u8,
    race: u8,
    order: u8,
    entropy: u64,
}

trait IAdventurerMetadata {
    fn pack(self: AdventurerMetadata) -> felt252;
    fn unpack(packed: felt252) -> AdventurerMetadata;
}

impl ImplAdventurerMetadata of IAdventurerMetadata {
    fn pack(self: AdventurerMetadata) -> felt252 {
        let mut packed = 0;
        packed = packed | pack_value(self.name.into(), pow::TWO_POW_219);
        packed = packed | pack_value(self.home_realm.into(), pow::TWO_POW_212);
        packed = packed | pack_value(self.race.into(), pow::TWO_POW_204);
        packed = packed | pack_value(self.order.into(), pow::TWO_POW_196);

        packed = packed | pack_value(self.entropy.into(), pow::TWO_POW_132);

        packed.try_into().unwrap()
    }
    fn unpack(packed: felt252) -> AdventurerMetadata {
        let packed = packed.into();
        AdventurerMetadata {
            name: U256TryIntoU32::try_into(unpack_value(packed, pow::TWO_POW_219, mask::MASK_32))
                .unwrap(),
            home_realm: U256TryIntoU8::try_into(
                unpack_value(packed, pow::TWO_POW_212, mask::MASK_8)
            )
                .unwrap(),
            race: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_204, mask::MASK_8))
                .unwrap(),
            order: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_196, mask::MASK_8))
                .unwrap(),
            entropy: U256TryIntoU64::try_into(unpack_value(packed, pow::TWO_POW_132, mask::MASK_64))
                .unwrap()
        }
    }
}
