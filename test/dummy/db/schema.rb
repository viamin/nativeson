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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_10_05_191517) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "item_descriptions", force: :cascade do |t|
    t.bigint "item_id"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "col_int"
    t.float "col_float"
    t.string "col_string"
    t.string "klass", default: "ItemDescription"
    t.index ["item_id"], name: "index_item_descriptions_on_item_id", unique: true
  end

  create_table "item_prices", force: :cascade do |t|
    t.bigint "item_id"
    t.float "current_price"
    t.float "previous_price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "klass", default: "ItemPrice"
    t.index ["item_id"], name: "index_item_prices_on_item_id"
  end

  create_table "items", force: :cascade do |t|
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.integer "col_int"
    t.float "col_float"
    t.string "col_string"
    t.string "klass", default: "Item"
    t.index ["user_id"], name: "index_items_on_user_id"
  end

  create_table "sub_widgets", force: :cascade do |t|
    t.string "name"
    t.bigint "widget_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "col_int"
    t.float "col_float"
    t.string "col_string"
    t.string "klass", default: "SubWidget"
    t.index ["widget_id"], name: "index_sub_widgets_on_widget_id"
  end

  create_table "user_profile_pics", force: :cascade do |t|
    t.bigint "user_profile_id"
    t.string "image_url"
    t.integer "image_width"
    t.integer "image_height"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "klass", default: "UserProfilePic"
    t.index ["user_profile_id"], name: "index_user_profile_pics_on_user_profile_id", unique: true
  end

  create_table "user_profiles", force: :cascade do |t|
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.integer "col_int"
    t.float "col_float"
    t.string "col_string"
    t.string "klass", default: "UserProfile"
    t.index ["user_id"], name: "index_user_profiles_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "email"
    t.integer "col_int"
    t.float "col_float"
    t.string "col_string"
    t.string "klass", default: "User"
  end

  create_table "widgets", force: :cascade do |t|
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.integer "col_int"
    t.float "col_float"
    t.string "col_string"
    t.string "klass", default: "Widget"
    t.index ["user_id"], name: "index_widgets_on_user_id"
  end

end
