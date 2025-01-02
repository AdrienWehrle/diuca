length = 500.
thickness = 100.

[Mesh]
  [pcg1]
    type = ParsedCurveGenerator
    x_formula = 't'
    y_formula = 'thickness - 0.05 * t'
    constant_names = 'length thickness'
    constant_expressions = '${length} ${thickness}'
    section_bounding_t_values = '0 ${length}'
    nums_segments = 7
  []
  [pcg2]
    type = ParsedCurveGenerator
    x_formula = 't'
    y_formula = '0 - 0.05 * t'
    constant_names = 'length thickness'
    constant_expressions = '${length} ${thickness}'
    section_bounding_t_values = '0 ${length}'
    nums_segments = 7
  []
  [fbcg]
    type = FillBetweenCurvesGenerator
    input_mesh_1 = pcg1
    input_mesh_2 = pcg2
    num_layers = 3
    bias_parameter = 0.0
    begin_side_boundary_id = 0
  []

  [add_bottom]
    type = ParsedGenerateNodeset
    input = fbcg
    expression = 'y = 0 - 0.05 * x'
    new_nodeset_name = 'bottom'
  []
  [add_top]
    type = ParsedGenerateNodeset
    input = add_bottom
    expression = 'y = thickness - 0.05 * x'
    constant_names = 'thickness'
    constant_expressions = '${thickness}'
    new_nodeset_name = 'top'
  []
  [add_left]
    type = ParsedGenerateNodeset
    input = add_top
    expression = 'x = 0'
    new_nodeset_name = 'left'
  []
  [add_right]
    type = ParsedGenerateNodeset
    input = add_left
    expression = 'x = length'
    constant_names = 'length'
    constant_expressions = '${length}'
    new_nodeset_name = 'right'
  []
  # [add_bottom]
  #   type = BoundingBoxNodeSetGenerator
  #   input = 'fbcg'
  #   bottom_left = '0 -1 0'
  #   top_right = '500 0 0'
  #   new_boundary = 'bottom'
  # []
  # [add_nodesets]
  #   type = NodeSetsFromSideSetsGenerator
  #   input = fbcg
  # []
  # [create_sideset]
  #   type = SideSetsFromNodeSetsGenerator
  #   input = fbcg
  # []

[]

[Variables]
  [./T]
  [../]
[]

[Kernels]
  [./HeatDiff]
    type = ADMatDiffusion
    variable = T
    diffusivity = diffusivity
  [../]
[]

[BCs]
  [zero]
    type = DirichletBC
    variable = T
    boundary = 'bottom left right'
    value = 0
  []
  [./top]
    type = ADFunctionDirichletBC
    variable = T
    boundary = 'top'
    function = '10*sin(pi*x*0.5)'
  [../]
[]

[Materials]
  [./k]
    type = ADGenericConstantMaterial
    prop_names = diffusivity
    prop_values = 1
  [../]
[]


[Executioner]
  type = Steady
[]

[Outputs]
  exodus = true
[]
