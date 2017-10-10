local gsMeanName     = "Magnet Dipole"
local gsFileName     = "magnetdipole"
local gsFilePrefix   = gsFileName.."_"
local gsFileMany     = gsFileName.."s"
local gsFileClass    = "gmod_magnetdipole"
local gsNullModel    = "null"
local VEC_ZERO, ANG_ZERO = Vector(), Angle()
local gnNormSquared  = math.sqrt(2)
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
  [ "permeabil" ] = "23"  ,      -- Environment permeability ( def. Air )
  [ "searchrad" ] = "0"   ,      -- Magnet search radius ( def. Non-searching )
  [ "poledepth" ] = "10"  ,      -- Default pole depth is 10% of the length
  [ "strength" ]  = "2000",      -- Magnet strength to repel and attract in [Am]
  [ "property" ]  = "0"   ,      -- Enable debug balloon properties
  [ "dampvel" ]   = "100" ,      -- Linear velocity damping
  [ "damprot" ]   = "100" ,      -- Angular velocity damping
  [ "enghost" ]   = "1"   ,      -- Check to enable ghosting
  [ "itother" ]   = "0"   ,      -- Used for enable (para/dia)magnetism
  [ "crossiz" ]   = "10"  ,      -- Size of the aim cross
  [ "length" ]    = "20"  ,      -- Distance from the center to one of the poles
  [ "advise" ]    = "1"   ,      -- Advisor for tool trace state and pole location
  [ "toggle" ]    = "1"   ,      -- Toggle numpad enabled key ( def. true )
  [ "model" ]     = gsNullModel, -- models/props_c17/oildrum001.mdl
  [ "offx" ]      = "0"   ,      -- Offset direction local X
  [ "offy" ]      = "0"   ,      -- Offset direction local Y
  [ "offz" ]      = "0"   ,      -- Offset direction local Z
  [ "key" ]       = "45"         -- Power on key ascii
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
  language.Add( "tool."..gsFileName..".name"         , "Magnet Dipole" )
  language.Add( "tool."..gsFileName..".desc"         , "Creates magnet dipole" )
  language.Add( "tool."..gsFileName..".0"            , "Left Click apply, Right to copy, Reload to remove" )
  language.Add( "tool."..gsFileName..".permeabil_con", "Permeability:")
  language.Add( "tool."..gsFileName..".permeabil_def", "<Select permeability>")
  language.Add( "tool."..gsFileName..".permeabil"    , "Defines the environment magnetic permeability.\nChose option to affect all magnets")
  language.Add( "tool."..gsFileName..".poledepth_con", "Pole depth:")
  language.Add( "tool."..gsFileName..".poledepth"    , "Defines how deep within the entity the poles are situated")
  language.Add( "tool."..gsFileName..".strength_con" , "Dipole Strength:")
  language.Add( "tool."..gsFileName..".strength"     , "Defines how powerful is the magnet dipole")
  language.Add( "tool."..gsFileName..".dampvel_con"  , "Linear damping:")
  language.Add( "tool."..gsFileName..".dampvel"      , "Defines how much damping the dipole will have for linear velocity")
  language.Add( "tool."..gsFileName..".damprot_con"  , "Angular damping:")
  language.Add( "tool."..gsFileName..".damprot"      , "Defines how much damping the dipole will have for angular velocity")
  language.Add( "tool."..gsFileName..".length_con"   , "Pole length:")
  language.Add( "tool."..gsFileName..".length"       , "Defines how far apart the poles are from the center")
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
  language.Add( "tool."..gsFileName..".toggle_con"   , "Toggle mode enabled")
  language.Add( "tool."..gsFileName..".toggle"       , "If the toggle mode is disabled you have to hold the on key")
  language.Add( "tool."..gsFileName..".key_con"      , "Key to start on:")
  language.Add( "tool."..gsFileName..".key"          , "Defines the numpad key to be use for starting the dipole")
  language.Add( "tool."..gsFileName..".itother_con"  , "Enable para/dia magnetism")
  language.Add( "tool."..gsFileName..".itother"      , "Enables magnet dipole interaction with normal props")
  language.Add( "tool."..gsFileName..".enghost_con"  , "Enable ghosting")
  language.Add( "tool."..gsFileName..".enghost"      , "Enables drawing the ghosted dipole to assist you where spawned")
  language.Add( "tool."..gsFileName..".advise_con"   , "Enable N/S Advisor")
  language.Add( "tool."..gsFileName..".advise"       , "Enables the composition of lines and circles drawing the dipole state")
  language.Add( "tool."..gsFileName..".property_con" , "Enable balloon properties")
  language.Add( "tool."..gsFileName..".property"     , "Enables drawing a balloon containing additional dipole information")
  language.Add( "Undone."..gsFileName                , "Undone magnetic dipole" )
  language.Add( "Cleanup."..gsFileName               , "Cleaned up magnet dipole" )
  language.Add( "Cleaned."..gsFileName               , "Cleaned up all magnet dipoles" )
end

TOOL.Category   = "Construction"                -- Name of the category
TOOL.Name       = "#tool."..gsFileName..".name" -- Name to display
TOOL.Command    = nil                           -- Command on click (nil for default)
TOOL.ConfigName = ""                            -- Configuration file name (nil for default)

if SERVER then
  cleanup.Register(gsFileMany)

  CreateConVar("sbox_max"..gsFileMany, 10, FCVAR_NOTIFY)

  local function onMagnetDipoleRemove(self, KeyOn)
    numpad.Remove(KeyOn);
  end

  function MakeMagnetDipole(ply      , pos      , ang      , key      , model    ,
                            strength , dampvel  , damprot  , itother  , searchrad,
                            length   , voff     , advise   , property , toggle )
    if (not ply:CheckLimit(gsFileMany)) then
      return false
    end
    if(model ~= gsNullModel) then -- <-- You never know .. ^_^
      -- Actually model handling is done by:
      -- /gmod_magnetdipole/shared.lua -> magdipoleConvertModel(sModel)
      local seMag = ents.Create(gsFileClass)
      if(seMag and seMag:IsValid()) then
        seMag:SetCollisionGroup(COLLISION_GROUP_NONE);
        seMag:SetSolid(SOLID_VPHYSICS);
        seMag:SetMoveType(MOVETYPE_VPHYSICS)
        seMag:SetModel(model)
        seMag:SetNotSolid( false );
        seMag:SetPos(pos)
        seMag:SetAngles(ang)
        seMag:Spawn()
        seMag:Setup(strength , dampvel  , damprot  , itother  , searchrad,
                    length   , voff     , advise   , property , toggle)
        seMag:SetPlayer(ply)
        seMag:Activate()
        seMag:SetColor(gtPalette.W)
        seMag:SetRenderMode(RENDERMODE_TRANSALPHA)
        seMag:CallOnRemove(gsFileClass.."_numpad_cleanup", onMagnetDipoleRemove,
          numpad.OnDown(ply, key, gsFileClass.."_toggle_state_on" , seMag),
          numpad.OnUp  (ply, key, gsFileClass.."_toggle_state_off", seMag))
        seMag:DrawShadow( true )
        seMag:PhysWake()
        local phPhys = seMag:GetPhysicsObject()
        if(phPhys and phPhys:IsValid()) then
          local Table = { mnNumKey = key,    msModel     = model,
                          mbAdvise = advise, mbProperty  = property }
          table.Merge(seMag:GetTable(),Table)
          return seMag
        end; seMag:Remove()
        ErrorNoHalt("MAGNETDIPOLE: MakeMagnetDipole: Physics object invalid!")
        return false
      end
      return false
    end
    return false
  end

  duplicator.RegisterEntityClass( gsFileClass, MakeMagnetDipole,
                                  "Pos"       , "Ang"       , "mnNumKey"  , "msModel"   ,
                                  "mnStrength", "mnDampVel" , "mnDampRot" , "mbEnIOther",
                                  "mnSearRad" , "mnLength"  , "mvDirLocal", "mbAdvise"  ,
                                  "mbProperty", "mbToggle")
end

local function PrintNotify(oPly,sText,sNotif)
  if(not oPly) then return end
  if(SERVER) then
    oPly:SendLua("GAMEMODE:AddNotify(\""..tostring(sText).."\", NOTIFY_"..tostring(sNotif)..", 6)")
    oPly:SendLua("surface.PlaySound(\"ambient/water/drip"..math.random(1, 4)..".wav\")")
  end
end

function TOOL:GetModel()
  return (magdipoleConvertModel(string.lower(self:GetClientInfo("model"))) or gsNullModel)
end

function TOOL:GetStrength()
  return (math.Clamp(self:GetClientNumber("strength") or 1,1,gnMaxStrength))
end

function TOOL:GetPoleDepth()
  return (math.Clamp(self:GetClientNumber("poledepth") or 0,0,90))
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

function TOOL:GetNumToggled()
  return ((self:GetClientNumber("toggle") ~= 0) or false)
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

function TOOL:GetInteractOthers()
  return ((self:GetClientNumber("itother") ~= 0) or false)
end

function TOOL:GetEnGhost()
  return ((self:GetClientNumber("enghost") ~= 0) or false)
end

function TOOL:GetPoleLength(oTrace, nDepth)
  local Len = (math.Clamp(self:GetClientNumber("length") or 0,0,gnMaxPoleLen))
  if(Len == 0) then
    local trEnt = oTrace.Entity
    if(trEnt and trEnt:IsValid()) then
      local Depth = tonumber(nDepth) or 0 -- Prercent 0 to 50
      if(Depth >= 0) then
        local Centre = trEnt:LocalToWorld(trEnt:OBBCenter())
        Len = (oTrace.HitPos - Centre):Length()
        Len = Len - ((Len * Depth) / 100)
      end
    end
  else Len = math.abs(Len) end; return Len
end

function TOOL:GetOffsets(oTrace, nLen)
  local Offx = (math.Clamp(self:GetClientNumber("offx") or 0,-gnMaxPoleOffs,gnMaxPoleOffs))
  local Offy = (math.Clamp(self:GetClientNumber("offy") or 0,-gnMaxPoleOffs,gnMaxPoleOffs))
  local Offz = (math.Clamp(self:GetClientNumber("offz") or 0,-gnMaxPoleOffs,gnMaxPoleOffs))
  if(Offx == 0 and Offy == 0 and Offz == 0) then
    local trEnt, vNorm = oTrace.Entity, oTrace.HitNormal
    if(trEnt and trEnt:IsValid()) then
      local Len = (tonumber(nLen) or 0); if(Len <= 0) then return 0, 0, 0 end
      local vOff = Vector(); vOff:Set(trEnt:GetPos()); vOff:Add(Len * vNorm)
      vOff:Set(trEnt:WorldToLocal(vOff)); return vOff
    end
  end; return Vector(Offx, Offy, Offz)
end

function TOOL:GetCrossairSize()
  return (math.Clamp(self:GetClientNumber("crossiz") or 0, 0,gnMaxCrossSiz))
end

function TOOL:LeftClick(tr)
  if(CLIENT) then return true end
  if(not tr) then return false end
  local trEnt     = magdipoleGetTracePhys(tr)
  if(not (tr.HitWorld or trEnt)) then return false end
  local poledepth = self:GetPoleDepth()
  local length    = self:GetPoleLength(tr,poledepth)
  if(length <= 0) then return false end
  local voff = self:GetOffsets(tr,length)
  if(voff:Length() < magdipoleGetEpsilonZero()) then return false end
  local key       = self:GetKey()
  local ply       = self:GetOwner()
  local model     = self:GetModel()
  local advise    = self:GetEnAdvisor()
  local toggle    = self:GetNumToggled()
  local dampvel   = self:GetDampVel()
  local damprot   = self:GetDampRot()
  local itother   = self:GetInteractOthers()
  local property  = self:GetEnProperty()
  local strength  = self:GetStrength()
  local searchrad = self:GetSearchRadius()
  if(tr.HitWorld and model ~= gsNullModel) then -- Spawn it on world...
    local Ang   = ply:GetAimVector():Angle()
          Ang.P = 0
          Ang.R = 0
    local seMag = MakeMagnetDipole(ply      , tr.HitPos, Ang      , key      , model    ,
                                   strength , dampvel  , damprot  , itother  , searchrad,
                                   length   , voff     , advise   , property , toggle )
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
      ply:AddCount(gsFileMany, seMag)
      undo.Create(gsMeanName)
        undo.SetCustomUndoText("Magnet: ["..seMag:EntIndex().."] "..string.GetFileFromFilename(model))
        undo.AddEntity(seMag)
        undo.SetPlayer(ply)
      undo.Finish()
      return true
    end
    return false
  elseif(trEnt) then
    local trPos   = trEnt:GetPos()
    local trAng   = trEnt:GetAngles()
    local trModel = trEnt:GetModel()
    local trClass = trEnt:GetClass()
    if(trClass == gsFileClass) then
      -- Updating with ignoring the Client's model
      -- not to displace the visual and collision models
      trEnt:Setup(strength , dampvel  , damprot  , itother  , searchrad,
                  length   , voff     , advise   , property , toggle)
      return true
    elseif(trClass == "prop_physics" and (model == gsNullModel or model == trModel)) then
      -- Creating when it is a prop
      -- and the "tr" is enabled for a magnet
      -- or it is the first one created
      local seMag = MakeMagnetDipole(ply      , trPos    , trAng    , key      , trModel  ,
                                     strength , dampvel  , damprot  , itother  , searchrad,
                                     length   , voff     , advise   , property , toggle)
      if(seMag) then
        trEnt:Remove()
        ply:ConCommand(gsFilePrefix.."model " ..trModel.." \n")
        ply:AddCount(gsFileMany, seMag)
        undo.Create(gsMeanName)
          undo.SetCustomUndoText("Magnet: ["..seMag:EntIndex().."] "..string.GetFileFromFilename(trModel))
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
  local trEnt = magdipoleGetTracePhys(tr)
  if(not (tr.HitWorld or trEnt)) then return false end
  local ply = self:GetOwner()
  if(trEnt) then
    local trModel = trEnt:GetModel()
    local trClass = trEnt:GetClass()
    if(trClass == gsFileClass) then
      local poledir  = trEnt:GetPoleDirectionLocal()
      local itother  = trEnt:GetInteractOthers()
      ply:ConCommand(gsFilePrefix.."model     "..trModel.." \n")
      ply:ConCommand(gsFilePrefix.."strength  "..trEnt:GetStrength().." \n")
      ply:ConCommand(gsFilePrefix.."dampvel   "..trEnt:GetDampVel().." \n")
      ply:ConCommand(gsFilePrefix.."damprot   "..trEnt:GetDampRot().." \n")
      ply:ConCommand(gsFilePrefix.."itother   "..((itother  and 1) or 0).." \n")
      ply:ConCommand(gsFilePrefix.."searchrad "..trEnt:GetSearchRadius().." \n")
      ply:ConCommand(gsFilePrefix.."length    "..trEnt:GetPoleLength().." \n")
      ply:ConCommand(gsFilePrefix.."offx      "..poledir.x.." \n")
      ply:ConCommand(gsFilePrefix.."offy      "..poledir.y.." \n")
      ply:ConCommand(gsFilePrefix.."offz      "..poledir.z.." \n")
      PrintNotify(ply,"Settings copied !","GENERIC")
      return true
    elseif(trClass == "prop_physics") then
      ply:ConCommand(gsFilePrefix.."model "..trModel.." \n")
      PrintNotify(ply,"Model: "..(trModel):GetFileFromFilename().." !","GENERIC")
      return true
    end
    return false
  elseif(tr.HitWorld) then
    ply:ConCommand(gsFilePrefix.."model "..gsNullModel.." \n")
    PrintNotify(ply,"Model cleared !","GENERIC")
    return true
  end
  return false
end

function TOOL:Reload(tr)
  if CLIENT  then return true end
  if(not tr) then return false end
  local trEnt = magdipoleGetTracePhys(tr)
  if(not trEnt) then return false end
  if(trEnt:GetClass() == gsFileClass) then trEnt:Remove(); return true end
  return false
end

function TOOL:UpdateGhost(oeGhost, plPly)
  if(not (oeGhost and oeGhost:IsValid())) then return end
  local tr    = plPly:GetEyeTrace()
  local trEnt = magdipoleGetTracePhys(tr)
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

local test = true
function TOOL:Think()
  local model = self:GetModel()
  if(util.IsValidModel(model)) then
    local ply = self:GetOwner()
    local gho = self.GhostEntity
    if(self:GetEnGhost()) then
      if (not (gho and gho:IsValid() and gho:GetModel() == model and model ~= gsNullModel)) then
        self:MakeGhostEntity(model,VEC_ZERO,ANG_ZERO); gho = self.GhostEntity
      end; self:UpdateGhost(gho, ply)
    else
      self:ReleaseGhostEntity()
      if(gho and gho:IsValid()) then gho:Remove() end
    end
  else
    self:ReleaseGhostEntity()
  end
end


function SetModelColor(trModel,sModel)
  if(sModel) then
    if(trModel) then
      if(trModel == sModel) then
        surface.SetDrawColor(gtPalette.G)
      else
        if(sModel == gsNullModel) then
          surface.SetDrawColor(gtPalette.C)
        else
          surface.SetDrawColor(gtPalette.Y)
        end
      end
    else
      if(sModel == gsNullModel) then
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
  if(not (ply and ply:IsValid())) then return end
  local tr = ply:GetEyeTrace()
  if(not tr) then return end
  local x = surface.ScreenWidth() / 2
  local y = surface.ScreenHeight() / 2
  local trEnt = tr.Entity
  local model = self:GetModel()
  local crossiz = self:GetCrossairSize()
  local crosszd = crossiz / gnNormSquared
  if(trEnt and trEnt:IsValid()) then
    local trModel = trEnt:GetModel()
    local trClass = trEnt:GetClass()
    if(trClass == gsFileClass) then
      local adv = trEnt:GetNWBool(gsFileClass.."_adv_en")
      if(not adv) then return end
      local trAng = trEnt:GetAngles()
      local trLen = trEnt:GetPoleLength()
      local trCen = trEnt:GetMagnetCenter()
      local trDir, wPos = trEnt:GetPoleDirectionLocal(), Vector()
      wPos:Set(trDir); wPos:Mul(trLen); wPos:Rotate(trAng); wPos:Add(trCen)
      local S = wPos:ToScreen()
      local SLen = (tr.HitPos - wPos):Length() / trLen
            wPos:Set(trDir); wPos:Rotate(trAng)
            wPos:Mul(-trLen); wPos:Add(trCen)
      local N = wPos:ToScreen()
      local NLen = (tr.HitPos - wPos):Length() / trLen
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
  surface.DrawLine(x - crosszd, y - crosszd,  x + crosszd, y + crosszd)
  surface.DrawLine(x + crosszd, y - crosszd,  x - crosszd, y + crosszd)
end

local gtConVarList = TOOL:BuildConVarList()
function TOOL.BuildCPanel(CPanel)
  -- https://wiki.garrysmod.com/page/Category:DForm
  local pID = GetConVar(gsFilePrefix.."permeabil"):GetInt() -- Load last used environment ID
        magdipoleSetPermeabilityID(pID)
  local pPerm, pItem = magdipoleGetPermeability(), nil
          CPanel:SetName(language.GetPhrase("tool."..gsFileName..".name"))
  pItem = CPanel:Help   (language.GetPhrase("tool."..gsFileName..".desc"))

  pItem = CPanel:AddControl( "ComboBox",{
            MenuButton = 1,
            Folder     = gsFileName,
            Options    = {["#Default"] = gtConVarList},
            CVars      = table.GetKeys(gtConVarList)})

  pItem = CPanel:ComboBox(language.GetPhrase( "tool."..gsFileName..".permeabil_con"), "permeabil")
  pItem:SetTooltip       (language.GetPhrase( "tool."..gsFileName..".permeabil"))
  pItem:SetValue         (pPerm and pPerm[1] or language.GetPhrase( "tool."..gsFileName..".permeabil_def"))
  pID, pMax = 1, magdipoleGetPermeabilityCnt() -- Start from the beginning when creating the panel
  pPerm = magdipoleGetPermeabilityID(pID)
  while(pID <= pMax) do
    pItem:AddChoice(pPerm[1], pID); pID = pID + 1
    pPerm = magdipoleGetPermeabilityID(pID)
  end
  pItem.OnSelect = function(pnSelf, nInd, sVal, anyData)
    RunConsoleCommand(gsFilePrefix.."permeabil", sVal)
    magdipoleSetPermeabilityID(sVal) -- Store environment ID to the CVAR
  end

  pItem = CPanel:NumSlider (language.GetPhrase("tool."..gsFileName..".strength_con"), gsFilePrefix.."strength", 1, gnMaxStrength, 3)
           pItem:SetTooltip(language.GetPhrase("tool."..gsFileName..".strength"))
  pItem = CPanel:NumSlider (language.GetPhrase("tool."..gsFileName..".dampvel_con"), gsFilePrefix.."dampvel", 1, gnMaxDampVel, 3)
           pItem:SetTooltip(language.GetPhrase("tool."..gsFileName..".dampvel"))
  pItem = CPanel:NumSlider (language.GetPhrase("tool."..gsFileName..".damprot_con"), gsFilePrefix.."damprot", 1, gnMaxDampRot, 3)
           pItem:SetTooltip(language.GetPhrase("tool."..gsFileName..".damprot"))
  pItem = CPanel:NumSlider (language.GetPhrase("tool."..gsFileName..".poledepth_con"), gsFilePrefix.."poledepth", 0, 50, 3)
           pItem:SetTooltip(language.GetPhrase("tool."..gsFileName..".poledepth"))
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
  pItem = CPanel:CheckBox  (language.GetPhrase("tool."..gsFileName..".itother_con"), gsFilePrefix.."itother")
           pItem:SetTooltip(language.GetPhrase("tool."..gsFileName..".itother"))
  pItem = CPanel:CheckBox  (language.GetPhrase("tool."..gsFileName..".enghost_con"), gsFilePrefix.."enghost")
           pItem:SetTooltip(language.GetPhrase("tool."..gsFileName..".enghost"))
  pItem = CPanel:CheckBox  (language.GetPhrase("tool."..gsFileName..".advise_con"), gsFilePrefix.."advise")
           pItem:SetTooltip(language.GetPhrase("tool."..gsFileName..".advise"))
  pItem = CPanel:CheckBox  (language.GetPhrase("tool."..gsFileName..".property_con"), gsFilePrefix.."property")
           pItem:SetTooltip(language.GetPhrase("tool."..gsFileName..".property"))
  pItem = CPanel:CheckBox  (language.GetPhrase("tool."..gsFileName..".toggle_con"), gsFilePrefix.."toggle")
           pItem:SetTooltip(language.GetPhrase("tool."..gsFileName..".toggle"))
end
