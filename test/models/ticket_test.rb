require "test_helper"

class TicketTest < ActiveSupport::TestCase
  test "sets and clears closed_at with status" do
    ticket = tickets(:ali_inverter)
    ticket.update!(status: :won)
    assert ticket.closed_at.present?

    ticket.update!(status: :open)
    assert_nil ticket.closed_at
  end
end
