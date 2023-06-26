class SubWidget < ApplicationRecord
  belongs_to :widget
end

#------------------------------------------------------------------------------
# SubWidget
#
# Name       SQL Type             Null    Primary Default
# ---------- -------------------- ------- ------- ----------
# id         bigint               false   true
# name       character varying    true    false
# widget_id  bigint               true    false
# created_at timestamp without time zone false   false
# updated_at timestamp without time zone false   false
# col_int    integer              true    false
# col_float  double precision     true    false
# col_string character varying    true    false
# klass      character varying    true    false   SubWidget
#
#------------------------------------------------------------------------------
