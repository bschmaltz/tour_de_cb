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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150121080729) do

  create_table "current_race_updates", force: true do |t|
    t.integer  "uid"
    t.integer  "rid"
    t.float    "distance"
    t.float    "game_time"
    t.float    "speed"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "lobbies", force: true do |t|
    t.string   "name"
    t.integer  "limit"
    t.string   "password"
    t.boolean  "racing"
    t.string   "map"
    t.string   "host"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "lobbies", ["name"], name: "index_lobbies_on_name", unique: true

  create_table "race_summaries", force: true do |t|
    t.integer  "uid"
    t.integer  "rid"
    t.integer  "place"
    t.float    "time"
    t.float    "distance"
    t.float    "calories"
    t.string   "map"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "races", force: true do |t|
    t.integer  "lid"
    t.integer  "rid"
    t.datetime "end_time"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", force: true do |t|
    t.string   "session_id", null: false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", unique: true
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at"

  create_table "users", force: true do |t|
    t.string  "email"
    t.string  "password"
    t.string  "password_confirmation"
    t.binary  "password_digest"
    t.float   "distance_travelled"
    t.string  "secret_key"
    t.integer "lid"
    t.float   "total_dis"
    t.string  "race_status"
  end

end
