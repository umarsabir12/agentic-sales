require "test_helper"

class ContactTest < ActiveSupport::TestCase
  test "normalizes phone to digits" do
    assert_equal "923009998877", Contact.new(phone: "+92 300 999-8877").phone
  end

  test "display name falls back to profile name then phone" do
    assert_equal "Ali Khan", contacts(:ali).display_name
    assert_equal "+123", Contact.new(phone: "123").display_name
  end

  test "drops the 00 international prefix and requires a country code" do
    assert_equal "971501234567", Contact.new(phone: "00971 50 123 4567").phone
    assert_not Contact.new(phone: "03001234567").valid?
  end

  test "avatar letter falls back when there is no name" do
    assert_equal "A", contacts(:ali).avatar_letter
    assert_equal "#", Contact.new(phone: "923001234567").avatar_letter
  end
end
