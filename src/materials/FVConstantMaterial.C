#include "FVConstantMaterial.h"
#include "MooseMesh.h"
#include "MooseFunctorArguments.h"

registerMooseObject("diucaApp", FVConstantMaterial);

InputParameters
FVConstantMaterial::validParams()
{
  InputParameters params = FunctorMaterial::validParams();

  // Material density
  params.addParam<Real>("density", 1., "Material density"); // kgm-3
  params.declareControllable("density");
  
  // Material viscosity
  params.addParam<Real>("viscosity", 1. , "Material viscosity"); // Pas
  params.declareControllable("viscosity");
  
  return params;
}

FVConstantMaterial::FVConstantMaterial(const InputParameters & parameters)
  : FunctorMaterial(parameters),

    // Ice density
    _rho(getParam<Real>("density")),
    _mu(getParam<Real>("viscosity"))

{
  const std::set<ExecFlagType> clearance_schedule(_execute_enum.begin(), _execute_enum.end());

  addFunctorProperty<Real>(
      "rho_material", [this](const auto &, const auto &) -> Real { return _rho; }, clearance_schedule);

  addFunctorProperty<Real>(
      "mu_material", [this](const auto &, const auto &) -> Real { return _mu; }, clearance_schedule);
}
