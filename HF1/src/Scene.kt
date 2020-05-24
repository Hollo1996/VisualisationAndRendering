import org.w3c.dom.HTMLCanvasElement
import org.khronos.webgl.WebGLRenderingContext as GL
import vision.gears.webglmath.UniformProvider
import vision.gears.webglmath.Vec3
import vision.gears.webglmath.Mat4
import kotlin.js.Date
import Texture3D
import Texture2D
import vision.gears.webglmath.Sampler3D
import vision.gears.webglmath.Sampler2D

class Scene (
  val gl : WebGL2RenderingContext) : UniformProvider("scene"){

  val vsQuad = Shader(gl, GL.VERTEX_SHADER, "shaders/quad-vs.glsl")
  val fsTrace = Shader(gl, GL.FRAGMENT_SHADER, "shaders/trace-fs.glsl")  
  val traceProgram = Program(gl, vsQuad, fsTrace, Program.PNT)
  val quadGeometry = TexturedQuadGeometry(gl)  

  val timeAtFirstFrame = Date().getTime()
  var timeAtLastFrame =  timeAtFirstFrame

  val camera = PerspectiveCamera(*Program.all)
  val volumeTexture = Texture3D(gl, "media/brain-at_4096.jpg")
  val volume = Sampler3D()
  val matcapTexture = Texture2D(gl, "media/matcap.jpg")
  val matcap = Sampler2D()

  init {
    register("volume", volume)
    volume.glTextures[0] = volumeTexture.glTexture
    register("matcap", matcap)
    matcap.glTextures[0] = matcapTexture.glTexture
    addComponentsAndGatherUniforms(*Program.all)
  }

  fun resize(gl : WebGL2RenderingContext, canvas : HTMLCanvasElement) {
    gl.viewport(0, 0, canvas.width, canvas.height)
    camera.setAspectRatio(canvas.width.toFloat() / canvas.height.toFloat())
  }

  @Suppress("UNUSED_PARAMETER")
  fun update(gl : WebGL2RenderingContext, keysPressed : Set<String>) {

    val timeAtThisFrame = Date().getTime()
    val dt = (timeAtThisFrame - timeAtLastFrame).toFloat() / 1000.0f
    val t = (timeAtThisFrame - timeAtFirstFrame).toFloat() / 1000.0f
    timeAtLastFrame = timeAtThisFrame
    camera.move(dt, keysPressed)

    // clear the screen
    gl.clearColor(1.0f, 0.0f, 0.0f, 1.0f)
    gl.clearDepth(1.0f)
    gl.clear(GL.COLOR_BUFFER_BIT or GL.DEPTH_BUFFER_BIT)
    
    traceProgram.draw(this, camera)
    quadGeometry.draw()    
  }
}
