# frozen_string_literal: true

class UserProfilePic < ApplicationRecord
  belongs_to :user_profile
end

#------------------------------------------------------------------------------
# UserProfilePic
#
# Name            SQL Type             Null    Primary Default
# --------------- -------------------- ------- ------- ----------
# id              bigint               false   true
# user_profile_id bigint               true    false
# image_url       character varying    true    false
# image_width     integer              true    false
# image_height    integer              true    false
# created_at      timestamp without time zone false   false
# updated_at      timestamp without time zone false   false
# klass           character varying    true    false   UserProfilePic
#
#------------------------------------------------------------------------------
