--[[
 * The Magnet dipole entity type file
 * Describes its entity as is server side
 * Location "lua/entities/gmod_magnetdipole"
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

-- Source: http://en.wikipedia.org/wiki/Force_between_magnets#Magnetic_dipole-dipole_interaction
-- Inform: Force between two magnetic poles ( Because they are indeed poles )
--[[
       F---- Gmod does not have that ...
       |
       V
F = ( miu * Strength_1 * Strength_2 ) / ( 4 * PI * R^2 )
                                                   ^
                                                   |
                                                   L---- Measured in GLU instead of Meters ..
miu(Air) = 1.25663753*10^(-6)
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
      "nIterOthers", "nMaterialConf", "nLength", "nSearchRad", "vPoleDirection"
    }, { "NORMAL", "NORMAL", "NORMAL", "NORMAL",
         "NORMAL", "NORMAL", "NORMAL", "NORMAL", "VECTOR" }, {
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
      "eMagnetDip", "vForceS", "vForceN",
      "vPosS", "vPosN", "nFoundCnt", "aFaundArr"
    }, { "ENTITY", "VECTOR", "VECTOR",
         "VECTOR", "VECTOR", "NORMAL", "ARRAY" } , {
      " Props are within the radius ",
      " ENT of the Magnet Dipole ",
      " Force on the south pole ",
      " Force on the north pole ",
      " Position of the south pole ",
      " Position of the north pole ",
      " Discovered ENTs count ",
      " Discovered ENTs array "
    });
  end
end

ENT.Strength = 0
ENT.DampVel  = 0
ENT.DampRot  = 0
ENT.SearRad  = 0
ENT.Length   = 0
ENT.PoleDirX = 0
ENT.PoleDirY = 0
ENT.PoleDirZ = 0
ENT.FoundCnt = 0
ENT.FoundArr = {}
ENT.EnIOther = false
ENT.OnState  = false
ENT.EnMater  = false

function ENT:Think()
  local NextTime  = CurTime() + 0.005
  local Phys      = self:GetPhysicsObject()
  local MineClass = self:GetClass()
  local wPowerOn, wStrength, wDampingVel, wDampingRot
  local wEnIterOther, wEnMaterConf, wLength, wSearchRad, wPoleDirection

  if(WireLib) then
    wLength        =  self.Inputs["nLength"].Value
    wPowerOn       = (self.Inputs["nPowerOn"].Value ~= 0)
    wStrength      =  self.Inputs["nStrength"].Value
    wDampingVel    =  self.Inputs["nDampingVel"].Value
    wDampingRot    =  self.Inputs["nDampingRot"].Value
    wEnIterOther   = (self.Inputs["nIterOthers"].Value ~= 0)
    wSearchRad     =  self.Inputs["nSearchRad"].Value
    wEnMaterConf   = (self.Inputs["nMaterialConf"].Value ~= 0)
    wPoleDirection =  self.Inputs["vPoleDirection"].Value
  end
  -- If on by wire don't turn off by numpad...
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
  if(wEnIterOther and wEnIterOther ~= 0) then
    self:SetIteractOthers(wEnIterOther)
  end
  if(wEnMaterConf and wEnMaterConf ~= 0) then
    self:SetMaterialConfig(wEnMaterConf)
  end
  if(wLength and wLength > 0) then
    self:SetPoleLength(wLength)
  end
  if(wSearchRad and wSearchRad > 0) then
    self:SetSearchRadius(wSearchRad)
  end
  if(wPoleDirection and
     wPoleDirection:Length() > 0
  ) then
    self:SetPoleDirectionLocal(wPoleDirection[1],
                               wPoleDirection[2],
                               wPoleDirection[3])
  end
  -- Update Baloon
  local Flag = self:GetNWBool(MineClass.."_pro_en")
  if(Flag) then
    self:SetNWString(MineClass.."_pro_tx",self:GetMagnetOverlayText())
  end

  if(Phys and Phys:IsValid() and On) then
    local InterOth   = self:GetIteractOthers()
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
        local vForceS = Vector()
        local vForceN = Vector()
        local dirNN   = Vector()
        local dirNS   = Vector()
        local dirSN   = Vector()
        local dirSS   = Vector()
        local magNN, magNS, magSN, magSS
        for _, Other in ipairs(Others) do
          if(Other and
             Other:IsValid() and
             Other ~= self
          ) then
            local OtherPhys  = Other:GetPhysicsObject()
            if(OtherPhys and OtherPhys:IsValid()) then
              -- If not the force will be Inf ( pole distance^2 = 0 ) !
              --- Hard coding because
              --- ( 4 * PI * 10 ^ (-7) ) / ( 4 * PI ) = 10^(-7)
              --- 10^(-5) -- Powerful magnets
              local OtherClass = Other:GetClass()
              if(OtherClass == "gmod_magnetdipole") then
                local OtherCenter = Other:GetMagnetCenter()
                local OtherSouth  = Other:GetSouthPosOrigin(OtherCenter)
                local OtherNorth  = Other:GetNorthPosOrigin(OtherCenter)
                local Gain = Other:GetStrength() * self:GetStrength()
                --- Repel Mine South [ MineS - OtherS ]
                dirSS:Set(MineSouth)
                dirSS:Sub(OtherSouth)
                magSS = dirSS:Length()
                magSS = Gain / ( magSS * magSS )
                dirSS:Normalize()
                --- Contract Mine South [ MineS - OtherN ]
                dirSN:Set(MineSouth)
                dirSN:Sub(OtherNorth)
                magSN = dirSN:Length()
                magSN = Gain / ( magSN * magSN )
                dirSN:Normalize()
                --- Contract Mine North [ MineN - OtherS ]
                dirNS:Set(MineNorth)
                dirNS:Sub(OtherSouth)
                magNS = dirNS:Length()
                magNS = Gain / ( magNS * magNS )
                dirNS:Normalize()
                --- Repel Mine North [ MineN - OtherN ]
                dirNN:Set(MineNorth)
                dirNN:Sub(OtherNorth)
                magNN = dirNN:Length()
                magNN = Gain / ( magNN * magNN )
                dirNN:Normalize()
                -- Relative to Mine Pole S
                vForceS:Add( magSS * dirSS)
                vForceS:Add(-magSN * dirSN)
                -- Relative to Mine Pole N
                vForceN:Add(-magNS * dirNS)
                vForceN:Add( magNN * dirNN)
                self:SetDiscovery(Other)
              elseif(InterOth and OtherClass == "prop_physics") then
                local Gain = self:GetStrength()
                      Gain = Gain * Gain
                      Gain = Gain * GetMagneticMaterialGain(Other)
                local OtherCenter = Other:LocalToWorld(Other:OBBCenter())
                --- South pole
                dirSS:Set(MineSouth)
                dirSS:Sub(OtherCenter)
                magSS = dirSS:Length()
                magSS = Gain / (magSS * magSS)
                dirSS:Normalize()
                --- North Pole
                dirNN:Set(MineNorth)
                dirNN:Sub(OtherCenter)
                magNN = dirNN:Length()
                magNN = Gain / (magNN * magNN)
                dirNN:Normalize()
                -- Relative to Mine Pole South
                vForceS:Add(-magSS * dirSS)
                -- Relative to Mine Pole North
                vForceN:Add(-magNN * dirNN)
                self:SetDiscovery(Other)
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
    end
  end
  if(WireLib) then
    WireLib.TriggerOutput(self,"eMagnetDip",self)
    WireLib.TriggerOutput(self,"nFoundCnt",self.FoundCnt)
    WireLib.TriggerOutput(self,"aFaundArr",self.FoundArr)
  end
  self:NextThink(NextTime)
  return true
end

function MagnetDipoleToggleState(oPly, oEnt )
  if( oEnt and
      oEnt:IsValid() and
      oEnt:GetClass() == "gmod_magnetdipole"
  ) then
    local flag = oEnt:GetOnState()
    if(flag) then
      oEnt:SetOnState(false)
    else
      oEnt:SetOnState(true)
    end
  end
end

numpad.Register("gmod_magnetdipole_toggle_state", MagnetDipoleToggleState)
