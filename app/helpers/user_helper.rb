module UserHelper
  def admin(user)        = t("symbol.#{user.admin?              ? 'tick' : 'cross'}")
  def otp_required(user) = t("symbol.#{user.otp_required?       ? 'tick' : 'cross'}")
  def otp_active(user)   = t("symbol.#{user.otp_secret.present? ? 'tick' : 'cross'}")
end
