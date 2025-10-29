module Constrainable
  extend ActiveSupport::Concern

  module ClassMethods
    def numerical_constraint(input, column, digits: 0)
      return unless input.present?
      format = "%.#{digits}f"
      case input
      when /\A[^\d.]*(\d+(?:\.\d+)?)[^\d.]+(\d+(?:\.\d+)?)[^\d.]*\z/
        min = ($1.to_f).round(digits)
        max = ($2.to_f).round(digits)
        min, max = max, min if max < min
        min == max ? "#{column} = #{format % min}" : "#{column} >= #{format % min} AND #{column} <= #{format % max}"
      when /\A[^\d><=.]*(=|>|<|>=|<=)[^\d><=.]*(\d+(?:\.\d+)?)[^\d><=.]*\z/
        rel = $1
        val = ($2.to_f).round(digits)
        "#{column} #{rel} #{format % val}"
      when /\A[^\d><=.]*(\d+(?:\.\d+)?)[^\d><=.]*\z/
        val = ($1.to_f).round(digits)
        "#{column} = #{format % val}"
      else
        nil
      end
    end

    def cross_constraint(input, cols, table: nil)
      cols = cols.map{ |c| "#{table}." + c } if table.present?
      terms = plain_terms(input) + quoted_terms(input)
      like_constraint(terms, cols)
    end

    private

    def like_constraint(terms, cols)
      return nil if terms.empty?
      clause = cols.map{ |c| "#{c} ILIKE '%%%s%%'"}.join(" OR ")
      clauses = terms.map{ |t| clause % Array.new(cols.size, t) }
      terms.size == 1 ? clauses.first : "(" + clauses.join(") AND (") + ")"
    end

    def plain_terms(input)
      input.to_s.gsub(/"[^"]*"/, "").scan(/[-〜[:alnum:]]+/)
    end

    def quoted_terms(input)
      input.to_s.scan(/"([-〜\s[:alnum:]]*)"/).flatten.reject{ |t| t.match(/\A\s*\z/) }
    end
  end
end
