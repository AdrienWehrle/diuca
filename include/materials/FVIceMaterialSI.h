#pragma once

#include "FunctorMaterial.h"

/**
 * Material objects inherit from Material and override computeQpProperties.
 *
 * Their job is to declare properties for use by other objects in the
 * calculation such as Kernels and BoundaryConditions.
 */
class FVIceMaterialSI : public FunctorMaterial
{
public:
  static InputParameters validParams();

  FVIceMaterialSI(const InputParameters & parameters);

protected:
  const unsigned int _mesh_dimension;

  // Glen parameters
  const Real _AGlen;
  const Real _nGlen;

  // density of the fluid
  const ADReal & _rho;

  // velocity
  const Moose::Functor<ADReal> & _vel_x;
  const Moose::Functor<ADReal> * const _vel_y;
  const Moose::Functor<ADReal> * const _vel_z;
  // const Moose::Functor<ADReal> & _vel_y;
  // const Moose::Functor<ADReal> & _vel_z;

  // Finite strain rate parameter
  const Real & _II_eps_min;

};
