mod CriminalSettings {

    // Controls the health of the first criminal in the game
    const STARTER_CRIMINAL_HEALTH: u16 = 5;

    // Controls the level of the first criminal in the game
    const STARTER_CRIMINAL_LEVEL: u16 = 1;

    // Controls the minimum damage from criminals
    const MINIMUM_DAMAGE: u16 = 1;

    // Controls the strength boost for criminals
    const STRENGTH_BONUS: u16 = 0;

    // Controls minimum health for criminals
    const MINIMUM_HEALTH: u8 = 5;

    // Controls the amount of gold received for slaying a criminal
    // relative to XP. The current setting of 2 will result
    // in adventurers receiving a base gold reward of 1/2 XP when
    // slaying criminals. Set this value to 1 to increase gold reward
    // increase it to lower gold reward. Note, unlike XP, the amount
    // of gold received after slaying a criminal includes a random bonus
    // between 0%-100%
    const GOLD_REWARD_DIVISOR: u16 = 2;

    // controls the size of the base gold reward bonus. The higher
    // this number, the smaller the base gold bonus will be. With the
    // setting at 5, the gold reward bonus base is 20% of the earned
    // xp
    const GOLD_REWARD_BONUS_DIVISOR: u16 = 4;

    // controls the range of the gold bonus when slaying criminals
    // the higher this number the wider the range of the gold bonus
    const GOLD_REWARD_BONUS_MAX_MULTPLIER: u128 = 4;

    // control the minimum base gold reward. Note the bonus
    // will be applied to this so even when the minimun is used
    // the actual amount may be slightly higher based on bonus
    const GOLD_REWARD_BASE_MINIMUM: u16 = 4;

    const XP_REWARD_MINIMUM: u16 = 4;
}

mod CriminalId {
    // ====================================================================================================
    // Magical Criminals
    // ====================================================================================================

    // Magical T1s
    const Burglar: u8 = 1; // A man who practices witchcraft
    const Carjacker: u8 =
        2; // A mythical being from Hindu mythology known to disrupt sacrifices, desecrate graves, and cause harm
    const Street_dealer: u8 = 3; // A type of reanimated corpse in Chinese legends and folklore
    const Cyberstalker: u8 =
        4; // A fox with the ability to shape-shift into a human form in Japanese folklore
    const Tax_evader: u8 =
        5; // A legendary reptile reputed to be the king of serpents and said to have the power to cause death with a single glance

    // Magical T2s
    const Hacker: u8 =
        6; // A female creature who turns those who look at her into stone in Greek mythology
    const Ponzi_schemer: u8 =
        7; // A trickster god known as the spirit of all knowledge of stories, usually taking the shape of a spider
    const Corporate_spy: u8 =
        8; // A type of undead creature, often a spellcaster who has become undead to pursue power eternal
    const Document_forger: u8 = 9; // A monstrous fire-breathing hybrid creature from Greek mythology
    const Money_launderer: u8 =
        10; // A mythical man-eating creature or evil spirit from the folklore of the First Nations Algonquin tribes 

    // Magical T3s
    const Organ_trafficker: u8 =
        11; // A multi-headed dog that guards the gates of the Underworld to prevent the dead from leaving in Greek mythology
    const Cult_member: u8 =
        12; // A human with the ability to shapeshift into a wolf, either purposely or after being placed under a curse
    const Political_assassin: u8 =
        13; // A female spirit in Irish folklore who heralds the death of a family member by wailing
    const Slave_trader: u8 = 14; // Undead creatures from Norse mythology
    const Streat_dealer: u8 =
        15; // A creature from folklore that subsists by feeding on the vital essence (usually in the form of blood) of the living

    // Magical T4s
    const Weapon_smuggler: u8 =
        16; // A monstrous creature from European folklore, first attested in stories from the Middle Ages
    const Ransomware_attacker: u8 =
        17; // A demon or monster in Arabian mythology, associated with graveyards and consuming human flesh
    const Art_thief: u8 =
        18; // A mythical creature of British folklore, considered to be particularly concentrated in the high moorland areas around Devon and Cornwall
    const Financial_fraudster: u8 =
        19; // A broad term referring to a number of preternatural legendary creatures
    const Identity_thief: u8 = 20; // Amphibious yōkai demons found in traditional Japanese folklore

    // Magical T5s
    const Extortionist: u8 =
        21; // A type of mythical being or legendary creature in European folklore, particularly Celtic, Slavic, German, English, and French folklore
    const Cybercriminal: u8 =
        22; // A diminutive supernatural being in Irish folklore, classed as a type of solitary fairy
    const Drug_dealer: u8 = 23; // A shape-changing aquatic spirit of Scottish legend
    const Professional_burglar: u8 = 24; // An undead creature or a ghost in Scottish dialect
    const Terrorist: u8 =
        25; // A diminutive spirit in Renaissance magic and alchemy, first introduced by Paracelsus in the 16th century
    // ====================================================================================================

    // ====================================================================================================
    // Hunter Criminals
    // ====================================================================================================

    // Hunter T1s
    const Panhandler: u8 =
        26; // Mythical creature with the body of a lion and the head and wings of an eagle
    const Trespasser: u8 =
        27; // A Persian legendary creature similar to the sphinx but with a scorpion's tail
    const Illegal_gambler: u8 =
        28; // Mythical bird that lived for five or six centuries in the Arabian desert, after this time burning itself on a funeral pyre and rising from the ashes with renewed youth to live through another cycle.
    const Counterfeiter: u8 =
        29; // Large, powerful reptiles with wings and the ability to breathe fire, known for their immense strength, ferocity, and avarice for treasure
    const Credit_card_thief: u8 =
        30; // A creature with the head of a bull and the body of a man in Greek mythology

    // Hunter T2s
    const Graffiti_vandal: u8 = 31; // A death spirit with a bird body and a woman's face in Greek mythology
    const IP_infringer: u8 = 32; // A skilled weaver in Greek mythology who was turned into a spider
    const Fare_evader: u8 = 33; // A Japanese chimera with a monkey's face, tiger's body, and snake tail
    const Shoplifter: u8 =
        34; // A person, in Navajo culture, who can turn into, inhabit, or disguise themselves as an animal
    const Pickpocket: u8 =
        35; // A creature from American folklore that is known for drinking the blood of livestock

    // Hunter T3s
    const Wildlife_trader: u8 = 36; // A creature from Asian mythology, humans who can change into tigers
    const Identity_impersonator: u8 =
        37; // A creature with a dragon's head and wings, a reptilian body, and a tail often ending in a diamond or arrow shape
    const Prostitute: u8 = 38; // An enormous legendary bird of prey from Middle Eastern mythology
    const Drug_manufacturer: u8 =
        39; // A mythical hooved chimerical creature known in various East Asian cultures
    const Ponzi_accomplice: u8 = 40; // A divine winged stallion in Greek mythology

    // Hunter T4s
    const Contraband_smuggler: u8 =
        41; // A creature with the front half of an eagle and the back half of a horse from medieval literature
    const Money_mule: u8 = 42; // A monstrous wolf in Norse mythology
    const Assault: u8 = 43; // An animal known for its power and agility in various cultures
    const Pharma_smuggler: u8 =
        44; // An ancient Egyptian demon with a body that was part lion, hippopotamus, and crocodile
    const Cult_leader: u8 = 45; // A larger and more powerful version of a wolf from fantasy literature

    // Hunter T5s
    const Wildlife_trafficker: u8 =
        46; // large, powerful mammals known for their stocky build, thick fur, and strong claws. Recognized for their remarkable strength.
    const Plane_hijacker: u8 =
        47; // Carnivorous mammals known for their social nature and hunting prowess, characterized by their sharp teeth, keen senses, and powerful bodies.
    const Serial_arsonist: u8 =
        48; // Arachnid characterized by their segmented body, a pair of pincers, and a long, curved tail ending in a venomous stinger. They are known for their venomous nature and are often recognized by their menacing appearance.
    const Bomb_maker: u8 =
        49; // Arachnid characterized by eight legs, ability to produce silk, and their predatory nature. Known for their diverse sizes, shapes, and colors.
    const KKK: u8 =
        50; // Small rodents known for their ability to adapt to various environments, characterized by their small size, sharp teeth, and long tails.
    // ====================================================================================================

    // ====================================================================================================
    // Brute Criminals
    // ====================================================================================================

    // Brute T1s
    const Child_abductor: u8 = 51; // One-eyed giants from Greek mythology
    const Assassin: u8 = 52; // An animated anthropomorphic being in Jewish folklore
    const Hitman: u8 = 53; // A race of deities from Greek mythology
    const Drug_lord: u8 = 54; // The Abominable Snowman from Himalayan folklore
    const Serial_bomber: u8 = 55; // A vicious monster in Greek mythology that lived at Nemea

    // Brute T2s
    const Tagger: u8 = 56; // A kind of yōkai, demon, or troll in Japanese folklore
    const Public_urinator: u8 = 57; // Large, hideous monster beings featured in mythology and fairy tales
    const Phone_snatcher: u8 = 58; // Unstoppable beings from various mythologies and popular culture
    const Joyrider: u8 =
        59; // A hairy, upright-walking, ape-like creature that dwells in the wilderness
    const Loiterer: u8 =
        60; // Corrupted humanoid creatures with foul appearances, known for their cruelty and viciousness, serving as minions of dark lords, skilled in combat, and dwelling in gloomy places.

    // Brute T3s
    const Public_nuisance: u8 = 61; // A criminal from the Book of Job, possibly a dinosaur or an elephant
    const Stock_market_manipulator: u8 =
        62; // A race of beings in J. R. R. Tolkien's fantasy world Middle-earth who resemble trees
    const Copyright_infringer: u8 = 63; // Humanoid beings of incredible strength and size
    const Insurance_fraudster: u8 = 64; // A giant sea monster from Scandinavian folklore
    const Smuggler_of_exotic_animals: u8 = 65; // A sea monster referenced in the Hebrew Bible

    // Brute T4s
    const Cyber_blackmailer: u8 =
        66; // An exceptionally large and powerful entity from various mythologies and popular culture
    const International_diamond_thief: u8 =
        67; // The offspring of the "sons of God" and the "daughters of men" in the Bible
    const Heist_mastermind: u8 = 68; // A legendary mythical criminal from French folklore
    const Serial_child_molester: u8 =
        69; // Legendary warrior known for their intense and uncontrollable battle frenzy, displaying heightened strength, endurance, and a disregard for personal safety. They are often depicted as fierce warriors who enter a trance-like state in combat, exhibiting extraordinary ferocity and unleashing devastating attacks upon their enemies.
    const Biochemical_terrorist: u8 = 70; // A powerful fictional monster in J. R. R. Tolkien's Middle-earth

    // Brute T5s
    const Genocide_perpetrator: u8 = 71; // A two-headed giant in English folklore
    const Cult_leader1: u8 =
        72; // A type of entity contrasted with gods and other figures, such as dwarfs and elves, in Norse mythology
    const Human_organs_trafficker: u8 = 73; // A serpentine water monster with many heads in Greek and Roman mythology
    const Bicycle_thief: u8 =
        74; // A mythical creature portrayed in Classical times with the head and tail of a bull and the body of a man
    const Litterer: u8 = 75; // A creature from Norse mythology and Scandinavian folklore


    // If you add criminals, make sure to update MAX_ID below
    // making this u128 as it's commonly used to select a random criminal based
    // on entropy variables which are u128 based
    const MAX_ID: u128 = 75;
}