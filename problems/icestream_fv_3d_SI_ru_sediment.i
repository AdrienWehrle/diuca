# a large glacier flowing towards the ocean (hydrostatic pressure at
# the glacier front, i.e. downstream boundary) in the influence of the
# driving stress (surface slope), over a flat bed.
# The mesh includes a sediment block which is the last layer of
# elements before the bottom boundary (where zero velocity is
# applied): the viscosity of the sediment layer is modulating basal
# sliding through a friction coefficient.
# An influx of ice is applied at the top of the domain (upstream
# boundary) to take into account the ice coming from the inner part of
# the ice sheet.

# NOTE: the sediment block is considered as ice for now

# ------------------------

# dt associated with rest time associated with the
# geometry (in seconds)
# ice has a high viscosity and hence response times
# of years
nb_years = 0.075
mult = 1
_dt = '${fparse nb_years * 3600 * 24 * 365 * mult}'

# upstream inlet (ice influx from the ice sheet interior)
inlet_mph = 0.1 # mh-1
inlet_mps = '${fparse inlet_mph / 3600}' # ms-1

# Numerical scheme parameters
velocity_interp_method = 'rc'
advected_interp_method = 'upwind'

vel_scaling = 1e-6

# Material properties
rho = 'rho_combined'
mu = 'mu_combined'

initial_II_eps_min = 1e-03

# ------------------------

[Problem]
  type = FEProblem
  near_null_space_dimension = 2
  null_space_dimension = 2
  transpose_null_space_dimension = 2
[]
[GlobalParams]
  rhie_chow_user_object = 'rc'
[]

[UserObjects]
  [rc]
    type = INSFVRhieChowInterpolator
    u = vel_x
    v = vel_y
    w = vel_z
    pressure = pressure
  []
  # [pin_pressure]
  #   type = NSPressurePin
  #   variable = pressure
  #   pin_type = point-value
  #   phi0 = 1e5
  #   point = '19600 0 100'
  # []
  # [pin_pressure2]
  #   type = NSPressurePin
  #   variable = pressure
  #   pin_type = point-value
  #   phi0 = 1e5
  #   point = '0 0 433.2' # 433.2
  # []
[]

[Mesh]

  [channel]
    type = FileMeshGenerator
    file = mesh_icestream.e
  []

  # [frontal_zone]
  #   type = SubdomainBoundingBoxGenerator
  #   input = 'channel'
  #   block_id = "10"
  #   bottom_left = '20000 -1000 -3000'
  #   top_right = '19000 15000 3000'
  #   restricted_subdomains = 'eleblock1 eleblock2'
  # []
  # [refined_front]
  #   type = RefineBlockGenerator
  #   input = "frontal_zone"
  #   block = "10"
  #   refinement = '1'
  #   enable_neighbor_refinement = true
  #   max_element_volume = 1e100
  # []
[]

[Variables]
  [vel_x]
    type = INSFVVelocityVariable
    two_term_boundary_expansion = true
    scaling = ${vel_scaling}
  []
  [vel_y]
    type = INSFVVelocityVariable
    two_term_boundary_expansion = true
    scaling = ${vel_scaling}
  []
  [vel_z]
    type = INSFVVelocityVariable
    two_term_boundary_expansion = true
    scaling = ${vel_scaling}
  []
  [pressure]
    type = INSFVPressureVariable
    two_term_boundary_expansion = true
  []
[]

[FVKernels]
  [mass]
    type = INSFVMassAdvection
    variable = pressure
    advected_interp_method = ${advected_interp_method}
    velocity_interp_method = ${velocity_interp_method}
    rho = ${rho}
  []

  [u_time]
    type = INSFVMomentumTimeDerivative
    variable = vel_x
    rho = ${rho}
    momentum_component = 'x'
  []
  [u_advection]
    type = INSFVMomentumAdvection
    variable = vel_x
    advected_interp_method = ${advected_interp_method}
    velocity_interp_method = ${velocity_interp_method}
    rho = ${rho}
    momentum_component = 'x'
  []
  [u_viscosity]
    type = INSFVMomentumDiffusion
    variable = vel_x
    mu = ${mu}
    momentum_component = 'x'
  []
  [u_pressure]
    type = INSFVMomentumPressure
    variable = vel_x
    pressure = pressure
    momentum_component = 'x'
  []
  [u_gravity]
    type = INSFVMomentumGravity
    variable = vel_x
    rho = ${rho}
    momentum_component = 'x'
    gravity = '0 0 -9.81'
  []

  [v_time]
    type = INSFVMomentumTimeDerivative
    variable = vel_y
    rho = ${rho}
    momentum_component = 'y'
  []
  [v_advection]
    type = INSFVMomentumAdvection
    variable = vel_y
    advected_interp_method = ${advected_interp_method}
    velocity_interp_method = ${velocity_interp_method}
    rho = ${rho}
    momentum_component = 'y'
  []
  [v_viscosity]
    type = INSFVMomentumDiffusion
    variable = vel_y
    mu = ${mu}
    momentum_component = 'y'
  []
  [v_pressure]
    type = INSFVMomentumPressure
    variable = vel_y
    pressure = pressure
    momentum_component = 'y'
  []
  [v_buoyant]
    type = INSFVMomentumGravity
    variable = vel_y
    rho = ${rho}
    momentum_component = 'y'
    gravity = '0 0 -9.81'
  []
  # [v_friction]
  #   type = PINSFVMomentumFriction
  #   variable = 'vel_y'
  #   Darcy_name = "Darcy_coefficient"
  #   # Forchheimer_name = 1e10
  #   block = "3"
  #   rho = ${rho}
  #   mu = ${mu}
  #   momentum_component = 'y'
  # []

  [w_time]
    type = INSFVMomentumTimeDerivative
    variable = vel_z
    rho = ${rho}
    momentum_component = 'z'
  []
  [w_advection]
    type = INSFVMomentumAdvection
    variable = vel_z
    advected_interp_method = ${advected_interp_method}
    velocity_interp_method = ${velocity_interp_method}
    rho = ${rho}
    momentum_component = 'z'
  []
  [w_viscosity]
    type = INSFVMomentumDiffusion
    variable = vel_z
    mu = ${mu}
    momentum_component = 'z'
  []
  [w_pressure]
    type = INSFVMomentumPressure
    variable = vel_z
    pressure = pressure
    momentum_component = 'z'
  []
  [w_buoyant]
    type = INSFVMomentumGravity
    variable = vel_z
    rho = ${rho}
    momentum_component = 'z'
    gravity = '0 0 -9.81'
  []
  # [w_friction]
  #   type = PINSFVMomentumFriction
  #   variable = 'vel_z'
  #   Darcy_name = "Darcy_coefficient"
  #   # Forchheimer_name = "Forchheimer_coefficient"
  #   block = "3"
  #   rho = ${rho}
  #   mu = ${mu}
  #   momentum_component = 'z'
  # []
[]

[FVBCs]

  # ice and sediment influx
  [ice_inlet_x]
    type = INSFVInletVelocityBC
    variable = vel_x
    boundary = 'upstream'
    functor = ${inlet_mps}
  []
  [ice_inlet_y]
    type = INSFVInletVelocityBC
    variable = vel_y
    boundary = 'upstream'
    functor = 0
  []
  [ice_inlet_z]
    type = INSFVInletVelocityBC
    variable = vel_z
    boundary = 'upstream'
    functor = 0
  []

  # no slip at the glacier base nor on the sides
  [no_slip_x]
    type = INSFVNoSlipWallBC
    variable = vel_x
    boundary = 'left left_sediment right right_sediment sediment'
    function = 0
  []
  [no_slip_y]
    type = INSFVNoSlipWallBC
    variable = vel_y
    boundary = 'left left_sediment right right_sediment sediment'
    function = 0
  []
  [no_slip_z]
    type = INSFVNoSlipWallBC
    variable = vel_z
    boundary = 'left left_sediment right right_sediment sediment'
    function = 0
  []

  # free slip
  [free_slip_x]
    type = INSFVNaturalFreeSlipBC
    variable = vel_x
    momentum_component = 'x'
    boundary = 'surface'
  []
  [free_slip_y]
    type = INSFVNaturalFreeSlipBC
    variable = vel_y
    momentum_component = 'y'
    boundary = 'surface'
  []
  [free_slip_z]
    type = INSFVNaturalFreeSlipBC
    variable = vel_z
    momentum_component = 'z'
    boundary = 'surface'
  []

  # ocean pressure at the glacier front
  [outlet_p]
    type = INSFVOutletPressureBC
    variable = pressure
    boundary = 'downstream'
    function = ocean_pressure
  []
[]

# ------------------------

[Functions]
  [ocean_pressure]
    type = ParsedFunction
    expression = 'if(z < 0, 1e5 -1028 * 9.81 * z, 1e5)' # -1e5 * 9.81 * z)'
  []
  [viscosity_rampup]
    type = ParsedFunction
    expression = 'initial_II_eps_min * exp(-(t-_dt) * 1e-6)'
    symbol_names = '_dt initial_II_eps_min'
    symbol_values = '${_dt} ${initial_II_eps_min}'
  []
[]

[Controls]
  [II_eps_min_control]
    type = RealFunctionControl
    parameter = 'FunctorMaterials/ice/II_eps_min'
    function = 'viscosity_rampup'
    execute_on = 'initial timestep_begin'
  []
[]

[FunctorMaterials]
  [ice]
    type = FVIceMaterialSI
    block = 'eleblock1 eleblock2' #  10
    velocity_x = "vel_x"
    velocity_y = "vel_y"
    velocity_z = "vel_z"
    pressure = "pressure"
    output_properties = 'mu_ice rho_ice'
    # II_eps_min = 1e-10
  []
  # [sediment]
  #   type = FVConstantMaterial
  #   block = 'eleblock3'
  #   viscosity = 1e10
  #   density = 1850.
  #   output_properties = 'mu_material rho_material'
  # []

  [sediment]
    type = FVSedimentMaterialSI
    block = 'eleblock3'
    velocity_x = "vel_x"
    velocity_y = "vel_y"
    velocity_z = "vel_z"
    pressure = "pressure"
    output_properties = 'mu_sediment rho_sediment'
    density  = 1850.
    FrictionCoefficient = 0.5
    # II_eps_min = 1e-10
  []
  [mu_combined]
    type = ADPiecewiseByBlockFunctorMaterial
    prop_name = 'mu_combined'
    subdomain_to_prop_value = 'eleblock1 mu_ice
                               eleblock2 mu_ice
                               eleblock3 mu_sediment' # 10  mu_ice
  []
  [rho_combined]
    type = ADPiecewiseByBlockFunctorMaterial
    prop_name = 'rho_combined'
    subdomain_to_prop_value = 'eleblock1 rho_ice
                               eleblock2 rho_ice
                               eleblock3 rho_sediment' # 10  rho_ice
  []
  # [darcy]
  #   type = ADGenericVectorFunctorMaterial
  #   prop_names = 'Darcy_coefficient Forchheimer_coefficient'
  #   prop_values = '1e20 1e20 1e20 1e20 1e20 1e20'
  # []
[]

[Preconditioning]
  active = ''
  [FSP]
    type = FSP
    # It is the starting point of splitting
    topsplit = 'up' # 'up' should match the following block name
    [up]
      splitting = 'u p' # 'u' and 'p' are the names of subsolvers
      splitting_type = schur
      # Splitting type is set as schur, because the pressure part of Stokes-like systems
      # is not diagonally dominant. CAN NOT use additive, multiplicative and etc.
      #
      # Original system:
      #
      # | Auu Aup | | u | = | f_u |
      # | Apu 0   | | p |   | f_p |
      #
      # is factorized into
      #
      # |I             0 | | Auu  0|  | I  Auu^{-1}*Aup | | u | = | f_u |
      # |Apu*Auu^{-1}  I | | 0   -S|  | 0  I            | | p |   | f_p |
      #
      # where
      #
      # S = Apu*Auu^{-1}*Aup
      #
      # The preconditioning is accomplished via the following steps
      #
      # (1) p* = f_p - Apu*Auu^{-1}f_u,
      # (2) p = (-S)^{-1} p*
      # (3) u = Auu^{-1}(f_u-Aup*p)
      petsc_options = '-pc_fieldsplit_detect_saddle_point'
      petsc_options_iname = '-pc_fieldsplit_schur_fact_type  -pc_fieldsplit_schur_precondition -ksp_gmres_restart -ksp_rtol -ksp_type'
      petsc_options_value = 'full                            selfp                             300                1e-4      fgmres'
    []
    [u]
      vars = 'vel_x vel_y'
      petsc_options_iname = '-pc_type -pc_hypre_type -ksp_type -ksp_rtol -ksp_gmres_restart -ksp_pc_side'
      petsc_options_value = 'hypre    boomeramg      gmres    5e-1      300                 right'
    []
    [p]
      vars = 'pressure'
      petsc_options_iname = '-ksp_type -ksp_gmres_restart -ksp_rtol -pc_type -ksp_pc_side'
      petsc_options_value = 'gmres    300                5e-1      jacobi    right'
    []
  []
  [SMP]
    type = SMP
    full = true
    petsc_options_iname = '-pc_type -pc_factor_shift_type'
    petsc_options_value = 'lu       NONZERO'
  []
[]

[Executioner]
  type = Transient
  num_steps = 100

  petsc_options_iname = '-pc_type -pc_factor_shift'
  petsc_options_value = 'lu       NONZERO'
  # petsc_options = '-pc_svd_monitor'
  # petsc_options_iname = '-pc_type'
  # petsc_options_value = 'svd'
  # petsc_options = '-pc_type fieldsplit -pc_fieldsplit_type schur -pc_fieldsplit_detect_saddle_point'
  # petsc_options = '--ksp_monitor'

  # nl_rel_tol = 1e-08
  # nl_abs_tol = 1e-13
  # nl_rel_tol = 1e-07

  # nl_abs_tol = 2e-06
  nl_abs_tol = 2e-05

  # l_tol = 1e-6
  l_tol = 1e-5

  nl_max_its = 100
  nl_forced_its = 3
  line_search = none

  dt = '${_dt}'
  # steady_state_detection = true
  # steady_state_tolerance = 1e-100
  check_aux = true
 
[]

[Outputs]
  console = true
  [out]
    type = Exodus
  []
[]

[Debug]
  show_var_residual_norms = true
[]
