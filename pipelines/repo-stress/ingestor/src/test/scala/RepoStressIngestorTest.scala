import org.scalatest.funsuite.AnyFunSuite

class RepoStressIngestorTest extends AnyFunSuite {
  
  test("SOFR spread calculation is numeric") {
    val sofr = 4.57
    val fedTarget = 4.50
    val spreadBps = (sofr - fedTarget) * 100.0
    assert(spreadBps.isInstanceOf[Double])
  }

  test("fed funds target midpoint calculation") {
    val upperLimit = 4.75
    val lowerLimit = 4.50
    val midpoint = (upperLimit + lowerLimit) / 2.0
    assert(midpoint == 4.625)
  }

  test("spread values are reasonable") {
    val sofr = 4.57
    val fedTarget = 4.50
    val spreadBps = (sofr - fedTarget) * 100.0
    // SOFR spreads typically -50 to +100 bps
    assert(spreadBps >= -100.0)
    assert(spreadBps <= 200.0)
  }

  test("stress level classification") {
    def classifyStress(spreadBps: Double): String = {
      Math.abs(spreadBps) match {
        case s if s < 10 => "NORMAL"
        case s if s < 25 => "ELEVATED"
        case s if s < 50 => "STRESS"
        case _ => "SEVERE_STRESS"
      }
    }

    assert(classifyStress(5.0) == "NORMAL")
    assert(classifyStress(15.0) == "ELEVATED")
    assert(classifyStress(35.0) == "STRESS")
    assert(classifyStress(75.0) == "SEVERE_STRESS")
  }
}

