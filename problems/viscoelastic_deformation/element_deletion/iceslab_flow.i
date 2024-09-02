# we use a unit system adapted to glaciology: 
#
# stress : MPa
# time:    year
# length:  m
#
# such that rho*g = 0.008829  MPa m^{-1}
# (with rho rho=917 and g=9.81e-06)


# ------------------------ 

# geometry of the ice slab
length = 5000
thickness = 1000
width = 2500

bed_elevation=-900
surface_elevation='${fparse bed_elevation + thickness}'
#  geometry of the ice slab
# length = 1000
# thickness = 200

[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
  use_displaced_mesh = true
[]

[Mesh]
  [glacier]
    type = GeneratedMeshGenerator
    dim = 3
    xmin = 0
    xmax = '${length}'
    ymin = 0
    ymax = '${width}'
    zmin = '${bed_elevation}'
    zmax = '${surface_elevation}'
    nx = 10
    ny = 5
    nz = 5
  []
[]

[Modules]
    [TensorMechanics]
      [Master]
        [all]
          strain = FINITE
          incremental = true
          add_variables = true
          generate_output = 'stress_xx stress_yy stress_zz
                             strain_xx strain_yy strain_zz'
          eigenstrain_names = ini_stress
        []
      []
    []
[]

[Functions]
  [ocean_pressure]
    type = ParsedFunction
    expression = 'if(z < 0, -1028*9.81*1e-6 * z, 0)'
  []
[]

[Functions]
  [weight]
    type = ParsedFunction
    expression = '917*-9.81e-06*(surface_elevation-z)' # initial stress that should result from the weight force
    symbol_names = 'surface_elevation'
    symbol_values = '${surface_elevation}'
  []
[]

[BCs]
  [anchor_x]
    type = DirichletBC
    variable = disp_x
    boundary = 'bottom top left back' 
    value = 0
  []
  [anchor_y]
    type = DirichletBC
    variable = disp_y
    boundary = 'bottom top left back'
    value = 0
  []
  [anchor_z]
    type = DirichletBC
    variable = disp_z
    boundary = 'back bottom top left' # back is bed
    value = 0
  []

  # [inlet]
  #   type = DirichletBC
  #   variable = disp_x
  #   boundary = 'left' 
  #   value = 0. # equivalent to 0.1mh-1
  # []
  [Pressure]
    [downstream_pressure]  
      boundary = 'right'
      function = ocean_pressure
      displacements = 'disp_x disp_y disp_z'
    []
  []
  
[]

[Kernels]
  [gravity_x]
    type = Gravity
    variable = disp_x
    value= 0.
  []
  [gravity_y]
    type = Gravity
    variable = disp_y
    value = 0.
  []
  [gravity_z]
    type = Gravity
    variable = disp_z
    value =-9.81e-06
  []
[]

[AuxKernels]
  [accel_x]
    type = NewmarkAccelAux
    variable = accel_x
    displacement = disp_x
    velocity = vel_x
    beta=0.25
    execute_on = timestep_end
  []
  [vel_x]
    type = NewmarkVelAux
    variable = vel_x
    acceleration = accel_x
    gamma=0.5
    execute_on = timestep_end
  []
  [accel_y]
    type = NewmarkAccelAux
    variable = accel_y
    displacement = disp_y
    velocity = vel_y
    beta=0.25
    execute_on = timestep_end
  []
  [vel_y]
    type = NewmarkVelAux
    variable = vel_y
    acceleration = accel_y
    gamma=0.5
    execute_on = timestep_end
  []
  [accel_z]
    type = NewmarkAccelAux
    variable = accel_z
    displacement = disp_z
    velocity = vel_z
    beta=0.25
    execute_on = timestep_end
  []
  [vel_z]
    type = NewmarkVelAux
    variable = vel_z
    acceleration = accel_z
    gamma=0.5
    execute_on = timestep_end
  []
[]

[AuxVariables]
  [vel_x]
  []
  [accel_x]
  []
  [vel_y]
  []
  [accel_y]
  []
  [vel_z]
  []
  [accel_z]
  []
[]

[Materials]
  [elasticity_tensor]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 8.7e3     # values from Hutter 1983 (Physics of Glaciers)
    poissons_ratio = 0.31      # values from Hutter 1983 (Physics of Glaciers)
  []
  [creep_plas]
    type = ComputeMultipleInelasticStress
    tangent_operator = elastic
    inelastic_models = 'creep'
    max_iterations = 50
    absolute_tolerance = 1e-07
    combined_inelastic_strain_weights = '1'
  []
  [creep]
    type = PowerLawCreepStressUpdate
    coefficient = 75e-1   # A value from Cuffey and Patterson (Physics of Glaciers, Appendix B)
    n_exponent = 3     # n value
    m_exponent = 0
    activation_energy = 0
  []
  [density_ice]
    # Defines the density of concrete
    type = GenericConstantMaterial
    prop_names = density
    prop_values = 917 # kg/m^3
  []
  # [strain]
  #   type = ComputeFiniteStrain
  #   eigenstrain_names = ini_stress
  # []
  [strain_from_initial_stress]
    type = ComputeEigenstrainFromInitialStress
    initial_stress = '0 0 0  0 0 0  0 0 weight'
    # initial_stress = '0 0 0  0 0 0  0 0 0'
    eigenstrain_name = ini_stress
  []
[]

# [Controls]
#   [inertia_switch]
#     type = TimePeriod
#     start_time = 0.0
#     end_time = 0.003
#     disable_objects = '*/vel_x */vel_y */vel_z
#                        */accel_x */accel_y */accel_z'
#     set_sync_times = true
#     execute_on = 'timestep_begin timestep_end'
#   []  
# []


[Preconditioning]
  [smp]
    type = SMP
    full = true
  []
[]

[Executioner]
  type = Transient

  l_max_its  = 50
  l_tol      = 1e-5
  nl_max_its = 50
  nl_rel_tol = 1e-5
  nl_abs_tol = 1e-5

  # dt = 0.01
  # dtmin = 0
  # dtmax = 1
  end_time = 100
  # [TimeStepper]
  #   type = ConstantDT
  #   dt = 1
  # []

  [TimeStepper]
    type = IterationAdaptiveDT
    optimal_iterations = 1
    linear_iteration_ratio = 1
    dt = 0.01
  []
[]

[Outputs]
  file_base = a
  exodus = true
#  csv    = true
[]
