# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_10_05_205710) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "contacts", force: :cascade do |t|
    t.string "phone", null: false
    t.string "name"
    t.string "profile_name"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["phone"], name: "index_contacts_on_phone", unique: true
  end

  create_table "conversations", force: :cascade do |t|
    t.bigint "contact_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "last_message_at"
    t.datetime "last_inbound_at"
    t.bigint "assigned_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_user_id"], name: "index_conversations_on_assigned_user_id"
    t.index ["contact_id"], name: "index_conversations_on_contact_id"
    t.index ["last_message_at"], name: "index_conversations_on_last_message_at"
  end

  create_table "message_templates", force: :cascade do |t|
    t.string "name", null: false
    t.string "language", default: "en_US", null: false
    t.string "category", null: false
    t.string "status", default: "DRAFT", null: false
    t.string "wa_template_id"
    t.string "header_format"
    t.string "header_text"
    t.text "body", null: false
    t.jsonb "body_examples", default: [], null: false
    t.string "footer"
    t.jsonb "buttons", default: [], null: false
    t.string "rejected_reason"
    t.datetime "synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "components", default: [], null: false
    t.index ["name", "language"], name: "index_message_templates_on_name_and_language", unique: true
    t.index ["wa_template_id"], name: "index_message_templates_on_wa_template_id", unique: true
  end

  create_table "messages", force: :cascade do |t|
    t.bigint "conversation_id", null: false
    t.integer "direction", null: false
    t.integer "sender_type", null: false
    t.bigint "user_id"
    t.text "body"
    t.string "wa_message_id"
    t.integer "delivery_status", default: 0, null: false
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "error_message"
    t.string "template_name"
    t.string "template_language"
    t.jsonb "template_params", default: [], null: false
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
    t.index ["wa_message_id"], name: "index_messages_on_wa_message_id", unique: true
  end

  create_table "tickets", force: :cascade do |t|
    t.bigint "contact_id", null: false
    t.bigint "conversation_id"
    t.bigint "assignee_id"
    t.string "title", null: false
    t.text "summary"
    t.string "product_interest"
    t.string "budget"
    t.integer "status", default: 0, null: false
    t.integer "priority", default: 1, null: false
    t.integer "source", default: 0, null: false
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "value", precision: 14, scale: 2
    t.index ["assignee_id"], name: "index_tickets_on_assignee_id"
    t.index ["contact_id"], name: "index_tickets_on_contact_id"
    t.index ["conversation_id"], name: "index_tickets_on_conversation_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", default: "", null: false
    t.integer "role", default: 0, null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "conversations", "contacts"
  add_foreign_key "conversations", "users", column: "assigned_user_id"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users"
  add_foreign_key "tickets", "contacts"
  add_foreign_key "tickets", "conversations"
  add_foreign_key "tickets", "users", column: "assignee_id"
end
