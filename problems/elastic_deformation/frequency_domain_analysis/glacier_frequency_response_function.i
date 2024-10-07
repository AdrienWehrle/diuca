# from moose/modules/solid_mechanics/examples/wave_propagation/cantilever_sweepi.

[Mesh]
  type = GeneratedMesh
  elem_type = HEX8
  dim = 3
  xmin = 0
  xmax = 5000.
  nx = 40
  zmin = 0
  zmax = 5000.
  ny = 6
  # ymin = -1000.
  # ymax = 500.
  ymin = 0.
  ymax = 500.
  nz = 40
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
    []
    [reaction_realy]
        type = Reaction
        variable = disp_y
        rate = 0# filled by controller
        extra_vector_tags = 'ref'
    []
    [reaction_realz]
        type = Reaction
        variable = disp_z
        rate = 0# filled by controller
        extra_vector_tags = 'ref'
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

  # [Pressure]
  #   [ice_pressure_side1]  
  #   boundary = "left back"
  #   function = ice_pressure_positive
  #   displacements = 'disp_x'
  #   []
  #   [ice_pressure_side2]  
  #   boundary = "right front"
  #   function = ice_pressure_positive
  #   displacements = 'disp_z'
  #   []
  # []
  
  [dirichlet_bottom_x]
    type = DirichletBC
    variable = disp_x
    value = 0
    boundary = 'bottom'
  []
  [dirichlet_bottom_z]
    type = DirichletBC
    variable = disp_z
    value = 0
    boundary = 'bottom'
  []
  [dirichlet_bottom_y]
    type = DirichletBC
    variable = disp_y
    value = 0
    boundary = 'bottom'
  []
  
  # [dirichlet_front_x]
  #   type = DirichletBC
  #   variable = disp_x
  #   value = 0
  #   boundary = 'front'
  # []
  # [dirichlet_front_y]
  #   type = DirichletBC
  #   variable = disp_y
  #   value = 0
  #   boundary = 'front'
  # []
  # [dirichlet_front_z]
  #   type = DirichletBC
  #   variable = disp_z
  #   value = 0
  #   boundary = 'front'
  # []

  # [dirichlet_back_x]
  #   type = DirichletBC
  #   variable = disp_x
  #   value = 0
  #   boundary = 'back'
  # []
  # [dirichlet_back_y]
  #   type = DirichletBC
  #   variable = disp_y
  #   value = 0
  #   boundary = 'back'
  # []
  # [dirichlet_back_z]
  #   type = DirichletBC
  #   variable = disp_z
  #   value = 0
  #   boundary = 'back'
  # []

  [back_xreal]
    type = NeumannBC
    variable = disp_x
    boundary = 'back'
    value = 1000
  []
  [back_yreal]
    type = NeumannBC
    variable = disp_y
    boundary = 'back'
    value = 1000
  []
  [back_zreal]
    type = NeumannBC
    variable = disp_z
    boundary = 'back'
    value = 1000
  []

  [front_xreal]
    type = NeumannBC
    variable = disp_x
    boundary = 'front'
    value = 1000
  []
  [front_yreal]
    type = NeumannBC
    variable = disp_y
    boundary = 'front'
    value = 1000
  []
  [front_zreal]
    type = NeumannBC
    variable = disp_z
    boundary = 'front'
    value = 1000
  []


  # [top_xreal]
  #   type = NeumannBC
  #   variable = disp_x
  #   boundary = 'top'
  #   value = 1000
  # []
  # [top_yreal]
  #   type = NeumannBC
  #   variable = disp_y
  #   boundary = 'top'
  #   value = 1000
  # []
  # [top_zreal]
  #   type = NeumannBC
  #   variable = disp_z
  #   boundary = 'top'
  #   value = 1000
  # []

  [right_xreal]
    type = NeumannBC
    variable = disp_z
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
    variable = disp_z
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
  [ice_pressure_positive]
    type = ParsedFunction
    value = '917*9.81*(600-z)'   
  []
  [ice_pressure_negative]
    type = ParsedFunction
    value = '-917*9.81*(600-z)'   
  []
[]

[Controls]
  [func_control]
    type = RealFunctionControl
    parameter = 'Kernels/*/rate'
    function = 'freq2'
    execute_on = 'initial timestep_begin'
  []
[]

[Executioner]
  type = Transient
  solve_type=LINEAR
  petsc_options_iname = ' -pc_type'
  petsc_options_value = 'lu'
  start_time = 0.01 #starting frequency
  end_time =  5.  #ending frequency
  nl_abs_tol = 1e-6
  [TimeStepper]
    type = ConstantDT
    dt = 0.1  #frequency stepsize
  []
[]

[Outputs]
  csv=true
  exodus=true
[]
