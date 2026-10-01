require "test_helper"

class ContactTest < ActiveSupport::TestCase
  test "normalizes phone to digits" do
    assert_equal "923009998877", Contact.new(phone: "+92 300 999-8877").phone
  end

  test "display name falls back to profile name then phone" do
    assert_equal "Ali Khan", contacts(:ali).display_name
    assert_equal "+123", Contact.new(phone: "123").display_name
  end
end
