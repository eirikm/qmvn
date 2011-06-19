require "test/unit"

class QmvnTest < Test::Unit::TestCase

  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    # Do nothing
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_output_is_as_expected
    assert_output_equals_reference('mvn_clean_install')
    assert_output_equals_reference('mvn_clean_install_compile_error')
    assert_output_equals_reference('mvn_clean_install_test_error')
    assert_output_equals_reference('mvn_clean_install_test_failure')
  end

  def assert_output_equals_reference(name)
    ref_data = "testdata/#{name}.ref"
    input_data = "testdata/#{name}.mvn_output"
    expected_output = IO.read(ref_data)

    actual_output = `./qmvn.rb #{input_data}`
    assert_equal expected_output, actual_output
  end
end