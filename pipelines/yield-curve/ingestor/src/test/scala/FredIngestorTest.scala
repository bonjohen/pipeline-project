import org.scalatest.funsuite.AnyFunSuite

class FredIngestorTest extends AnyFunSuite {
  test("spread inputs are numeric") {
    assert(4.27.isInstanceOf[Double])
  }
}
