/*
 * The Magnet module Shared file
 * Magnet module shared stuff
 * Location "lua/entities/gmod_magnetdipole"
 */

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

function ENT:ClearDiscovary()
  while(self.FoundCnt > 0) do
    self.FoundArr[self.FoundCnt] = nil
    self.FoundCnt = self.FoundCnt - 1
  end
end

function ENT:SetDiscovery(oEnt)
  if(oEnt and oEnt:IsValid()) then
    self.FoundCnt = self.FoundCnt + 1
    self.FoundArr[self.FoundCnt] = oEnt
  end
end

function ENT:GetDiscovery(nIndex)
  local Index = tonumber(nIndex) or 0
  if(Index <= 0 or
     Index > self.FoundCnt
  ) then return nil end
  return self.FoundArr[Index]
end

function ENT:GetDiscoveryCount()
  return self.FoundCnt
end

function ENT:GetOnState()
  return self.OnState
end

function ENT:SetOnState(anyStatus)
  self.OnState = tobool(anyStatus)
end

function ENT:GetIteractOthers()
  return self.EnIOther
end

function ENT:SetIteractOthers(anyStatus)
  self.EnIOther = tobool(anyStatus)
end

function ENT:GetSearchRadius()
  return self.SearRad
end

function ENT:SetSearchRadius(nRadius)
  local Radius = tonumber(nRadius) or 0
  if(Radius and Radius >= 0) then
    self.SearRad = Radius
  end
end

function ENT:GetStrength()
  return self.Strength
end

function ENT:SetStrength(nStr)
  local Str = tonumber(nStr) or 0
  if(Str and Str > 0) then
    self.Strength = Str
  end
end

function ENT:GetDampVel()
  return self.DampVel
end

function ENT:SetDampVel(nDamp)
  local nDamp = tonumber(nDamp) or 0
  if(nDamp and nDamp > 0) then
    self.DampVel = nDamp
  end
end

function ENT:GetDampRot()
  return self.DampRot
end

function ENT:SetDampRot(nDamp)
  local nDamp = tonumber(nDamp) or 0
  if(nDamp and nDamp > 0) then
    self.DampRot = nDamp
  end
end

function ENT:GetPoleDirectionLocal()
  local DirectionLocal = Vector(self.PoleDirX,
                                self.PoleDirY,
                                self.PoleDirZ)
  return DirectionLocal
end

function ENT:SetPoleDirectionLocal(nX,nY,nZ)
  local X = tonumber(nX) or 0
  local Y = tonumber(nY) or 0
  local Z = tonumber(nZ) or 0
  if(X == 0 and Y == 0 and Z == 0) then
    Z = 1 -- Default ENT's Local Z
  end
  local Class = self:GetClass()
  local Dir   = Vector(X,Y,Z)
        Dir:Normalize()
  self.PoleDirX = Dir[1]
  self.PoleDirY = Dir[2]
  self.PoleDirZ = Dir[3]
  self:SetNWFloat(Class.."_pdir_x",self.PoleDirX)
  self:SetNWFloat(Class.."_pdir_y",self.PoleDirY)
  self:SetNWFloat(Class.."_pdir_z",self.PoleDirZ)
end

function ENT:GetPoleLength()
  return self.Length
end

function ENT:SetPoleLength(nLen)
  local Len = tonumber(nLen) or 0
  if(Len and Len > 0) then
    self.Length = Len
    self:SetNWFloat(self:GetClass().."_plen",self.Length)
  end
end

function ENT:GetMagnetCenter()
  return self:LocalToWorld(self:OBBCenter())
end

function ENT:GetSouthPosOrigin(Origin)
  local SPos = self:GetPoleDirectionLocal()
        SPos:Rotate(self:GetAngles())
        SPos:Mul(self:GetPoleLength())
  if(Origin) then
    SPos:Add(Origin)
  end
  return SPos
end

function ENT:GetNorthPosOrigin(Origin)
  local NPos = self:GetPoleDirectionLocal()
        NPos:Rotate(self:GetAngles())
        NPos:Mul(-self:GetPoleLength())
  if(Origin) then
    NPos:Add(Origin)
  end
  return NPos
end

function ENT:GetMagnetOverlayText()
  local PoleDir = self:GetPoleDirectionLocal()
  local Text =                 (tostring(self))..
               "\nStrength: "..(RoundValue(self:GetStrength(),0.01) or "N/A")..
               "\nDamping: {"..(RoundValue(self:GetDampVel(),0.01) or "N/A")..", "
                             ..(RoundValue(self:GetDampRot(),0.01) or "N/A").."}"..
                 "\nLength: "..(RoundValue(self:GetPoleLength(),0.01) or "N/A")..
                 "\nRadius: "..(RoundValue(self:GetSearchRadius(),0.01) or "N/A")..
               "\nPoledir: {"..(RoundValue(PoleDir[1], 0.001) or "N")..", "
                             ..(RoundValue(PoleDir[2], 0.001) or "N")..", "
                             ..(RoundValue(PoleDir[3], 0.001) or "N").."}"..
             "\nEnts found: "..(tostring(self:GetDiscoveryCount()))..
             "\nIs Working: "..(tostring(self:GetOnState()))..
        "\nEnable Para/Dia: "..(tostring(self:GetIteractOthers()))
  return Text
end

function ENT:Setup(strength ,
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
  local Class = self:GetClass()
  if(Class == "gmod_magnetdipole") then
    self:SetSearchRadius(searchrad)
    self:SetStrength(strength)
    self:SetDampVel(dampvel)
    self:SetDampRot(damprot)
    self:SetIteractOthers(itother)
    self:SetPoleLength(length)
    self:SetPoleDirectionLocal(offx,offy,offz)
    self:SetNWBool(Class.."_adv_en",advise)
    self:SetNWBool(Class.."_pro_en",property)
    if(property) then
      self:SetNWString(Class.."_pro_tx",self:GetMagnetOverlayText())
    end
  end
end

--Extracts valid physObj ENT from trace
function GetTracePhys(oTrace)
  if(not oTrace) then return nil end      -- Duhh ...
  if(not oTrace.Hit ) then return nil end -- Did not hit anything
  if(oTrace.HitWorld) then return nil end -- It's not Entity
  local trEnt = oTrace.Entity
  if(trEnt                              and
     trEnt:IsValid()                    and
     trEnt:GetPhysicsObject():IsValid() and not
         ( trEnt:IsPlayer()  or
           trEnt:IsNPC()     or
           trEnt:IsVehicle() )
  ) then
    return trEnt  -- PhysObj ENT
  end
  return nil -- Some other kind of ENT
end

function RoundValue(exact, frac)
    local q,f = math.modf(exact/frac)
    return frac * (q + (f > 0.5 and 1 or 0))
end

-- Gets the file name of the model
function GetModelFileName(sModel)
  if(not sModel or
         sModel == "") then return "NULL" end
  local Len = string.len(sModel)
  local Cnt = Len
  local Ch  = string.sub(sModel,Cnt,Cnt)
  while(Ch ~= "/" and Cnt > 0) do
    Cnt = Cnt - 1
    Ch  = string.sub(sModel,Cnt,Cnt)
  end
  return string.sub(sModel,Cnt+1,Len)
end

--Prints a table ( or a value )
function Print(tT,sN)
  if(not tT)then
    print("Print No Data: Did u set your table ?")
    print("Print No Data: Print( Table, String )!")
    return
  end
  local N = type(sN)
  local T = type(tT)
  local L = ""
  if(N and (N == "string" or
            N == "number" )
  ) then
    N = tostring(sN)
  else
    N = "Data"
  end
  if(T ~= "table") then
    print("{"..T.."}["..N.."] => "..tostring(tT))
    return
  end
  T = tT
  print(N)
  for k,v in pairs(T) do
    if(type(k) == "string") then
      L = N.."[\""..k.."\"]"
    else
      L = N.."["..k.."]"
    end
    if(type(v) ~= "table") then
      if(type(v) == "string") then
        print(L.." = \""..v.."\"")
      else
        print(L.." = "..tostring(v))
      end
    else
      Print(v,L)
    end
  end
end

-- Converts a string to a program-valid model
function MagnetDipoleModel(sStr)
  if( not sStr ) then return "null" end
  if(sStr == "") then return "null" end
  if(sStr == "null") then return "null" end
  if(not util.IsValidModel(sStr)) then return "null" end
  if(not util.IsValidProp(sStr) ) then return "null" end
  return sStr
end

function GetMagneticMaterialGain(oEnt)
  if(not (oEnt and oEnt:IsValid())) then return 0 end
  local Enum = oEnt:GetMaterialType()
  if(Enum == MAT_ALIENFLESH	) then return -0.00003 end
  if(Enum == MAT_ANTLION	  ) then return -0.00001 end
  if(Enum == MAT_BLOODYFLESH) then return  0.00012 end
  if(Enum == MAT_CLIP	      ) then return  0.85000 end
  if(Enum == MAT_COMPUTER	  ) then return  0.91000 end
  if(Enum == MAT_CONCRETE	  ) then return  0.00300 end
  if(Enum == MAT_DIRT	      ) then return  0.00020 end
  if(Enum == MAT_EGGSHELL   ) then return -0.00007 end
  if(Enum == MAT_FLESH	    ) then return  0.00050 end
  if(Enum == MAT_FOLIAGE	  ) then return  0.01250 end
  if(Enum == MAT_GLASS	    ) then return -0.00001 end
  if(Enum == MAT_GRATE	    ) then return -0.00005 end
  if(Enum == MAT_SNOW	      ) then return -0.00004 end
  if(Enum == MAT_METAL	    ) then return  1.00000 end
  if(Enum == MAT_PLASTIC	  ) then return -0.00011 end
  if(Enum == MAT_SAND	      ) then return  0.00009 end
  if(Enum == MAT_SLOSH	    ) then return  0.00007 end
  if(Enum == MAT_TILE	      ) then return  0.00001 end
  if(Enum == MAT_GRASS	    ) then return -0.00001 end
  if(Enum == MAT_VENT	      ) then return  0.98000 end
  if(Enum == MAT_WOOD	      ) then return -0.00034 end
  if(Enum == MAT_DEFAULT    ) then return  0.00001 end
  if(Enum == MAT_WARPSHIELD ) then return  0.55000 end
  return 0
end

function StringReplace(sStr,tRep)
  if(not sStr or sStr == "") then return "" end
  if(not tRep) then return "" end
  if(not tRep[1]) then return "" end
  if(not tRep[1][1]) then return "" end
  if(not tRep[1][2]) then return "" end
  local Len = string.len(sStr)
  local S = 1
  local Rep = 1
  local Rez = ""
  local Sub, Ch, E
  while(S <= Len) do
    Ch = string.sub(sStr,S,S)
    while(tRep[Rep] and tRep[Rep][1] and tRep[Rep][2]) do
      E = S + string.len(tRep[Rep][1])-1
      Sub = string.sub(sStr,S,E)
      if(Sub == tRep[Rep][1]) then
        Rez = Rez..tRep[Rep][2]
        S = E
        Ch = ""
      end
      Rep = Rep + 1
    end
    if(Ch ~= "") then
      Rez = Rez..Ch
    end
    S = S + 1
    Rep = 1
  end
  return Rez
end
