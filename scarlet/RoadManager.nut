require("Manager.nut");
import("pathfinder.road", "RoadPathFinder", 4);

class RoadManager extends Manager {
    connected_towns = null;
    connected_towns_count = 0;
    
    constructor() {
        connected_towns = {};
    }

}

function RoadManager::Contains(table, element) {
    if (table == null) return false;
    foreach (elem, value in table) {
        if(elem == element) return true;
    }
    return false;
}

function RoadManager::IsConnected(townid_a, townid_b) {
    if (!RoadManager.Contains(RoadManager.connected_towns, townid_a) || !RoadManager.Contains(RoadManager.connected_towns, townid_b))
        return false;
    return RoadManager.connected_towns.townid_a.find(townid_b) != null || RoadManager.connected_towns.townid_b.find(townid_a) != null;
}

function RoadManager::GetBestRoadVehicle(cargo) {
    return Manager.GetBestVehicle(cargo, AIVehicle.VT_ROAD);
}

function RoadManager::ConnectNewCities(passenger_cargo) {
    /* Get a list of all towns on the map. */
    local townlist = AITownList();

    /* Sort the list by population, highest population first. */
    townlist.Valuate(AITown.GetPopulation);
    townlist.Sort(AIAbstractList.SORT_BY_VALUE, false);

    /* Pick the two towns with the highest population. */
    local townid_a = townlist.Begin();
    local townid_b = townlist.Next();
    
    while(AITown.GetDistanceManhattanToTile(townid_a, AITown.GetLocation(townid_b)) > 70 && !RoadManager.IsConnected(townid_a, townid_b)) {
        AILog.Info("Dist: " + AITown.GetDistanceManhattanToTile(townid_a, AITown.GetLocation(townid_b)));
        townid_b = townlist.Next();
    }
    
    local townloc_a = AITown.GetLocation(townid_a);
    local townloc_b = AITown.GetLocation(townid_b);
    AILog.Info("Connecting " + AITown.GetName(townid_a) + " with " + AITown.GetName(townid_b));
    if(RoadManager.ConnectTiles(townloc_a, townloc_b)) {
        if(!RoadManager.Contains(RoadManager.connected_towns, townid_a)) connected_towns.townid_a <- []
        if(!RoadManager.Contains(RoadManager.connected_towns, townid_b)) connected_towns.townid_b <- []
        local src = RoadManager.BuildSourceStationNear(townloc_a, passenger_cargo);
        local dst = RoadManager.BuildDestinationStationNear(townloc_b, passenger_cargo); 
        if(src != null && dst != null) {
            local depot_tile = RoadManager.BuildRoadDepotNear(src);
            if (depot_tile != null) {
                AILog.Info("Building vehicle");
                local vehicle = AIVehicle.BuildVehicle(depot_tile, GetBestRoadVehicle(passenger_cargo));
                AIOrder.AppendOrder(vehicle, src, AIOrder.OF_NONE);
                AIOrder.AppendOrder(vehicle, dst, AIOrder.OF_NONE);
                AIVehicle.StartStopVehicle(vehicle);
                RoadManager.connected_towns.townid_a.append(townid_b);
                RoadManager.connected_towns.townid_b.append(townid_a);
                RoadManager.connected_towns_count = RoadManager.connected_towns_count + 2;
            }
        }
    }
}

function RoadManager::GetStationType(cargo) {
    return (AICargo.HasCargoClass(cargo, AICargo.CC_PASSENGERS)) ? AIStation.STATION_BUS_STOP : AIStation.STATION_TRUCK_STOP;
}

function RoadManager::BuildSourceStationNear(tile, cargo) {
    return RoadManager.BuildStationNear(tile, cargo, AITile.GetCargoProduction) 
}

function RoadManager::BuildDestinationStationNear(tile, cargo) {
    return RoadManager.BuildStationNear(tile, cargo, AITile.GetCargoAcceptance) 
}

function RoadManager::GetNeighbourRoad(tile) {
    local neighbours = Manager.GetTilesAround(tile, 1);
    neighbours.Valuate(AIRoad.IsRoadTile);
    neighbours.KeepValue(1);
    return neighbours;
}

function RoadManager::GetVehicleType(cargo) {
    return (AICargo.HasCargoClass(cargo, AICargo.CC_PASSENGERS)) ? AIRoad.ROADVEHTYPE_BUS : AIRoad.ROADVEHTYPE_TRUCK;
}

function RoadManager::BuildStationNear(tile, cargo, valuator_fn) {
    local tilelist = Manager.GetAvailableTiles(tile, cargo, 1, 1, GetStationType(cargo), valuator_fn);
    AILog.Info("Trying to build station around " + tile);
    foreach (available_tile, value in tilelist) {
        if (AITile.GetSlope(available_tile) == AITile.SLOPE_FLAT) {
            foreach (neighbour, value in GetNeighbourRoad(available_tile)) {
                if(AIRoad.BuildRoadStation(available_tile, neighbour,
                                           GetVehicleType(cargo),
                                           AIStation.STATION_NEW)) {
                    if(AIRoad.BuildRoad(available_tile, neighbour)) {
                        AILog.Info("Successfuly built station around " + tile);
                        return available_tile;
                    } else {
                        AIRoad.RemoveRoadStation(available_tile);
                    }
                }
            }
        }
    }
    AILog.Info("Cannot build station around " + tile);
    return null;
}

function RoadManager::BuildRoadDepotNear(tile) {
    for (local i = 1; i<10; i=i+1) {
        AILog.Info("Counter: " + i);
        local tilelist = Manager.GetTilesAround(tile, i);
        tilelist.Valuate(AITile.IsBuildable);
        tilelist.KeepValue(1);
        AILog.Info("Trying to build depot around " + tile);
        foreach (available_tile, value in tilelist) {
            if (AITile.GetSlope(available_tile) == AITile.SLOPE_FLAT) {
                foreach (neighbour, value in GetNeighbourRoad(available_tile)) {
                    if(AIRoad.BuildRoadDepot(available_tile, neighbour)) {
                        if(AIRoad.BuildRoad(available_tile, neighbour)) {
                            AILog.Info("Successfuly built depot around " + tile);
                            return available_tile;
                        } else {
                            AIRoad.RemoveRoadDepot(available_tile)
                        }
                    }
                }
            }
        }
    }
    AILog.Info("Cannot build depot around " + tile);
    return null;
}

function RoadManager::ConnectTiles(tile_a, tile_b) {
    /* Tell OpenTTD we want to build normal road (no tram tracks). */
    AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);

    /* Create an instance of the pathfinder. */
    local pathfinder = RoadPathFinder();

    /* Set the cost for making a turn extreme high. */
    pathfinder.cost.turn = 500;

    /* Give the source and goal tiles to the pathfinder. */
    pathfinder.InitializePath([tile_a], [tile_b]);

    /* Try to find a path. */
    local path = false;
    while (path == false) {
      path = pathfinder.FindPath(100);
      Scarlet.Sleep(1);
      AILog.Error("Finding path...");
    }

    if (path == null) {
      /* No path was found. */
      AILog.Error("pathfinder.FindPath return null");
      return false;
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
    return true;
}
