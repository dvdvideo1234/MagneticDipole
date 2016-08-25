local gsMeanName     = "Magnet Dipole"
local gsFileName     = "magnetdipole"
local gsFilePrefix   = gsFileName.."_"
local gsFileMany     = gsFileName.."s"
local gsFileClass    = "gmod_"..gsFileName
local gsClassPolDirX = gsFileClass.."_pdir_x"
local gsClassPolDirY = gsFileClass.."_pdir_y"
local gsClassPolDirZ = gsFileClass.."_pdir_z"
local gsClassPolLen  = gsFileClass.."_plen"
local gsClassPrefix  = gsFileClass.."_"
local ANG_ZERO       = Angle()
local VEC_ZERO       = Vector()
local gnMaxPoleOffs  = 10
local gnMaxCrossSiz  = 50
local gnMaxPoleLen   = 1000
local gnMaxDampVel   = 1000
local gnMaxDampRot   = 1000
local gnMaxStrength  = 100000
local gnMaxSearchRad = 100000
local gtPalette = {
  B = Color(0,0,255,255),
  R = Color(255,0,0,255),
  Y = Color(255,255,0,255),
  G = Color(0,255,0,255),
  C = Color(0,255,255,255),
  W = Color(255,255,255,255)
}

TOOL.ClientConVar =
{
  [ "searchrad" ] = "0"   ,
  [ "strength" ]  = "2000",   -- Magnet Strength
  [ "property" ]  = "0"   ,
  [ "matercfg" ]  = "0"   ,
  [ "dampvel" ]   = "100" ,
  [ "damprot" ]   = "100" ,
  [ "enghost" ]   = "1"   ,
  [ "itother" ]   = "0"   ,
  [ "crossiz" ]   = "10"  ,
  [ "length" ]    = "20"  ,
  [ "advise" ]    = "1"   , -- Advisor
  [ "model" ]     = "null", -- models/props_c17/oildrum001.mdl
  [ "offx" ]      = "0"   ,
  [ "offy" ]      = "0"   ,
  [ "offz" ]      = "0"   ,
  [ "key" ]       = "45"
}

if CLIENT then
  TOOL.Information = {
    { name = "info",  stage = 1   },
    { name = "left"         },
    { name = "right"        },
    { name = "reload"       }
  }
  language.Add( "tool."..gsFileName..".left"         , "Creates a magnet dipole")
  language.Add( "tool."..gsFileName..".right"        , "Dipole copy/Prop filter set/World filter clear")
  language.Add( "tool."..gsFileName..".reload"       , "Removes a magnet dipole")
  language.Add( "tool."..gsFileName..".name"         , gsMeanName )
  language.Add( "tool."..gsFileName..".desc"         , "Makes an entity a "..gsMeanName )
  language.Add( "tool."..gsFileName..".0"            , "Left Click apply, Right to copy, Reload to remove" )
  language.Add( "tool."..gsFileName..".strength_con" , "Dipole Strength:")
  language.Add( "tool."..gsFileName..".strength"     , "Defines how powerful is the magnet dipole")
  language.Add( "tool."..gsFileName..".dampvel_con"  , "Linear damping:")
  language.Add( "tool."..gsFileName..".dampvel"      , "Defines how much damping the dipole will have for linear velocity")
  language.Add( "tool."..gsFileName..".damprot_con"  , "Angular damping:")
  language.Add( "tool."..gsFileName..".damprot"      , "Defines how much damping the dipole will have for angular velocity")
  language.Add( "tool."..gsFileName..".length_con"   , "Pole length:")
  language.Add( "tool."..gsFileName..".length"       , "Defines how far apart the poles are fron the center")
  language.Add( "tool."..gsFileName..".searchrad_con", "Search radius:")
  language.Add( "tool."..gsFileName..".searchrad"    , "Defines the radius of the sphere the dipole will search in")
  language.Add( "tool."..gsFileName..".offx_con"     , "OBB Offset X:")
  language.Add( "tool."..gsFileName..".offx"         , "The local magnitude pole offset X")
  language.Add( "tool."..gsFileName..".offy_con"     , "OBB Offset Y:")
  language.Add( "tool."..gsFileName..".offy"         , "The local magnitude pole offset Y")
  language.Add( "tool."..gsFileName..".offz_con"     , "OBB Offset Z:")
  language.Add( "tool."..gsFileName..".offz"         , "The local magnitude pole offset Y")
  language.Add( "tool."..gsFileName..".crossiz_con"  , "Crosshair size:")
  language.Add( "tool."..gsFileName..".crossiz"      , "Defines hod big the crosshair is on aiming anywhere")
  language.Add( "tool."..gsFileName..".key_con"      , "Key to start on:")
  language.Add( "tool."..gsFileName..".key"          , "Defines the numpad key to be use for starting the dipole")
  language.Add( "tool."..gsFileName..".matercfg_con" , "Enable material config")
  language.Add( "tool."..gsFileName..".matercfg"     , "Enables material configoration of the serface to be used on iteraction")
  language.Add( "tool."..gsFileName..".itother_con"  , "Enable para/dia magnetism")
  language.Add( "tool."..gsFileName..".itother"      , "Enables magnet dipole iteraction with normal props")
  language.Add( "tool."..gsFileName..".enghost_con"  , "Enable ghosting")
  language.Add( "tool."..gsFileName..".enghost"      , "Enables drawing the ghosted dipole to assist you where spawned")
  language.Add( "tool."..gsFileName..".advise_con"   , "Enable N/S Advisor")
  language.Add( "tool."..gsFileName..".advise"       , "Enables the composition of lines and cirlcles drawing the dipole state")
  language.Add( "tool."..gsFileName..".property_con" , "Enable baloon properties")
  language.Add( "tool."..gsFileName..".property"     , "Enables drawing a baloon containing addotional dipole information")
  language.Add( "Undone."..gsFileName       , "Undone "..gsMeanName )
  language.Add( "Cleanup."..gsFileName      , gsMeanName )
  language.Add( "Cleaned."..gsFileName      , "Cleaned up "..gsMeanName )
end

TOOL.Category   = "Construction"                -- Name of the category
TOOL.Name       = "#tool."..gsFileName..".name" -- Name to display
TOOL.Command    = nil                           -- Command on click (nil for default)
TOOL.ConfigName = ""                            -- Config file name (nil for default)

if SERVER then
  cleanup.Register(gsFileMany)

  CreateConVar("sbox_max"..gsFileMany, 10, FCVAR_NOTIFY)

  local function onMagnetDipoleRemove(self, KeyOn)
    numpad.Remove(KeyOn);
  end

  function MakeMagnetDipole(ply      , pos      , ang      , key      , model    ,
                            strength , dampvel  , damprot  , itother  , searchrad,
                            length   , offx     , offy     , offz     , advise   , property)
    if (not ply:CheckLimit(gsFileMany)) then
      return false
    end
    if(model ~= "null") then -- <-- You never know .. ^_^
      -- Actually model handling is done by:
      -- \gmod_magnetdipole\shared.lua -> MagnetDipoleModel(sModel)
      local seMag = ents.Create(gsFileClass)
      if(seMag and seMag:IsValid()) then
        seMag:SetCollisionGroup(COLLISION_GROUP_NONE);
        seMag:SetSolid(SOLID_VPHYSICS);
        seMag:SetMoveType(MOVETYPE_VPHYSICS)
        seMag:SetModel(model)
        seMag:SetNotSolid( false );
        seMag:SetPos(pos)
        seMag:SetAngles(ang)
        seMag:Setup(strength , dampvel  , damprot  , itother  ,
                    searchrad, length   , offx     , offy     ,
                    offz     , advise   , property)
        seMag:Spawn()
        seMag:SetPlayer(ply)
        seMag:Activate()
        seMag:SetColor(gtPalette.W)
        seMag:SetRenderMode(RENDERMODE_TRANSALPHA)
        seMag:CallOnRemove(gsClassPrefix.."numpad_cleanup", onMagnetDipoleRemove,
        numpad.OnDown(ply, key, gsClassPrefix.."toggle_state", seMag ) )
        seMag:DrawShadow( true )
        seMag:PhysWake()
        local phPhys = seMag:GetPhysicsObject()
          if(phPhys and phPhys:IsValid()) then
            local Table = { NumKey = key,    Model     = model,
                            Advise = advise, Property  = property }
            table.Merge(seMag:GetTable(),Table)
            return seMag
          end
        seMag:Remove()
        print("MAGNETDIPOLE: MakeMagnetDipole: Dipole physics object invalid!")
        return false
      end
      return false
    end
    return false
  end

  duplicator.RegisterEntityClass( gsFileClass, MakeMagnetDipole,
                                  "Pos"     , "Ang"     , "NumKey"  , "Model"  , "Strength",
                                  "DampVel" , "DampRot" , "EnIOther", "SearRad", "Length"  ,
                                  "PoleDirX", "PoleDirY", "PoleDirZ", "Advise" , "Property")
end

local function PrintNotify(plClient,sText,sNotifType)
  if(not plClient) then return end
  if(SERVER) then
    plClient:SendLua("GAMEMODE:AddNotify(\""..sText.."\", NOTIFY_"..sNotifType..", 6)")
    plClient:SendLua("surface.PlaySound(\"ambient/water/drip"..math.random(1, 4)..".wav\")")
  end
end

function TOOL:GetMeterialConfig()
  return ((self:GetClientNumber("matercfg") ~= 0) or false)
end

function TOOL:GetModel()
  return (MagnetDipoleModel(string.lower(self:GetClientInfo("model"))) or "null")
end

function TOOL:GetStrength()
  return (math.Clamp(self:GetClientNumber("strength") or 1,1,gnMaxStrength))
end

function TOOL:GetSearchRadius()
  return (math.Clamp(self:GetClientNumber("searchrad") or 0,0,gnMaxSearchRad))
end

function TOOL:GetKey()
  return (self:GetClientNumber("key") or 45)
end

function TOOL:GetEnAdvisor()
  return ((self:GetClientNumber("advise") ~= 0) or false)
end

function TOOL:GetEnProperty()
  return ((self:GetClientNumber("property") ~= 0) or false)
end

function TOOL:GetDampVel()
  return (math.Clamp(self:GetClientNumber("dampvel") or 0,0,gnMaxDampVel))
end

function TOOL:GetDampRot()
  return (math.Clamp(self:GetClientNumber("damprot") or 0,0,gnMaxDampRot))
end

function TOOL:GetIteractOthers()
  return ((self:GetClientNumber("itother") ~= 0) or false)
end

function TOOL:GetEnGhost()
  return ((self:GetClientNumber("enghost") ~= 0) or false)
end

function TOOL:GetPoleLength(oTrace, nDiv)
  local Len = (math.Clamp(self:GetClientNumber("length") or 0,0,gnMaxPoleLen))
  if(Len == 0) then
    local trEnt = oTrace.Entity
    if(trEnt and trEnt:IsValid()) then
      local Div = tonumber(nDiv) or 0
      if(Div > 0) then
        local Centre = trEnt:LocalToWorld(trEnt:OBBCenter())
        Len = (oTrace.HitPos - Centre):Length()
        Len = Len - (Len / Div)
      end
    end
  end
  return Len
end

function TOOL:GetOffsets(oTrace, nLength)
  local Offx = (math.Clamp(self:GetClientNumber("offx") or 0,-gnMaxPoleOffs,gnMaxPoleOffs))
  local Offy = (math.Clamp(self:GetClientNumber("offy") or 0,-gnMaxPoleOffs,gnMaxPoleOffs))
  local Offz = (math.Clamp(self:GetClientNumber("offz") or 0,-gnMaxPoleOffs,gnMaxPoleOffs))
  if(Offx == 0 and Offy == 0 and Offz == 0) then
    local trEnt = oTrace.Entity
    if(trEnt and trEnt:IsValid()) then
      local Length = tonumber(nLength) or 0
      if(Length <= 0) then return 0, 0, 0 end
      local Off = Vector()
      Off:Set(trEnt:GetPos())
      Off:Add(Length * oTrace.HitNormal)
      Off:Set(trEnt:WorldToLocal(Off))
      Offx, Offy, Offz = Off[1], Off[2], Off[3]
    end
  end
  return Offx, Offy, Offz
end

function TOOL:GetCrossairSize()
  return (math.Clamp(self:GetClientNumber("crossiz") or 0, 0,gnMaxCrossSiz))
end

function TOOL:LeftClick(tr)
  if(CLIENT) then return true end
  if(not tr) then return false end
  local trEnt     = GetTracePhys(tr)
  if(not (tr.HitWorld or trEnt)) then return false end
  local length    = self:GetPoleLength(tr,5)
  if(length <= 0) then return false end
  local offx, offy, offz = self:GetOffsets(tr,length)
  if(offx == 0 and offy == 0 and offz == 0) then return false end
  local key       = self:GetKey()
  local ply       = self:GetOwner()
  local model     = self:GetModel()
  local advise    = self:GetEnAdvisor()
  local dampvel   = self:GetDampVel()
  local damprot   = self:GetDampRot()
  local itother   = self:GetIteractOthers()
  local property  = self:GetEnProperty()
  local strength  = self:GetStrength()
  local searchrad = self:GetSearchRadius()
  local matercfg  = self:GetMeterialConfig()
  if(tr.HitWorld and
     model ~= "null") then
    -- print("Spawn it on World...")
    local Ang   = ply:GetAimVector():Angle()
          Ang.P = 0
          Ang.R = 0
    local seMag = MakeMagnetDipole(ply      ,
                                   tr.HitPos,
                                   Ang      ,
                                   key      ,
                                   model    ,
                                   strength ,
                                   dampvel  ,
                                   damprot  ,
                                   itother  ,
                                   searchrad,
                                   length   ,
                                   offx     ,
                                   offy     ,
                                   offz     ,
                                   advise   ,
                                   property , matercfg)
    if(seMag) then
      local vBBMin = seMag:OBBMins()
      local vPos = Vector(tr.HitPos[1],
                          tr.HitPos[2],
                          tr.HitPos[3] - (tr.HitNormal[3] * vBBMin[3]))
      local vBBCenterOff = vPos - seMag:GetMagnetCenter()
            vBBCenterOff[3] = 0
      vPos:Add(vBBCenterOff)
      seMag:SetPos(vPos)
      ply:ConCommand(gsFilePrefix.."model " ..model.." \n")
      ply:AddCount("magnetdipoles", seMag)
      undo.Create("Magnet Dipole")
        undo.AddEntity(seMag)
        undo.SetPlayer(ply)
      undo.Finish()
      return true
    end
    return false
  elseif(trEnt) then
    local trPos    = trEnt:GetPos()
    local trAng    = trEnt:GetAngles()
    local trModel  = trEnt:GetModel()
    local trClass  = trEnt:GetClass()
    if(trClass == gsFileClass) then
      -- print("Updating with ignoring the Client's model")
      -- not to displace the visual and collision models
      trEnt:Setup(strength ,
                  dampvel  ,
                  damprot  ,
                  itother  ,
                  searchrad,
                  length   ,
                  offx     ,
                  offy     ,
                  offz     ,
                  advise   ,
                  property , matercfg)
      return true
    elseif(trClass == "prop_physics" and
          (model == "null" or model == trModel)
    ) then
      -- print("Creating when it is a prop")
      -- and the "tr" is enabled for a magnet
      -- or it is the first one created
      local seMag = MakeMagnetDipole(ply      ,
                                     trPos    ,
                                     trAng    ,
                                     key      ,
                                     trModel  ,
                                     strength ,
                                     dampvel  ,
                                     damprot  ,
                                     itother  ,
                                     searchrad,
                                     length   ,
                                     offx     ,
                                     offy     ,
                                     offz     ,
                                     advise   ,
                                     property , matercfg)
      if(seMag) then
        trEnt:Remove()
        ply:ConCommand(gsFilePrefix.."model " ..trModel.." \n")
        ply:AddCount(gsFileMany, seMag)
        undo.Create(gsMeanName)
          undo.AddEntity(seMag)
          undo.SetPlayer(ply)
        undo.Finish()
        return true
      end
      return false
    end
    return false
  end
  return false
end

function TOOL:RightClick(tr)
  if CLIENT  then return true end
  if(not tr) then return false end
  local trEnt = GetTracePhys(tr)
  if(not (tr.HitWorld or trEnt)) then return false end
  local ply = self:GetOwner()
  if(trEnt) then
    local trModel = trEnt:GetModel()
    local trClass = trEnt:GetClass()
    if(trClass == gsFileClass) then
      local poledir  = trEnt:GetPoleDirectionLocal()
      local itother  = trEnt:GetIteractOthers()
      local matercfg = trEnt:GetMeterialConfig()
      ply:ConCommand(gsFilePrefix.."model     "..trModel.." \n")
      ply:ConCommand(gsFilePrefix.."strength  "..trEnt:GetStrength().." \n")
      ply:ConCommand(gsFilePrefix.."dampvel   "..trEnt:GetDampVel().." \n")
      ply:ConCommand(gsFilePrefix.."damprot   "..trEnt:GetDampRot().." \n")
      ply:ConCommand(gsFilePrefix.."itother   "..((itother and 1) or 0).." \n")
      ply:ConCommand(gsFilePrefix.."matercfg  "..((matercfg and 1) or 0).." \n")
      ply:ConCommand(gsFilePrefix.."searchrad "..trEnt:GetSearchRadius().." \n")
      ply:ConCommand(gsFilePrefix.."length    "..trEnt:GetPoleLength().." \n")
      ply:ConCommand(gsFilePrefix.."offx      "..poledir[1].." \n")
      ply:ConCommand(gsFilePrefix.."offy      "..poledir[2].." \n")
      ply:ConCommand(gsFilePrefix.."offz      "..poledir[3].." \n")
      PrintNotify(ply,"Settings copied !","GENERIC")
      return true
    elseif(trClass == "prop_physics") then
      ply:ConCommand(gsFilePrefix.."model "..trModel.." \n")
      PrintNotify(ply,"Model: "..GetModelFileName(trModel).." !","GENERIC")
      return true
    end
    return false
  elseif(tr.HitWorld) then
    ply:ConCommand(gsFilePrefix.."model null \n")
    PrintNotify(ply,"Model cleared !","GENERIC")
    return true
  end
  return false
end

function TOOL:Reload(tr)
  if CLIENT  then return true end
  if(not tr) then return false end
  local trEnt = GetTracePhys(tr)
  if(not trEnt) then return false end
  if(trEnt:GetClass() == gsFileClass) then trEnt:Remove(); return true end
  return false
end

function TOOL:UpdateGhost(oeGhost, plPly)
  if(not (oeGhost and oeGhost:IsValid())) then return end
  local tr    = plPly:GetEyeTrace()
  local trEnt = GetTracePhys(tr)
  if(trEnt) then
    oeGhost:SetNoDraw(true)
  else
    local vBBMin = oeGhost:OBBMins()
    local ghAng = plPly:GetAimVector():Angle()
          ghAng.P = 0
          ghAng.R = 0
    oeGhost:SetAngles(ghAng)
    oeGhost:SetPos(tr.HitPos - tr.HitNormal * vBBMin[3])
    oeGhost:SetNoDraw(false)
  end
end

function TOOL:Think()
  if (SERVER and !game.SinglePlayer()) then return end
  if (CLIENT and  game.SinglePlayer()) then return end
  local model = self:GetModel()
  local engho = self:GetEnGhost()
  if (not ( model ~= "null" and
            self.GhostEntity and
            self.GhostEntity:IsValid() and
            self.GhostEntity:GetModel() == model )
      and engho
  ) then
    self:MakeGhostEntity(model, VEC_ZERO, ANG_ZERO)
  end
  if(self.GhostEntity and self.GhostEntity:IsValid()) then
    if(engho) then
      self:UpdateGhost(self.GhostEntity, self:GetOwner())
    else
      self.GhostEntity:Remove()
    end
  else
    self.GhostEntity = nil
  end
end

function SetModelColor(trModel,sModel)
  if(sModel) then
    if(trModel) then
      if(trModel == sModel) then
        surface.SetDrawColor(gtPalette.G)
      else
        if(sModel == "null") then
          surface.SetDrawColor(gtPalette.C)
        else
          surface.SetDrawColor(gtPalette.Y)
        end
      end
    else
      if(sModel == "null") then
        surface.SetDrawColor(gtPalette.C)
      else
        surface.SetDrawColor(gtPalette.G)
      end
    end
  else
    surface.SetDrawColor(gtPalette.C)
  end
end

function TOOL:DrawHUD()
  if(SERVER) then return end
  local ply = self:GetOwner()
  if(not ply) then return end
  local tr  = ply:GetEyeTrace()
  if(not tr) then return end
  local trEnt   = tr.Entity
  local model   = self:GetModel()
  local crossiz = self:GetCrossairSize()
  local crsx    = crossiz / math.sqrt(2)
  local x       = surface.ScreenWidth()  / 2
  local y       = surface.ScreenHeight() / 2
  if(trEnt and trEnt:IsValid()) then
    local trModel = trEnt:GetModel()
    local trClass = trEnt:GetClass()
    if(trClass == gsFileClass) then
      local adv = trEnt:GetNWBool(gsFileClass.."_adv_en")
      if(not adv) then return end
      local trPDir = Vector(trEnt:GetNWFloat(gsClassPolDirX),
                            trEnt:GetNWFloat(gsClassPolDirY),
                            trEnt:GetNWFloat(gsClassPolDirZ))
      local trLen  = trEnt:GetNWFloat(gsClassPolLen)
      local trAng  = trEnt:GetAngles()
      local trwCenter = trEnt:GetMagnetCenter()
      local Pos = Vector()
            Pos:Set(trPDir)
            Pos:Mul(trLen)
            Pos:Rotate(trAng)
            Pos:Add(trwCenter)
      local S = Pos:ToScreen()
      local SLen = (tr.HitPos - Pos):Length() / trLen
            Pos:Set(trPDir)
            Pos:Rotate(trAng)
            Pos:Mul(-trLen)
            Pos:Add(trwCenter)
      local N = Pos:ToScreen()
      local NLen = (tr.HitPos - Pos):Length() / trLen
      local RadScale = math.Clamp(750 / (tr.HitPos - ply:GetPos()):Length(),1,100)
      surface.SetDrawColor(gtPalette.Y)
      surface.DrawLine(S.x, S.y, N.x, N.y)
      surface.DrawCircle(S.x, S.y, RadScale, gtPalette.B)
      surface.DrawCircle(N.x, N.y, RadScale, gtPalette.R)
      surface.DrawCircle(x,y,crossiz,Color(SLen*255,0,NLen*255,255))
      SetModelColor(trModel,model)
    elseif(trClass == "prop_physics") then
      surface.DrawCircle(x,y,crossiz,gtPalette.G)
      SetModelColor(trModel,model)
    else
      surface.DrawCircle(x,y,crossiz,gtPalette.C)
      SetModelColor(trModel,model)
    end
  elseif(tr.HitWorld) then
    surface.DrawCircle(x,y,crossiz,gtPalette.Y)
    SetModelColor(trModel,model)
  else
    surface.DrawCircle(x,y,crossiz,gtPalette.C)
    SetModelColor(trModel,model)
  end
  surface.DrawLine(x - crsx, y - crsx,  x + crsx, y + crsx)
  surface.DrawLine(x + crsx, y - crsx,  x - crsx, y + crsx)
end

local ConVarList = TOOL:BuildConVarList()
function TOOL.BuildCPanel( CPanel )
  -- https://wiki.garrysmod.com/page/Category:DForm
  local pItem -- pItem is the current panel created
          CPanel:SetName(language.GetPhrase("tool."..gsToolNameL..".name"))
  pItem = CPanel:Help   (language.GetPhrase("tool."..gsToolNameL..".desc"))

  pItem = CPanel:AddControl( "ComboBox",{
            MenuButton = 1,
            Folder     = gsToolNameL,
            Options    = {["#Default"] = ConVarList},
            CVars      = table.GetKeys(ConVarList)})

  pItem = CPanel:NumSlider (language.GetPhrase("tool."..gsFileName..".strength_con"), gsFilePrefix.."strength", 1, gnMaxStrength, 3)
           pItem:SetTooltip(language.GetPhrase("tool."..gsFileName..".strength"))
  pItem = CPanel:NumSlider (language.GetPhrase("tool."..gsFileName..".dampvel_con"), gsFilePrefix.."dampvel", 1, gnMaxDampVel, 3)
           pItem:SetTooltip(language.GetPhrase("tool."..gsFileName..".dampvel"))
  pItem = CPanel:NumSlider (language.GetPhrase("tool."..gsFileName..".damprot_con"), gsFilePrefix.."damprot", 1, gnMaxDampRot, 3)
           pItem:SetTooltip(language.GetPhrase("tool."..gsFileName..".damprot"))
  pItem = CPanel:NumSlider (language.GetPhrase("tool."..gsFileName..".length_con"), gsFilePrefix.."length", 0, gnMaxPoleLen, 3)
           pItem:SetTooltip(language.GetPhrase("tool."..gsFileName..".length"))
  pItem = CPanel:NumSlider (language.GetPhrase("tool."..gsFileName..".searchrad_con"), gsFilePrefix.."searchrad", 0, gnMaxSearchRad, 3)
           pItem:SetTooltip(language.GetPhrase("tool."..gsFileName..".searchrad"))
  pItem = CPanel:NumSlider (language.GetPhrase("tool."..gsFileName..".offx_con"), gsFilePrefix.."offx", -gnMaxPoleOffs, gnMaxPoleOffs, 3)
           pItem:SetTooltip(language.GetPhrase("tool."..gsFileName..".offx"))
  pItem = CPanel:NumSlider (language.GetPhrase("tool."..gsFileName..".offy_con"), gsFilePrefix.."offy", -gnMaxPoleOffs, gnMaxPoleOffs, 3)
           pItem:SetTooltip(language.GetPhrase("tool."..gsFileName..".offy"))
  pItem = CPanel:NumSlider (language.GetPhrase("tool."..gsFileName..".offz_con"), gsFilePrefix.."offz", -gnMaxPoleOffs, gnMaxPoleOffs, 3)
           pItem:SetTooltip(language.GetPhrase("tool."..gsFileName..".offz"))
  pItem = CPanel:NumSlider (language.GetPhrase("tool."..gsFileName..".crossiz_con"), gsFilePrefix.."crossiz", 0, gnMaxCrossSiz, 3)
           pItem:SetTooltip(language.GetPhrase("tool."..gsFileName..".crossiz"))
  CPanel:AddControl( "Numpad", {
            Label      = language.GetPhrase("tool."..gsFileName..".key_con"),
            Command    = gsFilePrefix.."key",
            ButtonSize = 10 }):SetTooltip(language.GetPhrase("tool."..gsFileName..".key"))
  pItem = CPanel:CheckBox  (language.GetPhrase("tool."..gsFileName..".matercfg_con"), gsFilePrefix.."matercfg")
           pItem:SetTooltip(language.GetPhrase("tool."..gsFileName..".matercfg"))
  pItem = CPanel:CheckBox  (language.GetPhrase("tool."..gsFileName..".itother_con"), gsFilePrefix.."itother")
           pItem:SetTooltip(language.GetPhrase("tool."..gsFileName..".itother"))
  pItem = CPanel:CheckBox  (language.GetPhrase("tool."..gsFileName..".enghost_con"), gsFilePrefix.."enghost")
           pItem:SetTooltip(language.GetPhrase("tool."..gsFileName..".enghost"))
  pItem = CPanel:CheckBox  (language.GetPhrase("tool."..gsFileName..".advise_con"), gsFilePrefix.."advise")
           pItem:SetTooltip(language.GetPhrase("tool."..gsFileName..".advise"))
  pItem = CPanel:CheckBox  (language.GetPhrase("tool."..gsFileName..".property_con"), gsFilePrefix.."property")
           pItem:SetTooltip(language.GetPhrase("tool."..gsFileName..".property"))
end
