import org.scalatest.funsuite.AnyFunSuite

class RepoStressJobTest extends AnyFunSuite {
  
  test("SOFR spread calculation") {
    val sofr = 4.57
    val fedUpper = 4.75
    val fedLower = 4.50
    val fedTarget = (fedUpper + fedLower) / 2.0
    val spreadBps = (sofr - fedTarget) * 100.0
    assert(Math.abs(spreadBps - (-5.5)) < 0.01) // Allow for floating point precision
  }

  test("spike detection logic") {
    def detectSpike(spreadBps: Double): Boolean = {
      Math.abs(spreadBps) > 25.0
    }

    assert(!detectSpike(10.0))
    assert(!detectSpike(25.0))
    assert(detectSpike(30.0))
    assert(detectSpike(-30.0))
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
    assert(classifyStress(-5.0) == "NORMAL")
    assert(classifyStress(20.0) == "ELEVATED")
    assert(classifyStress(40.0) == "STRESS")
    assert(classifyStress(60.0) == "SEVERE_STRESS")
  }

  test("handles zero values correctly") {
    val sofr = 0.0
    val fedTarget = 4.50
    val spreadBps = if (sofr > 0 && fedTarget > 0) (sofr - fedTarget) * 100.0 else 0.0
    assert(spreadBps == 0.0)
  }
}

