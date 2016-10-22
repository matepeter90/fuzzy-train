class Manager {};

function Manager::GetBestVehicle(cargo, vehicle_type) {
    local engines = AIEngineList(vehicle_type);
    engines.Valuate(AIEngine.IsBuildable);
    engines.KeepValue(1);
    AILog.Info(engines);
    engines.Valuate(AIEngine.CanRefitCargo,cargo);
    engines.KeepValue(1);
    engines.Valuate(Manager.GetEngineScore);
    engines.Sort(AIAbstractList.SORT_BY_VALUE, false);
    return engines.Begin();
}

function Manager::GetEngineScore(engine){
    //Formula is (capacity*power*speed*reliablity)/(runningCost*price)
    return (AIEngine.GetCapacity(engine) * 
            AIEngine.GetPower(engine) * 
            AIEngine.GetMaxSpeed(engine) * 
            AIEngine.GetReliability(engine)) / 
           (AIEngine.GetRunningCost(engine) * 
            AIEngine.GetPrice(engine));
}

function Manager::GetTilesAround(tile, radius) {
    local tiles = AITileList();
    local offset = null;
    local distedge = AIMap.DistanceFromEdge(tile);
    // A bit different is the town is near the edge of the map
    if (distedge < radius + 1) {
        offset = AIMap.GetTileIndex(distedge - 1, distedge - 1);
    } else {
        offset = AIMap.GetTileIndex(radius, radius);
    }
    tiles.AddRectangle(tile - offset, tile + offset);
    return tiles;
}

function Manager::GetAvailableTiles(tile, cargo, width, height, station_type, valuator_fn) {
    local radius = 15;
    local station_radius = AIStation.GetCoverageRadius(station_type);
    //Set a bigger radius for big cities
    if(AICargo.HasCargoClass(cargo, AICargo.CC_PASSENGERS)){
        local town_id = AITile.GetTownAuthority(tile);
        if(AITown.GetPopulation(town_id) > 5000) radius = 30;
    }
    //Get tiles around the given tile
    local tilelist = GetTilesAround(tile, radius)
    //Get buildable tiles
    tilelist.Valuate(AITile.IsBuildable);
    tilelist.KeepValue(1);
    //Get the best tiles which produce the most from the given cargo in descending order
    tilelist.Valuate(valuator_fn, cargo, width, height, station_radius);
    tilelist.KeepAboveValue(0);
    tilelist.Sort(AIAbstractList.SORT_BY_VALUE, false);
    return tilelist;
}
