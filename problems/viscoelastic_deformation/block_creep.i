# we use a unit system adapted to glaciology: 
#
# stress : MPa
# time:    year
# length:  m
#
# such that rho*g = 0.008829  MPa m^{-1}


[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
[]

[Mesh]
  [./glacier]
    type = GeneratedMeshGenerator
    dim = 3
    nx = 3
    ny = 2
    nz = 2
    xmin = 0
    xmax = 3
    ymin = 0
    ymax = 2
    zmin = 0
    zmax = 1
  []
  boundary_id = '0 1 2 3 4 5'     
  boundary_name = 'bottom back right front left top'
[]

[Modules/TensorMechanics/Master]
  [./all]
    strain = FINITE
    incremental = true
    add_variables = true
    generate_output = 'stress_yy strain_yy stress_zz strain_zz'
    eigenstrain_names = ini_stress
    # use_displaced_mesh = true
  [../]
[]

[Functions]
  [./ocean_pressure_func]
    type = ParsedFunction
    # value = '9.81*1028*max(20*t-y,0)'  #*sin(t/20)'
    value = '9.81*900*(100-y)'  #*sin(t/20)'
  [../]
[]


# [Functions]
#   [./top_pressure]
#     type = ParsedFunction
#     value = 'if(t < 50,0.1,0)' # 
#   [../]
# []

[BCs]
  [./velx]
    # type = PresetBC
    type = DirichletBC
    variable = disp_x
    # boundary = 'bottom'
    boundary = 'left'
    value = 0
  [../]
  [./vely]
    type = DirichletBC
    variable = disp_y
    # boundary = 'front'
    boundary = 'front back'
    # boundary = 'front back bottom'
    value = 0
  [../]
  [./velz]
    type = DirichletBC
    variable = disp_z
    boundary = 'bottom'
    value = 0
  [../]

  # [./surf_x]
  #   type = Pressure
  #   component = 2
  #   variable = disp_x
  #   boundary = 'top' 
  #   factor = -5e-3
  #   function = top_pressure
  # [../]


  [./surf_z]
    type = Pressure
    component = 2
    variable = disp_z
    boundary = 'top' 
    factor = 1e-2
    function = ocean_pressure_func
  [../]


[]



[Materials]
  [./elasticity_tensor]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 8.7e3     # values from Hutter 1983 (Physics of Glaciers)
    poissons_ratio = 0.31      # values from Hutter 1983 (Physics of Glaciers)
  [../]
  [./creep_plas]
    type = ComputeMultipleInelasticStress
    tangent_operator = elastic
    inelastic_models = 'creep'
    max_iterations = 50
    absolute_tolerance = 1e-07
    combined_inelastic_strain_weights = '1'
  [../]
  [./creep]
    type = PowerLawCreepStressUpdate
    coefficient = 75e-1   # A value from Cuffey and Patterson (Physics of Glaciers, Appendix B)
    n_exponent = 3     # n value
    m_exponent = 0
    activation_energy = 0
  [../]
  [./density_ice]
    # Defines the density of concrete
    type = GenericConstantMaterial
    prop_names = density
    prop_values = 1 # kg/m^3  (will be corrected in gravity)
  [../]
  # [./strain]
  #   type = ComputeFiniteStrain
  #   eigenstrain_names = ini_stress
  # [../]
  [./strain_from_initial_stress]
    type = ComputeEigenstrainFromInitialStress
    # initial_stress = '0 0 0  0 0 0  0 0 weight'
    initial_stress = '0 0 0  0 0 0  0 0 0'
    eigenstrain_name = ini_stress
  [../]
[]



[Preconditioning]
  [./smp]
    type = SMP
    full = true
  [../]
[]

[Executioner]
  type = Transient

  l_max_its  = 50
  l_tol      = 1e-5
  nl_max_its = 50
  nl_rel_tol = 1e-5
  nl_abs_tol = 1e-5

  dtmin = 0
  dtmax = 1
  end_time = 50
  [./TimeStepper]
    type = ConstantDT
    dt = 1
  [../]
[]

[Outputs]
  file_base = a
  exodus = true
#  csv    = true
[]
