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
  language.Add( "tool."..gsFileName..".name", gsMeanName )
  language.Add( "tool."..gsFileName..".desc", "Makes an entity a "..gsMeanName )
  language.Add( "tool."..gsFileName..".0"   , "Left Click apply, Right to copy, Reload to remove" )
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

  function MakeMagnetDipole(ply      ,
                            pos      ,
                            ang      ,
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
                            property)
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
        seMag:Setup(strength ,
                    dampvel  ,
                    damprot  ,
                    itother  ,
                    searchrad,
                    length   ,
                    offx     ,
                    offy     ,
                    offz     ,
                    advise   ,
                    property)
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
  return ((self:GetClientNumber("advise") ~= 0 ) or false)
end

function TOOL:GetEnProperty()
  return ((self:GetClientNumber("property") ~= 0 ) or false)
end

function TOOL:GetDampVel()
  return (math.Clamp(self:GetClientNumber("dampvel") or 0,0,gnMaxDampVel))
end

function TOOL:GetDampRot()
  return (math.Clamp(self:GetClientNumber("damprot") or 0,0,gnMaxDampRot))
end

function TOOL:GetIteractOthers()
  return ((self:GetClientNumber("itother") ~= 0 ) or false)
end

function TOOL:GetEnGhost()
  return ((self:GetClientNumber("enghost") ~= 0 ) or false)
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
                                   property)
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
                  property)
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
                                     property )
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
      local PolDir = trEnt:GetPoleDirectionLocal()
      local ItrOth = trEnt:GetIteractOthers()
      ply:ConCommand(gsFilePrefix.."model     "..trModel.." \n")
      ply:ConCommand(gsFilePrefix.."strength  "..trEnt:GetStrength().." \n")
      ply:ConCommand(gsFilePrefix.."dampvel   "..trEnt:GetDampVel().." \n")
      ply:ConCommand(gsFilePrefix.."damprot   "..trEnt:GetDampRot().." \n")
      ply:ConCommand(gsFilePrefix.."itother   "..((ItrOth and 1) or 0).." \n")
      ply:ConCommand(gsFilePrefix.."searchrad "..trEnt:GetSearchRadius().." \n")
      ply:ConCommand(gsFilePrefix.."length    "..trEnt:GetPoleLength().." \n")
      ply:ConCommand(gsFilePrefix.."offx      "..PolDir[1].." \n")
      ply:ConCommand(gsFilePrefix.."offy      "..PolDir[2].." \n")
      ply:ConCommand(gsFilePrefix.."offz      "..PolDir[3].." \n")
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
  if(trEnt:GetClass() == gsFileClass) then
     -- Print(trEnt:GetTable(),"ENT")
     trEnt:Remove()
     return true
  end
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

function TOOL.BuildCPanel( CPanel )
  CPanel:AddControl( "Header", {
            Text         = "#tool."..gsFileName..".name",
            Description  = "#tool."..gsFileName..".desc" })

  CPanel:AddControl("Slider", {
            Label   = "Dipole Strength:",
            Type    = "float",
            Min     = 1,
            Max     = gnMaxStrength,
            Command = gsFilePrefix.."strength"})

  CPanel:AddControl("Slider", {
            Label   = "Linear damping:",
            Type    = "float",
            Min     = 1,
            Max     = gnMaxDampVel,
            Command = gsFilePrefix.."dampvel"})

  CPanel:AddControl("Slider", {
            Label   = "Angular damping:",
            Type    = "float",
            Min     = 1,
            Max     = gnMaxDampRot,
            Command = gsFilePrefix.."damprot"})

  CPanel:AddControl("Slider", {
            Label   = "Pole Length",
            Type    = "float",
            Min     = 0,
            Max     = gnMaxPoleLen,
            Command = gsFilePrefix.."length"})

  CPanel:AddControl("Slider", {
            Label   = "Search radius:",
            Type    = "float",
            Min     = 0,
            Max     = gnMaxSearchRad,
            Command = gsFilePrefix.."searchrad"})

  CPanel:AddControl("Slider", {
            Label   = "Pole Local OBB Offset X:",
            Type    = "float",
            Min     = -gnMaxPoleOffs,
            Max     =  gnMaxPoleOffs,
            Command = gsFilePrefix.."offx"})

  CPanel:AddControl("Slider", {
            Label   = "Pole Local OBB Offset Y:",
            Type    = "float",
            Min     = -gnMaxPoleOffs,
            Max     =  gnMaxPoleOffs,
            Command = gsFilePrefix.."offy"})

  CPanel:AddControl("Slider", {
            Label   = "Pole Local OBB Offset Z:",
            Type    = "float",
            Min     = -gnMaxPoleOffs,
            Max     =  gnMaxPoleOffs,
            Command = gsFilePrefix.."offz"})

  CPanel:AddControl("Slider", {
            Label   = "Crosshair size:",
            Type    = "float",
            Min     = 0,
            Max     = gnMaxCrossSiz,
            Command = gsFilePrefix.."crossiz"})

  CPanel:AddControl( "Numpad", {
            Label      = "Key to start on:",
            Command    = gsFilePrefix.."key",
            ButtonSize = 10 } )

  CPanel:AddControl("Checkbox", {
            Label   = "Enable para-dia magnetism",
            Command = gsFilePrefix.."itother"})

  CPanel:AddControl("Checkbox", {
            Label   = "Enable ghosting",
            Command = gsFilePrefix.."enghost"})

  CPanel:AddControl("Checkbox", {
            Label   = "Enable N/S Advisor",
            Command = gsFilePrefix.."advise"})

  CPanel:AddControl("Checkbox", {
            Label   = "Enable baloon properties",
            Command = gsFilePrefix.."property"})
end
