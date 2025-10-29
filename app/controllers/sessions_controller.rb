class SessionsController < ApplicationController
  # prepend_before_action :debug_me

  def create
    user = User.find_by(email: params[:email])
    user = user&.authenticate(params[:password]) unless current_user.admin?
    if user
      if user.otp_required?
        session[:otp_user_id] = user.id
        session.keys.each do |key|
          logger.info "#{key} => #{session[key]}"
        end
        redirect_to new_otp_secret_path
      else
        session[:user_id] = user.id
        redirect_to notes_path
      end
    else
      flash.now[:alert] = t("session.invalid")
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path
  end

  private

  def debug_me
    logger.info "Debug me"
    logger.info "method:          #{request.method}"
    logger.info "remote ip:       #{request.remote_ip}"
    logger.info "query string:    #{request.query_string}"
    logger.info "url:             #{request.url}"
    logger.info "request path:    #{request.path.chomp('/')}"
    logger.info "session keys:    #{session.keys.length}"
    session.keys.sort.each do |key|
      logger.info "key/value:       #{key} => #{session[key]}"
    end
    request.headers.to_h.sort.to_h.each_pair do |key, val|
      logger.info "header:          #{key} => #{val}"
    end
    logger.info "---------------"
    logger.info "any valid token: #{any_authenticity_token_valid?}"
    request_authenticity_tokens.each do |token|
      logger.info "token:           #{token.blank? ? 'blank' : token}"
      if token.present?
        masked_token = decode_csrf_token(token) rescue nil
        if masked_token.present?
          logger.info "masked token:    #{masked_token}"
          if masked_token.length == AUTHENTICITY_TOKEN_LENGTH
            logger.info "token length 1"
            logger.info "real token:      #{compare_with_real_token(masked_token)}"
          elsif masked_token.length == AUTHENTICITY_TOKEN_LENGTH * 2
            logger.info "token length 2"
            csrf_token = unmask_token(masked_token)
            logger.info "csrf token:      #{csrf_token}"
            logger.info "global token:    #{compare_with_global_token(csrf_token)}"
            logger.info "real token:      #{compare_with_real_token(csrf_token)}"
            logger.info "form token:      #{valid_per_form_csrf_token?(csrf_token)}"
          else
            logger.info "token length failure"
          end
        else
          logger.info "masked token:        ERROR"
        end
      end
    end
  end
end
