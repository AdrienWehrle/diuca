#include "FVSedimentMaterialSI.h"
#include "MooseMesh.h"
#include "MooseFunctorArguments.h"

registerMooseObject("diucaApp", FVSedimentMaterialSI);

InputParameters
FVSedimentMaterialSI::validParams()
{
  InputParameters params = FunctorMaterial::validParams();

  // Friction properties
  params.addParam<Real>("FrictionCoefficient", 1.0, "Sediment friction coefficient");
  params.declareControllable("FrictionCoefficient");
    
  // Get velocity gradients to compute viscosity based on second invariant
  params.addParam<MooseFunctorName>("velocity_x", "Velocity in x dimension");
  params.addParam<MooseFunctorName>("velocity_y", "Velocity in y dimension");
  params.addParam<MooseFunctorName>("velocity_z", "Velocity in z dimension");

  // Mean pressure
  params.addRequiredCoupledVar("pressure", "Mean stress");

  // Sediment density (https://tc.copernicus.org/articles/14/261/2020/)
  params.addParam<Real>("density", 1850., "Ice density"); // kgm-3
  params.declareControllable("density"); // kgm-3
  
  return params;
}

FVSedimentMaterialSI::FVSedimentMaterialSI(const InputParameters & parameters)
  : FunctorMaterial(parameters),

    // Mesh dimension
    _mesh_dimension(_mesh.dimension()),

    // Ice density
    _rho(getParam<Real>("density")),
    
    // Velocities
    _vel_x(getFunctor<ADReal>("velocity_x")),
    _vel_y(getFunctor<ADReal>("velocity_y")),
    _vel_z(getFunctor<ADReal>("velocity_z")),

    // Friction properties
    _FrictionCoefficient(getParam<Real>("FrictionCoefficient")),

    // Pressure
    _pressure(getFunctor<ADReal>("pressure")),

    // Viscosity
    _viscosity(getFunctor<ADReal>("mu_sediment"))

{
  const std::set<ExecFlagType> clearance_schedule(_execute_enum.begin(), _execute_enum.end());

  addFunctorProperty<Real>(
      "rho_sediment", [this](const auto &, const auto &) -> Real { return _rho; }, clearance_schedule);

  addFunctorProperty<ADReal>(
      "mu_sediment",
      [this](const auto & r, const auto & t) -> ADReal
      {

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

	// Get pressure
	ADReal sig_m = _pressure(r, t);

	// Get viscosity
	Moose::StateArg previous_time(1, Moose::SolutionIterationType::Time);
	ADReal eta = _viscosity(r, previous_time);

	ADReal sxx = 2 * eta * u_x + sig_m;
	ADReal syy = 2 * eta * v_y + sig_m;
	ADReal szz = 2 * eta * w_z + sig_m;
	
	ADReal sxy = eta * (u_y + v_x);
	ADReal sxz = eta * (u_z + w_x);
	ADReal syz = eta * (v_z + w_y);
	
	ADReal sxx_dev = 2 * eta * u_x;
	ADReal syy_dev = 2 * eta * v_y;
	ADReal szz_dev = 2 * eta * w_z;
 
	// von Mises stress (second invariant)
	ADReal sig_e = std::sqrt(3./2. * (sxx_dev*sxx_dev + syy_dev*syy_dev + 2*sxy*sxy));
	
        // Compute viscosity
	ADReal viscosity = (_FrictionCoefficient * sig_m) / std::abs(sig_e); // Pas

	return viscosity;
      },
      clearance_schedule);
}
