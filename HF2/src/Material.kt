import vision.gears.webglmath.Mat4
import vision.gears.webglmath.Vec4
import vision.gears.webglmath.Vec3
import vision.gears.webglmath.Vec2
import vision.gears.webglmath.Vec1
import vision.gears.webglmath.UniformProvider

class Material(
    id : Int,
    vararg programs : Program
  ) : UniformProvider("materials[$id]") {
    
    val kd by Vec3(1.0f, 1.0f, 1.0f)
    val ks by Vec3(1.0f, 1.0f, 1.0f)
    //törési tényező
    val indexOfRefraction by Vec3(1.0f, 1.0f, 1.0f)
    //elnyelési tényező
    //fresnell
    val extinctionCoefficient by Vec3(0.5f, 0.5f, 0.5f)
    //fényesség
    val shininess by Vec1(1.0f)

    init{
        addComponentsAndGatherUniforms(*programs)
    }

}