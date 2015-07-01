/*
 * The Magnet Shared file
 * Magnet client side methods stuff
 * Location "lua/entities/gmod_magnetdipole"
 */

include('shared.lua')

function ENT:Draw()
  self:DrawModel()
  local tr = LocalPlayer():GetEyeTrace()
  if(not tr) then return end
  local trEnt = tr.Entity
  if(not (trEnt and trEnt:IsValid() and trEnt == self)) then return end
  local Class = self:GetClass()
  local Flag  = self:GetNWBool(Class.."_pro_en")
  if(Flag) then
    local Text = self:GetNWString(Class.."_pro_tx")
    AddWorldTip(self:EntIndex(), Text, 0.5, self:GetPos(), self)
  end
end
