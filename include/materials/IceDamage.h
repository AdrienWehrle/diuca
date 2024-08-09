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

#pragma once

#include "ScalarDamageBase.h"

/**
 * Scalar damage model that defines the damage parameter using a material property
 */
class IceDamage : public ScalarDamageBase
{
public:
  static InputParameters validParams();
  IceDamage(const InputParameters & parameters);

  // virtual void initQpStatefulProperties() override;
  
protected:
  
  virtual void updateQpDamageIndex() override;
  
  // Damage law parameters
  const Real & _r;
  const Real & _B;
  const Real & _sig_th;
  const Real & _alpha;

  /// Current stress
  // const MaterialProperty<double> & _von_mises;
  const MaterialProperty<RankTwoTensor> & _stress;

};
