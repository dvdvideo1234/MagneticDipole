--[[
 * The Magnet module Shared file
 * Magnet module shared stuff
 * Location "lua/entities/gmod_magnetdipole/shared.lua"
]]--

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

if(SERVER) then
  AddCSLuaFile("magnetdipole/wire_wrapper.lua")
end
include("magnetdipole/wire_wrapper.lua")

function ENT:GetMaterialGain()
  return magnetdipole.GetMaterialGain(self)
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
  local Radius = (tonumber(nRadius) or 0)
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
    return self:GetNWFloat(magdipoleSentName.."_plen")
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

function ENT:GetNumToggled()
  if(SERVER) then
    return self.mbToggle
  elseif(CLIENT) then
    return self:GetNWBool(magdipoleSentName.."_btog")
  end
end

function ENT:SetNumToggled(bTog)
  self.mbToggle = tobool(bTog)
  self:SetNWBool(magdipoleSentName.."_btog",self.mbToggle)
end

function ENT:GetMagnetOverlayText()
  local vDir = self:GetPoleDirectionLocal()
  local sTxt = (tostring(self))..
         "\nStrength: "..(magdipoleRoundValue(self:GetStrength(),0.01) or "N/A")..
         "\nDamping: {"..(magdipoleRoundValue(self:GetDampVel(),0.01) or "N/A")..", "
                       ..(magdipoleRoundValue(self:GetDampRot(),0.01) or "N/A").."}"..
           "\nLength: "..(magdipoleRoundValue(self:GetPoleLength(),0.01) or "N/A")..
           "\nRadius: "..(magdipoleRoundValue(self:GetSearchRadius(),0.01) or "N/A")..
         "\nPoledir: {"..(magdipoleRoundValue(vDir.x, 0.001) or "N")..", "
                       ..(magdipoleRoundValue(vDir.y, 0.001) or "N")..", "
                       ..(magdipoleRoundValue(vDir.z, 0.001) or "N").."}"..
       "\nEnts found: "..(tostring(self:GetDiscoveryCount()))..
        "\nIsWorking: "..(tostring(self:GetOnState()))..
  "\nEnable Para/Dia: "..(tostring(self:GetInteractOthers()))
  return sTxt
end

function ENT:Setup(strength , dampvel  , damprot  , itother  , searchrad,
                   length   , voff     , advise   , property , toggle)
  if(self:GetClass() == magdipoleSentName) then
    self:SetSearchRadius(searchrad)
    self:SetStrength(strength)
    self:SetDampVel(dampvel)
    self:SetDampRot(damprot)
    self:SetInteractOthers(itother)
    self:SetPoleLength(length)
    self:SetPoleDirectionLocal(voff)
    self:SetNumToggled(toggle)
    self:SetNWBool(magdipoleSentName.."_adv_en",advise)
    self:SetNWBool(magdipoleSentName.."_pro_en",property)
    if(property) then
      self:SetNWString(magdipoleSentName.."_pro_tx",self:GetMagnetOverlayText())
    end
  end
end

function ENT:ResetForce()
  self.mvForceS:Set(magdipoleVecZero)
  self.mvForceN:Set(magdipoleVecZero)
  return self.mvForceS, self.mvForceN
end

function ENT:MagnitudePole(vFor, vSet, vSub, nGain)

  local vDir = self.mvDummy; vDir:Set(vSet); vDir:Sub(vSub)
  local nMag = (magdipoleMetersGLU * vDir:Length()); nMag = (nGain / ( nMag * nMag ))
  vDir:Normalize(); vDir:Mul(nMag); vFor:Add(vDir)
end
