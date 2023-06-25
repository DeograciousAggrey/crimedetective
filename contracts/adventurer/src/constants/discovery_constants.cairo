mod DiscoveryEnums {
    #[derive(Copy, Drop, PartialEq)]
    enum ExploreResult {
        Criminal: (),
        Obstacle: (),
        Treasure: (),
    }

    #[derive(Copy, Drop, PartialEq)]
    enum TreasureDiscovery {
        Gold: (),
        XP: (),
        Health: (),
    }
}