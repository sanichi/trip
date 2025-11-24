class Ability
  include CanCan::Ability

  def initialize(user)
    alias_action :toggle_draft, to: :update

    if user.admin?
      can :manage, :all
    end

    unless user.guest?
      can :help, :page
      can [:read, :create], Image
      can [:update, :destroy], Image, user_id: user.id
      can [:read, :create], Trip
      can [:update, :destroy], Trip, user_id: user.id
      can [:read, :create], Day
      can [:update, :destroy], Day, trip: { user_id: user.id }
    end

    can :home, :page
  end
end
