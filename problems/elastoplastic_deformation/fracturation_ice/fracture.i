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
  [d]
  []
[]

[AuxVariables]
  [psie_active]
    order = CONSTANT
    family = MONOMIAL
  []
[]

[Kernels]
  [diff]
    type = ADPFFDiffusion
    variable = d
    fracture_toughness = Gc
    regularization_length = l
    normalization_constant = c0
  []
  [source]
    type = ADPFFSource
    variable = d
    free_energy = psi
  []
[]

[Materials]
  [fracture_properties]
    type = ADGenericConstantMaterial
    prop_names = 'Gc l'
    prop_values = '${Gc} ${l}'
  []
  [degradation]
    type = PowerDegradationFunction
    property_name = g
    expression = (1-d)^p*(1-eta)+eta
    phase_field = d
    parameter_names = 'p eta '
    parameter_values = '2 1e-6'
  []
  [crack_geometric]
    type = CrackGeometricFunction
    property_name = alpha
    expression = 'd^2'
    phase_field = d
  []
  [psi]
    type = ADDerivativeParsedMaterial
    property_name = psi
    expression = 'alpha*Gc/c0/l+g*psie_active'
    coupled_variables = 'd psie_active'
    material_property_names = 'alpha(d) g(d) Gc c0 l'
    derivative_order = 1
  []
[]

[Executioner]
  type = Transient

  solve_type = NEWTON
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_package -snes_type'
  petsc_options_value = 'lu       superlu_dist                  vinewtonrsls'
  automatic_scaling = true

  nl_rel_tol = 1e-8
  nl_abs_tol = 1e-10
[]

[Outputs]
  print_linear_residuals = false
[]
