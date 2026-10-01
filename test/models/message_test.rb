require "test_helper"

class MessageTest < ActiveSupport::TestCase
  test "staff messages require a user" do
    message = conversations(:ali_open).messages.build(direction: :outbound, sender_type: :staff, body: "Hi")
    assert_not message.valid?
    assert_includes message.errors[:user], "can't be blank"
  end
end
