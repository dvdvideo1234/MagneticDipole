--[[
 * The Magnet dipole entity type file
 * Describes its entity as is server side
 * Location "lua/entities/gmod_magnetdipole/init.lua"
]]--

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

-- Strength      - How strong the Magnet dipole is
-- Damp(Vel/Rot) - Linear and angular damping of the PhysObj
-- Length        - How far the Dipole's pole spreads ( The South )
-- Centre        - The centre of the EMagnet ( Constant = ENT:OBBCenter)
-- SPos          - Position of the south pole ( = Centre + Length * DirSouth )
-- NPos          - Position of the north pole ( = Centre - Length * DirSouth )
-- SearRad       - How Many glu the magnet should be searching for others ( 0 for passive - does not search )
-- On            - Pretty obvious isn't it ?

-- Source: https://en.wikipedia.org/wiki/Force_between_magnets#Gilbert_Model
-- Inform: Force between two magnetic poles ( Because they are indeed poles )
--[[
       F---- Gmod does not have that ... GetPermeability()
       |
       V
F = ( miu * Strength_1 * Strength_2 ) / ( 4 * PI * R^2 )
                                                   ^
                                                   |
                                                   L---- Measured in GLU instead of Meters ..
]]

function ENT:Initialize()
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetSolid(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)
  local phys = self:GetPhysicsObject()
  if (phys:IsValid()) then
    phys:Wake()
  end
  if(WireLib) then
    WireLib.CreateSpecialInputs(self,{
      "nPowerOn", "nStrength", "nDampingVel", "nDampingRot",
      "nIterOthers", "nLength", "nSearchRad", "vPoleDirection"
    }, { "NORMAL", "NORMAL", "NORMAL", "NORMAL",
         "NORMAL", "NORMAL", "NORMAL", "VECTOR" }, {
      " Power it On ",
      " Strength on the Magnet Dipole ",
      " Linear damping of the PhysObj ",
      " Angular damping of the PhysObj ",
      " Para/Dia magnetism enabled ",
      " Material configuration enabled ",
      " Distance from centre to any pole ",
      " Dipole search radius ",
      " Local vector of the South pole "
    });
    WireLib.CreateSpecialOutputs(self, {
      "eMagnetEnt", "vForceS", "vForceN"  , "vPosC"
      "vPosS"     , "vPosN"  , "nFoundCnt", "aFaundArr"
    }, { "ENTITY", "VECTOR", "VECTOR", "VECTOR",
         "VECTOR", "VECTOR", "NORMAL", "NORMAL", "ARRAY" } , {
      " ENT of the Magnet Dipole ",
      " Force on the south pole ",
      " Force on the north pole ",
      " Position of the center ",
      " Position of the south pole ",
      " Position of the north pole ",
      " Discovered ENTs count ",
      " Discovered ENTs array "
    });
  end
end

ENT.mnStrength = 0
ENT.mnDampVel  = 0
ENT.mnDampRot  = 0
ENT.mnSearRad  = 0
ENT.mnLength   = 0
ENT.mnPoleDirX = 0
ENT.mnPoleDirY = 0
ENT.mnPoleDirZ = 0
ENT.mnFoundCnt = 0
ENT.mtFoundArr = {}
ENT.mbEnIOther = false
ENT.mbOnState  = false

function ENT:Think()
  local NextTime  = CurTime() + 0.01
  local MineClass = self:GetClass()
  local wPowerOn, wStrength, wDampingVel, wDampingRot
  local wEnIterOther, wLength, wSearchRad, wPoleDirection

  if(WireLib) then
    wLength        =  self.Inputs["nLength"].Value
    wPowerOn       = (self.Inputs["nPowerOn"].Value ~= 0)
    wStrength      =  self.Inputs["nStrength"].Value
    wDampingVel    =  self.Inputs["nDampingVel"].Value
    wDampingRot    =  self.Inputs["nDampingRot"].Value
    wEnIterOther   = (self.Inputs["nIterOthers"].Value ~= 0)
    wSearchRad     =  self.Inputs["nSearchRad"].Value
    wPoleDirection =  self.Inputs["vPoleDirection"].Value
  end
  -- If on by wire do not turn off by numpad...
  local On = wPowerOn or self:GetOnState()
  -- Assert parameters Wire/Numpad
  if(wStrength and wStrength > 0) then
    self:SetStrength(wStrength)
  end
  if(wDampVel and wDampVel > 0) then
    self:SetDampVel(wDampVel)
  end
  if(wDampRot and wDampRot > 0) then
    self:SetDampRot(wDampRot)
  end
  if(wEnIterOther) then -- Boolean
    self:SetInteractOthers(wEnIterOther)
  end
  if(wLength and wLength > 0) then
    self:SetPoleLength(wLength)
  end
  if(wSearchRad and wSearchRad > 0) then
    self:SetSearchRadius(wSearchRad)
  end
  if(wPoleDirection and wPoleDirection:Length() > 0) then
    self:SetPoleDirectionLocal(wPoleDirection[1], wPoleDirection[2], wPoleDirection[3])
  end
  local Flag = self:GetNWBool(MineClass.."_pro_en")
  if(Flag) then -- Update Baloon if enabled to save communication
    self:SetNWString(MineClass.."_pro_tx",self:GetMagnetOverlayText())
  end
  local Phys = self:GetPhysicsObject()
  if(Phys and Phys:IsValid() and On) then
    local InterOth   = self:GetInteractOthers()
    local DamVel     = self:GetDampVel()
    local DamRot     = self:GetDampRot()
    local MineCentre = self:GetMagnetCenter()
    local MineSouth  = self:GetSouthPosOrigin(MineCentre)
    local MineNorth  = self:GetNorthPosOrigin(MineCentre)
    local SearchRad  = self:GetSearchRadius()
    if(DamVel >= 0 and DamRot >= 0) then
      Phys:SetDamping(DamVel, DamRot)
    end
    if(SearchRad > 0) then
      self:ClearDiscovary()
      local Others = ents.FindInSphere(MineCentre, SearchRad)
      if(Others) then
        local vForceS, vForceN = Vector(), Vector()
        local dirNN, dirNS, dirSN, dirSS = Vector(), Vector(), Vector(), Vector()
        for _, Other in ipairs(Others) do
          if(Other and Other:IsValid() and Other ~= self) then
            local OtherPhys = Other:GetPhysicsObject()
            if(OtherPhys and OtherPhys:IsValid()) then
              local OtherClass = Other:GetClass()
              if(OtherClass == "gmod_magnetdipole") then
                local OtherCenter = Other:GetMagnetCenter()
                local OtherSouth  = Other:GetSouthPosOrigin(OtherCenter)
                local OtherNorth  = Other:GetNorthPosOrigin(OtherCenter)
                local Gain = (Other:GetStrength() * self:GetStrength() * GetPermeability()[2]) / (4 * math.pi())
                --- Repel   Mine South [ MineS - OtherS ] -- MagnitudePole(vDir, vSet, vSub, nGain)
                self:MagnitudePole(dirSS, MineSouth, OtherSouth,  Gain); vForceS:Add(dirSS)
                --- Attract Mine South [ MineS - OtherN ]
                self:MagnitudePole(dirSN, MineSouth, OtherNorth, -Gain); vForceS:Add(dirSN)
                --- Attract Mine North [ MineN - OtherS ]
                self:MagnitudePole(dirNS, MineNorth, OtherSouth, -Gain); vForceN:Add(dirNS)
                --- Repel   Mine North [ MineN - OtherN ]
                self:MagnitudePole(dirNN, MineNorth, OtherNorth,  Gain); vForceN:Add(dirNN)
                self:AddDiscovery(Other)
              elseif(InterOth and OtherClass == "prop_physics") then
                local Gain = (self:GetStrength() * GetMaterialGain(Other) * GetPermeability()[2]) / (4 * math.pi())
                local OtherCenter = Other:LocalToWorld(Other:OBBCenter())
                --- South pole
                self:MagnitudePole(dirSS, MineSouth, OtherCenter, -Gain); vForceS:Add(dirSS)
                --- North Pole
                self:MagnitudePole(dirNN, MineNorth, OtherCenter, -Gain); vForceN:Add(dirNN)
                self:AddDiscovery(Other)
              end
            end
          end
        end
        Phys:ApplyForceOffset(vForceS,MineSouth)
        Phys:ApplyForceOffset(vForceN,MineNorth)
        if(WireLib) then
          WireLib.TriggerOutput(self,"vForceS",vForceS)
          WireLib.TriggerOutput(self,"vForceN",vForceN)
        end
      end
    end
    if(WireLib) then
      WireLib.TriggerOutput(self,"vPosS",MineSouth)
      WireLib.TriggerOutput(self,"vPosN",MineNorth)
      WireLib.TriggerOutput(self,"vPosC",MineCentre)
    end
  end
  if(WireLib) then
    WireLib.TriggerOutput(self,"eMagnetEnt",self)
    WireLib.TriggerOutput(self,"nFoundCnt",self.mnFoundCnt)
    WireLib.TriggerOutput(self,"aFaundArr",self.mtFoundArr)
  end
  self:NextThink(NextTime)
  return true
end

function MagnetDipoleToggleState(oPly, oEnt )
  if(oEnt and oEnt:IsValid() and oEnt:GetClass() == "gmod_magnetdipole") then
    local flag = oEnt:GetOnState()
    if(flag) then
      oEnt:SetOnState(false)
    else
      oEnt:SetOnState(true)
    end
  end
end

numpad.Register("gmod_magnetdipole_toggle_state", MagnetDipoleToggleState)
