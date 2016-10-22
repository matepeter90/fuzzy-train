require("RoadManager.nut");

class Scarlet extends AIController {
    function Start();
}

function Scarlet::SetCompanyName(name) {
    if (!AICompany.SetName(name)) {
        local i = 2;
        while (!AICompany.SetName(name + " #" + i)) {
        i = i + 1;
        }
    }
}


function Scarlet::Start() {
    SetCompanyName("Scarlet")
    local passenger_cargo = GetPassengerCargoID();
    local rm = RoadManager()
    while(true) {
        if(passenger_cargo != -1 && rm.connected_towns_count < 5) {
            rm.ConnectNewCities(passenger_cargo);    
        }
        AILog.Info("I am a very new AI with a ticker called MyNewAI and I am at tick " + this.GetTick());
        this.Sleep(50);
    }
}



//function Scarlet::GetTilesAroundTown(town_id, width, height) {
//    local townplace = AITown.GetLocation(town_id);
//    local radius = 15;
//    if (AITown.GetPopulation(town_id) > 5000) radius = 30;
//    local tiles = GetTilesAround(townplace, radius);
//    tiles.Valuate(Scarlet.IsRectangleWithinTownInfluence, town_id, width, height);
//    tiles.KeepValue(1);
//    return tiles;
//}
//
//function Scarlet::IsRectangleWithinTownInfluence(tile, town_id, width, height) {
//    if (width <= 1 && height <= 1) return AITile.IsWithinTownInfluence(tile, town_id);
//    local offsetX = AIMap.GetTileIndex(width - 1, 0);
//    local offsetY = AIMap.GetTileIndex(0, height - 1);
//    return AITile.IsWithinTownInfluence(tile, town_id) ||
//                 AITile.IsWithinTownInfluence(tile + offsetX + offsetY, town_id) ||
//                 AITile.IsWithinTownInfluence(tile + offsetX, town_id) ||
//                 AITile.IsWithinTownInfluence(tile + offsetY, town_id);
//}
//
//function Scarlet::FindRichCargo() {
//    local list = AICargoList();
//    list.Valuate(AICargo.IsFreight);
//    list.KeepValue(0);
//    list.Valuate(AICargo.GetCargoIncome, 10, 2);
//    return list.Begin();
//}

function Scarlet::GetPassengerCargoID() {
    local cargoList = AICargoList();
    cargoList.Valuate(AICargo.HasCargoClass, AICargo.CC_PASSENGERS);
    cargoList.KeepValue(1);
    if (cargoList.Count() == 0) {
        AILog.Error("Your game doesn't have any passengers cargo");
        return -1;
    }
    return cargoList.Begin();
}

