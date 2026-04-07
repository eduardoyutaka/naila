module Catalyst::DividerHelper
  def catalyst_divider(soft: false, **opts)
    css = [
      "w-full border-t",
      soft ? "border-zinc-950/5 dark:border-white/5" : "border-zinc-950/10 dark:border-white/10",
      opts.delete(:class),
    ].compact.join(" ")
    tag.hr(role: "presentation", class: css, **opts)
  end
end
