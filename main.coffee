WIDTH = 500
HEIGHT = 300

## shader sources
vertexShaderSource = """
attribute vec3 position;
attribute vec4 color;
uniform   mat4 mvpMatrix;
varying   vec4 vColor;

void main(void){
    vColor = color;
    gl_Position = mvpMatrix * vec4(position, 1.0);
}
"""

fragmentShaderSource = """
precision mediump float;
varying vec4 vColor;
void main(void){
    gl_FragColor = vColor;
}
"""

## vertex position
vertexPosition = new Float32Array [
  0.0, 1.0, 0.0,
  1.0, 0.0, 0.0,
  -1.0, 0.0, 0.0
]

vertexColor = new Float32Array [
  1.0, 0.0, 0.0, 1.0,
  0.0, 1.0, 0.0, 1.0,
  0.0, 0.0, 1.0, 1.0
]

# load and compile shader by gl context
loadShader = (gl, type, source) ->
  shader = gl.createShader type
  gl.shaderSource shader, source
  gl.compileShader shader
  unless gl.getShaderParameter shader, gl.COMPILE_STATUS
    throw new Error gl.getShaderInfoLog(shader)
  shader

# link vertexshader and fragmentshader
createProgram = (gl, vs, fs) ->
  # link vertex and fragment
  program = gl.createProgram()
  gl.attachShader(program, vs)
  gl.attachShader(program, fs)
  gl.linkProgram(program)

  # check link status
  unless gl.getProgramParameter(program, gl.LINK_STATUS)
    throw new Error gl.getProgramInfoLog(program)

  # activate
  gl.useProgram(program)
  program

createVBO = (gl, data)->
  vbo = gl.createBuffer()
  gl.bindBuffer gl.ARRAY_BUFFER, vbo
  gl.bufferData(gl.ARRAY_BUFFER, data, gl.STATIC_DRAW)
  gl.bindBuffer(gl.ARRAY_BUFFER, null)
  vbo

addAttribute = (gl, program, vbo, name, type, argsCount ) ->
  gl.bindBuffer(gl.ARRAY_BUFFER, vbo)
  attr = gl.getAttribLocation(program, name)
  gl.enableVertexAttribArray(attr)
  gl.vertexAttribPointer(attr, argsCount, type, false, 0, 0)

window.addEventListener 'load', ->
  # prepare canvas element
  canvas = document.createElement 'canvas'
  document.body.appendChild canvas

  canvas.width = WIDTH
  canvas.height = HEIGHT

  # create canvas context
  gl = canvas.getContext('webgl')
  gl.clearColor(0.0, 0.0, 0.0, 1.0)
  gl.clearDepth(1.0)
  gl.clear(gl.COLOR_BUFFER_BIT)

  # load shaders
  vertexShader = loadShader gl, gl.VERTEX_SHADER, vertexShaderSource
  fragmentShader = loadShader gl, gl.FRAGMENT_SHADER, fragmentShaderSource

  program = createProgram gl, vertexShader, fragmentShader

  positionVBO = createVBO gl, vertexPosition
  colorVBO = createVBO gl, vertexColor

  ## prepare position attribute
  # addAttribute(gl, program, positionVBO, 'position', gl.FLOAT, 3)
  gl.bindBuffer(gl.ARRAY_BUFFER, positionVBO)
  attLocation = gl.getAttribLocation(program, 'position')
  gl.enableVertexAttribArray(attLocation)
  gl.vertexAttribPointer(attLocation, 3, gl.FLOAT, false, 0, 0)

  # prepare color attribute
  gl.bindBuffer(gl.ARRAY_BUFFER, colorVBO)
  attColor = gl.getAttribLocation(program, 'color')
  gl.enableVertexAttribArray(attColor)
  gl.vertexAttribPointer(attColor, 4, gl.FLOAT, false, 0, 0)

  # create mvpMatrix
  m = new matIV()
  mMatrix = m.identity(m.create())
  vMatrix = m.identity(m.create())
  pMatrix = m.identity(m.create())
  mvpMatrix = m.identity(m.create())
  m.lookAt([0.0, 1.0, 3.0], [0, 0, 0], [0, 1, 0], vMatrix)
  m.perspective(90, WIDTH / HEIGHT, 0.1, 100, pMatrix)
  m.multiply(pMatrix, vMatrix, mvpMatrix)
  m.multiply(mvpMatrix, mMatrix, mvpMatrix)

  # register mvpMatrix as uniform
  uniLocation = gl.getUniformLocation(program, 'mvpMatrix')
  gl.uniformMatrix4fv(uniLocation, false, mvpMatrix)

  gl.drawArrays(gl.TRIANGLES, 0, 3)
  gl.flush()
