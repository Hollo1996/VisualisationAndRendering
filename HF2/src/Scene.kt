import org.w3c.dom.HTMLCanvasElement
import org.khronos.webgl.WebGLRenderingContext as GL
import vision.gears.webglmath.UniformProvider
import vision.gears.webglmath.Vec3
import vision.gears.webglmath.Vec4
import vision.gears.webglmath.Mat4
import vision.gears.webglmath.SamplerCube
import vision.gears.webglmath.Mat4Array
import vision.gears.webglmath.Vec4Array
import kotlin.js.Date

class Scene (
  val gl : WebGL2RenderingContext) : UniformProvider("scene"){

  val vsQuad = Shader(gl, GL.VERTEX_SHADER, "shaders/quad-vs.glsl")
  val fsTrace = Shader(gl, GL.FRAGMENT_SHADER, "shaders/trace-fs.glsl")  
  val traceProgram = Program(gl, vsQuad, fsTrace)
  val quadGeometry = TexturedQuadGeometry(gl)  

  val timeAtFirstFrame = Date().getTime()
  var timeAtLastFrame =  timeAtFirstFrame

  val camera = PerspectiveCamera(*Program.all)

  val quadrics= Array<Quadric>(5){ 
    Quadric(it,*Program.all) 
  }
  init{
    quadrics[0].surface.set(Quadric.origoPlanesY)
    quadrics[0].surface.translate(0.0f,-2.0f,0.0f)
    quadrics[0].clipper.set(Quadric.none)

    quadrics[0].materialIndex.set(0.0f)

    quadrics[1].surface.set(Quadric.paraboloid)
    quadrics[1].surface.scale(2.0f,2.0f,2.0f)
    quadrics[1].surface.translate(0.0f,2.0f,0.0f)
    quadrics[1].clipper.set(Quadric.sphere)
    quadrics[1].clipper.scale(8.0f,8.0f,8.0f)
    quadrics[1].clipper.translate(0.0f,8.0f,0.0f)

    quadrics[1].materialIndex.set(0.0f)

    quadrics[2].surface.set(Quadric.sphere)
    quadrics[2].surface.scale(2.0f,2.0f,2.0f)
    quadrics[2].surface.translate(5.0f,1.1f,5.0f)
    quadrics[2].clipper.set(Quadric.none)

    quadrics[2].materialIndex.set(1.0f)

    quadrics[3].surface.set(Quadric.cylinder)
    quadrics[3].surface.scale(2.0f,2.0f,2.0f)
    quadrics[3].surface.translate(-5.0f,1.1f,-5.0f)
    quadrics[3].clipper.set(Quadric.origoPlanesY)
    quadrics[3].clipper.scale(2.0f,-6.0f,2.0f)
    quadrics[3].materialIndex.set(2.0f)

    quadrics[4].surface.set(Quadric.origoPlanesY)
    quadrics[4].surface.scale(2.0f,-6.0f,2.0f)
    quadrics[4].clipper.set(Quadric.cylinder)
    quadrics[4].clipper.scale(2.0f,2.0f,2.0f)
    quadrics[4].clipper.translate(-5.0f,1.1f,-5.0f)
    quadrics[4].materialIndex.set(2.0f)
    
    /*quadrics[1].surface.set(Quadric.hyperbolicParaboloid)
    quadrics[1].surface.translate(0.0f,1.1f,0.0f)
    quadrics[1].clipper.set(Quadric.sphere)
    quadrics[1].clipper.scale(2.0f,2.0f,2.0f)
    quadrics[1].clipper.translate(0.0f,1.1f,0.0f)

    quadrics[1].materialIndex.set(0.0f)
    
    quadrics[2].surface.set(Quadric.sphere)
    quadrics[2].surface.scale(2.0f,2.0f,2.0f)
    quadrics[2].surface.translate(0.0f,1.1f,0.0f)
    quadrics[2].clipper.set(Quadric.hyperbolicParaboloid)
    quadrics[2].clipper.scale(-1.0f,1.0f,-1.0f)
    quadrics[2].clipper.translate(0.0f,1.1f,0.0f)

    quadrics[2].materialIndex.set(0.0f)*/
  }

  val lights= Array<Light>(3){ 
    Light(it,*Program.all) 
  }
  init {
    lights[0].position.set(1.0f,1.0f,-1.0f,0.0f).normalize()
    lights[0].powerDensity.set(1.0f,1.0f,1.0f)
    lights[1].position.set(-1.0f,10.0f,1.0f,1.0f)
    lights[1].powerDensity.set(100.0f,100.0f,100.0f)
    lights[2].position.set(-1.0f,10.0f,-1.0f,1.0f)
    lights[2].powerDensity.set(100.0f,100.0f,100.0f)
  }

  val materials= Array<Material>(3){ 
    Material(it,*Program.all) 
  }
  init {
    //gold
    materials[0].kd.set(0.0f,0.0f,0.0f)
    materials[0].ks.set(1.0f,0.7f,0.0f)
    materials[0].indexOfRefraction.set(0.16f,0.34f,1.65f)
    materials[0].extinctionCoefficient.set(4.58f,2.71f,1.95f)
    materials[0].shininess.set(14.0f)
    //glass
    materials[1].kd.set(0.1f, 0.1f, 0.1f)
    materials[1].ks.set(0.5f, 0.5f, 0.5f)
    materials[1].indexOfRefraction.set(1.2f, 1.2f, 1.2f)
    materials[1].extinctionCoefficient.set(0.000000001f, 0.000000001f, 0.000000001f)
    materials[1].shininess.set(20.0f)
    //plastic
    materials[2].kd.set(0.0f,1.0f,0.0f)
    materials[2].ks.set(0.0f, 0.0f, 0.0f)
    materials[2].indexOfRefraction.set(0.16f,0.34f,1.65f)
    materials[2].extinctionCoefficient.set(4.58f,2.71f,1.95f)
    materials[2].shininess.set(1.0f)

  }

  val envTexture = TextureCube(gl,
    "media/posx.jpg",
    "media/negx.jpg",
    "media/posy.jpg",
    "media/negy.jpg",
    "media/posz.jpg",
    "media/negz.jpg"
  )
  val env by SamplerCube()

  init{
    env.set(envTexture)
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
    val t  = (timeAtThisFrame - timeAtFirstFrame).toFloat() / 1000.0f    
    timeAtLastFrame = timeAtThisFrame
    
    camera.move(dt, keysPressed)

    // clear the screen
    gl.clearColor(0.7f, 0.0f, 0.3f, 1.0f)
    gl.clearDepth(1.0f)
    gl.clear(GL.COLOR_BUFFER_BIT or GL.DEPTH_BUFFER_BIT)
    
    traceProgram.draw(this, camera, *quadrics, *lights, *materials)
    quadGeometry.draw()    
  }
}
