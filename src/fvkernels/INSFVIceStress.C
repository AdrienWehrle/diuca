//* This file is part of the MOOSE framework
//* https://www.mooseframework.org
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html
// modified from MOOSE INSFVMixingLengthReynoldsStress

// probably use instead https://github.com/idaholab/moose/blob/a35543bb275d046234e6544b1e4c11563b57c710/framework/src/fvkernels/FVKernel.C#L10
// with this https://github.com/casperversteeg/WhALE/blob/b115054ef7aeac03d99bb1c6c4a542ed9fa9b9fc/src/auxkernels/ComputeINSStress.CAD

#include "INSFVIceStress.h"
#include "INSFVVelocityVariable.h"
#include "SystemBase.h"

registerMooseObject("diucaApp", INSFVIceStress);

InputParameters
INSFVIceStress::validParams()
{
  InputParameters params = INSFVFluxKernel::validParams();
  params.addClassDescription(
      "Compute ice stresses following Glen's flow law");
  params.addRequiredParam<MooseFunctorName>("velocity_x", "The velocity in the x direction.");
  params.addParam<MooseFunctorName>("velocity_y", "The velocity in the y direction.");
  params.addParam<MooseFunctorName>("velocity_z", "The velocity in the z direction.");
  params.addParam<MooseFunctorName>("mu", "Ice viscosity");
  params.addRequiredCoupledVar("pressure", "Mean stress");
  MooseEnum momentum_component("x=0 y=1 z=2");
  params.addRequiredParam<MooseEnum>(
      "momentum_component",
      momentum_component,
      "The component of the stress that this kernel applies to.");
  return params;
}

INSFVIceStress::INSFVIceStress(const InputParameters & params)
  : INSFVFluxKernel(params),
    _dim(blocksMaxDimension()),
    _axis_index(getParam<MooseEnum>("momentum_component")),
    _vel_x(getFunctor<ADReal>("velocity_x")),
    _vel_y(_mesh.dimension() >= 2 ? &getFunctor<ADReal>("velocity_y") : nullptr),
    _vel_z(_mesh.dimension() == 3 ? &getFunctor<ADReal>("velocity_z") : nullptr),
    _mu(getFunctor<ADReal>("mu"))
{
  
  if (_dim >= 2 && !_vel_y)
    mooseError(
        "In two or more dimensions, the v velocity must be supplied using the 'v' parameter");
  if (_dim >= 3 && !_vel_z)
    mooseError("In three dimensions, the w velocity must be supplied using the 'w' parameter");

}

ADReal
INSFVIceStress::computeStrongResidual()
{

  // only xx, yy or zz stresses at the moment
  
  const auto face = makeCDFace(*_face_info);
  const auto state = determineState();

  const ADReal mu = _mu(face, state);
  const auto grad_var = _vel_x.gradient(face, state);
  
  if (_index == 0)
    {
      auto grad_var = _vel_x.gradient(face, state);
    }
  else if (_index == 1)
    {
      auto grad_var = _vel_y->gradient(face, state);
    }
  else if (_index == 2)
    {
      auto grad_var = _vel_z->gradient(face, state);
    }

  // compute deviatoric stress
  ADReal sigma_index_dev = 2 * mu * grad_var(_index);

  return sigma_index_dev;
}

// ADReal
// INSFVIceStress::computeSegregatedContribution()
// {
//   return computeStrongResidual(false);
// }

void
INSFVIceStress::gatherRCData(const FaceInfo & fi)
{
  if (skipForBoundary(fi))
    return;

  _face_info = &fi;
  _normal = fi.normal();
  _face_type = fi.faceType(std::make_pair(_var.number(), _var.sys().number()));

  addResidualAndJacobian(computeStrongResidual() * (fi.faceArea() * fi.faceCoord()));
  // addResidualAndJacobian(computeStrongResidual(true) * (fi.faceArea() * fi.faceCoord()));

  // if (_face_type == FaceInfo::VarFaceNeighbors::ELEM ||
  //     _face_type == FaceInfo::VarFaceNeighbors::BOTH)
  //   _rc_uo.addToA(&fi.elem(), _index, _ae * (fi.faceArea() * fi.faceCoord()));
  // if (_face_type == FaceInfo::VarFaceNeighbors::NEIGHBOR ||
  //     _face_type == FaceInfo::VarFaceNeighbors::BOTH)
  //   _rc_uo.addToA(fi.neighborPtr(), _index, _an * (fi.faceArea() * fi.faceCoord()));
}
