import("pathfinder.road", "RoadPathFinder", 4);

class Scarlet extends AIController {
    function Start();
}

function Scarlet::Start() {
    if (!AICompany.SetName("Scarlet")) {
        local i = 2;
        while (!AICompany.SetName("Scarlet #" + i)) {
        i = i + 1;
        }
    }

    local towns = BuildRichRoad();
    local cargo = FindRichCargo();
    local depot_tile;
    //local truck_station = !AICargo.HasCargoClass(cargo, AICargo.CC_PASSENGERS);
    //AILog.Info(cargo);
    //AILog.Info(truck_station);
    AILog.Info("Connected towns: " + towns);
    local src_tile = BuildSrcRoadStation(towns[0], cargo);
    local dst_tile = BuildDstRoadStation(towns[1], cargo);
    if (src_tile != null) {
        local depot_tile = BuildRoadDepotNear(src_tile);
        if (depot_tile != null) {
            AILog.Info("Building vehicle");
            AIVehicle.BuildVehicle(depot_tile, GetBestRoadVehicle(cargo));
        }
    }
    while(true) {
        AILog.Info("I am a very new AI with a ticker called MyNewAI and I am at tick " + this.GetTick());
        this.Sleep(50);
    }
}

function Scarlet::BuildSrcRoadStation (townid, cargo) {
    local rad = AIStation.GetCoverageRadius(AIStation.STATION_TRUCK_STOP);
    local tilelist = GetTilesAroundTown(townid, 1, 1);
    tilelist.Valuate(AITile.IsBuildable);
    tilelist.KeepValue(1);
    tilelist.Valuate(AITile.GetCargoProduction, cargo, 1, 1, rad);
    tilelist.KeepAboveValue(0);
    local success = false;
    local station_tile = null;
    AILog.Info("Trying to build station");
    foreach (tile, value in tilelist) {
        if (AITile.GetSlope(tile) == AITile.SLOPE_FLAT) {
            local neighbours = GetNeighbourRoad(tile);
            foreach (neighbour, value in neighbours) {
                success = AIRoad.BuildRoadStation(tile, neighbour,
                                           AIRoad.ROADVEHTYPE_TRUCK,
                                           AIStation.STATION_NEW);
                if(success) {
                  AIRoad.BuildRoad(tile, neighbour);
                  station_tile = tile;
                  break;
                  }
            }
        }
        if (success) break;
    }
    if (success) {
        AILog.Info("Successfuly built station");
    } else {
        AILog.Info("Cannot build station");
    }
    return station_tile;
}

function Scarlet::GetNeighbourRoad(tile) {
    local neighbours = GetTilesAround(tile, 1);
    neighbours.Valuate(AIRoad.IsRoadTile);
    neighbours.KeepValue(1);
    return neighbours;
}

function Scarlet::GetBestRoadVehicle(cargo) {
    local engines = AIEngineList(AIVehicle.VT_ROAD);
    engines.Valuate(AIEngine.IsBuildable);
    engines.KeepValue(1);
    AILog.Info(engines);
    engines.Valuate(AIEngine.CanRefitCargo,cargo);
    engines.KeepValue(1);
    engines.Valuate(GetEngineScore);
    engines.Sort(AIAbstractList.SORT_BY_VALUE, false);
    return engines.Begin();
}

function Scarlet::GetEngineScore(engine){
    local score = AIEngine.GetCapacity(engine) * AIEngine.GetPower(engine) * AIEngine.GetMaxSpeed(engine) * AIEngine.GetReliability(engine);
    score = score / (AIEngine.GetRunningCost(engine) * AIEngine.GetPrice(engine) * AIEngine.GetRunningCost(engine));
    return score;
}

function Scarlet::BuildDstRoadStation (townid, cargo) {
    local rad = AIStation.GetCoverageRadius(AIStation.STATION_TRUCK_STOP);
    local tilelist = GetTilesAroundTown(townid, 1, 1);
    tilelist.Valuate(AITile.IsBuildable);
    tilelist.KeepValue(1);
    tilelist.Valuate(AITile.GetCargoAcceptance, cargo, 1, 1, rad);
    tilelist.KeepAboveValue(8);
    tilelist.Sort(AIAbstractList.SORT_BY_VALUE, false);
    local success = false;
    local station_tile = null;
    AILog.Info("Trying to build station");
    foreach (tile, value in tilelist) {
        if (AITile.GetSlope(tile) == AITile.SLOPE_FLAT) {
            local neighbours = GetNeighbourRoad(tile);
            foreach (neighbour, value in neighbours) {
                success = AIRoad.BuildRoadStation(tile, neighbour,
                                           AIRoad.ROADVEHTYPE_TRUCK,
                                           AIStation.STATION_NEW);
                if(success) {
                  AIRoad.BuildRoad(tile, neighbour);
                  station_tile = tile;
                  break;
                  }
            }
        }
        if (success) break;
    }
    if (success) {
        AILog.Info("Successfuly built station");
    } else {
        AILog.Info("Cannot build station");
    }
    return station_tile;
}

function Scarlet::BuildRoadDepotNear(tile) {
    local success = false;
    local station_tile;
    for (local i = 1; i<10; i=i+1) {
        AILog.Info("Counter: " + i);
        local tilelist = GetTilesAround(tile, i);
        tilelist.Valuate(AITile.IsBuildable);
        tilelist.KeepValue(1);
        AILog.Info("Trying to build depot");
        foreach (tile, value in tilelist) {
            if (AITile.GetSlope(tile) == AITile.SLOPE_FLAT) {
                local neighbours = GetNeighbourRoad(tile);
                foreach (neighbour, value in neighbours) {
                    success = AIRoad.BuildRoadDepot(tile, neighbour);
                    if(success) {
                      AIRoad.BuildRoad(tile, neighbour);
                      station_tile = tile;
                      break;
                      }
                }
            }
            if (success) break;
        }
        if (success) {
            AILog.Info("Successfuly built depot");
            return station_tile;
        }
    }
    AILog.Info("Cannot build depot");
    return null;
}

function Scarlet::GetTilesAround(tile, radius) {
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

function Scarlet::GetTilesAroundTown(town_id, width, height) {
    local townplace = AITown.GetLocation(town_id);
    local radius = 15;
    if (AITown.GetPopulation(town_id) > 5000) radius = 30;
    local tiles = GetTilesAround(townplace, radius);
    tiles.Valuate(Scarlet.IsRectangleWithinTownInfluence, town_id, width, height);
    tiles.KeepValue(1);
    return tiles;
}

function Scarlet::IsRectangleWithinTownInfluence(tile, town_id, width, height)
{
    if (width <= 1 && height <= 1) return AITile.IsWithinTownInfluence(tile, town_id);
    local offsetX = AIMap.GetTileIndex(width - 1, 0);
    local offsetY = AIMap.GetTileIndex(0, height - 1);
    return AITile.IsWithinTownInfluence(tile, town_id) ||
                 AITile.IsWithinTownInfluence(tile + offsetX + offsetY, town_id) ||
                 AITile.IsWithinTownInfluence(tile + offsetX, town_id) ||
                 AITile.IsWithinTownInfluence(tile + offsetY, town_id);
}

function Scarlet::FindRichCargo() {
    local list = AICargoList();

    list.Valuate(AICargo.IsFreight);
    list.KeepValue(0);
    list.Valuate(AICargo.GetCargoIncome, 10, 2);
    return list.Begin();
}


function Scarlet::BuildRichRoad() {
    /* Get a list of all towns on the map. */
    local townlist = AITownList();

    /* Sort the list by population, highest population first. */
    townlist.Valuate(AITown.GetPopulation);
    townlist.Sort(AIAbstractList.SORT_BY_VALUE, false);

    /* Pick the two towns with the highest population. */
    local townid_a = townlist.Begin();
    local townid_b = townlist.Next();

    while(AITown.GetDistanceManhattanToTile(townid_a, AITown.GetLocation(townid_b)) > 70){
        AILog.Info("Dist: " + AITown.GetDistanceManhattanToTile(townid_a, AITown.GetLocation(townid_b)));
        townid_b = townlist.Next();
    }

    /* Print the names of the towns we'll try to connect. */
    AILog.Info("Going to connect " + AITown.GetName(townid_a) + " to " + AITown.GetName(townid_b));

    /* Tell OpenTTD we want to build normal road (no tram tracks). */
    AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);

    /* Create an instance of the pathfinder. */
    local pathfinder = RoadPathFinder();

    /* Set the cost for making a turn extreme high. */
    pathfinder.cost.turn = 50;

    /* Give the source and goal tiles to the pathfinder. */
    pathfinder.InitializePath([AITown.GetLocation(townid_a)], [AITown.GetLocation(townid_b)]);

    /* Try to find a path. */
    local path = false;
    while (path == false) {
      path = pathfinder.FindPath(100);
      this.Sleep(1);
      AILog.Error("Finding path...");
    }

    if (path == null) {
      /* No path was found. */
      AILog.Error("pathfinder.FindPath return null");
    }

    /* If a path was found, build a road over it. */
    while (path != null) {
      local par = path.GetParent();
      if (par != null) {
        local last_node = path.GetTile();
        if (AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) == 1 ) {
          if (!AIRoad.BuildRoad(path.GetTile(), par.GetTile())) {
            /* An error occured while building a piece of road. TODO: handle it.
             * Note that is can also be the case that the road was already build. */
          }
        } else {
          /* Build a bridge or tunnel. */
          if (!AIBridge.IsBridgeTile(path.GetTile()) && !AITunnel.IsTunnelTile(path.GetTile())) {
            /* If it was a road tile, demolish it first. Do this to work around expended roadbits. */
            if (AIRoad.IsRoadTile(path.GetTile())) AITile.DemolishTile(path.GetTile());
            if (AITunnel.GetOtherTunnelEnd(path.GetTile()) == par.GetTile()) {
              if (!AITunnel.BuildTunnel(AIVehicle.VT_ROAD, path.GetTile())) {
                /* An error occured while building a tunnel. TODO: handle it. */
              }
            } else {
              local bridge_list = AIBridgeList_Length(AIMap.DistanceManhattan(path.GetTile(), par.GetTile()) + 1);
              bridge_list.Valuate(AIBridge.GetMaxSpeed);
              bridge_list.Sort(AIAbstractList.SORT_BY_VALUE, false);
              if (!AIBridge.BuildBridge(AIVehicle.VT_ROAD, bridge_list.Begin(), path.GetTile(), par.GetTile())) {
                /* An error occured while building a bridge. TODO: handle it. */
              }
            }
          }
        }
      }
      path = par;
    }
    AILog.Info("Done");
    return [townid_a, townid_b];
}
