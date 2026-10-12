# Demo data for trying the app on a fresh deploy.
#
#   bin/rails demo:seed    # create users, contacts, conversations, tickets
#   bin/rails demo:clear   # remove demo contacts (and their conversations/tickets)
#
# Outbound messages are never left "pending", so nothing is sent to WhatsApp.
# Phone numbers use fictional ranges (UK 07700 900xxx, US 555-01xx).
namespace :demo do
  DEMO_TAG = "[demo]".freeze

  desc "Create demo users, contacts, conversations and tickets"
  task seed: :environment do
    password = ENV["DEMO_PASSWORD"].presence || SecureRandom.base58(12)

    admin = User.find_or_create_by!(email: "admin@example.com") { |u| u.assign_attributes(name: "Admin", role: :admin, password:) }
    reps = [ [ "Sara Sales", "sara@example.com" ], [ "Bilal Ahmed", "bilal@example.com" ] ].map do |name, email|
      User.find_or_create_by!(email:) { |u| u.assign_attributes(name:, role: :agent, password:) }
    end

    # [name, phone, status, assignee, ticket, messages]; message ages are hours ago.
    scenarios = [
      [ "Ali Khan", "447700900101", :ai_active, nil,
        { title: "5kW hybrid inverter – home install", product_interest: "5kW hybrid inverter", budget: "300,000 PKR", value: 300_000, priority: :high },
        [ [ :in, "Hi, do you have the solar inverter in 5kW?", 3 ],
          [ :ai, "Hi Ali! Yes, the 5kW hybrid inverter is in stock. Is this for a home or business?", 2.9 ],
          [ :in, "Home. Budget is around 300k PKR. Can someone call me?", 2.5 ] ] ],
      [ "Maria Lopez", "447700900102", :human_active, 0,
        { title: "Bulk quote – 20 units", value: 1_200_000, status: :in_progress, priority: :medium },
        [ [ :in, "What are your opening hours?", 30 ],
          [ :ai, "We're open Monday to Saturday, 9am–6pm.", 29.9 ],
          [ :in, "I'd like a quote for 20 units for my shop.", 5 ],
          [ :staff, "Hi Maria, I'm Sara from sales. Which model are you interested in?", 4 ] ] ],
      [ "John Carter", "15555550103", :ai_active, nil, nil,
        [ [ :in, "Do you deliver to Lahore?", 1 ],
          [ :ai, "Yes! Delivery to Lahore takes 2–3 working days and is free over 50,000 PKR.", 0.9 ] ] ],
      [ "Ayesha Raza", "447700900104", :human_active, 1,
        { title: "Battery backup for clinic", product_interest: "Lithium battery 10kWh", budget: "800k", value: 800_000, status: :in_progress, priority: :urgent },
        [ [ :in, "Our clinic needs backup power urgently, load shedding is 6 hours a day.", 8 ],
          [ :ai, "Sorry to hear that. How many rooms and what equipment needs power?", 7.9 ],
          [ :in, "4 rooms, 2 fridges for vaccines, lights and fans.", 7 ],
          [ :staff, "Thanks Ayesha, I'll prepare a quote for a 10kWh system today.", 6 ] ] ],
      [ "Omar Farooq", "15555550105", :closed, 0,
        { title: "Solar panels – 10 units", value: 450_000, status: :won, priority: :medium },
        [ [ :in, "I want to confirm the order for 10 panels.", 72 ],
          [ :staff, "Confirmed! Installation is booked for Thursday.", 70 ] ] ],
      [ "Hina Malik", "447700900106", :closed, nil,
        { title: "Inverter price inquiry", value: 150_000, status: :lost, priority: :low },
        [ [ :in, "How much is the 3kW inverter?", 120 ],
          [ :ai, "The 3kW inverter is 150,000 PKR including installation.", 119.9 ],
          [ :in, "Too expensive, thanks.", 119 ] ] ],
      [ "David Kim", "15555550107", :ai_active, nil, nil,
        [ [ :in, "Hello, is anyone there?", 40 ],
          [ :ai, "Hi David! Yes, how can I help you today?", 39.9 ] ] ],
      [ "Fatima Noor", "447700900108", :ai_active, nil,
        { title: "Net metering consultation", product_interest: "Net metering", priority: :medium },
        [ [ :in, "Can you help with net metering approval?", 0.5 ] ] ]
    ]

    scenarios.each do |name, phone, status, rep_index, ticket_attrs, messages|
      contact = Contact.find_or_initialize_by(phone:)
      next puts("skip #{name} (exists)") if contact.persisted?

      contact.update!(profile_name: name, notes: "#{DEMO_TAG} Demo contact")
      rep = rep_index && reps[rep_index]
      start = messages.first.last.hours.ago
      convo = contact.conversations.create!(created_at: start)

      messages.each do |kind, body, hours|
        attrs = { body:, created_at: hours.hours.ago }
        attrs.merge!(case kind
          when :in    then { direction: :inbound, sender_type: :customer }
          when :ai    then { direction: :outbound, sender_type: :ai, delivery_status: :read }
          when :staff then { direction: :outbound, sender_type: :staff, user: rep || reps.first, delivery_status: :delivered }
        end)
        convo.messages.create!(attrs)
      end

      convo.update!(status:, assigned_user: rep)
      contact.tickets.create!(ticket_attrs.merge(conversation: convo, assignee: rep, created_at: start)) if ticket_attrs
      puts "created #{name}"
    end

    puts "\nDone. Users: admin@example.com, sara@example.com, bilal@example.com"
    puts ENV["DEMO_PASSWORD"].present? ? "Password: (DEMO_PASSWORD)" : "Password for new users: #{password}"
    puts "Existing users keep their old password."
  end

  desc "Delete demo contacts and their conversations/tickets"
  task clear: :environment do
    contacts = Contact.where("notes LIKE ?", "#{DEMO_TAG}%")
    count = contacts.count
    contacts.destroy_all
    puts "Removed #{count} demo contacts."
  end
end
