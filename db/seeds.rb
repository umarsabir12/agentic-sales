# Development seed data. Safe to run multiple times.

admin = User.find_or_create_by!(email: "admin@example.com") do |u|
  u.name = "Admin"
  u.password = "password"
  u.role = :admin
end

rep = User.find_or_create_by!(email: "sales@example.com") do |u|
  u.name = "Sara Sales"
  u.password = "password"
  u.role = :agent
end

return unless Rails.env.development?

ali = Contact.find_or_create_by!(phone: "923001234567") { |c| c.profile_name = "Ali Khan" }
maria = Contact.find_or_create_by!(phone: "447700900123") { |c| c.profile_name = "Maria" }

if ali.conversations.none?
  convo = ali.conversations.create!
  convo.messages.create!(direction: :inbound, sender_type: :customer, body: "Hi, do you have the solar inverter in 5kW?")
  convo.messages.create!(direction: :outbound, sender_type: :ai, delivery_status: :read, body: "Hi Ali! Yes, the 5kW hybrid inverter is in stock. Is this for a home or business installation?")
  convo.messages.create!(direction: :inbound, sender_type: :customer, body: "Home. Budget is around 300k PKR. Can someone call me?")
  ali.tickets.create!(conversation: convo, title: "5kW hybrid inverter – home install", product_interest: "5kW hybrid inverter",
                      budget: "300,000 PKR", value: 300_000, priority: :high, summary: "Customer wants a home installation and requested a call back.")
end

if maria.conversations.none?
  convo = maria.conversations.create!
  convo.messages.create!(direction: :inbound, sender_type: :customer, body: "What are your opening hours?")
  convo.messages.create!(direction: :outbound, sender_type: :ai, delivery_status: :delivered, body: "We're open Monday to Saturday, 9am–6pm.")
  convo.messages.create!(direction: :inbound, sender_type: :customer, body: "I'd like a quote for 20 units for my shop.")
  convo.take_over!(rep)
  convo.messages.create!(direction: :outbound, sender_type: :staff, user: rep, delivery_status: :sent, body: "Hi Maria, I'm Sara from sales. Which model are you interested in?")
  maria.tickets.create!(conversation: convo, assignee: rep, status: :in_progress, title: "Bulk quote – 20 units", value: 1_200_000, priority: :medium)
end

puts "Seeded. Sign in as #{admin.email} / password"
