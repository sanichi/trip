module NoteHelper
  def author_menu(selected)
    opts = User.pluck(:name, :id)
    opts.unshift [t("any"), ""]
    options_for_select(opts, selected)
  end

  def draft_menu(selected)
    opts = %w/published draft/.map{|o| [t("note.#{o}"), o]}
    opts.unshift [t("any"), ""]
    options_for_select(opts, selected)
  end
end
