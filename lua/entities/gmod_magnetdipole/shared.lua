--[[
 * The Magnet module Shared file
 * Magnet module shared stuff
 * Location "lua/entities/gmod_magnetdipole/shared.lua"
]]--
local magdipoleSentName     = "gmod_magnetdipole"
local magdipoleEpisilonZero = 1e-5
local magdipoleMaterialGain =
{
  [MAT_ALIENFLESH ] = -0.00003,
  [MAT_ANTLION    ] = -0.00001,
  [MAT_BLOODYFLESH] =  0.00012,
  [MAT_CLIP       ] =  0.85000,
  [MAT_COMPUTER   ] =  0.91000,
  [MAT_CONCRETE   ] =  0.00300,
  [MAT_DIRT       ] =  0.00020,
  [MAT_EGGSHELL   ] = -0.00007,
  [MAT_FLESH      ] =  0.00050,
  [MAT_FOLIAGE    ] =  0.01250,
  [MAT_GLASS      ] = -0.00001,
  [MAT_GRATE      ] = -0.00005,
  [MAT_SNOW       ] = -0.00004,
  [MAT_METAL      ] =  1.00000,
  [MAT_PLASTIC    ] = -0.00011,
  [MAT_SAND       ] =  0.00009,
  [MAT_SLOSH      ] =  0.00007,
  [MAT_TILE       ] =  0.00001,
  [MAT_GRASS      ] = -0.00001,
  [MAT_VENT       ] =  0.98000,
  [MAT_WOOD       ] = -0.00034,
  [MAT_DEFAULT    ] =  0.00001,
  [MAT_WARPSHIELD ] =  0.55000
}
local magdipolePermeability = -- Environment # Permeability # Relative permeability
{ -- https://en.wikipedia.org/wiki/Permeability_(electromagnetism)#Values_for_some_common_materials
  Now = 23, -- Default is air
  { "Metglas 2714A (annealed)"     , 1.2600000000000000 , 1002676.141507600000000 },
  { "Iron (99.95%)"                , 0.2500000000000000 ,  198943.678870555000000 },
  { "Nanoperm"                     , 0.1000000000000000 ,   79577.471548222200000 },
  { "Hyperphysics"                 , 0.0250000000000000 ,   19894.367887055500000 },
  { "Steel alloy"                  , 0.0630000000000000 ,   50133.807075380000000 },
  { "Chromium"                     , 0.0630000000000000 ,   50133.807075380000000 },
  { "Cobalt-Iron"                  , 0.0230000000000000 ,   18302.818456091100000 },
  { "Permalloy"                    , 0.0100000000000000 ,    7957.747154822220000 },
  { "Iron (99.8%)"                 , 0.0063000000000000 ,    5013.380707538000000 },
  { "Electrical steel"             , 0.0050000000000000 ,    3978.873577411110000 },
  { "Ferritic steel (annealed)"    , 0.0017600000000000 ,    1400.563499248710000 },
  { "Martensitic steel (annealed)" , 0.0010660000000000 ,     848.295846704048000 },
  { "Ferrite (manganese zinc)"     , 0.0008700000000000 ,     692.324002469533000 },
  { "Ferrite (nickel zinc)"        , 0.0004100000000000 ,     326.267633347711000 },
  { "Carbon Steel"                 , 0.0001260000000000 ,     100.267614150760000 },
  { "Nickel"                       , 0.0004400000000000 ,     350.140874812178000 },
  { "Martensitic steel (hardened)" , 0.0000850000000000 ,      67.640850815988800 },
  { "Austenitic steel"             , 0.0000050300000000 ,       4.002746818875570 },
  { "Neodymium"                    , 0.0000013200000000 ,       1.050422624436530 },
  { "Platinum"                     , 0.0000012569700000 ,       1.000264944119690 },
  { "Aluminum"                     , 0.0000012566650000 ,       1.000022232831470 },
  { "Wood"                         , 0.0000012566376000 ,       1.000000428604260 },
  { "Air"                          , 0.0000012566375300 ,       1.000000372900030 },
  { "Concrete"                     , 0.0000012566370614 ,       1.000000000000000 },
  { "Vacuum"                       , 0.0000012566370614 ,       1.000000000000000 },
  { "Hydrogen"                     , 0.0000012566371000 ,       1.000000030716900 },
  { "Teflon"                       , 0.0000012567000000 ,       1.000050084946510 },
  { "Sapphire"                     , 0.0000012566368000 ,       0.999999791984490 },
  { "Copper"                       , 0.0000012566290000 ,       0.999993584941709 },
  { "Water"                        , 0.0000012566270000 ,       0.999991993392278 },
  { "Bismuth"                      , 0.0000012564300000 ,       0.999835225773328 },
  { "Superconductor"               , 0.0000000000000000 ,       0.000000000000000 }
}
local magdipoleVecZero   = Vector()
local magdipoleAngZero   = Angle ()
local magdipoleMetersGLU = 0.01905 -- Convert the [glu] length to meters

function magdipoleGetSentName()
  return magdipoleSentName end

function magdipoleGetZeroVecAng()
  return magdipoleVecZero, magdipoleAngZero end

--Extracts valid physObj ENT from trace
function magdipoleGetTracePhys(oTrace)
  if(not oTrace) then return nil end      -- Duhh ...
  if(not oTrace.Hit ) then return nil end -- Did not hit anything
  if(oTrace.HitWorld) then return nil end -- It's not Entity
  local trEnt = oTrace.Entity
  if(trEnt                              and
     trEnt:IsValid()                    and
     trEnt:GetPhysicsObject():IsValid() and not
         ( trEnt:IsPlayer()  or
           trEnt:IsNPC()     or
           trEnt:IsVehicle() or
           trEnt:IsRagdoll() or
           trEnt:IsWidget() )
  ) then return trEnt end  -- PhysObj ENT
  return nil -- Some other kind of ENT
end


function magdipoleGetEpsilonZero()
  return magdipoleEpisilonZero
end

function magdipoleRoundValue(exact, frac)
  local q, f = math.modf(exact/frac)
  return frac * (q + (f > 0.5 and 1 or 0))
end

-- Converts a string to a program-valid model
function magdipoleConvertModel(sStr)
  if(not sStr) then return "null" end
  if(sStr == "") then return "null" end
  if(sStr == "null") then return "null" end
  if(not util.IsValidModel(sStr)) then return "null" end
  if(not util.IsValidProp(sStr) ) then return "null" end
  return sStr
end

function magdipoleGetMaterialGain(oEnt)
  if(not (oEnt and oEnt:IsValid())) then return 0 end
  local MG = magdipoleMaterialGain -- https://wiki.garrysmod.com/page/Enums/MAT
  return (MG[oEnt:GetMaterialType()] or 0)
end

function magdipoleGetPermeabilityID(nID)
  local PB = magdipolePermeability
  local ID = math.floor(math.Clamp(tonumber(nID) or 0, 1, #PB)); return PB[ID]
end

function magdipoleGetPermeability()
  local PB = magdipolePermeability
  return magdipoleGetPermeabilityID(PB.Now)
end

function magdipoleSetPermeability(nID)
  local PB = magdipolePermeability
  PB.Now = math.floor(math.Clamp(tonumber(nID) or 0, 1, #PB))
end

ENT.Type            = "anim"
if(WireLib) then
  ENT.Base          = "base_wire_entity"
  ENT.WireDebugName = "Magnet Dipole"
else
  ENT.Base          = "base_gmodentity"
end
ENT.PrintName       = "Magnet Dipole"
ENT.Author          = "dvd_video"
ENT.Contact         = "dvd_video@abv.bg"
ENT.Spawnable       = false
ENT.AdminSpawnable  = false

function ENT:GetMaterialGain()
  -- https://wiki.garrysmod.com/page/Enums/MAT
  local MG = magdipoleMaterialGain
  return (MG[self:GetMaterialType()] or 0)
end

function ENT:ClearDiscovary()
  local Arr, Cnt = self.mtFoundArr, self.mnFoundCnt
  while(Cnt > 0) do Arr[Cnt] = nil; Cnt = Cnt - 1; end
  self.mnFoundCnt = Cnt -- Empty stack
end

function ENT:AddDiscovery(oEnt)
  if(oEnt and oEnt:IsValid()) then
    self.mnFoundCnt = self.mnFoundCnt + 1
    self.mtFoundArr[self.mnFoundCnt] = oEnt
  end
end

function ENT:GetDiscovery(nIndex)
  local Index = tonumber(nIndex) or 0
  if(Index <= 0 or Index > self.mnFoundCnt ) then return nil end
  return self.mtFoundArr[Index]
end

function ENT:GetDiscoveryCount() return self.mnFoundCnt end
function ENT:GetDiscoveryArray() return self.mnFoundArr end

function ENT:GetOnState() return   self.mbOnState end
function ENT:SetOnState(anyStatus) self.mbOnState = tobool(anyStatus) end

function ENT:GetInteractOthers() return  self.mbEnIOther end
function ENT:SetInteractOthers(anyStatus) self.mbEnIOther = tobool(anyStatus) end

function ENT:GetSearchRadius()
  return self.mnSearRad
end

function ENT:SetSearchRadius(nRadius)
  local Radius = tonumber(nRadius) or 0
  if(Radius and Radius >= 0) then
    self.mnSearRad = Radius
  end
end

function ENT:GetStrength() return self.mnStrength end

function ENT:SetStrength(nStr)
  local Str = tonumber(nStr) or 0
  if(Str and Str > 0) then self.mnStrength = Str end
end

function ENT:GetDampVel()
  return self.mnDampVel end

function ENT:SetDampVel(nDamp)
  local Damp = tonumber(nDamp) or 0
  if(Damp and Damp > 0) then
    self.mnDampVel = Damp
  end
end

function ENT:GetDampRot()
  return self.mnDampRot end

function ENT:SetDampRot(nDamp)
  local Damp = tonumber(nDamp) or 0
  if(Damp and Damp > 0) then
    self.mnDampRot = Damp
  end
end

function ENT:GetPoleDirectionLocal()
  if(SERVER) then
    return self.mvDirLocal
  elseif(CLIENT) then
    return self:GetNWVector(magdipoleSentName.."_pdir")
  else return Vector() end
end

function ENT:SetPoleDirectionLocal(vOff)
   -- Default ENT's Local Z of all are zeros
  if(vOff:Length() < magdipoleGetEpsilonZero()) then vOff.z = 1 end
  self.mvDirLocal:Set(vOff); self.mvDirLocal:Normalize()
  self:SetNWVector(magdipoleSentName.."_pdir",self.mvDirLocal)
end

function ENT:GetPoleLength()
  if(SERVER) then
    return self.mnLength
  elseif(CLIENT) then
    return trEnt:GetNWFloat(magdipoleSentName.."_plen")
  else return 0 end
end

function ENT:SetPoleLength(nLen)
  local Len = tonumber(nLen) or 0
  if(Len and Len > 0) then
    self.mnLength = Len
    self:SetNWFloat(magdipoleSentName.."_plen",self.mnLength)
  end
end

function ENT:GetMagnetCenter()
  return self:LocalToWorld(self:OBBCenter())
end

function ENT:GetSouthPosOrigin(vOrg)
  local SPos = self.mvPosS
        SPos:Set(self:GetPoleDirectionLocal())
        SPos:Rotate(self:GetAngles())
        SPos:Mul(self:GetPoleLength())
  if(vOrg) then SPos:Add(vOrg) end; return SPos
end

function ENT:GetNorthPosOrigin(vOrg)
  local NPos = self.mvPosN
        NPos:Set(self:GetPoleDirectionLocal())
        NPos:Rotate(self:GetAngles())
        NPos:Mul(-self:GetPoleLength())
  if(vOrg) then NPos:Add(vOrg) end; return NPos
end

function ENT:GetMagnetOverlayText()
  local PoleDir = self:GetPoleDirectionLocal()
  local Text =                 (tostring(self))..
               "\nStrength: "..(magdipoleRoundValue(self:GetStrength(),0.01) or "N/A")..
               "\nDamping: {"..(magdipoleRoundValue(self:GetDampVel(),0.01) or "N/A")..", "
                             ..(magdipoleRoundValue(self:GetDampRot(),0.01) or "N/A").."}"..
                 "\nLength: "..(magdipoleRoundValue(self:GetPoleLength(),0.01) or "N/A")..
                 "\nRadius: "..(magdipoleRoundValue(self:GetSearchRadius(),0.01) or "N/A")..
               "\nPoledir: {"..(magdipoleRoundValue(PoleDir.x, 0.001) or "N")..", "
                             ..(magdipoleRoundValue(PoleDir.y, 0.001) or "N")..", "
                             ..(magdipoleRoundValue(PoleDir.z, 0.001) or "N").."}"..
             "\nEnts found: "..(tostring(self:GetDiscoveryCount()))..
             "\nIs Working: "..(tostring(self:GetOnState()))..
        "\nEnable Para/Dia: "..(tostring(self:GetInteractOthers()))
  return Text
end

function ENT:Setup(strength , dampvel  , damprot  , itother  ,
                   searchrad, length   , voffx    , advise   , property )
  if(self:GetClass() == magdipoleSentName) then
    self:SetSearchRadius(searchrad)
    self:SetStrength(strength)
    self:SetDampVel(dampvel)
    self:SetDampRot(damprot)
    self:SetInteractOthers(itother)
    self:SetPoleLength(length)
    self:SetPoleDirectionLocal(voff)
    self:SetNWBool(magdipoleSentName.."_adv_en",advise)
    self:SetNWBool(magdipoleSentName.."_pro_en",property)
    if(property) then
      self:SetNWString(magdipoleSentName.."_pro_tx",self:GetMagnetOverlayText())
    end
  end
end

function ENT:ResetForce()
  self.vForceS:Set(magdipoleVecZero)
  self.vForceN:Set(magdipoleVecZero)
  return self.vForceS, self.vForceN
end

function ENT:MagnitudePole(vFor, vSet, vSub, nGain)
  local vDir = self.mvDummy; vDir:Set(vSet); vDir:Sub(vSub)
  local nMag = (magdipoleMetersGLU * vDir:Length()); nMag = (nGain / ( nMag * nMag ))
  vDir:Normalize(); vDir:Mul(nMag); vFor:Add(vDir)
end
