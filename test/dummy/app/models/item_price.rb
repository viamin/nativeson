# frozen_string_literal: true

class ItemPrice < ApplicationRecord
  belongs_to :item
end

#------------------------------------------------------------------------------
# ItemPrice
#
# Name           SQL Type             Null    Primary Default
# -------------- -------------------- ------- ------- ----------
# id             bigint               false   true
# item_id        bigint               true    false
# current_price  double precision     true    false
# previous_price double precision     true    false
# created_at     timestamp without time zone false   false
# updated_at     timestamp without time zone false   false
# klass          character varying    true    false   ItemPrice
#
#------------------------------------------------------------------------------
