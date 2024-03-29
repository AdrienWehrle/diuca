#include "IceMaterial.h"

registerMooseObject("diuca", IceMaterial);

InputParameters
IceMaterial::validParams()
{
  InputParameters params = Material::validParams();

  // Get velocity gradients to compute viscosity based on the effective strain rate
  params.addRequiredCoupledVar("velocity_x", "Velocity in x dimension");
  params.addRequiredCoupledVar("velocity_y", "Velocity in y dimension");
  params.addRequiredCoupledVar("velocity_z", "Velocity in z dimension");

  // Mean pressure
  params.addRequiredCoupledVar("pressure", "Mean stress");

  // Fluid properties
  params.addParam<Real>("AGlen", 75., "Fluidity parameter in Glen's flow law"); // MPa-3a-1

  params.addParam<Real>("nGlen", 3., "Glen exponent");   //
  params.addParam<Real>("density", 917., "Ice density"); // kgm-3

  // Convergence parameters
  params.addParam<Real>("II_eps_min", 5.98e-6, "Finite strain rate parameter"); // a-1

  return params;
}

IceMaterial::IceMaterial(const InputParameters & parameters)
  : Material(parameters),

    // Glen parameters
    _AGlen(getParam<Real>("AGlen")),
    _nGlen(getParam<Real>("nGlen")),

    // Ice density
    _rho(getParam<Real>("density")),

    // Velocity gradients
    _grad_velocity_x(coupledGradient("velocity_x")),
    _grad_velocity_y(coupledGradient("velocity_y")),
    _grad_velocity_z(coupledGradient("velocity_z")),

    // Finite strain rate parameter
    _II_eps_min(getParam<Real>("II_eps_min")),

    // Mean stress
    _pressure(coupledValue("pressure")),

    // Ice properties created by this object
    _viscosity(declareProperty<Real>("mu")),
    _density(declareProperty<Real>("rho"))
{
}

void
IceMaterial::computeQpProperties()
{

  // Wrap term with Glen's fluidity parameter for clarity
  Real ApGlen = std::pow(_AGlen, -1. / _nGlen);

  // Get current velocity gradients at quadrature point
  Real u_x = _grad_velocity_x[_qp](0);
  Real u_y = _grad_velocity_x[_qp](1);
  Real u_z = _grad_velocity_x[_qp](2);

  Real v_x = _grad_velocity_y[_qp](0);
  Real v_y = _grad_velocity_y[_qp](1);
  Real v_z = _grad_velocity_y[_qp](2);

  Real w_x = _grad_velocity_z[_qp](0);
  Real w_y = _grad_velocity_z[_qp](1);
  Real w_z = _grad_velocity_z[_qp](2);

  Real eps_xy = 0.5 * (u_y + v_x);
  Real eps_xz = 0.5 * (u_z + w_x);
  Real eps_yz = 0.5 * (v_z + w_y);

  // Compute effective strain rate (3D)
  Real II_eps = 0.5 * (u_x * u_x + v_y * v_y + w_z * w_z +
                       2. * (eps_xy * eps_xy + eps_xz * eps_xz + eps_yz * eps_yz));

  // Finite strain rate parameter included to avoid infinite viscosity at low stresses
  if (II_eps < _II_eps_min)
    II_eps = _II_eps_min;

  // Compute viscosity
  _viscosity[_qp] = (0.5 * ApGlen * std::pow(II_eps, -(1. - 1. / _nGlen) / 2.)); // MPa a
  _viscosity[_qp] = std::max(_viscosity[_qp], 0.0001);

  // Constant density
  _density[_qp] = _rho;
}
