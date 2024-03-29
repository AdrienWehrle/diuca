#include "ADIceMaterial.h"
#include "MooseMesh.h"

registerMooseObject("diucaApp", ADIceMaterial);

InputParameters
ADIceMaterial::validParams()
{
  InputParameters params = ADMaterial::validParams();

  // Get velocity gradients to compute viscosity based on the effective strain rate
  params.addRequiredCoupledVar("velocity_x", "Velocity in x dimension");
  params.addCoupledVar("velocity_y", "Velocity in y dimension");
  params.addCoupledVar("velocity_z", "Velocity in z dimension");

  // Mean pressure
  params.addRequiredCoupledVar("pressure", "Mean stress");

  // Fluid properties
  params.addParam<ADReal>("AGlen", 75., "Fluidity parameter in Glen's flow law"); // MPa-3a-1

  params.addParam<ADReal>("nGlen", 3., "Glen exponent");   //
  params.addParam<ADReal>("density", 917., "Ice density"); // kgm-3

  // Convergence parameters
  params.addParam<ADReal>("II_eps_min", 5.98e-6, "Finite strain rate parameter"); // a-1

  return params;
}

ADIceMaterial::ADIceMaterial(const InputParameters & parameters)
  : ADMaterial(parameters),

    // Mesh dimension
    _mesh_dimension(_mesh.dimension()),

    // Glen parameters
    _AGlen(getParam<ADReal>("AGlen")),
    _nGlen(getParam<ADReal>("nGlen")),

    // Ice density
    _rho(getParam<ADReal>("density")),

    // Velocity gradients
    _grad_velocity_x(adCoupledGradient("velocity_x")),
    _grad_velocity_y(_mesh_dimension >= 2 ? adCoupledGradient("velocity_y") : _ad_grad_zero),
    _grad_velocity_z(_mesh_dimension == 3 ? adCoupledGradient("velocity_z") : _ad_grad_zero),

    // Finite strain rate parameter
    _II_eps_min(getParam<ADReal>("II_eps_min")),

    // Mean stress
    _pressure(adCoupledValue("pressure")),

    // Ice properties created by this object
    _viscosity(declareADProperty<Real>("mu")),
    _density(declareADProperty<Real>("rho"))
{
}

void
ADIceMaterial::computeQpProperties()
{

  // Wrap term with Glen's fluidity parameter for clarity
  ADReal ApGlen = std::pow(_AGlen, -1. / _nGlen);

  // Get current velocity gradients at quadrature point
  ADReal u_x = _grad_velocity_x[_qp](0);
  ADReal u_y = _grad_velocity_x[_qp](1);
  ADReal u_z = _grad_velocity_x[_qp](2);

  ADReal v_x = _grad_velocity_y[_qp](0);
  ADReal v_y = _grad_velocity_y[_qp](1);
  ADReal v_z = _grad_velocity_y[_qp](2);

  ADReal w_x = _grad_velocity_z[_qp](0);
  ADReal w_y = _grad_velocity_z[_qp](1);
  ADReal w_z = _grad_velocity_z[_qp](2);

  ADReal eps_xy = 0.5 * (u_y + v_x);
  ADReal eps_xz = 0.5 * (u_z + w_x);
  ADReal eps_yz = 0.5 * (v_z + w_y);

  // Compute effective strain rate (3D)
  ADReal II_eps = 0.5 * (u_x * u_x + v_y * v_y + w_z * w_z +
                         2. * (eps_xy * eps_xy + eps_xz * eps_xz + eps_yz * eps_yz));

  // Finite strain rate parameter included to avoid infinite viscosity at low stresses
  if (II_eps < _II_eps_min)
    II_eps = _II_eps_min;

  // Compute viscosity
  _viscosity[_qp] = (0.5 * ApGlen * std::pow(II_eps, -(1. - 1. / _nGlen) / 2.)); // MPa a
  _viscosity[_qp] = std::max(_viscosity[_qp], 0.0001);

  // Constant density
  _density[_qp] = _rho;

  // std::cout << "p=" << _pressure[_qp] << "   mu=" << _viscosity[_qp] << "  v_y=" <<  v_y << std::endl;
  
}
