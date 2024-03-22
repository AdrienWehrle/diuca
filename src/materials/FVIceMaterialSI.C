#include "FVIceMaterialSI.h"
#include "MooseMesh.h"

registerMooseObject("diucaApp", FVIceMaterialSI);

InputParameters
FVIceMaterialSI::validParams()
{
  InputParameters params = FunctorMaterial::validParams();

  // Get velocity gradients to compute viscosity based on the effective strain rate
  // params.addRequiredCoupledVar("velocity_x", "Velocity in x dimension");
  // params.addCoupledVar("velocity_y", "Velocity in y dimension");
  // params.addCoupledVar("velocity_z", "Velocity in z dimension");

  params.addParam<MooseFunctorName>("velocity_x", "Velocity in x dimension");
  params.addParam<MooseFunctorName>("velocity_y", "Velocity in y dimension");
  params.addParam<MooseFunctorName>("velocity_z", "Velocity in z dimension");

  // Mean pressure
  params.addRequiredCoupledVar("pressure", "Mean stress");

  // Fluid properties
  params.addParam<Real>(
      "AGlen", 2.378234398782344e-24, "Fluidity parameter in Glen's flow law"); // Pa-3s-1

  params.addParam<Real>("nGlen", 3., "Glen exponent");     //
  params.addParam<ADReal>("density", 917., "Ice density"); // kgm-3

  // Convergence parameters
  params.addParam<Real>("II_eps_min", 1e-25, "Finite strain rate parameter"); // s-1
  params.declareControllable("II_eps_min"); // s-1

  return params;
}

FVIceMaterialSI::FVIceMaterialSI(const InputParameters & parameters)
  : FunctorMaterial(parameters),

    // Mesh dimension
    _mesh_dimension(_mesh.dimension()),

    // Glen parameters
    _AGlen(getParam<Real>("AGlen")),
    _nGlen(getParam<Real>("nGlen")),

    // Ice density
    _rho(getParam<ADReal>("density")),

    // Velocities
    _vel_x(getFunctor<ADReal>("velocity_x")),
    _vel_y(getFunctor<ADReal>("velocity_y")),
    _vel_z(getFunctor<ADReal>("velocity_z")),

    // Finite strain rate parameter
    _II_eps_min(getParam<Real>("II_eps_min"))
{
  const std::set<ExecFlagType> clearance_schedule(_execute_enum.begin(), _execute_enum.end());

  _console << "Maximum allowed viscosity : "
           << (0.5 * std::pow(_AGlen, -1. / _nGlen) *
               std::pow(_II_eps_min, -(1. - 1. / _nGlen) / 2.))
           << std::endl;

  addFunctorProperty<ADReal>(
      "rho_ice", [this](const auto &, const auto &) -> ADReal { return _rho; }, clearance_schedule);

  addFunctorProperty<ADReal>(
      "mu_ice",
      [this](const auto & r, const auto & t) -> ADReal
      {
        // Wrap term with Glen's fluidity parameter for clarity
        ADReal ApGlen = std::pow(_AGlen, -1. / _nGlen);

        // Get current velocity gradients at quadrature point
        auto gradx = _vel_x.gradient(r, t);
        ADReal u_x = gradx(0);
        ADReal u_y = gradx(1);
        ADReal u_z = gradx(2);

        auto grady = _vel_y.gradient(r, t);
        ADReal v_x = grady(0);
        ADReal v_y = grady(1);
        ADReal v_z = grady(2);

        auto gradz = _vel_z.gradient(r, t);
        ADReal w_x = gradz(0);
        ADReal w_y = gradz(1);
        ADReal w_z = gradz(2);

        ADReal eps_xy = 0.5 * (u_y + v_x);
        ADReal eps_xz = 0.5 * (u_z + w_x);
        ADReal eps_yz = 0.5 * (v_z + w_y);

        // Compute effective strain rate (3D)
        ADReal II_eps = 0.5 * (u_x * u_x + v_y * v_y + w_z * w_z +
                               2. * (eps_xy * eps_xy + eps_xz * eps_xz + eps_yz * eps_yz));

        // Finite strain rate parameter included to avoid infinite viscosity at low stresses
        if (II_eps < _II_eps_min)
          II_eps = _II_eps_min;

	// std::cout << _II_eps_min << std::endl;
	
        // Compute viscosity
        ADReal viscosity = (0.5 * ApGlen * std::pow(II_eps, -(1. - 1. / _nGlen) / 2.)); // Pas
        return std::max(viscosity, 3.153600e09);
      },
      clearance_schedule);
}
