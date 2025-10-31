class Ability
  include CanCan::Ability

  def initialize(user)
    if user.admin?
      can :manage, :all
    end

    unless user.guest?
      can :help, :page
      can [:read, :create], Note
      can [:update, :destroy], Note, user_id: user.id
      can [:read, :create], Trip
      can [:update, :destroy], Trip, user_id: user.id
    end

    can :home, :page
    can :read, Trip
  end
end
