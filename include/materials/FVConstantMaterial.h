#pragma once

#include "FunctorMaterial.h"

/**
 * Material objects inherit from Material and override computeQpProperties.
 *
 * Their job is to declare properties for use by other objects in the
 * calculation such as Kernels and BoundaryConditions.
 */
class FVConstantMaterial : public FunctorMaterial
{
public:
  static InputParameters validParams();

  FVConstantMaterial(const InputParameters & parameters);

protected:

  // Material density
  const Real & _rho;
  const Real & _mu;

};
