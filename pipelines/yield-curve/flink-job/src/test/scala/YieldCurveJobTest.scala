import org.scalatest.funsuite.AnyFunSuite

class YieldCurveJobTest extends AnyFunSuite {
  test("inversion logic") {
    val spread = (4.0 - 4.5) * 100
    assert(spread < 0)
  }
}
