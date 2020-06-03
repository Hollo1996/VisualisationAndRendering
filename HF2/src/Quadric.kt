import vision.gears.webglmath.Mat4
import vision.gears.webglmath.Vec4
import vision.gears.webglmath.UniformProvider

class Quadric(
    id : Int,
    vararg programs : Program
  ) : UniformProvider("quadrics[$id]") {

    val surface by QuadraticMat4()
    val clipper by QuadraticMat4()
    val kd by Vec4(1.0f,1.0f,1.0f,0.0f)

  init{
    addComponentsAndGatherUniforms(*programs)
  }

  companion object {
    val sphere=QuadraticMat4(
      1.0f, 0.0f, 0.0f, 0.0f,
      0.0f, 1.0f, 0.0f, 0.0f,
      0.0f, 0.0f, 1.0f, 0.0f,
      0.0f, 0.0f, 0.0f, -1.0f
    )
    val paraboloid=QuadraticMat4(
      1.0f, 0.0f, 0.0f, 0.0f,
      0.0f, 0.0f, 0.0f, 0.0f,
      0.0f, 0.0f, 1.0f, 0.0f,
      0.0f, -1.0f, 0.0f, 0.0f
    )
    val hyperbolicParaboloid=QuadraticMat4(
      1.0f, 0.0f, 0.0f, 0.0f,
      0.0f, 0.0f, 0.0f, 0.0f,
      0.0f, 0.0f, -1.0f, 0.0f,
      0.0f, -1.0f, 0.0f, 0.0f
    )
    val hyperboloidOfOneSheet=QuadraticMat4(
      1.0f, 0.0f, 0.0f, 0.0f,
      0.0f, -1.0f, 0.0f, 0.0f,
      0.0f, 0.0f, 1.0f, 0.0f,
      0.0f, 0.0f, 0.0f, -1.0f
    )
    val hyperboloidOfTwoSheets=QuadraticMat4(
      1.0f, 0.0f, 0.0f, 0.0f,
      0.0f, -1.0f, 0.0f, 0.0f,
      0.0f, 0.0f, 1.0f, 0.0f,
      0.0f, 0.0f, 0.0f, 1.0f
    )
    val cone =QuadraticMat4(
      1.0f, 0.0f, 0.0f, 0.0f,
      0.0f, -1.0f, 0.0f, 0.0f,
      0.0f, 0.0f, 1.0f, 0.0f,
      0.0f, 0.0f, 0.0f, 0.0f
    )
    val cylinder =QuadraticMat4(
      1.0f, 0.0f, 0.0f, 0.0f,
      0.0f, 0.0f, 0.0f, 0.0f,
      0.0f, 0.0f, 1.0f, 0.0f,
      0.0f, 0.0f, 0.0f, -1.0f
    )
    val hyperbolicCylinder =QuadraticMat4(
      1.0f, 0.0f, 0.0f, 0.0f,
      0.0f, 0.0f, 0.0f, 0.0f,
      0.0f, 0.0f, -1.0f, 0.0f,
      0.0f, 0.0f, 0.0f, -1.0f
    )
    val parabolicCylinder =QuadraticMat4(
      1.0f, 0.0f, 0.0f, 0.0f,
      0.0f, 0.0f, 0.0f, 0.0f,
      0.0f, 0.0f, 0.0f, 0.0f,
      0.0f, 0.0f, 1.0f, 0.0f
    )
    val doublePlanesX =QuadraticMat4(
      1.0f, 0.0f, 0.0f, 0.0f,
      0.0f, 0.0f, 0.0f, 0.0f,
      0.0f, 0.0f, 0.0f, 0.0f,
      0.0f, 0.0f, 0.0f, -1.0f
    )
    val origoPlanesY =QuadraticMat4(
      0.0f, 0.0f, 0.0f, 0.0f,
      0.0f, 1.0f, 0.0f, 0.0f,
      0.0f, 0.0f, 0.0f, 0.0f,
      0.0f, 0.0f, 0.0f, -1.0f
    )
    val origoPlanesZ =QuadraticMat4(
      0.0f, 0.0f, 0.0f, 0.0f,
      0.0f, 0.0f, 0.0f, 0.0f,
      0.0f, 0.0f, 1.0f, 0.0f,
      0.0f, 0.0f, 0.0f, -1.0f
    )
    val none =QuadraticMat4(
      0.0f, 0.0f, 0.0f, 0.0f,
      0.0f, 0.0f, 0.0f, 0.0f,
      0.0f, 0.0f, 0.0f, 0.0f,
      0.0f, 0.0f, 0.0f, 0.0f
    )
  }
}
