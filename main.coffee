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
  0.0, 1.0, 1.0,
  1.0, 0.0, 1.0,
  -1.0, 0.0, 1.0
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

addAttribute = (gl, program, vbo, name, argsCount, type = gl.FLOAT ) ->
  gl.bindBuffer(gl.ARRAY_BUFFER, vbo)
  attr = gl.getAttribLocation(program, name)
  gl.enableVertexAttribArray(attr)
  gl.vertexAttribPointer(attr, argsCount, type, false, 0, 0)

draw = (gl, locationUniform, mvpMatrix) ->
  gl.uniformMatrix4fv(locationUniform, false, mvpMatrix)
  gl.drawArrays(gl.TRIANGLES, 0, 3)

# loop property
count = 0

# matrix buffers
m = new matIV()
mMatrix   = m.identity(m.create())
vMatrix   = m.identity(m.create())
pMatrix   = m.identity(m.create())
tmpMatrix = m.identity(m.create())
mvpMatrix = m.identity(m.create())

# setup camera
m.lookAt([0.0, 0.0, 3.0], [0, 0, 0], [0, 1, 0], vMatrix)
m.perspective(90, WIDTH / HEIGHT, 0.1, 100, pMatrix)
m.multiply(pMatrix, vMatrix, tmpMatrix)

startLoop = (gl) ->
  # load shaders
  vertexShader = loadShader gl, gl.VERTEX_SHADER, vertexShaderSource
  fragmentShader = loadShader gl, gl.FRAGMENT_SHADER, fragmentShaderSource
  program = createProgram gl, vertexShader, fragmentShader

  # uniform
  locationUniform = gl.getUniformLocation(program, 'mvpMatrix')

  # prepare position attribute
  positionVBO = createVBO gl, vertexPosition
  addAttribute(gl, program, positionVBO, 'position', 3)

  # prepare color attribute
  colorVBO = createVBO gl, vertexColor
  addAttribute(gl, program, colorVBO, 'color', 4)

  do update = ->
    count++
    # if (count % 15) isnt 0 then return do update

    gl.clearColor(0.0, 0.0, 0.0, 1.0)
    gl.clearDepth(1.0)
    gl.clear(gl.COLOR_BUFFER_BIT)

    rad = (count % 360) * Math.PI / 180

    # Draw 1st item
    x = Math.cos(rad)
    y = Math.sin(rad)

    m.identity(mMatrix)
    m.translate(mMatrix, [x, y, 0.0], mMatrix)
    m.multiply(tmpMatrix, mMatrix, mvpMatrix)
    draw(gl, locationUniform, mvpMatrix)

    # Draw 2nd item
    x = Math.sin(rad)
    y = Math.cos(rad)
    scaleRate = Math.sin(rad)

    m.identity(mMatrix)
    m.translate(mMatrix, [x-1.5, y, 0.0], mMatrix)
    m.scale(mMatrix, [scaleRate, scaleRate, 0.0], mMatrix)
    m.multiply(tmpMatrix, mMatrix, mvpMatrix)
    draw(gl, locationUniform, mvpMatrix)

    gl.flush()
    requestAnimationFrame update

window.addEventListener 'load', ->
  canvas = document.createElement 'canvas'
  document.body.appendChild canvas
  canvas.width  = WIDTH
  canvas.height = HEIGHT

  gl = canvas.getContext('webgl')
  startLoop(gl)
