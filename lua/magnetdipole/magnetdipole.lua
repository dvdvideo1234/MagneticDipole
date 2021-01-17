---------------- Localizing instances ------------------

local SERVER = SERVER
local CLIENT = CLIENT

---------------- Material gains ------------------

local gtMaterialGain =
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

---------------- Environment permability ------------------

local gtPermeability = -- Environment # Permeability # Relative permeability
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

local gsToolName     = "magnetdipole"
local gvVecZero      = Vector()
local gaAngZero      = Angle ()
local gnMetersGLU    = 0.01905 -- Convert the [glu] length to meters
local gsNullModel    = "null"
local gsSentName     = "gmod_"..gsToolName
local gnEpisilonZero = 1e-5

module(gsToolName)

function GetMetersGLU()
  return gnMetersGLU
end

function GetNullModel()
  return gsNullModel
end

function GetToolName()
  return gsToolName
end

function GetSentName()
  return gsSentName
end

function GetZeroVecAng()
  return gvVecZero, gaAngZero
end

function Select(bCnd, vT, vF)
  if(bCnd) then return vT end
  return vF -- False value
end

--Extracts valid physObj ENT from trace
function GetTracePhys(oTr)
  if(not oTr) then return nil end      -- Duhh ...
  if(not oTr.Hit ) then return nil end -- Did not hit anything
  if(oTr.HitWorld) then return nil end -- It's not Entity
  local trEnt = oTr.Entity
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

function GetEpsilonZero()
  return gnEpisilonZero
end

function GetRound(exact, frac)
  local q, f = math.modf(exact/frac)
  return frac * (q + (f > 0.5 and 1 or 0))
end

-- Converts a string to a program-valid model
function GetModel(vMod)
  local sStr = tostring(vMod or "")
  if(sStr == "") then return gsNullModel end
  if(sStr == gsNullModel) then return gsNullModel end
  if(not util.IsValidModel(sStr)) then return gsNullModel end
  if(not util.IsValidProp(sStr) ) then return gsNullModel end
  return sStr
end

-- https://wiki.garrysmod.com/page/Enums/MAT
function GetMaterialGain(oEnt)
  if(not (oEnt and oEnt:IsValid())) then return 0 end
  return (gtMaterialGain[oEnt:GetMaterialType()] or 0)
end

function GetPermeabilityCnt()
  return #gtPermeability
end

function GetPermeabilityID(nID)
  local PC = GetPermeabilityCnt()
  local PB = math.Clamp(tonumber(nID) or 0, 1, PC)
  return gtPermeability[math.floor(PB)]
end

function SetPermeabilityID(nID)
  local PC = GetPermeabilityCnt()
  local PB = math.Clamp(tonumber(nID) or 0, 1, PC)
  gtPermeability.Now = math.floor(PB)
end

function GetPermeability()
  return GetPermeabilityID(gtPermeability.Now)
end
