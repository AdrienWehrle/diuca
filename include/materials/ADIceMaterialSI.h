#pragma once

#include "ADMaterial.h"

/**
 * Material objects inherit from Material and override computeQpProperties.
 *
 * Their job is to declare properties for use by other objects in the
 * calculation such as Kernels and BoundaryConditions.
 */
class ADIceMaterialSI : public ADMaterial
{
public:
  static InputParameters validParams();

  ADIceMaterialSI(const InputParameters & parameters);

protected:
  /// Necessary override. This is where the values of the properties are computed.
  virtual void computeQpProperties() override;
  const unsigned int _mesh_dimension;

  // Glen parameters
  const ADReal & _AGlen;
  const ADReal & _nGlen;

  // density of the fluid
  const ADReal & _rho;

  // velocity gradients
  const ADVariableGradient & _grad_velocity_x;
  const ADVariableGradient & _grad_velocity_y;
  const ADVariableGradient & _grad_velocity_z;

  // Finite strain rate parameter
  const Real & _II_eps_min;
  const ADVariableValue & _pressure;

  /// viscosity of the fluid (mu)
  ADMaterialProperty<Real> & _viscosity;
  /// density of the fluid (rho)
  ADMaterialProperty<Real> & _density;
};
