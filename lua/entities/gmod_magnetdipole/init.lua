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
local magdipoleForceMargin     = 100           -- Scale the real force to expected in source
local magdipoleDenominator     = (4 * math.pi) -- Used in the real force calculating formula
local magdipoleGetPermeability = magdipoleGetPermeability
local magdipoleGetMaterialGain = magdipoleGetMaterialGain
local magdipoleSentName        = magdipoleGetSentName()
local magdipoleSelect          = magdipoleSelect
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
  self.mbToggle   = true
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
      "eMagnetEnt", "vForceS", "vForceN" , "vPosC",
      "vPosS"     , "vPosN"  , "bMoves"  , "nFoundCnt", "aFaundArr"
    }, { "ENTITY", "VECTOR", "VECTOR", "VECTOR",
         "VECTOR", "VECTOR", "NORMAL", "NORMAL", "ARRAY" } , {
      " ENT of the Magnet Dipole ",
      " Force on the south pole ",
      " Force on the north pole ",
      " Position of the center ",
      " Position of the south pole ",
      " Position of the north pole ",
      " Whenever the entity is frozen ",
      " Discovered ENTs count ",
      " Discovered ENTs array "
    });
  end
end

-- These are /WireLib/ wrappers. They are called only if wiremod is installed
function ENT:WireRead(sName)
  local tInput = self.Inputs[sName]; if(not tInput) then
    ErrorNoHalt("MAGNETDIPOLE: ENT.WireRead: Input <"..tostring(sName).."> invalid"); return nil end
  local bHook = (tInput and IsValid(tInput.Src) or false)
  return (bHook and tInput.Value or nil) -- The value here can be anything
end -- Returns a value if the wire input is hooked otherwise returns nil

function ENT:WireWrite(sName, anyVal)
  WireLib.TriggerOutput(self,sName,anyVal); return self
end

function ENT:Think()
  local NextTime  = CurTime() + 0.01
  local MineClass = self:GetClass()
  local wPowerOn, wStrength, wDampingVel, wDampingRot
  local wEnIterOther, wLength, wSearchRad, wPoleDirection
  if(WireLib) then
    wLength        = self:WireRead("nLength"       )
    wPowerOn       = self:WireRead("nPowerOn"      )
    wStrength      = self:WireRead("nStrength"     )
    wDampingVel    = self:WireRead("nDampingVel"   )
    wDampingRot    = self:WireRead("nDampingRot"   )
    wEnIterOther   = self:WireRead("nIterOthers"   )
    wSearchRad     = self:WireRead("nSearchRad"    )
    wPoleDirection = self:WireRead("vPoleDirection")
  end
  -- If on by wire do not turn off by numpad...
  local enOn = magdipoleSelect((wPowerOn ~= nil), (wPowerOn ~= 0), self:GetOnState())
  -- Assert parameters Wire/Numpad
  if(wDampVel   and wDampVel   >= 0) then self:SetDampVel(wDampVel)   end
  if(wDampRot   and wDampRot   >= 0) then self:SetDampRot(wDampRot)   end
  if(wStrength  and wStrength  >= 0) then self:SetStrength(wStrength) end
  if(wLength    and wLength    >  0) then self:SetPoleLength(wLength) end
  if(wSearchRad and wSearchRad >  0) then self:SetSearchRadius(wSearchRad) end
  if(wEnIterOther and wEnIterOther ~= 0) then
    self:SetInteractOthers(wEnIterOther) end
  if(wPoleDirection and wPoleDirection:Length() > 0) then
    self:SetPoleDirectionLocal(wPoleDirection) end
  -- Update Balloon if enabled to save communication
  if(self:GetNWBool(MineClass.."_pro_en")) then
    self:SetNWString(MineClass.."_pro_tx",self:GetMagnetOverlayText()) end
  local minePhys = self:GetPhysicsObject()
  if(minePhys and minePhys:IsValid() and enOn) then
    local isMoved = minePhys:IsMotionEnabled()
    local inteOth = self:GetInteractOthers()
    local damVel  = self:GetDampVel()
    local damRot  = self:GetDampRot()
    local mineCen = self:GetMagnetCenter()
    local mineSou = self:GetSouthPosOrigin(mineCen)
    local mineNor = self:GetNorthPosOrigin(mineCen)
    local mineRad = self:GetSearchRadius()
    if(damVel >= 0 and damRot >= 0) then
      minePhys:SetDamping(damVel, damRot) end
    if(mineRad > 0 and isMoved) then
      self:ClearDiscovary()
      local tFound = ents.FindInSphere(mineCen, mineRad)
      if(tFound) then
        local vForceS, vForceN = self:ResetForce()
        for _, they in ipairs(tFound) do
          if(they and they:IsValid() and they ~= self) then
            local theyPhys = they:GetPhysicsObject()
            if(theyPhys and theyPhys:IsValid()) then
              local theyClass = they:GetClass()
              local theyGhost = they[magdipoleSentName]
              if(theyClass == magdipoleSentName and not theyGhost) then
                local theyCen = they:GetMagnetCenter()
                local theySou = they:GetSouthPosOrigin(theyCen)
                local theyNor = they:GetNorthPosOrigin(theyCen)
                local nGain = magdipoleGetPermeability()[2]
                      nGain = nGain * they:GetStrength() * self:GetStrength()
                      nGain = (magdipoleForceMargin * nGain) / magdipoleDenominator
                --- Repel   Mine South [ MineS - OtherS ]
                self:MagnitudePole(vForceS, mineSou, theySou,  nGain)
                --- Attract Mine South [ MineS - OtherN ]
                self:MagnitudePole(vForceS, mineSou, theyNor, -nGain)
                --- Attract Mine North [ MineN - OtherS ]
                self:MagnitudePole(vForceN, mineNor, theySou, -nGain)
                --- Repel   Mine North [ MineN - OtherN ]
                self:MagnitudePole(vForceN, mineNor, theyNor,  nGain)
                self:AddDiscovery(they)
              elseif(inteOth and theyClass == "prop_physics" and not theyGhost) then
                local nGain = magdipoleGetPermeability()[2]
                      nGain = nGain * (self:GetStrength() * magdipoleGetMaterialGain(they)) -- Magnetised prop
                      nGain = (nGain * magdipoleForceMargin * self:GetStrength()) / magdipoleDenominator
                local theyCen = they:LocalToWorld(they:OBBCenter())
                self:MagnitudePole(vForceS, mineSou, theyCen, -nGain) --- South pole
                self:MagnitudePole(vForceN, mineNor, theyCen, -nGain) --- North Pole
                self:AddDiscovery(they)
              end
            end
          end
        end
        minePhys:ApplyForceOffset(vForceS,mineSou)
        minePhys:ApplyForceOffset(vForceN,mineNor)
        if(WireLib) then
          self:WireWrite("vForceS",vForceS):WireWrite("vForceN",vForceN) end
      end
    end
    if(WireLib) then self:WireWrite("vPosN",mineNor):WireWrite("vPosC",mineCen)
      self:WireWrite("vPosS",mineSou):WireWrite("bMoves",(isMoved and 1 or 0)) end
  end
  if(WireLib) then self:WireWrite("eMagnetEnt",self)
    self:WireWrite("nFoundCnt" ,self.mnFoundCnt):WireWrite("aFaundArr" ,self.mtFoundArr) end
  self:NextThink(NextTime); return true
end

function MagnetDipoleToggleStateOn(oPly, oEnt)
  if(oEnt and oEnt:IsValid() and oEnt:GetClass() == magdipoleSentName) then
    if(oEnt:GetNumToggled()) then
      if(oEnt:GetOnState()) then oEnt:SetOnState(false)
      else oEnt:SetOnState(true) end
    else
      oEnt:SetOnState(true)
    end
  end
end

function MagnetDipoleToggleStateOff(oPly, oEnt)
  if(oEnt and oEnt:IsValid() and oEnt:GetClass() == magdipoleSentName) then
    if(not oEnt:GetNumToggled()) then
      oEnt:SetOnState(false)
    end
  end
end

numpad.Register(magdipoleSentName.."_toggle_state_on" , MagnetDipoleToggleStateOn)
numpad.Register(magdipoleSentName.."_toggle_state_off", MagnetDipoleToggleStateOff)
