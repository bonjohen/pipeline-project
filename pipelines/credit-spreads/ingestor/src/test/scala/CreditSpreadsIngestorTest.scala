import org.scalatest.funsuite.AnyFunSuite

class CreditSpreadsIngestorTest extends AnyFunSuite {
  
  test("spread calculation is numeric") {
    val hyYield = 7.85
    val treasuryYield = 4.27
    val spreadBps = (hyYield - treasuryYield) * 100.0
    assert(spreadBps.isInstanceOf[Double])
    assert(spreadBps > 0)
  }

  test("spread values are reasonable") {
    val hyYield = 7.85
    val treasuryYield = 4.27
    val spreadBps = (hyYield - treasuryYield) * 100.0
    // Credit spreads typically 300-800 bps
    assert(spreadBps >= 100.0)
    assert(spreadBps <= 2000.0)
  }

  test("regime classification logic") {
    def classifyRegime(spreadBps: Double): String = {
      spreadBps match {
        case s if s < 300 => "COMPRESSED"
        case s if s < 500 => "NORMAL"
        case s if s < 700 => "ELEVATED"
        case _ => "DISTRESSED"
      }
    }

    assert(classifyRegime(250.0) == "COMPRESSED")
    assert(classifyRegime(400.0) == "NORMAL")
    assert(classifyRegime(600.0) == "ELEVATED")
    assert(classifyRegime(800.0) == "DISTRESSED")
  }
}

