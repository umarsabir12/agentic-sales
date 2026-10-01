require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "initials" do
    assert_equal "AU", users(:admin).initials
  end
end
