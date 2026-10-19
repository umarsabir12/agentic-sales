class Users::RegistrationsController < Devise::RegistrationsController
  layout "auth"

  protected
    # The first account on a new install becomes the admin, so production can be set up
    # without a console. Everyone after that waits for an admin's approval.
    def build_resource(hash = {})
      super
      if User.none?
        resource.role = :admin
        resource.approved_at = Time.current
      end
    end

    def sign_up_params
      params.expect(user: %i[ name company email password ])
    end
end
