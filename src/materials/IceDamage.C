// https://github.com/idaholab/blackbear/blob/devel/src/materials/MazarsDamage.C

/****************************************************************/
/*               DO NOT MODIFY THIS HEADER                      */
/*                       BlackBear                              */
/*                                                              */
/*           (c) 2017 Battelle Energy Alliance, LLC             */
/*                   ALL RIGHTS RESERVED                        */
/*                                                              */
/*          Prepared by Battelle Energy Alliance, LLC           */
/*            Under Contract No. DE-AC07-05ID14517              */
/*            With the U. S. Department of Energy               */
/*                                                              */
/*            See COPYRIGHT for full restrictions               */
/****************************************************************/

#include "IceDamage.h"

#include "ElasticityTensorTools.h"
#include "MooseUtils.h"

#include "libmesh/utility.h"
#include "RankTwoScalarTools.h"

registerMooseObject("diucaApp", IceDamage);

InputParameters
IceDamage::validParams()
{
  InputParameters params = ScalarDamageBase::validParams();
  params.addClassDescription("Ice damage model");

  params.addParam<Real>("r", 0.43, "Damage law exponent");
  params.addParam<Real>("B", 1., "Damage rate");  
  params.addParam<Real>("sig_th", 0.11, "Damage threshold stress");
  params.addParam<Real>("alpha", 1., "Linear combination parameter on von Mises stresses");
  
  return params;
}

IceDamage::IceDamage(const InputParameters & parameters)
  : ScalarDamageBase(parameters),

  // Damage law parameters
  _r(getParam<Real>("r")),
  _B(getParam<Real>("B")),
  _sig_th(getParam<Real>("sig_th")),
  _alpha(getParam<Real>("alpha")),

  // stress for damage quantification
  // _von_mises(getMaterialProperty<double>("von_mises"))
  _stress(getMaterialProperty<RankTwoTensor>("stress"))
  
{
}

// void
// IceDamage::initQpStatefulProperties()
// {
//   ScalarDamageBase::initQpStatefulProperties();
//   _damage_index[_qp] = 0.0;
// }

void
IceDamage::updateQpDamageIndex()
{

  const auto & stress = MetaPhysicL::raw_value(_stress[_qp]);
  const auto & _von_mises = RankTwoScalarTools::vonMisesStress(stress);
  
  // access damage at previous timestep
  Real d_old = _damage_index_old[_qp];
  
  // stress measure
  Real Xi = _alpha * _von_mises;

  // compute damage
  // Real damage_dt = _B * std::pow((Xi/(1.-d_old)) - _sig_th, _r);
  Real damage_dt = _B * (Xi - d_old);
  
  // update damage  
  _damage_index[_qp] = d_old + _dt * damage_dt;

  // std::cout << _damage_index[_qp];
}
