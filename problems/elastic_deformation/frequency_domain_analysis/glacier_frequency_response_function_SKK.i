# from moose/modules/solid_mechanics/examples/wave_propagation/cantilever_sweep.i

# choose if bed is coupled or not
bed_coupled = 0

[Mesh]
  [channel]      
    type = FileMeshGenerator
    file = ../../../meshes/mesh_icestream_wtsed.e
  []
  # [refined_channel]
  #   type = RefineBlockGenerator
  #   input = 'channel'
  #   block = '1 2'
  #   refinement = '1 1'
  #   enable_neighbor_refinement = true
  #   max_element_volume = 1e100
  # []
[]

[GlobalParams]
  order = FIRST
  family = LAGRANGE
  displacements = 'disp_x disp_y disp_z'
[]

[Problem]
 type = ReferenceResidualProblem
 reference_vector = 'ref'
 extra_tag_vectors = 'ref'
 group_variables = 'disp_x disp_y disp_z'
[]

[Physics]
  [SolidMechanics]
    [QuasiStatic]
      [all]
        strain = SMALL
        add_variables = true
        new_system = true
        formulation = TOTAL
      []
    []
  []
[]

[Kernels]
    #reaction terms
    [reaction_realx]
        type = Reaction
        variable = disp_x
        rate = 0# filled by controller
        extra_vector_tags = 'ref'
        block = '1 2'
    []
    [reaction_realy]
        type = Reaction
        variable = disp_y
        rate = 0# filled by controller
        extra_vector_tags = 'ref'
        block = '1 2'
    []
    [reaction_realz]
        type = Reaction
        variable = disp_z
        rate = 0# filled by controller
        extra_vector_tags = 'ref'
        block = '1 2'
    []
[]

[AuxVariables]
  [disp_mag]
  []
[]

[AuxKernels]
  [disp_mag]
    type = ParsedAux
    variable = disp_mag
    coupled_variables = 'disp_x disp_y disp_z'
    expression = 'sqrt(disp_x^2+disp_y^2+disp_z^2)'
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

  [upstream_xreal]
    type = NeumannBC
    variable = disp_x
    boundary = 'upstream'
    value = 1000
  []
  [upstream_yreal]
    type = NeumannBC
    variable = disp_y
    boundary = 'upstream'
    value = 1000
  []
  [upstream_zreal]
    type = NeumannBC
    variable = disp_z
    boundary = 'upstream'
    value = 1000
  []

  [right_xreal]
    type = NeumannBC
    variable = disp_x
    boundary = 'right'
    value = 1000
  []
  [right_yreal]
    type = NeumannBC
    variable = disp_y
    boundary = 'right'
    value = 1000
  []
  [right_zreal]
    type = NeumannBC
    variable = disp_z
    boundary = 'right'
    value = 1000
  []

  [left_xreal]
    type = NeumannBC
    variable = disp_x
    boundary = 'left'
    value = 1000
  []
  [left_yreal]
    type = NeumannBC
    variable = disp_y
    boundary = 'left'
    value = 1000
  []
  [left_zreal]
    type = NeumannBC
    variable = disp_z
    boundary = 'left'
    value = 1000
  []
  [downstream_xreal]
    type = NeumannBC
    variable = disp_x
    boundary = 'downstream'
    value = 1000
  []
  [downstream_yreal]
    type = NeumannBC
    variable = disp_y
    boundary = 'downstream'
    value = 1000
  []
  [downstream_zreal]
    type = NeumannBC
    variable = disp_z
    boundary = 'downstream'
    value = 1000
  []

  # [bottom_xreal]
  #   type = NeumannBC
  #   variable = disp_x
  #   boundary = 'bottom'
  #   value = 1000
  # []
  # [bottom_yreal]
  #   type = NeumannBC
  #   variable = disp_y
  #   boundary = 'bottom'
  #   value = 1000
  # []
  # [bottom_zreal]
  #   type = NeumannBC
  #   variable = disp_z
  #   boundary = 'bottom'
  #   value = 1000
  # []
[]


[Materials]
  [elastic_tensor_Al]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 8.7e9 # Pa
    poissons_ratio = 0.32
  []
  [compute_stress]
    type = ComputeLagrangianLinearElasticStress
  []
[]

[Postprocessors]
  [dispMag]
    type = NodalExtremeValue
    value_type = max
    variable = disp_mag
  []
[]

[Functions]
  [freq2]
    type = ParsedFunction
    symbol_names = density
    symbol_values = 917 # 2.7e3 #Al kg/m3
    expression = '-t*t*density'
  []
  [bed_coupling_function]
    type = ParsedFunction
    expression = '${bed_coupled} = 0'
  []
[]

[Controls]
  [func_control]
    type = RealFunctionControl
    parameter = 'Kernels/*/rate'
    function = 'freq2'
    execute_on = 'initial timestep_begin'
  []
  [bed_not_coupled]
    type = ConditionalFunctionEnableControl
    conditional_function = bed_coupling_function
    disable_objects = 'BCs::dirichlet_bottom_x BCs::dirichlet_bottom_y'
    # enable_objects = 'BCs::bottom_xreal BCs::bottom_yreal'
    execute_on = 'INITIAL TIMESTEP_BEGIN'
  []
[]

[Executioner]
  type = Transient
  solve_type=LINEAR
  petsc_options_iname = ' -pc_type'
  petsc_options_value = 'lu'
  start_time = 0.01 #starting frequency
  end_time =  5.  #ending frequency
  nl_abs_tol = 1e-8
  [TimeStepper]
    type = ConstantDT
    dt = 0.01  #frequency stepsize
  []
[]

[Outputs]
  csv=true
  exodus=true
[]
