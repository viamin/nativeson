# frozen_string_literal: true

class ItemDescription < ApplicationRecord
  belongs_to :item
end

#------------------------------------------------------------------------------
# ItemDescription
#
# Name        SQL Type             Null    Primary Default
# ----------- -------------------- ------- ------- ----------
# id          bigint               false   true
# item_id     bigint               true    false
# description character varying    true    false
# created_at  timestamp without time zone false   false
# updated_at  timestamp without time zone false   false
# col_int     integer              true    false
# col_float   double precision     true    false
# col_string  character varying    true    false
# klass       character varying    true    false   ItemDescription
#
#------------------------------------------------------------------------------
