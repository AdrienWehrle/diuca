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

# NOTE: the sediment block is deleted for now (no slip boundary)

# ------------------------

# dt associated with rest time associated with the
# geometry (in seconds)
# ice has a high viscosity and hence response times
# of years
nb_years = 0.1
_dt = '${fparse nb_years * 3600 * 24 * 365}'

# upstream inlet (ice influx from the ice sheet interior)
inlet_mph = 0.1 # 0.1 # mh-1
inlet_mps = '${fparse inlet_mph / 3600}' # ms-1

initial_II_eps_min = 1e-25

# ------------------------

# [Problem]
#   # near_null_space_dimension = 1
#   null_space_dimension = 1
#   transpose_null_space_dimension = 1
# []

[Mesh]

  [channel]      
  type = FileMeshGenerator
  file = mesh_icestream.e
  []

  # delete sediment block for now (below bedrock)
  [delete_sediment_block]
    type = BlockDeletionGenerator
    input = channel
    block = '3'
  []
  [frontal_zone]
    type = SubdomainBoundingBoxGenerator
    input = 'delete_sediment_block'
    block_id = 10
    bottom_left = '20000 -1000 -3000'
    top_right = '19000  15000 3000'
  []
  [refined_front]
    type = RefineBlockGenerator
    input = "frontal_zone"
    block = '10'
    refinement = '1'
    enable_neighbor_refinement = true
  []
  # [mesh_combined_interm]
  #   type = CombinerGenerator
  #   inputs = 'channel refined_front'
  # []
  [pin_pressure_node]
    type = BoundingBoxNodeSetGenerator
    input = 'refined_front'
    bottom_left = '19599.99 -0.00001 99.9999'
    top_right = '19600.001 0.000001 100.001'
    new_boundary = 'pressure_pin_node'
  []
[]

[GlobalParams]
  integrate_p_by_parts = true
  order = FIRST
[]

[AuxVariables]
  [vel_x]
  []
  [vel_y]
  []
  [vel_z]
  []
  [vel_x_mon]
    type = MooseVariableFVReal
    order = CONSTANT
  []
  [vel_y_mon]
    type = MooseVariableFVReal
    order = CONSTANT
  []
  [vel_z_mon]
    type = MooseVariableFVReal
    order = CONSTANT
  []
  [p_mon]
    type = MooseVariableFVReal
    order = CONSTANT
  []
[]

[AuxKernels]
  [vel_x]
    type = VectorVariableComponentAux
    variable = vel_x
    vector_variable = velocity
    component = 'x'
  []
  [vel_y]
    type = VectorVariableComponentAux
    variable = vel_y
    vector_variable = velocity
    component = 'y'
  []
  [vel_z]
    type = VectorVariableComponentAux
    variable = vel_z
    vector_variable = velocity
    component = 'z'
  []
  [proj_x]
    type = ProjectionAux
    variable = 'vel_x_mon'
    v = vel_x
  []
  [proj_y]
    type = ProjectionAux
    variable = 'vel_y_mon'
    v = vel_y
  []
  [proj_z]
    type = ProjectionAux
    variable = 'vel_z_mon'
    v = vel_z
  []
  [proj_p]
    type = ProjectionAux
    variable = 'p_mon'
    v = p
  []
[]

[Variables]
  [velocity]
    family = LAGRANGE_VEC
    scaling = 1e-8
    initial_condition = 1e-8
  []
  [p]
  []
[]

[Kernels]
  [mass]
    type = INSADMass
    variable = p
  []
  [mass_stab]
    type = INSADMassPSPG
    variable = p
  []
  [momentum_time]
    type = INSADMomentumTimeDerivative
    variable = velocity
  []
  [momentum_advection]
    type = INSADMomentumAdvection
    variable = velocity
  []
  [momentum_viscous]
    type = INSADMomentumViscous
    variable = velocity
  []
  [momentum_pressure]
    type = INSADMomentumPressure
    variable = velocity
    pressure = p
  []
  [momentum_supg]
    type = INSADMomentumSUPG
    variable = velocity
    velocity = velocity
  []
  [gravity]
    type = INSADGravityForce
    variable = velocity
    gravity = '0 0 -9.81'
  []
[]

[BCs]

  # ice and sediment influx
  [inlet]
    type = ADVectorFunctionDirichletBC
    variable = velocity
    boundary = 'upstream'
    function_x = "${inlet_mps}"
    function_y = 0.
    function_z = 0.
  []

  # no slip at the glacier base nor on the sides
  [noslip]
    type = ADVectorFunctionDirichletBC
    variable = velocity
    boundary = 'bottom left right'
    function_x = 0.
    function_y = 0.
    function_z = 0.
  []

 #  ocean pressure at the glacier front
 [outlet_p]
    type = ADFunctionDirichletBC
    variable = p
    boundary = 'downstream'
    function = ocean_pressure
 []

 [pin_pressure]
    type = DirichletBC
    variable = p
    boundary = 'pressure_pin_node'
    value = 1e5
 []

  # the glacier surface is a free boundary
  [freeslip]
    type = INSADMomentumNoBCBC
    variable = velocity
    pressure = p
    boundary = 'surface'
    
  []
[]

[Materials]
  [ice]
    type = ADIceMaterialSI
    velocity_x = "vel_x"
    velocity_y = "vel_y"
    velocity_z = "vel_z"
    pressure = "p"
    output_properties = "mu"
    outputs = "out"
    II_eps_min = "${initial_II_eps_min}"
  []
  [ins_mat]
    type = INSADTauMaterial
    velocity = velocity
    pressure = p
  []
[]

[Functions]
  [ocean_pressure]
    type = ParsedFunction
    expression = 'if(z < 0, -1028 * 9.81 * z, 1e5)'
  []
  [ice_weight]
    type = ParsedFunction
    expression = '917 * 9.81 * (100 - z)'
  []
  [viscosity_rampup]
    type = ParsedFunction
    expression = 'initial_II_eps_min * exp(-(t-_dt) * 1e-6)'
    # expression = 'initial_II_eps_min * exp((t - _dt) * 1e-7)'
    symbol_names = '_dt initial_II_eps_min'
    symbol_values = '${_dt} ${initial_II_eps_min}'
  []
[]

# [Controls]
#   [II_eps_min_control]
#     type = RealFunctionControl
#     parameter = 'Materials/ice/II_eps_min'
#     function = 'viscosity_rampup'
#     execute_on = 'initial timestep_begin'
#   []
# []


[Preconditioning]
  [SMP]
    type = SMP
    full = true
    solve_type = 'NEWTON'
    # petsc_options = '-pc_svd_monitor'
    # petsc_options_iname = '-pc_type'
    # petsc_options_value = 'svd'
    petsc_options_iname = '-pc_type -pc_factor_shift -pc_mat_solve_package -fieldsplit_velocity_pc_type'
    petsc_options_value = 'lu       NONZERO mumps hypre'

    # -fieldsplit_velocity_pc_type gamg or ml or hypre
  []
[]

[Executioner]
  type = Transient
  num_steps = 100

  # nl_rel_tol = 1e-08
  # nl_abs_tol = 1e-13
  nl_rel_tol = 1e-07
  nl_abs_tol = 1e-07

  nl_max_its = 100
  line_search = none

  # The scaling is not working as expected, makes the matrix worse
  # This is probably due to the lack of on-diagonals in pressure
  automatic_scaling = false

  dt = "${_dt}"
  # steady_state_detection = true
  # steady_state_tolerance = 1e-100

  # [Adaptivity]
  #   interval = 1
  #   refine_fraction = 0.5
  #   coarsen_fraction = 0.3
  #   max_h_level = 10
  #   cycles_per_step = 2
  # []

[]

[Outputs]
  console = true
  [out]
    type = Exodus
  []
[]
