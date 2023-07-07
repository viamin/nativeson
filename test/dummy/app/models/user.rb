# frozen_string_literal: true

class User < ApplicationRecord
  has_many :items, dependent: :destroy
  has_many :item_prices, through: :items
  has_many :widgets, dependent: :destroy
  has_one :user_profile, dependent: :destroy
  has_many :sub_widgets, through: :widgets
end

#------------------------------------------------------------------------------
# User
#
# Name        SQL Type             Null    Primary Default
# ----------- -------------------- ------- ------- ----------
# id          bigint               false   true
# created_at  timestamp without time zone false   false
# updated_at  timestamp without time zone false   false
# name        character varying    true    false
# email       character varying    true    false
# col_int     integer              true    false
# col_float   double precision     true    false
# col_string  character varying    true    false
# klass       character varying    true    false   User
# permissions jsonb                true    false
# timezone    character varying    true    false   UTC
#
#------------------------------------------------------------------------------
