#pragma once

#include "FunctorMaterial.h"

/**
 * Material objects inherit from Material and override computeQpProperties.
 *
 * Their job is to declare properties for use by other objects in the
 * calculation such as Kernels and BoundaryConditions.
 */
class FVSedimentMaterialSI : public FunctorMaterial
{
public:
  static InputParameters validParams();

  FVSedimentMaterialSI(const InputParameters & parameters);

protected:
  const unsigned int _mesh_dimension;

  // density of the fluid
  const Real & _rho;

  // velocity
  const Moose::Functor<ADReal> & _vel_x;
  const Moose::Functor<ADReal> & _vel_y;
  const Moose::Functor<ADReal> & _vel_z;

  // Sediment friction parameter
  const Real & _FrictionCoefficient;

  // pressure
  const Moose::Functor<ADReal> & _pressure;

  // viscosity
  const Moose::Functor<ADReal> & _viscosity;
  
};
