# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120305081024) do

  create_table "ad_unit_sizes", :force => true do |t|
    t.integer  "height"
    t.integer  "width"
    t.boolean  "is_aspect_ratio"
    t.string   "environment_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "network_id"
  end

  create_table "ad_unit_sizes_ad_units", :id => false, :force => true do |t|
    t.integer "ad_unit_id"
    t.integer "ad_unit_size_id"
  end

  add_index "ad_unit_sizes_ad_units", ["ad_unit_id"], :name => "index_ad_unit_sizes_ad_units_on_ad_unit_id"

  create_table "ad_units", :force => true do |t|
    t.string   "dfp_id"
    t.string   "parent_id_dfp"
    t.string   "parent_id_bulk"
    t.string   "name"
    t.string   "description"
    t.string   "target_window"
    t.string   "target_platform"
    t.boolean  "explicitly_targeted"
    t.integer  "level"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "synced_at"
    t.integer  "network_id"
  end

  add_index "ad_units", ["network_id", "parent_id_dfp"], :name => "index_ad_units_on_network_id_and_parent_id_dfp"
  add_index "ad_units", ["network_id"], :name => "index_ad_units_on_network_id"
  add_index "ad_units", ["parent_id_bulk", "name"], :name => "index_ad_units_on_parent_id_bulk_and_name"
  add_index "ad_units", ["parent_id_bulk"], :name => "index_ad_units_on_parent_id_bulk"

  create_table "companies", :force => true do |t|
    t.string   "name"
    t.string   "company_type"
    t.text     "address"
    t.string   "email"
    t.string   "fax_phone"
    t.string   "primary_phone"
    t.string   "dfp_id"
    t.text     "comment"
    t.string   "credit_status"
    t.boolean  "enable_same_advertiser_competitive_exclusion"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "external_id"
    t.datetime "synced_at"
    t.integer  "network_id"
  end

  add_index "companies", ["network_id", "dfp_id"], :name => "index_companies_on_network_id_and_dfp_id"
  add_index "companies", ["network_id", "name", "company_type"], :name => "index_companies_on_network_id_and_name_and_company_type", :unique => true
  add_index "companies", ["network_id"], :name => "index_companies_on_network_id"

  create_table "companies_labels", :id => false, :force => true do |t|
    t.integer "company_id"
    t.integer "label_id"
  end

  create_table "companion_associations", :force => true do |t|
    t.integer  "ad_unit_size_id"
    t.integer  "companion_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "dfp_users", :force => true do |t|
    t.string   "name"
    t.string   "email"
    t.string   "role_name"
    t.string   "role_id"
    t.integer  "network_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "labels", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.string   "label_type"
    t.string   "dfp_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "synced_at"
    t.integer  "network_id"
  end

  add_index "labels", ["network_id", "name"], :name => "index_labels_on_network_id_and_name"
  add_index "labels", ["network_id"], :name => "index_labels_on_network_id"

  create_table "orders", :force => true do |t|
    t.string   "advertiser_id"
    t.string   "name"
    t.string   "trafficker_id"
    t.string   "sales_person_id"
    t.string   "agency_id"
    t.string   "external_order_id"
    t.string   "po_number"
    t.integer  "network_id"
    t.text     "notes"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "uploads", :force => true do |t|
    t.string   "name"
    t.string   "location"
    t.string   "datatype"
    t.string   "filename"
    t.boolean  "imported"
    t.string   "errors_file"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "network_id"
    t.string   "created_file"
    t.string   "not_created_file"
  end

  add_index "uploads", ["network_id"], :name => "index_uploads_on_network_id"

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "password"
    t.integer  "network_id"
    t.string   "environment"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
