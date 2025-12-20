import org.scalatest.funsuite.AnyFunSuite

class CreditSpreadsJobTest extends AnyFunSuite {
  
  test("credit spread calculation") {
    val hyYield = 7.85
    val treasuryYield = 4.27
    val spreadBps = (hyYield - treasuryYield) * 100.0
    assert(spreadBps == 358.0)
  }

  test("regime classification") {
    def classifyRegime(spreadBps: Double): String = {
      spreadBps match {
        case s if s < 300 => "COMPRESSED"
        case s if s < 500 => "NORMAL"
        case s if s < 700 => "ELEVATED"
        case _ => "DISTRESSED"
      }
    }

    assert(classifyRegime(250.0) == "COMPRESSED")
    assert(classifyRegime(358.0) == "NORMAL")
    assert(classifyRegime(650.0) == "ELEVATED")
    assert(classifyRegime(900.0) == "DISTRESSED")
  }

  test("stress level classification") {
    def classifyStress(spreadBps: Double): String = {
      spreadBps match {
        case s if s < 400 => "LOW"
        case s if s < 600 => "MODERATE"
        case s if s < 800 => "HIGH"
        case _ => "EXTREME"
      }
    }

    assert(classifyStress(350.0) == "LOW")
    assert(classifyStress(500.0) == "MODERATE")
    assert(classifyStress(700.0) == "HIGH")
    assert(classifyStress(900.0) == "EXTREME")
  }
}

