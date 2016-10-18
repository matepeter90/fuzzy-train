class Scarlet extends AIInfo {
  function GetAuthor()      { return "Max"; }
  function GetName()        { return "Scarlet"; }
  function GetDescription() { return ""; }
  function GetVersion()     { return 1; }
  function GetDate()        { return "2016-10-18"; }
  function CreateInstance() { return "Scarlet"; }
  function GetShortName()   { return "SCRL"; }
  function GetAPIVersion()  { return "1.0"; }
}

RegisterAI(Scarlet());
