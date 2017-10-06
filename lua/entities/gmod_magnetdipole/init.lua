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
-- Center        - The center of the EMagnet ( Constant = ENT:OBBCenter)
-- SPos          - Position of the south pole ( = Center + Length * DirSouth )
-- NPos          - Position of the north pole ( = Center - Length * DirSouth )
-- SearRad       - How Many [glu] the magnet should be searching for others ( 0 for passive - does not search )
-- On            - Pretty obvious isn't it ?

-- Pretty much this is needed for properly calculate the force by the book
-- I am just putting this here to avoid doing it in real-time
local magdipoleForceMargin = 1000          -- Scale the real force to expected in source
local magdipoleDenominator = (4 * math.pi) -- Used in the real force calculating formula
local magdipoleGetPermeability = magdipoleGetPermeability
local magdipoleGetMaterialGain = magdipoleGetMaterialGain
local magdipoleSentName        = magdipoleGetSentName()
-- Source: https://en.wikipedia.org/wiki/Force_between_magnets#Gilbert_Model
-- Inform: Force between two magnetic poles ( Because they are indeed poles )
--[[
       F---- Gmod does not have that ... magdipoleGetPermeability()
       |
       V
F = ( miu * Strength_1 * Strength_2 ) / ( 4 * PI * R^2 ) = G / ( R^2 )
                                                   ^
                                                   |
                                                   L---- Measured in GLU instead of Meters ..
]]

function ENT:Initialize()
  self.mnStrength = 0
  self.mnDampVel  = 0
  self.mnDampRot  = 0
  self.mnSearRad  = 0
  self.mnLength   = 0
  self.mnPoleDirX = 0
  self.mnPoleDirY = 0
  self.mnPoleDirZ = 0
  self.mnFoundCnt = 0
  self.mtFoundArr = {}
  self.mbEnIOther = false
  self.mbOnState  = false
  self.mvPosS     = Vector()
  self.mvPosN     = Vector()
  self.mvForceS   = Vector()
  self.mvForceN   = Vector()
  self.mvDirLocal = Vector()
  self.mvDummy    = Vector()
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
      " Distance from center to any pole ",
      " Dipole search radius ",
      " Local vector of the South pole "
    });
    WireLib.CreateSpecialOutputs(self, {
      "eMagnetEnt", "vForceS", "vForceN"  , "vPosC",
      "vPosS"     , "vPosN"  , "nFoundCnt", "aFaundArr"
    }, { "ENTITY", "VECTOR", "VECTOR", "VECTOR",
         "VECTOR", "VECTOR", "NORMAL", "ARRAY" } , {
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
    self:SetPoleDirectionLocal(wPoleDirection)
  end
  local Flag = self:GetNWBool(MineClass.."_pro_en")
  if(Flag) then -- Update Balloon if enabled to save communication
    self:SetNWString(MineClass.."_pro_tx",self:GetMagnetOverlayText())
  end
  local minePhys = self:GetPhysicsObject()
  if(minePhys and minePhys:IsValid() and On) then
    local inteOth = self:GetInteractOthers()
    local DamVel  = self:GetDampVel()
    local DamRot  = self:GetDampRot()
    local mineCen = self:GetMagnetCenter()
    local mineSou = self:GetSouthPosOrigin(mineCen)
    local mineNor = self:GetNorthPosOrigin(mineCen)
    local mineRad = self:GetSearchRadius()
    if(DamVel >= 0 and DamRot >= 0) then
      minePhys:SetDamping(DamVel, DamRot)
    end
    if(SearchRad > 0) then
      self:ClearDiscovary()
      local tFound = ents.FindInSphere(mineCen, SearchRad)
      if(tFound) then
        local vForceS, vForceN = self:ResetForce()
        for _, they in ipairs(tFound) do
          if(they and they:IsValid() and they ~= self) then
            local theyPhys = they:GetPhysicsObject()
            if(theyPhys and theyPhys:IsValid()) then
              local theyClass = they:GetClass()
              if(theyClass == magdipoleSentName) then
                local theyCen = they:GetMagnetCenter()
                local theySou = they:GetSouthPosOrigin(theyCen)
                local theyNor = they:GetNorthPosOrigin(theyCen)
                local nGain = magdipoleGetPermeability()[2]
                      nGain = nGain * they:GetStrength() * self:GetStrength()
                      nGain = (magdipoleForceMargin * nGain) / magdipoleDenominator
                --- Repel   Mine South [ MineS - OtherS ] -- MagnitudePole(vDir, vSet, vSub, nGain)
                self:MagnitudePole(vForceS, mineSou, theyNor,  nGain)
                --- Attract Mine South [ MineS - OtherN ]
                self:MagnitudePole(vForceS, mineSou, theySou, -nGain)
                --- Attract Mine North [ MineN - OtherS ]
                self:MagnitudePole(vForceN, mineNor, theyNor, -nGain)
                --- Repel   Mine North [ MineN - OtherN ]
                self:MagnitudePole(vForceN, mineNor, theySou,  nGain)
                self:AddDiscovery(they)
              elseif(InterOth and theyClass == "prop_physics") then
                local nGain = magdipoleGetPermeability()[2]
                      nGain = nGain * self:GetStrength() * magdipoleGetMaterialGain(they)
                      nGain = (magdipoleForceMargin * nGain) / magdipoleDenominator
                local OtherCenter = they:LocalToWorld(they:OBBCenter())
                self:MagnitudePole(vForceS, mineSou, OtherCenter, -nGain) --- South pole
                self:MagnitudePole(vForceN, mineNor, OtherCenter, -nGain) --- North Pole
                self:AddDiscovery(they)
              end
            end
          end
        end
        minePhys:ApplyForceOffset(vForceS,mineSou)
        minePhys:ApplyForceOffset(vForceN,mineNor)
        if(WireLib) then
          WireLib.TriggerOutput(self,"vForceS",vForceS)
          WireLib.TriggerOutput(self,"vForceN",vForceN)
        end
      end
    end
    if(WireLib) then
      WireLib.TriggerOutput(self,"vPosS",mineSou)
      WireLib.TriggerOutput(self,"vPosN",mineNor)
      WireLib.TriggerOutput(self,"vPosC",mineCen)
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
  if(oEnt and oEnt:IsValid() and oEnt:GetClass() == magdipoleSentName) then
    local flag = oEnt:GetOnState()
    if(flag) then
      oEnt:SetOnState(false)
    else
      oEnt:SetOnState(true)
    end
  end
end

numpad.Register(magdipoleSentName.."_toggle_state", MagnetDipoleToggleState)
