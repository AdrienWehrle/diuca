E = 8.7e9
nu = 0.32 
K = '${fparse E/3/(1-2*nu)}'
G = '${fparse E/2/(1+nu)}'

Gc = 0.1 # 2.7 # probably in MPa? # KIC = 100 kPa m1/2
l = 0.02 # 0.02

[MultiApps]
  [fracture]
    type = TransientMultiApp
    input_files = fracture.i
    cli_args = 'Gc=${Gc};l=${l}'
    execute_on = 'TIMESTEP_END'
  []
[]

[Transfers]
  [from_d]
    type = MultiAppCopyTransfer
    from_multi_app = 'fracture'
    variable = d
    source_variable = d
  []
  [to_psie_active]
    type = MultiAppCopyTransfer
    to_multi_app = 'fracture'
    variable = psie_active
    source_variable = psie_active
  []
[]

[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
[]

[Mesh]
  
  [channel]      
    type = FileMeshGenerator
    file = ../../../meshes/mesh_icestream_wtsed.e
  []

  [deactivated]      
    type = FileMeshGenerator
    file = ../../../meshes/deactivated_element.e
  []

  [combined]
    type = CombinerGenerator
    inputs = 'channel deactivated'
  []

  [final_mesh]
    type = SubdomainBoundingBoxGenerator
    input = combined
    block_id = 255
    block_name = deactivated
    bottom_left = '-60 19950 -10'
    top_right = '60 20100 60'
  []

  # [refined_mesh]
  #   type = RefineBlockGenerator
  #   input = "final_mesh"
  #   block = "1 2 255"
  #   refinement = '1 1 1'
  #   enable_neighbor_refinement = true
  #   max_element_volume = 1e100
  # []

  final_generator = final_mesh # refined_mesh

[]

[Adaptivity]
  initial_steps = 2
  stop_time = 0
  max_h_level = 2
[]

[Variables]
  [disp_x]
  []
  [disp_y]
  []
  [disp_z]
  []
[]

[AuxVariables]
  [fy]
  []
  [d]
  []
[]

[Kernels]
  # [gravity_x]
  #   type = Gravity
  #   variable = disp_x
  #   value= 0.
  #   block = '1 2'
  # []
  # [gravity_y]
  #   type = Gravity
  #   variable = disp_y
  #   value = 0.
  #   block = '1 2'
  # []
  # [gravity_z]
  #   type = Gravity
  #   variable = disp_z
  #   value = -9.81
  #   block = '1 2'
  # []
  [solid_x]
    type = ADStressDivergenceTensors
    variable = disp_x
    component = 0
  []
  [solid_y]
    type = ADStressDivergenceTensors
    variable = disp_y
    component = 1
  []
  [solid_z]
    type = ADStressDivergenceTensors
    variable = disp_z
    component = 2
  []
[]

[AuxVariables]
  [calving_boolean]
  []
[]

[AuxKernels]
  [calving]
    type = FunctionAux
    variable = calving_boolean
    function = calving_criterion
    execute_on = 'INITIAL TIMESTEP_BEGIN TIMESTEP_END'
  []
[]

[BCs]
  [dirichlet_bottom_x]
    type = DirichletBC
    variable = disp_x
    value = 0
    boundary = 'bottom'
  []
  [dirichlet_bottom_y]
    type = DirichletBC
    variable = disp_y
    value = 0
    boundary = 'bottom'
  []
  [dirichlet_bottom_z]
    type = DirichletBC
    variable = disp_z
    value = 0
    boundary = 'bottom'
  []
  [left_x]
    type = DirichletBC
    variable = disp_x
    value = 0.01
    boundary = 'left'
  []
[]

[Functions]
  [weight]
    type = ParsedFunction
    value = '-8829*(1000-z)'    # initial stress that should result from the weight force
  []
  [upstream_dirichlet]
    type = ParsedFunction
    value = '0'
  []
  [ocean_pressure]
    type = ParsedFunction
    value = '8829*(1000-z)'   
  []
  [calving_criterion]
    type = ParsedFunction
    value = 'if((x>18000.)&(t>0.001), 1000., -1000.)'
  []
[]

[Materials]
  [bulk]
    type = ADGenericConstantMaterial
    prop_names = 'K G'
    prop_values = '${K} ${G}'
  []
  [density]
    type = GenericConstantMaterial
    prop_names = density
    prop_values = 900 #kg/m3
    block = '1 2'
  []
  [degradation]
    type = PowerDegradationFunction
    property_name = g
    expression = (1-d)^p*(1-eta)+eta
    phase_field = d
    parameter_names = 'p eta '
    parameter_values = '2 1e-6'
  []
  [strain]
    type = ADComputeSmallStrain
  []
  [elasticity]
    type = SmallDeformationIsotropicElasticity
    bulk_modulus = K
    shear_modulus = G
    phase_field = d
    degradation_function = g
    decomposition = NONE
    output_properties = 'elastic_strain psie_active'
    outputs = exodus
  []
  [stress]
    type = ComputeSmallDeformationStress
    elasticity_model = elasticity
    output_properties = 'stress'
    outputs = exodus
  []
[]

[UserObjects]
  [calving_event]
    type = CoupledVarThresholdElementSubdomainModifier
    coupled_var = 'calving_boolean'
    block = '1 2'
    criterion_type = ABOVE
    threshold = 0.
    subdomain_id = 255
    moving_boundary_name = downstream 
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
[]

[Executioner]
  type = Transient

  solve_type = NEWTON
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_package'
  petsc_options_value = 'lu       superlu_dist                 '
  automatic_scaling = true

  nl_rel_tol = 1e-8
  nl_abs_tol = 1e-10

  dt = 2e-5
  end_time = 3.5e-3

  fixed_point_max_its = 20
  accept_on_max_fixed_point_iteration = true
  fixed_point_rel_tol = 1e-8
  fixed_point_abs_tol = 1e-10
[]

[Outputs]
  exodus = true
  print_linear_residuals = false
[]
